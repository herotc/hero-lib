--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroDBC
local DBC = HeroDBC.DBC
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
local mathceil = math.ceil
local mathfloor = math.floor
local mathrandom = math.random
local pairs = pairs
local tinsert = table.insert
local tablesort = table.sort
local type = type
local unpack = unpack
-- WoW API
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local InCombatLockdown = InCombatLockdown
local IsActionInRange = IsActionInRange
local IsItemInRange = IsItemInRange
local IsSpellInRange = IsSpellInRange
-- File Locals
local RangeExceptions = {}
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
  local Types = { "Melee", "Ranged" }

  for _, Type in pairs(Types) do
    local ItemRange = DBC.ItemRange[Type]
    local Hostile, Friendly = RangeTableByType[Type].Hostile, RangeTableByType[Type].Friendly

    -- Map the range indices and sort them since the order is not guaranteed.
    Hostile.RangeIndex = { unpack(ItemRange.Hostile.RangeIndex) }
    tablesort(Hostile.RangeIndex, Utils.SortMixedASC)
    Friendly.RangeIndex = { unpack(ItemRange.Friendly.RangeIndex) }
    tablesort(Friendly.RangeIndex, Utils.SortMixedASC)

    -- Take randomly one item for each range.
    for k, v in pairs(ItemRange.Hostile.ItemRange) do
      Hostile.ItemRange[k] = v[mathrandom(1, #v)]
    end
    for k, v in pairs(ItemRange.Friendly.ItemRange) do
      Friendly.ItemRange[k] = v[mathrandom(1, #v)]
    end
  end
end

--- ============================ CONTENT ============================
-- Empty table, later populated during ADDON_LOADED.
local function UpdateRangeExceptions()
  -- Clear the exceptions table.
  wipe(RangeExceptions)

  -- Let's only add exceptions for the current class.
  local ClassID = Cache.Persistent.Player.Class[3]

  -- Add exceptions to the RangeExceptions table
  -- (TODO: Check for lots of other edge cases).

  if ClassID == 1 then
    -- Warrior: 
  elseif ClassID == 2 then
    -- Paladin: Crusader's Reprieve increases Crusader Strike, Templar's Strike, and Rebuke to 8y.
    local CRRange = (Spell(403042):IsAvailable()) and 3 or 0
    tinsert(RangeExceptions, 35395, 5 + CRRange)
    tinsert(RangeExceptions, 96231, 5 + CRRange)
    tinsert(RangeExceptions, 407480, 5 + CRRange)
  elseif ClassID == 3 then
    -- Hunter: 
  elseif ClassID == 4 then
    -- Rogue: Acrobatic Strikes increases range of all melee attacks by 3y.
    local ASRange = (Spell(196924):IsAvailable()) and 3 or 0
    tinsert(RangeExceptions, 703, 5 + ASRange)
    tinsert(RangeExceptions, 1329, 5 + ASRange)
    tinsert(RangeExceptions, 1766, 5 + ASRange)
    tinsert(RangeExceptions, 5938, 5 + ASRange)
    tinsert(RangeExceptions, 193315, 5 + ASRange)
    tinsert(RangeExceptions, 196937, 5 + ASRange)
    tinsert(RangeExceptions, 200758, 5 + ASRange)
    tinsert(RangeExceptions, 360194, 5 + ASRange)
    tinsert(RangeExceptions, 385627, 5 + ASRange)
    tinsert(RangeExceptions, 426591, 5 + ASRange)
  elseif ClassID == 5 then
    -- Priest: 
  elseif ClassID == 6 then
    -- Death Knight: 
  elseif ClassID == 7 then
    -- Shaman: 
  elseif ClassID == 8 then
    -- Mage: 
  elseif ClassID == 9 then
    -- Warlock: 
  elseif ClassID == 10 then
    -- Monk: 
  elseif ClassID == 11 then
    -- Druid
    local SpecID = Cache.Persistent.Player.Spec[1]
    if SpecID == 102 then
      -- Balance: Astral Influence increases the range of all abilities by 3/5y, depending on rank.
      local AIRange = mathceil(2.5 * Spell(197524):TalentRank())
      tinsert(RangeExceptions, 339, 35 + AIRange)
      tinsert(RangeExceptions, 2908, 40 + AIRange)
      tinsert(RangeExceptions, 8921, 40 + AIRange)
      tinsert(RangeExceptions, 78675, 40 + AIRange)
      tinsert(RangeExceptions, 93402, 40 + AIRange)
      tinsert(RangeExceptions, 190984, 40 + AIRange)
      tinsert(RangeExceptions, 194153, 40 + AIRange)
      tinsert(RangeExceptions, 202770, 40 + AIRange)
    elseif SpecID == 103 or SpecID == 104 then
      -- Feral/Guardian: Astral Influence increases the range of all abilities by 1/3y, depending on rank.
      local AIRange = math.floor(1.5 * Spell(197524):TalentRank())
      tinsert(RangeExceptions, 339, 35 + AIRange)
      tinsert(RangeExceptions, 1822, 5 + AIRange)
      tinsert(RangeExceptions, 2908, 40 + AIRange)
      tinsert(RangeExceptions, 5211, 5 + AIRange)
      tinsert(RangeExceptions, 5221, 5 + AIRange)
      tinsert(RangeExceptions, 6795, 30 + AIRange)
      tinsert(RangeExceptions, 8921, 40 + AIRange)
      tinsert(RangeExceptions, 16979, 25 + AIRange)
      tinsert(RangeExceptions, 33917, 5 + AIRange)
      tinsert(RangeExceptions, 49376, 25 + AIRange)
      tinsert(RangeExceptions, 77758, 8 + AIRange)
      tinsert(RangeExceptions, 93402, 40 + AIRange)
      tinsert(RangeExceptions, 102793, 30 + AIRange)
      tinsert(RangeExceptions, 106830, 8 + AIRange)
      tinsert(RangeExceptions, 106839, 13 + AIRange)
      tinsert(RangeExceptions, 202028, 8 + AIRange)
      tinsert(RangeExceptions, 213771, 8 + AIRange)
      tinsert(RangeExceptions, 274837, 5 + AIRange)
    end
  elseif ClassID == 12 then
    -- Demon Hunter: Improved Disrupt increases Disrupt to 10y.
    tinsert(RangeExceptions, 183752, (Spell(320361):IsAvailable()) and 10 or 5)
  elseif ClassID == 13 then
    -- Evoker: 
  end
end

-- Create our base table with all of our possible range checking spells.
local function UpdateRangeSpells()
  local BookType = BOOKTYPE_SPELL
  local max = 0
  -- Only using tabs 2 and 3 because we don't care about "General" or off-spec.
  for i = 2, 3 do
    local _, _, offset, numSlots, _, specID = GetSpellTabInfo(i)
    if specID == 0 then
      max = offset + numSlots
    end
  end

  -- Reset the Cache table.
  if type(Cache.Persistent.RangeSpells) == "table" then
    wipe(Cache.Persistent.RangeSpells)
  else
    Cache.Persistent.RangeSpells = {}
  end
  Cache.Persistent.RangeSpells.HostileIndex = {}
  Cache.Persistent.RangeSpells.FriendlyIndex = {}
  Cache.Persistent.RangeSpells.HostileSpells = {}
  Cache.Persistent.RangeSpells.FriendlySpells = {}
  Cache.Persistent.RangeSpells.MinRangeSpells = {}

  for SpellBookID = 1, max do
    local Type, BaseSpellID = GetSpellBookItemInfo(SpellBookID, BookType)
    -- PETACTION probably isn't needed, but later we can be open to using the pet spell tab.
    if Type == "SPELL" or type == "PETACTION" then
      -- Get the name and spell ID from the spellbook slot.
      local SpellName = GetSpellBookItemName(SpellBookID, BookType)
      local _, SpellID = GetSpellLink(SpellName)
      -- We only care about spells with a range, obviously.
      if SpellHasRange(SpellBookID, BookType) then
        -- Pull the range data from DBC.
        local SMRInfo = DBC.SpellMeleeRange[SpellID]
        -- Make sure we actually get something back from DBC.
        if SMRInfo then
          local IsMelee = SMRInfo[1]
          local MinRange = SMRInfo[2]
          -- If we have an exception, use that. Otherwise, use the max range from DBC.
          local MaxRange = (RangeExceptions[SpellID]) and RangeExceptions[SpellID] or SMRInfo[3]
          -- Added IsReady and CooldownDown checks here, as we were getting some funky spell additions otherwise.
          if MaxRange and Spell(SpellID):IsLearned() then
            -- If we have a hostile as our target, only add spells to the table that return a value for IsSpellInRange.
            if not Target or not Player:CanAttack(Target) or Target and Player:CanAttack(Target) and IsSpellInRange(Spell(SpellID):BookIndex(), Spell(SpellID):BookType(), "target") ~= nil then
              -- If we don't have the range category yet, create it, add this spell to that category, and add the distance to RangeIndex.
              if not Cache.Persistent.RangeSpells.HostileSpells[MaxRange] then
                Cache.Persistent.RangeSpells.HostileSpells[MaxRange] = {}
                tinsert(Cache.Persistent.RangeSpells.HostileIndex, MaxRange)
              end
              tinsert(Cache.Persistent.RangeSpells.HostileSpells[MaxRange], SpellID)
              if MinRange and MinRange > 0 then
                Cache.Persistent.RangeSpells.MinRangeSpells[SpellID] = MinRange
              end
            end
          end
        end
      end
    end
  end

  -- Sort the RangeIndex table, as we need it to be in order for later iterating.
  tablesort(Cache.Persistent.RangeSpells.HostileIndex)
  tablesort(Cache.Persistent.RangeSpells.FriendlyIndex)
end

-- Dummy frame for event registration.
HL.RangeSpellFrame = CreateFrame("Frame", "HeroLib_MainFrame", UIParent)
HL.RangeSpellFrame:RegisterEvent("ADDON_LOADED")
HL.RangeSpellFrame:SetScript("OnEvent", function (self, Event, Arg1)
  if Event == "ADDON_LOADED" then
    if Arg1 == "HeroLib" then
      -- Initial building of exceptions table
      UpdateRangeExceptions()
      -- Initial table creation.
      UpdateRangeSpells()
      -- Register to recreate table when spells change.
      HL:RegisterForEvent(function()
        UpdateRangeExceptions()
        UpdateRangeSpells()
      end, "SPELLS_CHANGED")
      C_Timer.After(2, function()
        HL.RangeSpellFrame:UnregisterEvent("ADDON_LOADED")
      end)
    end
  end
end)

-- Get if the unit is in range, distance check through IsSpellInRange or IsItemInRange, depending on combat state.
-- Do keep in mind that if you're checking the range for a distance from the player (player-centered AoE like Fan of Knives),
-- you should use the radius - 1.5yds as distance (ex: instead of 10 you should use 8.5) because the player CombatReach is ignored (the distance is computed from the center to the edge, instead of edge to edge).
function Unit:IsInRange(Distance)
  assert(type(Distance) == "number", "Distance must be a number.")
  assert(Distance >= 5 and Distance <= 100, "Distance must be between 5 and 100.")

  if InCombatLockdown() then
    IsInRange = self:IsInRangeBySpell(Distance)
  else
    IsInRange = self:IsInRangeByItem(Distance)
  end

  return IsInRange
end

function Unit:IsInRangeBySpell(Distance)
  -- Range Check from Cache
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
  local Identifier = Distance
  local IsInRange = UnitInfoIsInRange[Identifier]

  -- Pull our range table from Cache
  local RangeTable = Cache.Persistent.RangeSpells
  local IsHostile = Player:CanAttack(self)
  -- Only use our hostile spells table if we can attack the target
  local SpellRange = (IsHostile) and RangeTable.HostileSpells or RangeTable.FriendlySpells

  -- Determine what spell to use to check range
  local CheckSpell = nil
  -- Select the appropriate index
  local RangeIndex = (IsHostile) and RangeTable.HostileIndex or RangeTable.FriendlyIndex
  for i = #RangeIndex, 1, -1 do
    local Range = RangeIndex[i]
    -- Protect against removed indexes
    if Range == nil then
      i = i - 1
      if i <= 0 then
        return false
      else
        Range = RangeIndex[i]
      end
    end
    if Range and Range <= Distance then
      for SpellIndex, SpellID in pairs(SpellRange[Range]) do
        -- Does the spell have a MinRange? Is it higher than our current range check?
        local MinRange = Cache.Persistent.RangeSpells.MinRangeSpells[SpellID]
        if MinRange and MinRange < Distance and not self:IsInRange(MinRange) or not MinRange or not IsHostile then
          -- Check the API IsSpellInRange
          -- It returns nil on a spell that can't be used for range checking and 0 or 1 for one that can
          local BookIndex = Spell(SpellID):BookIndex()
          local BookType = Spell(SpellID):BookType()
          local SpellInRange = IsSpellInRange(BookIndex, BookType, self:ID())
          -- If the spell can't be used for range checking, remove it from the table.
          if SpellInRange == nil then
            SpellRange[Range][SpellIndex] = nil
            -- If the range category is now empty, remove it and its index entry.
            local CheckCount = 0
            for _ in pairs(SpellRange[Range]) do CheckCount = CheckCount + 1 end
            if CheckCount == 0 then
              RangeIndex[i] = nil
              SpellRange[Range] = nil
            end
          else
            CheckSpell = Spell(SpellID)
            break
          end
        end
      end
      Distance = Range - 1
    end
    if CheckSpell then break end
  end

  -- Check the range
  if not CheckSpell then return false end
  IsInRange = self:IsSpellInRange(CheckSpell)
  UnitInfoIsInRange[Identifier] = IsInRange
  return IsInRange
end

function Unit:IsInRangeByItem(Distance)
  -- Range Check from Cache
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
  local Identifier = Distance
  local IsInRange = UnitInfoIsInRange[Identifier]

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
  return IsInRange
end

-- Get if the unit is in range, distance check through IsSpellInRange.
-- Melee ranges are different than Ranged one, we can only check the 5y Melee range through items at this moment.
-- If you have a spell that increase your melee range you should instead use Unit:IsInSpellRange().
-- Supported hostile ranges: 5
-- Supported friendly ranges: 5
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

  return self:IsInRange(5)
end

-- Get if the unit is in range, distance check through IsSpellInRange (works only for targeted spells only)
function Unit:IsSpellInRange(ThisSpell)
  local GUID = self:GUID()
  if not GUID then return false end
  if ThisSpell:BookIndex() == nil then return false end
  
  return IsSpellInRange(ThisSpell:BookIndex(), ThisSpell:BookType(), self:ID()) == 1
end

-- Get if the unit is in range, distance check through IsActionInRange (works only for targeted actions only)
function Unit:IsActionInRange(ActionSlot)
  return IsActionInRange(ActionSlot, self:ID())
end

-- Find Range mixin, used by Unit:MinDistance() and Unit:MaxDistance()
local function FindRange(ThisUnit, Max)
  local RangeTable = Cache.Persistent.RangeSpells
  local RangeIndex = RangeTable.RangeIndex
  if not RangeIndex then return nil end

  for i = #RangeIndex - (Max and 1 or 0), 1, -1 do
    if RangeIndex[i] and not ThisUnit:IsInRange(RangeIndex[i]) then
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
