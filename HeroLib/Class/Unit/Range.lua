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
-- File Locals



--- ============================ CONTENT ============================
--- IsInRange
-- Run ManuallyFilterItemRanges() while standing at less than 1yds from an hostile target and the same for a friendly focus (easy with dummies like the ones in Orgrimmar)
-- Keep running this function until you get the message in the chat saying that the filtering is done.
-- Due to some issues with the Blizzard API we need to do multiple iterations on different frame (ideally do one call each 3-5secs)
function HL.ManuallyFilterItemRanges(LastPass)
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
  local IsItemInRange = IsItemInRange
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

        for i = 1, #ItemIDs do
          local ItemID = ItemIDs[i]

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
-- Get if the unit is in range, you can use a number or a spell as argument.
function Unit:IsInRange(Distance, AoESpell)
  local GUID = self:GUID()
  if GUID then
    -- Regular ranged distance check through IsItemInRange & Special distance check (like melee)
    local DistanceType, Identifier, IsInRange = type(Distance), nil, nil
    if DistanceType == "number" or (DistanceType == "string" and Distance == "Melee") then
      Identifier = Distance
      -- Select the hostile or friendly range table
      local RangeTable = Player:CanAttack(self) and IsInRangeTable.Hostile or IsInRangeTable.Friendly
      local ItemRange = RangeTable.ItemRange
      -- AoESpell Offset & Distance Fallback
      if DistanceType == "number" then
        -- AoESpell ignores Player CombatReach which is equals to 1.5yds
        if AoESpell then
          Distance = Distance - 1.5
        end
        -- If the distance we wants to check doesn't exists, we look for a fallback.
        if not ItemRange[Distance] then
          local RangeIndex = RangeTable.RangeIndex
          for i = #RangeIndex, 1, -1 do
            local Range = RangeIndex[i]
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
      end
      IsInRange = IsItemInRange(ItemRange[Distance], self.UnitID)
      -- Distance check through IsSpellInRange (works only for targeted spells only)
    elseif DistanceType == "table" then
      Identifier = tostring(Distance:ID())
      IsInRange = IsSpellInRange(Distance:BookIndex(), self.UnitID) == 1
    else
      error("Invalid Distance.")
    end

    local UnitInfo = Cache.UnitInfo[GUID]
    if not UnitInfo then
      UnitInfo = {}
      Cache.UnitInfo[GUID] = UnitInfo
    end

    local UI_IsInRange
    if AoESpell then
      UI_IsInRange = UnitInfo.IsInRangeAoE
      if not UI_IsInRange then
        UI_IsInRange = {}
        UnitInfo.IsInRangeAoE = UI_IsInRange
      end
    else
      UI_IsInRange = UnitInfo.IsInRange
      if not UI_IsInRange then
        UI_IsInRange = {}
        UnitInfo.IsInRange = UI_IsInRange
      end
    end
    if UI_IsInRange[Identifier] == nil then
      UI_IsInRange[Identifier] = IsInRange
    end

    return IsInRange
  end
  return nil
end

--- Find Range mixin (used in xDistanceToPlayer)
-- param Unit Object_Unit Unit to query on.
-- param Max Boolean Min or Max range ?
local function FindRange(Unit, Max)
  local RangeIndex = IsInRangeTable.Hostile.RangeIndex
  for i = #RangeIndex - (Max and 1 or 0), 1, -1 do
    if not Unit:IsInRange(RangeIndex[i]) then
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
