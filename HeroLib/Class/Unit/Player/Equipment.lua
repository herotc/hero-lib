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
local pairs = pairs
local select = select
-- File Locals



--- ============================ CONTENT ============================
-- Save the current player's equipment.
HL.Equipment = {}
function HL.GetEquipment()
  local Item
  for i = 1, 19 do
    Item = select(1, GetInventoryItemID("Player", i))
    -- If there is an item in that slot
    if Item ~= nil then
      HL.Equipment[i] = Item
    end
  end
end

-- Check player set bonuses (call HL.GetEquipment before to refresh the current gear)
HasTierSets = {
  ["T18"] = {
    [0] = function(Count) return Count > 1, Count > 3 end, -- Return Function
    [1] = { [5] = 124319, [10] = 124329, [1] = 124334, [7] = 124340, [3] = 124346 }, -- Warrior:      Chest, Hands, Head, Legs, Shoulder
    [2] = { [5] = 124318, [10] = 124328, [1] = 124333, [7] = 124339, [3] = 124345 }, -- Paladin:      Chest, Hands, Head, Legs, Shoulder
    [3] = { [5] = 124284, [10] = 124292, [1] = 124296, [7] = 124301, [3] = 124307 }, -- Hunter:       Chest, Hands, Head, Legs, Shoulder
    [4] = { [5] = 124248, [10] = 124257, [1] = 124263, [7] = 124269, [3] = 124274 }, -- Rogue:        Chest, Hands, Head, Legs, Shoulder
    [5] = { [5] = 124172, [10] = 124155, [1] = 124161, [7] = 124166, [3] = 124178 }, -- Priest:       Chest, Hands, Head, Legs, Shoulder
    [6] = { [5] = 124317, [10] = 124327, [1] = 124332, [7] = 124338, [3] = 124344 }, -- Death Knight: Chest, Hands, Head, Legs, Shoulder
    [7] = { [5] = 124303, [10] = 124293, [1] = 124297, [7] = 124302, [3] = 124308 }, -- Shaman:       Chest, Hands, Head, Legs, Shoulder
    [8] = { [5] = 124171, [10] = 124154, [1] = 124160, [7] = 124165, [3] = 124177 }, -- Mage:         Chest, Hands, Head, Legs, Shoulder
    [9] = { [5] = 124173, [10] = 124156, [1] = 124162, [7] = 124167, [3] = 124179 }, -- Warlock:      Chest, Hands, Head, Legs, Shoulder
    [10] = { [5] = 124247, [10] = 124256, [1] = 124262, [7] = 124268, [3] = 124273 }, -- Monk:         Chest, Hands, Head, Legs, Shoulder
    [11] = { [5] = 124246, [10] = 124255, [1] = 124261, [7] = 124267, [3] = 124272 }, -- Druid:        Chest, Hands, Head, Legs, Shoulder
    [12] = nil -- Demon Hunter: Chest, Hands, Head, Legs, Shoulder
  },
  ["T18_ClassTrinket"] = {
    [0] = function(Count) return Count > 0 end, -- Return Function
    [1] = { [13] = 124523, [14] = 124523 }, -- Warrior:      Worldbreaker's Resolve
    [2] = { [13] = 124518, [14] = 124518 }, -- Paladin:      Libram of Vindication
    [3] = { [13] = 124515, [14] = 124515 }, -- Hunter:       Talisman of the Master Tracker
    [4] = { [13] = 124520, [14] = 124520 }, -- Rogue:        Bleeding Hollow Toxin Vessel
    [5] = { [13] = 124519, [14] = 124519 }, -- Priest:       Repudiation of War
    [6] = { [13] = 124513, [14] = 124513 }, -- Death Knight: Reaper's Harvest
    [7] = { [13] = 124521, [14] = 124521 }, -- Shaman:       Core of the Primal Elements
    [8] = { [13] = 124516, [14] = 124516 }, -- Mage:         Tome of Shifting Words
    [9] = { [13] = 124522, [14] = 124522 }, -- Warlock:      Fragment of the Dark Star
    [10] = { [13] = 124517, [14] = 124517 }, -- Monk:         Sacred Draenic Incense
    [11] = { [13] = 124514, [14] = 124514 }, -- Druid:        Seed of Creation
    [12] = { [13] = 139630, [14] = 139630 } -- Demon Hunter: Etching of Sargeras
  },
  ["T19"] = {
    [0] = function(Count) return Count > 1, Count > 3 end, -- Return Function
    [1] = { [5] = 138351, [15] = 138374, [10] = 138354, [1] = 138357, [7] = 138360, [3] = 138363 }, -- Warrior:      Chest, Back, Hands, Head, Legs, Shoulder
    [2] = { [5] = 138350, [15] = 138369, [10] = 138353, [1] = 138356, [7] = 138359, [3] = 138362 }, -- Paladin:      Chest, Back, Hands, Head, Legs, Shoulder
    [3] = { [5] = 138339, [15] = 138368, [10] = 138340, [1] = 138342, [7] = 138344, [3] = 138347 }, -- Hunter:       Chest, Back, Hands, Head, Legs, Shoulder
    [4] = { [5] = 138326, [15] = 138371, [10] = 138329, [1] = 138332, [7] = 138335, [3] = 138338 }, -- Rogue:        Chest, Back, Hands, Head, Legs, Shoulder
    [5] = { [5] = 138319, [15] = 138370, [10] = 138310, [1] = 138313, [7] = 138316, [3] = 138322 }, -- Priest:       Chest, Back, Hands, Head, Legs, Shoulder
    [6] = { [5] = 138349, [15] = 138364, [10] = 138352, [1] = 138355, [7] = 138358, [3] = 138361 }, -- Death Knight: Chest, Back, Hands, Head, Legs, Shoulder
    [7] = { [5] = 138346, [15] = 138372, [10] = 138341, [1] = 138343, [7] = 138345, [3] = 138348 }, -- Shaman:       Chest, Back, Hands, Head, Legs, Shoulder
    [8] = { [5] = 138318, [15] = 138365, [10] = 138309, [1] = 138312, [7] = 138315, [3] = 138321 }, -- Mage:         Chest, Back, Hands, Head, Legs, Shoulder
    [9] = { [5] = 138320, [15] = 138373, [10] = 138311, [1] = 138314, [7] = 138317, [3] = 138323 }, -- Warlock:      Chest, Back, Hands, Head, Legs, Shoulder
    [10] = { [5] = 138325, [15] = 138367, [10] = 138328, [1] = 138331, [7] = 138334, [3] = 138337 }, -- Monk:         Chest, Back, Hands, Head, Legs, Shoulder
    [11] = { [5] = 138324, [15] = 138366, [10] = 138327, [1] = 138330, [7] = 138333, [3] = 138336 }, -- Druid:        Chest, Back, Hands, Head, Legs, Shoulder
    [12] = { [5] = 138376, [15] = 138375, [10] = 138377, [1] = 138378, [7] = 138379, [3] = 138380 } -- Demon Hunter: Chest, Back, Hands, Head, Legs, Shoulder
  },
  ["T20"] = {
    [0] = function(Count) return Count > 1, Count > 3 end, -- Return Function
    [1] = { [5] = 147187, [15] = 147188, [10] = 147189, [1] = 147190, [7] = 147191, [3] = 147192 }, -- Warrior:      Chest, Back, Hands, Head, Legs, Shoulder
    [2] = { [5] = 147157, [15] = 147158, [10] = 147159, [1] = 147160, [7] = 147161, [3] = 147162 }, -- Paladin:      Chest, Back, Hands, Head, Legs, Shoulder
    [3] = { [5] = 147139, [15] = 147140, [10] = 147141, [1] = 147142, [7] = 147143, [3] = 147144 }, -- Hunter:       Chest, Back, Hands, Head, Legs, Shoulder
    [4] = { [5] = 147169, [15] = 147170, [10] = 147171, [1] = 147172, [7] = 147173, [3] = 147174 }, -- Rogue:        Chest, Back, Hands, Head, Legs, Shoulder
    [5] = { [5] = 147167, [15] = 147163, [10] = 147164, [1] = 147165, [7] = 147166, [3] = 147168 }, -- Priest:       Chest, Back, Hands, Head, Legs, Shoulder
    [6] = { [5] = 147121, [15] = 147122, [10] = 147123, [1] = 147124, [7] = 147125, [3] = 147126 }, -- Death Knight: Chest, Back, Hands, Head, Legs, Shoulder
    [7] = { [5] = 147175, [15] = 147176, [10] = 147177, [1] = 147178, [7] = 147179, [3] = 147180 }, -- Shaman:       Chest, Back, Hands, Head, Legs, Shoulder
    [8] = { [5] = 147149, [15] = 147145, [10] = 147146, [1] = 147147, [7] = 147148, [3] = 147150 }, -- Mage:         Chest, Back, Hands, Head, Legs, Shoulder
    [9] = { [5] = 147185, [15] = 147181, [10] = 147182, [1] = 147183, [7] = 147184, [3] = 147186 }, -- Warlock:      Chest, Back, Hands, Head, Legs, Shoulder
    [10] = { [5] = 147151, [15] = 147152, [10] = 147153, [1] = 147154, [7] = 147155, [3] = 147156 }, -- Monk:         Chest, Back, Hands, Head, Legs, Shoulder
    [11] = { [5] = 147133, [15] = 147134, [10] = 147135, [1] = 147136, [7] = 147137, [3] = 147138 }, -- Druid:        Chest, Back, Hands, Head, Legs, Shoulder
    [12] = { [5] = 147127, [15] = 147128, [10] = 147129, [1] = 147130, [7] = 147131, [3] = 147132 } -- Demon Hunter: Chest, Back, Hands, Head, Legs, Shoulder
  },
  ["T21"] = {
    [0] = function(Count) return Count > 1, Count > 3 end, -- Return Function
    [1] = { [5] = 152178, [15] = 152179, [10] = 152180, [1] = 152181, [7] = 152182, [3] = 152183 }, -- Warrior:      Chest, Back, Hands, Head, Legs, Shoulder
    [2] = { [5] = 152148, [15] = 152149, [10] = 152150, [1] = 152151, [7] = 152152, [3] = 152153 }, -- Paladin:      Chest, Back, Hands, Head, Legs, Shoulder
    [3] = { [5] = 152130, [15] = 152131, [10] = 152132, [1] = 152133, [7] = 152134, [3] = 152135 }, -- Hunter:       Chest, Back, Hands, Head, Legs, Shoulder
    [4] = { [5] = 152160, [15] = 152161, [10] = 152162, [1] = 152163, [7] = 152164, [3] = 152165 }, -- Rogue:        Chest, Back, Hands, Head, Legs, Shoulder
    [5] = { [5] = 152158, [15] = 152154, [10] = 152155, [1] = 152156, [7] = 152157, [3] = 152159 }, -- Priest:       Chest, Back, Hands, Head, Legs, Shoulder
    [6] = { [5] = 152112, [15] = 152113, [10] = 152114, [1] = 152115, [7] = 152116, [3] = 152117 }, -- Death Knight: Chest, Back, Hands, Head, Legs, Shoulder
    [7] = { [5] = 152166, [15] = 152167, [10] = 152168, [1] = 152169, [7] = 152170, [3] = 152171 }, -- Shaman:       Chest, Back, Hands, Head, Legs, Shoulder
    [8] = { [5] = 152140, [15] = 152136, [10] = 152137, [1] = 152138, [7] = 152139, [3] = 152141 }, -- Mage:         Chest, Back, Hands, Head, Legs, Shoulder
    [9] = { [5] = 152176, [15] = 152172, [10] = 152173, [1] = 152174, [7] = 152175, [3] = 152177 }, -- Warlock:      Chest, Back, Hands, Head, Legs, Shoulder
    [10] = { [5] = 152142, [15] = 152143, [10] = 152144, [1] = 152145, [7] = 152146, [3] = 152147 }, -- Monk:         Chest, Back, Hands, Head, Legs, Shoulder
    [11] = { [5] = 152124, [15] = 152125, [10] = 152126, [1] = 152127, [7] = 152128, [3] = 152129 }, -- Druid:        Chest, Back, Hands, Head, Legs, Shoulder
    [12] = { [5] = 152118, [15] = 152119, [10] = 152120, [1] = 152121, [7] = 152122, [3] = 152123 } -- Demon Hunter: Chest, Back, Hands, Head, Legs, Shoulder
  }
}
function HL.HasTier(Tier)
  -- Set Bonuses are disabled in Challenge Mode (Diff = 8) and in Proving Grounds (Map = 1148).
  local DifficultyID, _, _, _, _, MapID = select(3, GetInstanceInfo())
  if DifficultyID == 8 or MapID == 1148 then return false end
  -- Check gear
  if HasTierSets[Tier][Cache.Persistent.Player.Class[3]] then
    local Count = 0
    local Item
    for Slot, ItemID in pairs(HasTierSets[Tier][Cache.Persistent.Player.Class[3]]) do
      Item = HL.Equipment[Slot]
      if Item and Item == ItemID then
        Count = Count + 1
      end
    end
    return HasTierSets[Tier][0](Count)
  else
    return false
  end
end
