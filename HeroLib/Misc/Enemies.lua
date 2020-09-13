--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache, Utils = HeroCache, HL.Utils
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
local GetTime = GetTime
local RangeIndex = HL.Enum.ItemRange.Hostile.RangeIndex
-- Lua
local pairs = pairs
local tableinsert = table.insert
local tablesort = table.sort
local wipe = table.wipe
-- File Locals
local Enemies = Cache.Enemies
local EnemiesCount = Cache.EnemiesCount
local UnitIDs = {
  "Arena",
  "Boss",
  "Nameplate"
}

do
  HL.RangeTracker = {
    AbilityTimeout = 1,
    NucleusAbilities = {},
    SplashableCount = {}
  }
end
local RT = HL.RangeTracker;

--- ============================ RANGE COUNT ============================

local function NumericRange(range)
  return range == "Melee" and 5 or range;
end

local function UpdateEnemiesCount(Distance, AoESpell)
  local DistanceType, Identifier = type(Distance), nil
  -- Regular ranged distance check through IsItemInRange & Special distance check (like melee)
  if DistanceType == "number" or (DistanceType == "string" and Distance == 'Melee') then
    Identifier = Distance
    -- Distance check through IsSpellInRange (works only for targeted spells only)
  elseif DistanceType == "table" then
    Identifier = tostring(Distance:ID())
  else
    error("Invalid Distance.")
  end
  -- Prevent building the same table if it's already cached.
  if Enemies[Identifier] then return end
  -- Init the Variables used to build the table.
  local EnemiesTable = {}
  Enemies[Identifier] = EnemiesTable
  -- Check if there is another Enemies table with a greater Distance to filter from it.
  if #Enemies >= 1 and type(Distance) == "number" then
    local DistanceValues = {}
    for Key, _ in pairs(Enemies) do
      if type(Key) == "number" and Key >= Distance then
        tableinsert(DistanceValues, Key)
      end
    end
    -- Check if we have caught a table that we can use.
    if #DistanceValues >= 1 then
      if #DistanceValues >= 2 then
        tablesort(DistanceValues, Utils.SortASC)
      end
      for _, DistanceUnit in pairs(Enemies[DistanceValues[1]]) do
        if DistanceUnit:IsInRange(Distance, AoESpell) then
          tableinsert(EnemiesTable, DistanceUnit)
        end
      end
      return
    end
  end
  -- Else build from all the available units.
  local InsertedUnits = {}
  for _, UnitID in pairs(UnitIDs) do
    local Units = Unit[UnitID]
    for _, ThisUnit in pairs(Units) do
      local GUID = ThisUnit:GUID()
      if not InsertedUnits[GUID] and ThisUnit:Exists() and not ThisUnit:IsBlacklisted()
        and not ThisUnit:IsUserBlacklisted() and not ThisUnit:IsDeadOrGhost() and Player:CanAttack(ThisUnit)
        and ThisUnit:IsInRange(Distance, AoESpell) then
        tableinsert(EnemiesTable, ThisUnit)
        InsertedUnits[GUID] = true
      end
    end
  end
  -- Cache the count of enemies
  EnemiesCount[Identifier] = #EnemiesTable
end

--- ============================ SPLASH DATA ============================

do
  local UpdateAbilityCache = function (...)
    local _,_,_,_,_,_,_,DestGUID,_,_,_,SpellID = ...;
    local Ability = RT.NucleusAbilities[SpellID];
    if Ability then
      if Ability.LastDamageTime+RT.AbilityTimeout < GetTime() then
        wipe(Ability.LastDamaged);
      end

      Ability.LastDamaged[DestGUID] = true;
      Ability.LastDamageTime = GetTime();
    end
  end

  HL:RegisterForSelfCombatEvent(UpdateAbilityCache, "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE");
  HL:RegisterForPetCombatEvent(UpdateAbilityCache, "SPELL_DAMAGE");
end

HL:RegisterForEvent(
  function()
    local GUID = Target:GUID()
    for _, Ability in pairs(RT.NucleusAbilities) do
      if Ability.LastDamaged[GUID] then
        --If the new Target is already known we just retain the proximity map
      else
        --Otherwise we Reset
        wipe(Ability.LastDamaged);
        Ability.LastDamageTime = 0;
      end
    end
  end
, "PLAYER_TARGET_CHANGED");

HL:RegisterForCombatEvent(
  function (...)
    local DestGUID = select(8, ...);
    for _, Ability in pairs(RT.NucleusAbilities) do
      Ability.LastDamaged[DestGUID] = nil;
    end
  end
, "UNIT_DIED", "UNIT_DESTROYED");

local function EffectiveRangeSanitizer(EffectiveRange)
  --The Enemies Cache only works for specific Ranges
  for i=2,#RangeIndex do
    if RangeIndex[i] >= EffectiveRange then
      return RangeIndex[i]
    end
  end
  return -1
end

