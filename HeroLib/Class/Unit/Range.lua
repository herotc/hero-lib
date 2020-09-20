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
-- IsInRangeTable generated manually by FilterItemRange
local RangeTableByType = {
  Melee = {
    Hostile = {
      RangeIndex = {},
      ItemRange = {}
    },
    Friendly = {
      RangeIndex = {},
      ItemRange = {}
    }
  },
  Ranged = {
    Hostile = {
      RangeIndex = {},
      ItemRange = {}
    },
    Friendly = {
      RangeIndex = {},
      ItemRange = {}
    }
  }
}
do
  local Types = {"Melee", "Ranged"}

  for _, Type in pairs(Types) do
    local Enum = HL.Enum.ItemRange[Type]
    local Hostile, Friendly = RangeTableByType[Type].Hostile, RangeTableByType[Type].Friendly

    -- Map the range indices and sort them since the order is not guaranteed.
    Hostile.RangeIndex = Enum.Hostile.RangeIndex
    tablesort(Hostile.RangeIndex, Utils.SortMixedASC)
    Friendly.RangeIndex = Enum.Friendly.RangeIndex
    tablesort(Friendly.RangeIndex, Utils.SortMixedASC)

    -- Take randomly one item for each range.
    for k, v in pairs(Enum.Hostile.ItemRange) do
      Hostile.ItemRange[k] = v[mathrandom(1, #v)]
    end
    for k, v in pairs(Enum.Friendly.ItemRange) do
      Friendly.ItemRange[k] = v[mathrandom(1, #v)]
    end

    -- Removes the items ranges in order to free up the memory.
    Enum.Hostile.ItemRange = nil
    Enum.Friendly.ItemRange = nil
  end
end

-- Get if the unit is in range, distance check through IsItemInRange.
-- Do keep in mind that if you're checking the range for a distance from the player (player-centered AoE like Fan of Knives),
-- you should use the radius - 1.5yds as distance (ex: instead of 10 you should use 8.5) because the player CombatReach is ignored (the distance is computed from the center to the edge, instead of edge to edge).
function Unit:IsInRange(Distance)
  assert(type(Distance) == "number", "Distance must be a number.")
  assert(Distance >= 5 and Distance <= 100, "Distance must be between 5 and 100.")

  local GUID = self:GUID()
  if not GUID then return false end

  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end
  local UnitInfoIsInRange = UnitInfo.IsInRange
  if not UnitInfoIsInRange then
    UnitInfoIsInRange = {}
    UnitInfo.IsInRange = UnitInfoIsInRange
  end

  local Identifier = Distance -- Considering the Distance can change if it doesn't exist we use the one passed as argument for the cache
  local IsInRange = UnitInfoIsInRange[Identifier]
  if IsInRange == nil then
    -- Select the hostile or friendly range table
    local RangeTableByReaction = RangeTableByType.Ranged
    local RangeTable = Player:CanAttack(self) and RangeTableByReaction.Hostile or RangeTableByReaction.Friendly
    local ItemRange = RangeTable.ItemRange

    -- If the distance we want to check doesn't exists, we look for a fallback.
    if not ItemRange[Distance] then
      -- Iterate in reverse order the ranges in order to find the exact rannge or one that is lower than the one we look for (so we are guarantee it is in range)
      local RangeIndex = RangeTable.RangeIndex
      for i = #RangeIndex, 1, -1 do
        local Range = RangeIndex[i]
        if Range == Distance then break end
        if Range < Distance then
          Distance = Range
          break
        end
      end
    end

    IsInRange = IsItemInRange(ItemRange[Distance], self:ID())
    UnitInfoIsInRange[Identifier] = IsInRange
  end

  return IsInRange
end

-- Get if the unit is in range, distance check through IsItemInRange.
-- Melee ranges are different than Ranged one, we can only check the 5y Melee range through items at this moment.
-- If you have a spell that increase your melee range you should instead use Unit:IsInSpellRange().
function Unit:IsInMeleeRange(Distance)
  assert(type(Distance) == "number", "Distance must be a number.")
  assert(Distance >= 5 and Distance <= 100, "Distance must be between 5 and 100.")

  -- At this moment we cannot check multiple melee range (5, 8, 10), only the 5yds one from the item.
  -- So we use the ranged item while substracting 1.5y, which is the player hitbox radius.
  if (Distance ~= 5) then
    return self:IsInRange(Distance - 1.5)
  end

  local GUID = self:GUID()
  if not GUID then return false end

  local RangeTableByReaction = RangeTableByType.Melee
  local RangeTable = Player:CanAttack(self) and RangeTableByReaction.Hostile or RangeTableByReaction.Friendly
  local ItemRange = RangeTable.ItemRange

  return IsItemInRange(ItemRange[Distance], self:ID())
end

-- Get if the unit is in range, distance check through IsSpellInRange (works only for targeted spells only)
function Unit:IsSpellInRange(ThisSpell)
  local GUID = self:GUID()
  if not GUID then return false end

  return IsSpellInRange(ThisSpell:BookIndex(), self:ID()) == 1
end

-- Find Range mixin, used by Unit:MinDistance() and Unit:MaxDistance()
local function FindRange(ThisUnit, Max)
  local RangeTableByReaction = RangeTableByType.Ranged
  local RangeTable = Player:CanAttack(ThisUnit) and RangeTableByReaction.Hostile or RangeTableByReaction.Friendly
  local RangeIndex = RangeTable.RangeIndex

  for i = #RangeIndex - (Max and 1 or 0), 1, -1 do
    if not ThisUnit:IsInRange(RangeIndex[i]) then
      return Max and RangeIndex[i + 1] or RangeIndex[i]
    end
  end
end

-- Get the minimum distance to the player, using Unit:IsInRange().
function Unit:MinDistance()
  return FindRange(self)
end

-- Get the maximum distance to the player, using Unit:IsInRange().
function Unit:MaxDistance()
  return FindRange(self, true)
end

--- USE WHAT IS BELOW ONLY IF YOU KNOW WHAT YOU'RE DOING ---
-- Run ManuallyFilterItemRanges() while standing at less than 1yds from an hostile target and the same for a friendly focus (easy with dummies like the ones in Orgrimmar)
-- Keep running this function until you get the message in the chat saying that the filtering is done.
-- Due to some issues with the Blizzard API we need to do multiple iterations on different frame (ideally do one call each 3-5secs)
function HL.ManuallyFilterItemRanges()
  -- Reset (in case you spammed it too much!)
  if HL.ManualManualRangeTableByTypeIterations then
    local Iterations = HL.ManualManualRangeTableByTypeIterations
    if Iterations.Current == Iterations.Last then
      HL.Print('ManuallyFilterItemRanges reset !')
      HL.ManualManualRangeTableByType = nil
    end
  end

  -- Init
  if not HL.ManualRangeTableByType then
    HL.Print('ManuallyFilterItemRanges initialized...')
    HL.ManualRangeTableByType = {
      Melee = {
        Hostile = {
          RangeIndex = {},
          ItemRange = {}
        },
        Friendly = {
          RangeIndex = {},
          ItemRange = {}
        }
      },
      Ranged = {
        Hostile = {
          RangeIndex = {},
          ItemRange = {}
        },
        Friendly = {
          RangeIndex = {},
          ItemRange = {}
        }
      }
    }
    HL.ManualRangeTableByTypeIterations = {
      Current = 0,
      Last = 15
    }
  end

  -- Locals
  local ManualRangeTableByType = HL.ManualRangeTableByType
  local Iterations = HL.ManualRangeTableByTypeIterations
  local MeleeTable, RangedTable = ManualRangeTableByType.Melee, ManualRangeTableByType.Ranged
  local MHostileTable, MFriendlyTable = MeleeTable.Hostile, MeleeTable.Friendly
  local MHTItemRange, MHTRangeIndex = MHostileTable.ItemRange, MHostileTable.RangeIndex
  local MFTItemRange, MFTRangeIndex = MFriendlyTable.ItemRange, MFriendlyTable.RangeIndex
  local RHostileTable, RFriendlyTable = RangedTable.Hostile, RangedTable.Friendly
  local RHTItemRange, RHTRangeIndex = RHostileTable.ItemRange, RHostileTable.RangeIndex
  local RFTItemRange, RFTRangeIndex = RFriendlyTable.ItemRange, RFriendlyTable.RangeIndex
  local TUnitID, FUnitID = Target.UnitID, Focus.UnitID
  local ValueIsInTable = Utils.ValueIsInTable

  -- Inside a given frame, we do 5 iterations.
  for i = 1, 5 do
    -- Filter items that can only be casted on an unit. (i.e. blacklist ground targeted aoe items)
    for Type, Ranges in pairs(HL.Enum.ItemRangeUnfiltered) do
      local HTItemRange = Type == "Melee" and MHTItemRange or RHTItemRange
      local HTRangeIndex = Type == "Melee" and MHTRangeIndex or RHTRangeIndex
      local FTItemRange = Type == "Melee" and MFTItemRange or RFTItemRange
      local FTRangeIndex = Type == "Melee" and MFTRangeIndex or RFTRangeIndex

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
    MHostileTable.ItemRange = Utils.JSON.encode(MHTItemRange)
    MHostileTable.RangeIndex = Utils.JSON.encode(MHTRangeIndex)
    MFriendlyTable.ItemRange = Utils.JSON.encode(MFTItemRange)
    MFriendlyTable.RangeIndex = Utils.JSON.encode(MFTRangeIndex)
    RHostileTable.ItemRange = Utils.JSON.encode(RHTItemRange)
    RHostileTable.RangeIndex = Utils.JSON.encode(RHTRangeIndex)
    RFriendlyTable.ItemRange = Utils.JSON.encode(RFTItemRange)
    RFriendlyTable.RangeIndex = Utils.JSON.encode(RFTRangeIndex)

    -- Pass it to SavedVariables
    if not _G.HeroLibDB then _G.HeroLibDB = {} end
    _G.HeroLibDB.ManualRangeTableByType = ManualRangeTableByType
    HL.Print('ManuallyFilterItemRanges done.')
  else
    HL.Print('ManuallyFilterItemRanges still needs ' .. Iterations.Last - Iterations.Current .. ' iteration(s).')
  end
end
