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
local mathrandom = math.random
local pairs = pairs
local tableinsert = table.insert
local tablesort = table.sort
local tostring = tostring
local type = type
-- WoW API
local IsItemInRange = IsItemInRange
local IsSpellInRange = IsSpellInRange
-- File Locals



--- ============================ CONTENT ============================
--- IsInRange
-- Run ManuallyFilterItemRanges() while standing at less than 1yds from an hostile target and the same for a friendly focus (easy with dummies like the ones in Orgrimmar)
-- Keep running this function until you get the message in the chat saying that the filtering is done.
-- Due to some issues with the Blizzard API we need to do multiple iterations on different frame (ideally do one call each 3-5secs)
function HL.ManuallyFilterItemRanges()
  -- Reset (in case you spammed it too much!)
  if HL.ManualIsInRangeTableIterations then
    local Iterations = HL.ManualIsInRangeTableIterations
    if Iterations.Current == Iterations.Last then
      HL.Print('ManuallyFilterItemRanges reset !')
      HL.ManualIsInRangeTable = nil
    end
  end

  -- Init
  if not HL.ManualIsInRangeTable then
    HL.Print('ManuallyFilterItemRanges initialized...')
    HL.ManualIsInRangeTable = {
      Hostile = {
        RangeIndex = {},
        ItemRange = {}
      },
      Friendly = {
        RangeIndex = {},
        ItemRange = {}
      }
    }
    HL.ManualIsInRangeTableIterations = {
      Current = 0,
      Last = 15
    }
  end

  -- Locals
  local IsInRangeTable = HL.ManualIsInRangeTable
  local Iterations = HL.ManualIsInRangeTableIterations
  local HostileTable, FriendlyTable = IsInRangeTable.Hostile, IsInRangeTable.Friendly
  local HTItemRange, HTRangeIndex = HostileTable.ItemRange, HostileTable.RangeIndex
  local FTItemRange, FTRangeIndex = FriendlyTable.ItemRange, FriendlyTable.RangeIndex
  local TUnitID, FUnitID = Target.UnitID, Focus.UnitID
  local ValueIsInTable = Utils.ValueIsInTable

  -- Inside a given frame, we do 5 iterations.
  for i = 1, 5 do
    -- Filter items that can only be casted on an unit. (i.e. blacklist ground targeted aoe items)
    for Type, Ranges in pairs(HL.Enum.ItemRangeUnfiltered) do
      for Range, ItemIDs in pairs(Ranges) do
        -- RangeIndex
        if Type == "Melee" and Range == 5 then
          -- Special case for melees
          Range = "Melee"
        else
          -- The parser assume a string that's why we convert it to a string
          Range = tostring(Range)
        end

        for j = 1, #ItemIDs do
          local ItemID = ItemIDs[j]

          -- Hostile filter
          if IsItemInRange(ItemID, TUnitID) then
            -- Make the Range table if it doesn't exist yet
            if not HTItemRange[Range] then
              HTItemRange[Range] = {}
              tableinsert(HTRangeIndex, Range)
            end
            -- Check if the item isn't already inserted since we do multiple passes then insert it
            if not ValueIsInTable(HTItemRange[Range], ItemID) then
              tableinsert(HTItemRange[Range], ItemID)
            end
          end

          -- Friendly filter
          if IsItemInRange(ItemID, FUnitID) then
            -- Make the Range table if it doesn't exist yet
            if not FTItemRange[Range] then
              FTItemRange[Range] = {}
              tableinsert(FTRangeIndex, Range)
            end
            -- Check if the item isn't already inserted since we do multiple passes
            if not ValueIsInTable(FTItemRange[Range], ItemID) then
              tableinsert(FTItemRange[Range], ItemID)
            end
          end
        end
      end
    end
  end

  -- Increment the pass counter
  Iterations.Current = Iterations.Current + 1

  if Iterations.Current == Iterations.Last then
    -- Encode in JSON the content (JSON is used since it's easier to work with)
    HostileTable.ItemRange = Utils.JSON.encode(HTItemRange)
    HostileTable.RangeIndex = Utils.JSON.encode(HTRangeIndex)
    FriendlyTable.ItemRange = Utils.JSON.encode(FTItemRange)
    FriendlyTable.RangeIndex = Utils.JSON.encode(FTRangeIndex)

    -- Pass it to SavedVariables
    _G.HeroLibDB = IsInRangeTable
    HL.Print('ManuallyFilterItemRanges done.')
  else
    HL.Print('ManuallyFilterItemRanges still needs ' .. Iterations.Last - Iterations.Current .. ' iteration(s).')
  end
end

-- IsInRangeTable generated manually by FilterItemRange
local IsInRangeTable = {
  Hostile = {
    RangeIndex = {},
    ItemRange = {}
  },
  Friendly = {
    RangeIndex = {},
    ItemRange = {}
  }
}
do
  local Enum = HL.Enum.ItemRange
  local Hostile, Friendly = IsInRangeTable.Hostile, IsInRangeTable.Friendly

  Hostile.RangeIndex = Enum.Hostile.RangeIndex
  tablesort(Hostile.RangeIndex, Utils.SortMixedASC)
  Friendly.RangeIndex = Enum.Friendly.RangeIndex
  tablesort(Friendly.RangeIndex, Utils.SortMixedASC)

  for k, v in pairs(Enum.Hostile.ItemRange) do
    Hostile.ItemRange[k] = v[mathrandom(1, #v)]
  end
  Enum.Hostile.ItemRange = nil
  for k, v in pairs(Enum.Friendly.ItemRange) do
    Friendly.ItemRange[k] = v[mathrandom(1, #v)]
  end
  Enum.Friendly.ItemRange = nil
end

-- Get if the unit is in range, distance check through IsItemInRange
function Unit:IsInRange(Distance, AoESpell)
  local GUID = self:GUID()
  if not GUID then return nil end

  local DistanceType = type(Distance)
  if DistanceType == "number" then
    local UnitInfo = Cache.UnitInfo[GUID]
    if not UnitInfo then
      UnitInfo = {}
      Cache.UnitInfo[GUID] = UnitInfo
    end

    local UnitInfoIsInRange = AoESpell and UnitInfo.IsInRange or UnitInfo.IsInAoERange
    if not UnitInfoIsInRange then
      UnitInfoIsInRange = {}
      UnitInfo.IsInRange = UnitInfoIsInRange
    end

    local DistanceKey = Distance
    local IsInRange = UnitInfoIsInRange[DistanceKey]
    if IsInRange == nil then
      -- Select the hostile or friendly range table
      local RangeTable = Player:CanAttack(self) and IsInRangeTable.Hostile or IsInRangeTable.Friendly
      local ItemRange = RangeTable.ItemRange

      -- AoESpell ignores Player CombatReach which is equals to 1.5yds
      if AoESpell then
        Distance = Distance - 1.5
      end

      -- If the distance we want to check doesn't exists, we look for a fallback.
      if not ItemRange[Distance] then
        -- Iterate in reverse order the ranges in order to find one that is lower than the one we look for (so we are guarantee it is in range)
        local RangeIndex = RangeTable.RangeIndex
        for i = #RangeIndex, 1, -1 do
          local Range = RangeIndex[i]
          -- TODO: The type check is here since we have the Melee range Index, in the future both should be split
          if type(Range) == "number" and Range < Distance then
            Distance = Range
            break
          end
        end
        -- Test again in case we didn't found a new range
        if not ItemRange[Distance] then
          Distance = "Melee"
        end
      end

      IsInRange = IsItemInRange(ItemRange[Distance], self.UnitID)
      UnitInfoIsInRange[DistanceKey] = IsInRange
    end

    return IsInRange
  elseif DistanceType == "string" and Distance == "Melee" then
    HL.Debug("Please use IsInMeleeRange instead of IsInRange for melee range check.")
    return self:IsInMeleeRange()
  elseif DistanceType == "table" then
    HL.Debug("Please use IsInSpellRange instead of IsInRange for melee range check.")
    return self:IsInSpellRange(Distance)
  else
    error("Invalid Distance.")
  end


end

-- Get if the unit is in range, distance check through IsSpellInRange (works only for targeted spells only)
function Unit:IsInSpellRange(SpellToCheck)
  local GUID = self:GUID()
  if not GUID then return nil end

  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end

  local UnitInfoIsInSpellRange = UnitInfo.IsInSpellRange
  if not UnitInfoIsInSpellRange then
    UnitInfoIsInSpellRange = {}
    UnitInfo.IsInSpellRange = UnitInfoIsInSpellRange
  end

  local SpellName = SpellToCheck:Name()
  local IsInSpellRange = UnitInfoIsInSpellRange[SpellName]
  if IsInSpellRange == nil then
    IsInSpellRange = IsSpellInRange(SpellToCheck:BookIndex(), self.UnitID) == 1
    UnitInfoIsInSpellRange[SpellName] = IsInSpellRange
  end

  return IsInSpellRange
end

-- Get if the unit is in range, distance check through IsItemInRange (Melee ranges are different than Ranged one, we can only check the 5y Melee range through items)
-- If you have a spell that increase your melee range you should instead use Unit:IsInSpellRange()
function Unit:IsInMeleeRange()
  local GUID = self:GUID()
  if not GUID then return nil end

  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end

  local IsInMeleeRange = UnitInfo.IsInMeleeRange
  if IsInMeleeRange == nil then
    -- Select the hostile or friendly range table
    local RangeTable = Player:CanAttack(self) and IsInRangeTable.Hostile or IsInRangeTable.Friendly
    local ItemRange = RangeTable.ItemRange
    IsInMeleeRange = IsItemInRange(ItemRange["Melee"], self.UnitID)
    UnitInfo.IsInMeleeRange = IsInMeleeRange
  end

  return IsInMeleeRange
end

--- Find Range mixin (used in xDistanceToPlayer)
-- param Unit Object_Unit Unit to query on.
-- param Max Boolean Min or Max range ?
local function FindRange(ThisUnit, Max)
  local RangeIndex = IsInRangeTable.Hostile.RangeIndex

  for i = #RangeIndex - (Max and 1 or 0), 1, -1 do
    if not ThisUnit:IsInRange(RangeIndex[i]) then
      return Max and RangeIndex[i + 1] or RangeIndex[i]
    end
  end

  return "Melee"
end

-- Get the minimum distance to the player.
function Unit:MinDistanceToPlayer(IntOnly)
  local Range = FindRange(self)
  return IntOnly and ((Range == "Melee" and 5) or Range) or Range
end

-- Get the maximum distance to the player.
function Unit:MaxDistanceToPlayer(IntOnly)
  local Range = FindRange(self, true)
  return IntOnly and ((Range == "Melee" and 5) or Range) or Range
end