local function RecentlyDamagedIn(GUID, SplashRange)
  local ValidAbility = false
  for _, Ability in pairs(RT.NucleusAbilities) do
    --The Ability needs to have splash radius thats smaller or equal to over
    if SplashRange >= Ability.Range then
      ValidAbility = true
      if Ability.LastDamageTime+Ability.Timeout > GetTime() then
        if Ability.LastDamaged[GUID] and Ability.LastDamaged then return true end
      end
    end
  end
  --If we didnt find a valid ability we return true
  return not ValidAbility;
end

local function UpdateSplashCount(UpdateUnit, SplashRange)
  if not UpdateUnit:Exists() then return end

  -- Purge abilities that don't contain our current target
  -- Mostly for cases where our pet AoE damaged enemies after we target swapped
  local TargetGUID = Target:GUID()
  for _, Ability in pairs(RT.NucleusAbilities) do
    if not Ability.LastDamaged[TargetGUID] then
      wipe(Ability.LastDamaged);
      Ability.LastDamageTime = 0;
    end
  end

  local Distance = NumericRange(UpdateUnit:MaxDistanceToPlayer());
  local MaxRange = EffectiveRangeSanitizer(Distance+SplashRange);
  local MinRange = EffectiveRangeSanitizer(Distance-SplashRange);

  --Prevent calling Get Enemies twice
  if not EnemiesCount[MaxRange] then
    UpdateEnemiesCount(MaxRange);
  end

  -- Use the Enemies Cache as the starting point
  local TotalEnemies = Enemies[MaxRange]
  local CurrentCount = 0
  for _, Enemy in pairs(TotalEnemies) do
    --Units that are outside of the parameters or havent been seen lately get removed
    if NumericRange(Enemy:MaxDistanceToPlayer(true)) >= MinRange
    and NumericRange(Enemy:MinDistanceToPlayer(true)) < MaxRange
    and RecentlyDamagedIn(Enemy:GUID(), SplashRange) then
      CurrentCount = CurrentCount + 1
    end
  end

  if not RT.SplashableCount[UpdateUnit:GUID()] then
    RT.SplashableCount[UpdateUnit:GUID()] = {}
  end
  RT.SplashableCount[UpdateUnit:GUID()][SplashRange] = CurrentCount
end

function HL.GetSplashCount(UpdateUnit, SplashRange)
  if not UpdateUnit:Exists() then return 0 end

  local SplashableUnit = RT.SplashableCount[UpdateUnit:GUID()];
  if SplashableUnit and SplashableUnit[SplashRange] then
    return math.max(1, SplashableUnit[SplashRange])
  end

  return 1;
end

function HL.ValidateSplashCache()
  for _, Ability in pairs(RT.NucleusAbilities) do
    if Ability.LastDamageTime+Ability.Timeout > GetTime() then return true; end
  end
  return false;
end

function HL.RegisterNucleusAbility(AbilityId, AbilityRange, AbilityTimeout)
  local AbilityIdType = type(AbilityId)
  AbilityTimeout = AbilityTimeout or 4
  AbilityRange = AbilityRange or 8

  if AbilityId == nil then
    error("RegisterNucleusAbility - Invalid nil Id")
    return
  elseif (AbilityIdType ~= "number" and AbilityIdType ~= "table") or type(AbilityRange) ~= "number" or type(AbilityTimeout) ~= "number" then
    error("RegisterNucleusAbility - Invalid non-numeric values")
    return
  elseif (AbilityIdType ~= "table" and AbilityId < 1) or AbilityRange < 1 or AbilityTimeout < 1 then
    error("RegisterNucleusAbility - Invalid non-positive values")
    return
  end

  local NucleusAbility = {
    Range=AbilityRange,
    LastDamageTime=0,
    LastDamaged={},
    Timeout=AbilityTimeout
  }

  -- Table cases are for when we want multiple spell IDs to map to a single tracking event
  -- This is useful in cases where a spell procs secondary cleave abilities on secondary targets
  if AbilityIdType == "table" then
    for _, Id in pairs(AbilityId) do
      if type(Id) == "number" then
        HL.Debug("RegisterNucleusAbility - Adding ability " .. Id .. " with " .. AbilityRange .. "y distance")
        RT.NucleusAbilities[Id] = NucleusAbility
      end
    end
  else
    HL.Debug("RegisterNucleusAbility - Adding ability " .. AbilityId .. " with " .. AbilityRange .. "y distance")
    RT.NucleusAbilities[AbilityId] = NucleusAbility
  end
end

function HL.UnregisterNucleusAbilities()
  HL.Debug("UnregisterNucleusAbilities()")
  HL.RangeTracker = {
    AbilityTimeout = 1,
    NucleusAbilities = {},
    SplashableCount = {}
  }
end

--- ============================ CONTENT ============================
-- Fill the Enemies Cache table.
function HL.GetEnemies(Distance, AoESpell, UseSplashData, SplashTargetUnit)
  if UseSplashData then
    if type(Distance) ~= "number" then
      error("Invalid Splash Distance")
      return
    end
    UpdateSplashCount(SplashTargetUnit, Distance)
    EnemiesCount[Distance] = HL.GetSplashCount(SplashTargetUnit, Distance)
  else
    UpdateEnemiesCount(Distance, AoESpell)
  end
end
