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
local mathmax = math.max
local mathmin = math.min
local pairs = pairs
local select = select
local tableinsert = table.insert
local type = type
local unpack = unpack
local wipe = table.wipe
local GetInstanceInfo = GetInstanceInfo
-- File Locals



--- ============================ CONTENT ============================
local TTD = {
  Settings = {
    -- Refresh time (seconds) : min=0.1,  max=2,    default = 0.1
    Refresh = 0.1,
    -- History time (seconds) : min=5,    max=120,  default = 10+0.4
    HistoryTime = 10 + 0.4,
    -- Max history count :      min=20,   max=500,  default = 100
    HistoryCount = 100
  },
  Cache = {}, -- A cache of unused { time, value } tables to reduce garbage due to table creation
  IterableUnits = {
    Target,
    Focus,
    MouseOver,
    unpack(Utils.MergeTable(Boss, Nameplate))
  }, -- It's not possible to unpack multiple tables during the creation process, so we merge them before unpacking it (not efficient but done only 1 time)
  -- TODO: Improve IterableUnits creation
  Units = {}, -- Used to track units
  ExistingUnits = {}, -- Used to track GUIDs of currently existing units (to be compared with tracked units)
  Throttle = 0
}
HL.TTD = TTD

function HL.TTDRefresh()
  -- This may not be needed if we don't have any units but caching them in case
  -- We do speeds it all up a little bit
  local CurrentTime = GetTime()
  local HistoryCount = TTD.Settings.HistoryCount
  local HistoryTime = TTD.Settings.HistoryTime
  local TTDCache = TTD.Cache
  local IterableUnits = TTD.IterableUnits
  local Units = TTD.Units
  local ExistingUnits = TTD.ExistingUnits

  wipe(ExistingUnits)

  local ThisUnit
  for i = 1, #IterableUnits do
    ThisUnit = IterableUnits[i]
    if ThisUnit:Exists() then
      local GUID = ThisUnit:GUID()
      -- Check if we didn't already scanned this unit.
      if not ExistingUnits[GUID] then
        ExistingUnits[GUID] = true
        local HealthPercentage = ThisUnit:HealthPercentage()
        -- Check if it's a valid unit
        if Player:CanAttack(ThisUnit) and HealthPercentage < 100 then
          local UnitTable = Units[GUID]
          -- Check if we have seen one time this unit, if we don't then initialize it.
          if not UnitTable or HealthPercentage > UnitTable[1][1][2] then
            UnitTable = { {}, CurrentTime }
            Units[GUID] = UnitTable
          end
          local Values = UnitTable[1]
          local Time = CurrentTime - UnitTable[2]
          -- Check if the % HP changed since the last check (or if there were none)
          if not Values or HealthPercentage ~= Values[2] then
            local Value
            local LastIndex = #TTDCache
            -- Check if we can re-use a table from the cache
            if LastIndex == 0 then
              Value = { Time, HealthPercentage }
            else
              Value = TTDCache[LastIndex]
              TTDCache[LastIndex] = nil
              Value[1] = Time
              Value[2] = HealthPercentage
            end
            tableinsert(Values, 1, Value)
            local n = #Values
            -- Delete values that are no longer valid
            while (n > HistoryCount) or (Time - Values[n][1] > HistoryTime) do
              TTDCache[#Cache + 1] = Values[n]
              Values[n] = nil
              n = n - 1
            end
          end
        end
      end
    end
  end

  -- Not sure if it's even worth it to do this here
  -- Ideally this should be event driven or done at least once a second if not less
  for Key in pairs(Units) do
    if not ExistingUnits[Key] then
      Units[Key] = nil
    end
  end
end

-- Get the estimated time to reach a Percentage
-- TODO : Cache the result, not done yet since we mostly use TimeToDie that cache for TimeToX 0%.
-- Returns Codes :
-- 11111 : No GUID
--  9999 : Negative TTD
--  8888 : Not Enough Samples or No Health Change
--  7777 : No DPS
--  6666 : Dummy
--    25 : A Player
function Unit:TimeToX(Percentage, MinSamples)
  if self:IsDummy() then return 6666 end
  if self:IsAPlayer() and Player:CanAttack(self) then return 25 end
  local Seconds = 8888
  local UnitTable = TTD.Units[self:GUID()]
  -- Simple linear regression
  -- ( E(x^2)  E(x) )  ( a )  ( E(xy) )
  -- ( E(x)     n  )  ( b ) = ( E(y)  )
  -- Format of the above: ( 2x2 Matrix ) * ( 2x1 Vector ) = ( 2x1 Vector )
  -- Solve to find a and b, satisfying y = a + bx
  -- Matrix arithmetic has been expanded and solved to make the following operation as fast as possible
  if UnitTable then
    local MinSamples = MinSamples or 3
    local Values = UnitTable[1]
    local n = #Values
    if n > MinSamples then
      local a, b = 0, 0
      local Ex2, Ex, Exy, Ey = 0, 0, 0, 0

      for i = 1, n do
        local Value = Values[i]
        local x, y = Value[1], Value[2]

        Ex2 = Ex2 + x * x
        Ex = Ex + x
        Exy = Exy + x * y
        Ey = Ey + y
      end
      -- Invariant to find matrix inverse
      local Invariant = 1 / (Ex2 * n - Ex * Ex)
      -- Solve for a and b
      a = (-Ex * Exy * Invariant) + (Ex2 * Ey * Invariant)
      b = (n * Exy * Invariant) - (Ex * Ey * Invariant)
      if b ~= 0 then
        -- Use best fit line to calculate estimated time to reach target health
        Seconds = (Percentage - a) / b
        -- Subtract current time to obtain "time remaining"
        Seconds = mathmin(7777, Seconds - (GetTime() - UnitTable[2]))
        if Seconds < 0 then Seconds = 9999 end
      end
    end
  end
  return Seconds
end

-- Get the unit TTD Percentage
local SpecialTTDPercentageData = {
  --- Shadowlands
  ----- Dungeons -----
  --- De Other Side
  -- Mueh'zala leaves the fight at 10%.
  [166608] = 10,
  --- Mists of Tirna Scithe
  -- Tirnenns leaves the fight at 20%.
  [164929] = 20, -- Tirnenn Villager
  [164804] = 20, -- Droman Oulfarran
  --- Sanguine Depths
  -- General Kaal leaves the fight at 50%.
  [162099] = 50,
  ----- Castle of Nathria -----
  --- Stone Legion Generals
  -- General Kaal leaves the fight at 50% if General Grashaal has not fight yet. We take 49% as check value since it get -95% dmg reduction at 50% until intermission is over.
  [168112] = function(self) return (not self:CheckHPFromBossList(168113, 99) and 49) or 0 end,
  --- Sun King's Salvation
  -- Shade of Kael'thas fight is 60% -> 45% and then 10% -> 0%.
  [165805] = function(self) return (self:HealthPercentage() > 20 and 45) or 0 end,

  --- Legion
  ----- Open World  -----
  --- Stormheim Invasion
  -- Lord Commander Alexius
  [118566] = 85,
  ----- Dungeons -----
  --- Halls of Valor
  -- Hymdall leaves the fight at 10%.
  [94960] = 10,
  -- Fenryr leaves the fight at 60%. We take 50% as check value since it doesn't get immune at 60%.
  [95674] = function(self) return (self:HealthPercentage() > 50 and 60) or 0 end,
  -- Odyn leaves the fight at 80%.
  [95676] = 80,
  --- Maw of Souls
  -- Helya leaves the fight at 70%.
  [96759] = 70,
  ----- Trial of Valor -----
  --- Odyn
  -- Hyrja & Hymdall leaves the fight at 25% during first stage and 85%/90% during second stage (HM/MM).
  [114360] = function(self) return (not self:CheckHPFromBossList(114263, 99) and 25) or (Player:InstanceDifficulty() == 16 and 85) or 90 end,
  [114361] = function(self) return (not self:CheckHPFromBossList(114263, 99) and 25) or (Player:InstanceDifficulty() == 16 and 85) or 90 end,
  -- Odyn leaves the fight at 10%.
  [114263] = 10,
  ----- Nighthold -----
  --- Elisande leaves the fight two times at 10% then normally dies. She looses 50% power per stage (100 -> 50 -> 0).
  [106643] = function(self) return (self:Power() > 0 and 10) or 0 end,

  --- Warlord of Draenor (WoD)
  ----- Dungeons -----
  --- Shadowmoon Burial Grounds
  -- Carrion Worm doesn't die but leave the area at 10%.
  [88769] = 10,
  [76057] = 10,
  ----- HellFire Citadel -----
  --- Hellfire Assault
  -- Mar'Tak doesn't die and leave fight at 50% (blocked at 1hp anyway).
  [93023] = 50,
}
function Unit:SpecialTTDPercentage(NPCID)
  local SpecialTTDPercentage = SpecialTTDPercentageData[NPCID]
  if not SpecialTTDPercentage then return 0 end

  if type(SpecialTTDPercentage) == "number" then
    return SpecialTTDPercentage
  end

  return SpecialTTDPercentage(self)
end

-- Get the unit TimeToDie
function Unit:TimeToDie(MinSamples)
  local GUID = self:GUID()
  if not GUID then return 11111 end

  local MinSamples = MinSamples or 3
  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end

  local TTD = UnitInfo.TTD
  if not TTD then
    TTD = {}
    UnitInfo.TTD = TTD
  end
  if not TTD[MinSamples] then
    TTD[MinSamples] = self:TimeToX(self:SpecialTTDPercentage(self:NPCID()), MinSamples)
  end

  return TTD[MinSamples]
end

-- Get the boss unit TimeToDie
function Unit:BossTimeToDie(MinSamples)
  if self:IsInBossList() or self:IsDummy() then
    return self:TimeToDie(MinSamples)
  end

  return 11111
end

-- Get if the unit meets the TimeToDie requirements.
function Unit:FilteredTimeToDie(Operator, Value, Offset, ValueThreshold, MinSamples)
  local TTD = self:TimeToDie(MinSamples)

  return TTD < (ValueThreshold or 7777) and Utils.CompareThis(Operator, TTD + (Offset or 0), Value) or false
end

-- Get if the boss unit meets the TimeToDie requirements.
function Unit:BossFilteredTimeToDie(Operator, Value, Offset, ValueThreshold, MinSamples)
  if self:IsInBossList() or self:IsDummy() then
    return self:FilteredTimeToDie(Operator, Value, Offset, ValueThreshold, MinSamples)
  end

  return false
end

-- Get if the Time To Die is Valid for an Unit (i.e. not returning a warning code).
function Unit:TimeToDieIsNotValid(MinSamples)
  return self:TimeToDie(MinSamples) >= 7777
end

-- Get if the Time To Die is Valid for a boss Unit (i.e. not returning a warning code or not being a boss).
function Unit:BossTimeToDieIsNotValid(MinSamples)
  if self:IsInBossList() then
    return self:TimeToDieIsNotValid(MinSamples)
  end

  return true
end

-- Returns the max fight length of boss units, or the current selected target if no boss units
function HL.FightRemains(Enemies, BossOnly)
  local BossExists, MaxTimeToDie
  for _, BossUnit in pairs(Boss) do
    if BossUnit:Exists() then
      BossExists = true
      if not BossUnit:TimeToDieIsNotValid() then
        MaxTimeToDie = mathmax(MaxTimeToDie or 0, BossUnit:TimeToDie())
      end
    end
  end

  if BossExists or BossOnly then
    -- If we have a boss list but no valid boss time, return invalid
    return MaxTimeToDie or 11111
  end

  -- If we specify an AoE range, iterate through all the targets in the specified range
  if Enemies then
    for _, CycleUnit in pairs(Enemies) do
      if not CycleUnit:IsUserCycleBlacklisted() and (CycleUnit:AffectingCombat() or CycleUnit:IsDummy()) and not CycleUnit:TimeToDieIsNotValid() then
        MaxTimeToDie = mathmax(MaxTimeToDie or 0, CycleUnit:TimeToDie())
      end
    end
    if MaxTimeToDie then
      return MaxTimeToDie
    end
  end

  return Target:TimeToDie()
end

-- Returns the max fight length of boss units, 11111 if not a boss fight
function HL.BossFightRemains()
  return HL.FightRemains(nil, true)
end

-- Get if the Time To Die is Valid for a boss fight remains
function HL.BossFightRemainsIsNotValid()
  return HL.BossFightRemains() >= 7777
end

-- Returns if the current fight length meets the requirements.
function HL.FilteredFightRemains(Enemies, Operator, Value, CheckIfValid, BossOnly)
  local FightRemains = HL.FightRemains(Enemies, BossOnly)
  if CheckIfValid and FightRemains >= 7777 then
    return false
  end

  return Utils.CompareThis(Operator, FightRemains, Value) or false
end

-- Returns if the current boss fight length meets the requirements, 11111 if not a boss fight.
function HL.BossFilteredFightRemains(Operator, Value, CheckIfValid)
  return HL.FilteredFightRemains(nil, Operator, Value, CheckIfValid, true)
end

