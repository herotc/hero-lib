--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache, Utils = HeroCache, HL.Utils
local Unit = HL.Unit
local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid = Unit.Party, Unit.Raid
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local IsSpellKnown = IsSpellKnown
local IsPlayerSpell = IsPlayerSpell
local IsUsableSpell = IsUsableSpell
local GetSpellCount = GetSpellCount
local GetSpellPowerCost = GetSpellPowerCost
local pairs = pairs
local unpack = unpack
local wipe = table.wipe
-- File Locals



--- ============================ CONTENT ============================
-- Get the spell ID.
function Spell:ID()
  return self.SpellID
end

-- Get the spell Type.
function Spell:Type()
  return self.SpellType
end

-- Get the Time since Last spell Cast.
function Spell:TimeSinceLastCast()
  return GetTime() - self.LastCastTime
end

-- Get the Time since Last spell Display.
function Spell:TimeSinceLastDisplay()
  return GetTime() - self.LastDisplayTime
end

-- Get the Time since Last Buff applied on the player.
function Spell:TimeSinceLastAppliedOnPlayer()
  return GetTime() - self.LastAppliedOnPlayerTime
end

-- Get the Time since Last Buff removed from the player.
function Spell:TimeSinceLastRemovedOnPlayer()
  return GetTime() - self.LastRemovedFromPlayerTime
end

-- Register the spell damage formula.
function Spell:RegisterDamage(Function)
  self.DamageFormula = Function
end

-- Get the spell damage formula if it exists.
function Spell:Damage()
  return self.DamageFormula and self.DamageFormula() or 0
end

-- Get the spell Info.
function Spell:Info(Type, Index)
  local Identifier
  if Type == "ID" then
    Identifier = self:ID()
  elseif Type == "Name" then
    Identifier = self:Name()
  else
    error("Spell Info Type Missing.")
  end
  if not Identifier then error("Identifier Not Found.") end

  local SpellInfo = Cache.SpellInfo[Identifier]
  if not SpellInfo then
    Cache.SpellInfo[Identifier] = {}
    SpellInfo = Cache.SpellInfo[Identifier]
  end

  local Info = Cache.SpellInfo[Identifier].Info
  if not Info then
    Cache.SpellInfo[Identifier].Info = { GetSpellInfo(Identifier) }
    Info = Cache.SpellInfo[Identifier].Info
  end

  return Index and Info[Index] or unpack(Info)
end

-- Get the spell Info from the spell ID.
function Spell:InfoID(Index)
  return self:Info("ID", Index)
end

-- Get the spell Info from the spell Name.
function Spell:InfoName(Index)
  return self:Info("Name", Index)
end

-- Get the spell Name.
function Spell:Name()
  return self:Info("ID", 1)
end

-- Get the spell Minimum Range.
function Spell:MinimumRange()
  return self:InfoID(5)
end

-- Get the spell Maximum Range.
function Spell:MaximumRange()
  return self:InfoID(6)
end

-- Check if the spell Is Melee or not.
function Spell:IsMelee()
  return self:MinimumRange() == 0 and self:MaximumRange() == 0
end

-- Check if the spell Is Available or not.
function Spell:IsAvailable(CheckPet)
  return CheckPet and IsSpellKnown(self.SpellID, true) or IsPlayerSpell(self.SpellID)
end

-- Check if the spell Is Known or not.
function Spell:IsKnown(CheckPet)
  return IsSpellKnown(self.SpellID, CheckPet and true or false)
end

-- Check if the spell Is Known (including Pet) or not.
function Spell:IsPetKnown()
  return self:IsKnown(true)
end

-- Check if the spell Is Usable or not.
function Spell:IsUsable()
  return IsUsableSpell(self.SpellID)
end

-- Check if the spell is Usable (by resources) in predicted mode
function Spell:IsUsableP(Offset)
  local CostTable = self:CostTable()
  local Usable = true
  if #CostTable > 0 then
    local i = 1
    while ( Usable == true ) and ( i <= #CostTable ) do
        local CostInfo = CostTable[i]
        local Type = CostInfo.type
        if ( Player.PredictedResourceMap[Type]() < ( ( (self.CustomCost and self.CustomCost[Type]) and self.CustomCost[Type]() or CostInfo.minCost ) + ( Offset and Offset or 0 ) ) ) then Usable = false end
        i = i + 1
    end
  end
  return Usable
end

-- Only checks IsUsableP against the primary resource for pooling
function Spell:IsUsablePPool(Offset)
  local CostTable = self:CostTable()
  if #CostTable > 0 then
    local CostInfo = CostTable[1]
    local Type = CostInfo.type
    return ( Player.PredictedResourceMap[Type]() >= ( ( (self.CustomCost and self.CustomCost[Type]) and self.CustomCost[Type]() or CostInfo.minCost ) + ( Offset and Offset or 0 ) ) )
  else
    return true
  end
end

-- Check if the spell is in the Spell Learned Cache.
function Spell:IsLearned()
  return Cache.Persistent.SpellLearned[self:Type()][self:ID()] or false
end

function Spell:Count()
  return GetSpellCount(self:ID())
end

--[[*
  * @function Spell:IsCastable
  * @desc Check if the spell Is Castable or not.
  *
  * @param {number} [Range] - Range to check.
  * @param {boolean} [AoESpell] - Is it an AoE Spell ?
  * @param {object} [ThisUnit=Target] - Unit to check the range for.
  *
  * @returns {boolean}
  *]]
function Spell:IsCastable(Range, AoESpell, ThisUnit)
  if Range then
    local RangeUnit = ThisUnit or Target
    return self:IsLearned() and self:CooldownUp() and RangeUnit:IsInRange(Range, AoESpell)
  else
    return self:IsLearned() and self:CooldownUp()
  end
end

--[[*
  * @function Spell:IsCastableP
  * @override Spell:IsCastable
  * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Spell:IsCastableP(Range, AoESpell, ThisUnit, BypassRecovery, Offset)
  if Range then
    local RangeUnit = ThisUnit or Target
    return self:IsLearned() and self:CooldownRemainsP(BypassRecovery or true, Offset or "Auto") == 0 and RangeUnit:IsInRange(Range, AoESpell)
  else
    return self:IsLearned() and self:CooldownRemainsP(BypassRecovery or true, Offset or "Auto") == 0
  end
end

-- Check if the spell Is Castable and Usable or not.
function Spell:IsReady(Range, AoESpell, ThisUnit)
  return self:IsCastable(Range, AoESpell, ThisUnit) and self:IsUsable()
end

-- Check if the spell Is CastableP and UsableP or not.
function Spell:IsReadyP(Range, AoESpell, ThisUnit)
  return self:IsCastableP(Range, AoESpell, ThisUnit) and self:IsUsableP()
end

-- action.foo.cast_time
function Spell:CastTime()
  local CastTime = self:InfoID(4)

  return CastTime and self:InfoID(4) / 1000 or 0
end

-- action.foo.execute_time
function Spell:ExecuteTime()
  local CastTime = self:CastTime()
  local GCD = Player:GCD()

  return CastTime > GCD and CastTime or GCD
end

-- Get the CostTable using GetSpellPowerCost.
function Spell:CostTable()
  local SpellID = self.SpellID
  local SpellInfo = Cache.SpellInfo[SpellID]
  if not SpellInfo then
    SpellInfo = {}
    Cache.SpellInfo[SpellID] = SpellInfo
  end

  local CostTable = SpellInfo.CostTable
  if not CostTable then
    -- {hasRequiredAura, type, name, cost, minCost, requiredAuraID, costPercent, costPerSec}
    CostTable = GetSpellPowerCost(SpellID)
    SpellInfo.CostTable = CostTable
  end

  return CostTable
end

-- Get the CostInfo from the CostTable.
function Spell:CostInfo(Index, Key)
  if not Key or type(Key) ~= "string" then error("Invalid Key type.") end

  local CostTable = self:CostTable()

  return CostTable and CostTable[Index] and CostTable[Index][Key] or nil
end

-- action.foo.cost
function Spell:Cost(Index)
  local Index = Index or 1
  local Cost = self:CostInfo(Index, "cost")

  return Cost or 0
end

-- action.foo.tick_time
local TickTime = HL.Enum.TickTime
function Spell:FilterTickTime(SpecID)
  local RegisteredSpells = {}
  local BaseTickTime = HL.Enum.TickTime
  -- Fetch registered spells during the init
  for Spec, Spells in pairs(HL.Spell[HL.SpecID_ClassesSpecs[SpecID][1]]) do
    for _, Spell in pairs(Spells) do
      local SpellID = Spell:ID()
      local TickTimeInfo = BaseTickTime[SpellID][1]
      if TickTimeInfo ~= nil then
        RegisteredSpells[SpellID] = TickTimeInfo
      end
    end
  end
  TickTime = RegisteredSpells
end

-- active_dot.foo
function Spell:ActiveDot()
  if not Cache.Enemies[50] then HL.GetEnemies(50) end
  local Active = 0
  for _, Enemy in pairs(Cache.Enemies[50]) do
    if Enemy:DebuffP(self) then Active = Active + 1 end
  end
  return Active
end

function Spell:BaseTickTime()
  local Tick = TickTime[self.SpellID]
  if not Tick or Tick == 0 then return 0 end
  local TickTime = Tick[1]
  return TickTime / 1000
end

function Spell:TickTime()
  local BaseTickTime = self:BaseTickTime()
  if not BaseTickTime or BaseTickTime == 0 then return 0 end
  local Hasted = TickTime[self.SpellID][2]
  if Hasted then return BaseTickTime * Player:SpellHaste() end
  return BaseTickTime
end

-- Base Duration of a dot/hot/channel...
local SpellDuration = HL.Enum.SpellDuration
function Spell:BaseDuration()
  local Duration = SpellDuration[self.SpellID]
  if not Duration or Duration == 0 then return 0 end
  local BaseDuration = Duration[1]
  return BaseDuration / 1000
end

function Spell:MaxDuration()
  local Duration = SpellDuration[self.SpellID]
  if not Duration or Duration == 0 then return 0 end
  local BaseDuration = Duration[2]
  return BaseDuration / 1000
end

function Spell:PandemicThreshold()
  local BaseDuration = self:BaseDuration()
  if not BaseDuration or BaseDuration == 0 then return 0 end
  return BaseDuration * 0.3
end

local SpellGCD = HL.Enum.TriggerGCD
function Spell:GCD()
  local Gcd = SpellGCD[self.SpellID]
  if not Gcd or Gcd == 0 then return 0 end
  return Gcd / 1000
end
