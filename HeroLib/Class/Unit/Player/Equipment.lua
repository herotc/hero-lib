--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL          = ...
-- HeroLib
local Cache, Utils           = HeroCache, HL.Utils
local Unit                   = HL.Unit
local Player, Pet, Target    = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver       = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid            = Unit.Party, Unit.Raid
local Spell                  = HL.Spell
local Item                   = HL.Item

-- Base API locals
local GetInventoryItemID     = GetInventoryItemID
-- Accepts: unitID, invSlotId; Returns: itemId (number)
local GetProfessionInfo      = GetProfessionInfo
local GetProfessions         = GetProfessions
-- Accepts: nil; Returns: prof1 (number), prof2 (number), archaeology (number), fishing (number), cooking (number)

-- Lua locals
local select                 = select
local wipe                   = wipe

-- File Locals
local Equipment              = {}
local UseableItems           = {}


--- ============================ CONTENT =============================
-- Define our tier set tables
-- TierSets[TierNumber][ClassID][ItemSlot] = Item ID
local TierSets = {
  -- Dragonflight - Vault of the Incarnates
  [29] = {
    -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
    -- Warrior
    [1]  = {[1] = 200426, [3] = 200428, [5] = 200423, [7] = 200427, [10] = 200425},
    -- Paladin
    [2]  = {[1] = 200417, [3] = 200419, [5] = 200414, [7] = 200418, [10] = 200416},
    -- Hunter
    [3]  = {[1] = 200390, [3] = 200392, [5] = 200387, [7] = 200391, [10] = 200389},
    -- Rogue
    [4]  = {[1] = 200372, [3] = 200374, [5] = 200369, [7] = 200373, [10] = 200371},
    -- Priest
    [5]  = {[1] = 200327, [3] = 200329, [5] = 200324, [7] = 200328, [10] = 200326},
    -- Death Knight
    [6]  = {[1] = 200408, [3] = 200410, [5] = 200405, [7] = 200409, [10] = 200407},
    -- Shaman
    [7]  = {[1] = 200399, [3] = 200401, [5] = 200396, [7] = 200400, [10] = 200398},
    -- Mage
    [8]  = {[1] = 200318, [3] = 200320, [5] = 200315, [7] = 200319, [10] = 200317},
    -- Warlock
    [9]  = {[1] = 200336, [3] = 200338, [5] = 200333, [7] = 200337, [10] = 200335},
    -- Monk
    [10] = {[1] = 200363, [3] = 200365, [5] = 200360, [7] = 200364, [10] = 200362},
    -- Druid
    [11] = {[1] = 200354, [3] = 200356, [5] = 200351, [7] = 200355, [10] = 200353},
    -- Demon Hunter
    [12] = {[1] = 200345, [3] = 200347, [5] = 200342, [7] = 200346, [10] = 200344},
    -- Evoker
    [13] = {[1] = 200381, [3] = 200383, [5] = 200378, [7] = 200382, [10] = 200380}
  },
  -- Dragonflight - Aberrus, the Shadowed Crucible
  [30] = {
    -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
    -- Warrior
    [1]  = {[1] = 202443, [3] = 202441, [5] = 202446, [7] = 202442, [10] = 202444},
    -- Paladin
    [2]  = {[1] = 202452, [3] = 202450, [5] = 202455, [7] = 202451, [10] = 202453},
    -- Hunter
    [3]  = {[1] = 202479, [3] = 202477, [5] = 202482, [7] = 202478, [10] = 202480},
    -- Rogue
    [4]  = {[1] = 202497, [3] = 202495, [5] = 202500, [7] = 202496, [10] = 202498},
    -- Priest
    [5]  = {[1] = 202542, [3] = 202540, [5] = 202545, [7] = 202541, [10] = 202543},
    -- Death Knight
    [6]  = {[1] = 202461, [3] = 202459, [5] = 202464, [7] = 202460, [10] = 202462},
    -- Shaman
    [7]  = {[1] = 202470, [3] = 202468, [5] = 202473, [7] = 202469, [10] = 202471},
    -- Mage
    [8]  = {[1] = 202551, [3] = 202549, [5] = 202554, [7] = 202550, [10] = 202552},
    -- Warlock
    [9]  = {[1] = 202533, [3] = 202531, [5] = 202536, [7] = 202532, [10] = 202534},
    -- Monk
    [10] = {[1] = 202506, [3] = 202504, [5] = 202509, [7] = 202505, [10] = 202507},
    -- Druid
    [11] = {[1] = 202515, [3] = 202513, [5] = 202518, [7] = 202514, [10] = 202516},
    -- Demon Hunter
    [12] = {[1] = 202524, [3] = 202522, [5] = 202527, [7] = 202523, [10] = 202525},
    -- Evoker
    [13] = {[1] = 202488, [3] = 202486, [5] = 202491, [7] = 202487, [10] = 202489}
  },
  -- Dragonflight - Amirdrassil, the Dream's Hope
  [31] = {
    -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
    -- Warrior
    [1]  = {[1] = 207182, [3] = 207180, [5] = 207185, [7] = 207181, [10] = 207183},
    -- Paladin
    [2]  = {[1] = 207191, [3] = 207189, [5] = 207194, [7] = 207190, [10] = 207192},
    -- Hunter
    [3]  = {[1] = 207218, [3] = 207216, [5] = 207221, [7] = 207217, [10] = 207219},
    -- Rogue
    [4]  = {[1] = 207236, [3] = 207234, [5] = 207239, [7] = 207235, [10] = 207237},
    -- Priest
    [5]  = {[1] = 207281, [3] = 207279, [5] = 207284, [7] = 207280, [10] = 207282},
    -- Death Knight
    [6]  = {[1] = 207200, [3] = 207198, [5] = 207203, [7] = 207199, [10] = 207201},
    -- Shaman
    [7]  = {[1] = 207209, [3] = 207207, [5] = 207212, [7] = 207208, [10] = 207210},
    -- Mage
    [8]  = {[1] = 207290, [3] = 207288, [5] = 207293, [7] = 207289, [10] = 207291},
    -- Warlock
    [9]  = {[1] = 207272, [3] = 207270, [5] = 207275, [7] = 207271, [10] = 207273},
    -- Monk
    [10] = {[1] = 207245, [3] = 207243, [5] = 207248, [7] = 207244, [10] = 207246},
    -- Druid
    [11] = {[1] = 207254, [3] = 207252, [5] = 207257, [7] = 207253, [10] = 207255},
    -- Demon Hunter
    [12] = {[1] = 207263, [3] = 207261, [5] = 207266, [7] = 207262, [10] = 207264},
    -- Evoker
    [13] = {[1] = 207227, [3] = 207225, [5] = 207230, [7] = 207226, [10] = 207228}
  },
  -- Dragonflight - Season 4
  ["DFS4"] = {
    -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
    -- Warrior
    [1]  = {[1] = 217218, [3] = 217220, [5] = 217216, [7] = 217219, [10] = 217217},
    -- Paladin
    [2]  = {[1] = 217198, [3] = 217200, [5] = 217196, [7] = 217199, [10] = 217197},
    -- Hunter
    [3]  = {[1] = 217183, [3] = 217185, [5] = 217181, [7] = 217184, [10] = 217182},
    -- Rogue
    [4]  = {[1] = 217208, [3] = 217210, [5] = 217206, [7] = 217209, [10] = 217207},
    -- Priest
    [5]  = {[1] = 217202, [3] = 217204, [5] = 217205, [7] = 217203, [10] = 217201},
    -- Death Knight
    [6]  = {[1] = 217223, [3] = 217225, [5] = 217221, [7] = 217224, [10] = 217222},
    -- Shaman
    [7]  = {[1] = 217238, [3] = 217240, [5] = 217236, [7] = 217239, [10] = 217237},
    -- Mage
    [8]  = {[1] = 217232, [3] = 217234, [5] = 217235, [7] = 217233, [10] = 217231},
    -- Warlock
    [9]  = {[1] = 217212, [3] = 217214, [5] = 217215, [7] = 217213, [10] = 217211},
    -- Monk
    [10] = {[1] = 217188, [3] = 217190, [5] = 217186, [7] = 217189, [10] = 217187},
    -- Druid
    [11] = {[1] = 217193, [3] = 217195, [5] = 217191, [7] = 217194, [10] = 217192},
    -- Demon Hunter
    [12] = {[1] = 217228, [3] = 217230, [5] = 217226, [7] = 217229, [10] = 217227},
    -- Evoker
    [13] = {[1] = 217178, [3] = 217180, [5] = 217176, [7] = 217179, [10] = 217177}
  },
  ["TWW1"] = {
    -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
    -- Warrior
    [1]  = {[1] = 211984, [3] = 211982, [5] = 211987, [7] = 211983, [10] = 211985},
    -- Paladin
    [2]  = {[1] = 211993, [3] = 211991, [5] = 211996, [7] = 211992, [10] = 211994},
    -- Hunter
    [3]  = {[1] = 212020, [3] = 212018, [5] = 212023, [7] = 212019, [10] = 212021},
    -- Rogue
    [4]  = {[1] = 212038, [3] = 212036, [5] = 212041, [7] = 212037, [10] = 212039},
    -- Priest
    [5]  = {[1] = 212083, [3] = 212081, [5] = 212086, [7] = 212082, [10] = 212084},
    -- Death Knight
    [6]  = {[1] = 212002, [3] = 212000, [5] = 212005, [7] = 212001, [10] = 212003},
    -- Shaman
    [7]  = {[1] = 212011, [3] = 212009, [5] = 212014, [7] = 212010, [10] = 212012},
    -- Mage
    [8]  = {[1] = 212092, [3] = 212090, [5] = 212095, [7] = 212091, [10] = 212093},
    -- Warlock
    [9]  = {[1] = 212074, [3] = 212072, [5] = 212077, [7] = 212073, [10] = 212075},
    -- Monk
    [10] = {[1] = 212047, [3] = 212045, [5] = 212050, [7] = 212046, [10] = 212048},
    -- Druid
    [11] = {[1] = 212056, [3] = 212054, [5] = 212059, [7] = 212055, [10] = 212057},
    -- Demon Hunter
    [12] = {[1] = 212065, [3] = 212063, [5] = 212068, [7] = 212064, [10] = 212066},
    -- Evoker
    [13] = {[1] = 212029, [3] = 212027, [5] = 212032, [7] = 212028, [10] = 212030}
  },
}

-- Usable items that may not become active until an event or threshold.
-- Adding an item to this list forces it into the UseableItems table.
local UsableItemOverride = {
  -- Dragonflight
  [208321] = true, -- Iridal
}

-- Retrieve the current player's equipment.
function Player:GetEquipment()
  return Equipment
end

-- Retrieve the current player's usable items
function Player:GetOnUseItems()
  return UseableItems
end

-- Retrieve the current player's trinket items
function Player:GetTrinketItems()
  local Equip = Player:GetEquipment()
  local Trinket1 = Equip[13] and Item(Equip[13]) or Item(0)
  local Trinket2 = Equip[14] and Item(Equip[14]) or Item(0)
  return Trinket1, Trinket2
end

-- Retrieve the current player's trinket data
function Player:GetTrinketData()
  local Equip = Player:GetEquipment()
  local Trinket1 = Equip[13] and Item(Equip[13]) or Item(0)
  local Trinket2 = Equip[14] and Item(Equip[14]) or Item(0)
  local Trinket1Spell = Trinket1:OnUseSpell()
  local Trinket2Spell = Trinket2:OnUseSpell()
  local Trinket1Range = (Trinket1Spell and Trinket1Spell.MaximumRange > 0 and Trinket1Spell.MaximumRange <= 100) and Trinket1Spell.MaximumRange or 100
  local Trinket2Range = (Trinket2Spell and Trinket2Spell.MaximumRange > 0 and Trinket2Spell.MaximumRange <= 100) and Trinket2Spell.MaximumRange or 100
  local Trinket1CastTime = Trinket1Spell and Trinket1Spell:CastTime() or 0
  local Trinket2CastTime = Trinket2Spell and Trinket2Spell:CastTime() or 0
  local T1 = {
    Object = Trinket1,
    ID = Trinket1:ID(),
    Spell = Trinket1Spell,
    Range = Trinket1Range,
    CastTime = Trinket1CastTime,
    Cooldown = Trinket1:Cooldown(),
    Blacklisted = Player:IsItemBlacklisted(Trinket1)
  }
  local T2 = {
    Object = Trinket2,
    ID = Trinket2:ID(),
    Spell = Trinket2Spell,
    Range = Trinket2Range,
    CastTime = Trinket2CastTime,
    Cooldown = Trinket2:Cooldown(),
    Blacklisted = Player:IsItemBlacklisted(Trinket2)
  }
  return T1, T2
end

-- Save the current player's equipment.
function Player:UpdateEquipment()
  wipe(Equipment)
  wipe(UseableItems)

  for i = 1, 19 do
    local ItemID = select(1, GetInventoryItemID("player", i))
    -- If there is an item in that slot
    if ItemID ~= nil then
      -- Equipment
      Equipment[i] = ItemID
      -- Useable Items
      local ItemObject
      if i == 13 or i == 14 then
        ItemObject = Item(ItemID, {i})
      else
        ItemObject = Item(ItemID)
      end
      if ItemObject:OnUseSpell() or UsableItemOverride[ItemID] then
        table.insert(UseableItems, ItemObject)
      end
    end
  end

  -- Update tier sets worn
  local ClassID = Cache.Persistent.Player.Class[3]
  local TierItem
  for TierNum in pairs(TierSets) do
    Cache.Persistent.TierSets[TierNum] = {}
    Cache.Persistent.TierSets[TierNum]["2pc"] = false
    Cache.Persistent.TierSets[TierNum]["4pc"] = false
    local Count = 0
    for SlotID, ItemID in pairs(TierSets[TierNum][ClassID]) do
      TierItem = Equipment[SlotID]
      if TierItem and TierItem == ItemID then
        Count = Count + 1
      end
    end
    if Count >= 2 then Cache.Persistent.TierSets[TierNum]["2pc"] = true end
    if Count >= 4 then Cache.Persistent.TierSets[TierNum]["4pc"] = true end
  end

  self:RegisterListenedItemSpells()
end

do
  -- Global Custom Items
  -- Note: Can still be overriden on a per-module basis by passing in to ExcludedItems
  local GenericItems = {
    ----- Generic items that we always want to exclude
    --- The War Within
    [218422] = true, -- Forged Aspirant's Medallion
    [218716] = true, -- Forged Gladiator's Medallion
    [218717] = true, -- Forged Gladiator's Sigil of Adaptation
    [219931] = true, -- Algari Competitor's Medallion
    -- TWW Engineering Epic Quality Wrists
    [221805] = true,
    [221806] = true,
    [221807] = true,
    [221808] = true,
    -- TWW Engineering Uncommon Quality Wrists
    [217155] = true,
    [217156] = true,
    [217157] = true,
    [217158] = true,
    --- Dragonflight
    [207783] = true, -- Cruel Dreamcarver
    [204388] = true, -- Draconic Cauterizing Magma
    [201962] = true, -- Heat of Primal Winter
    [203729] = true, -- Ominous Chromatic Essence
    [200563] = true, -- Primal Ritual Shell
    [193000] = true, -- Ring-Bound Hourglass
    [193757] = true, -- Ruby Whelp Shell
    [202612] = true, -- Screaming Black Dragonscale
    [209948] = true, -- Spring's Keeper
    [195220] = true, -- Uncanny Pocketwatch
    -- DF Engineering Epic Quality Wrists
    [198322] = true,
    [198327] = true,
    [198332] = true,
    [198333] = true,
  }

  local EngItems = {
    ----- Engineering items (only available to a player with Engineering) to exclude
    ----- Most tinkers are situational at best, so we'll exclude every item with a tinker slot
    --- The War Within
    -- Epic Quality Goggles
    [221801] = true,
    [221802] = true,
    [221803] = true,
    [221804] = true,
    -- Rare Quality Goggles
    [225642] = true,
    [225643] = true,
    [225644] = true,
    [225645] = true,
    -- Uncommon Quality Goggles
    [217151] = true,
    [217152] = true,
    [217153] = true,
    [217154] = true,
    --- Dragonflight
    -- Epic Quality Goggles
    [198323] = true,
    [198324] = true,
    [198325] = true,
    [198326] = true,
    -- Rare Quality Goggles
    [198328] = true,
    [198329] = true,
    [198330] = true,
    [198331] = true,
    -- Uncommon Quality Goggles
    [205278] = true,
    [205279] = true,
    [205280] = true,
    [205281] = true,
  }

  local CustomItems = {
    -- Dragonflight
    GlobeofJaggedIce                = Item(193732, {13, 14}),
    TreemouthsFesteringSplinter     = Item(193652, {13, 14}),
  }

  local CustomItemSpells = {
    -- Dragonflight
    SkeweringColdDebuff               = Spell(388929),
  }

  local RangeOverrides = {
    [207172]                          = 10, -- Belor'relos, the Suncaller
  }

  -- Check if the trinket is coded as blacklisted by the user or not.
  local function IsUserItemBlacklisted(Item)
    if not Item then return false end

    local ItemID = Item:ID()
    if HL.GUISettings.General.Blacklist.ItemUserDefined[ItemID] then
      if type(HL.GUISettings.General.Blacklist.ItemUserDefined[ItemID]) == "boolean" then
        return true
      else
        return HL.GUISettings.General.Blacklist.ItemUserDefined[ItemID](Item)
      end
    end

    return false
  end

  -- Check if the trinket is coded as blacklisted either globally or by the user
  function Player:IsItemBlacklisted(Item)
    if IsUserItemBlacklisted(Item) or not Item:SlotIDs() then
      return true
    end

    local ItemID = Item:ID()
    local ItemSlot = Item:SlotIDs()[1]

    -- Exclude all tabards and shirts
    if ItemSlot == 19 or ItemSlot == 4 then return true end

    -- Dragonflight items being excluded with custom checks.
    if ItemID == CustomItems.GlobeofJaggedIce:ID() then
      return Target:DebuffStack(CustomItemSpells.SkeweringColdDebuff) < 4
    end

    if ItemID == CustomItems.TreemouthsFesteringSplinter:ID() then
      return not (Player:IsTankingAoE(8) or Player:IsTanking(Target))
    end

    -- Any generic items we always want to exclude from suggestions.
    if GenericItems[ItemID] then return true end

    -- Handle Engineering excludes.
    for _, profindex in pairs({GetProfessions()}) do
      local prof = GetProfessionInfo(profindex)
      if prof == "Engineering" then
        -- Hacky workaround for excluding Engineering cloak/waist tinkers.
        -- If possible, find a way to parse tinkers and handle this properly.
        if ItemSlot == 6 or ItemSlot == 15 then
          return true
        end
        -- Exclude specific Engineering items.
        if EngItems[ItemID] then return true end
      end
    end

    -- Return false by default
    return false
  end

  -- Return the trinket item of the first usable trinket that is not blacklisted or excluded
  function Player:GetUseableItems(ExcludedItems, slotID, excludeTrinkets)
    for _, Item in ipairs(UseableItems) do
      local ItemID = Item:ID()
      local IsExcluded = false

      -- Did we specify a slotID? If so, mark as excluded if this trinket isn't in that slot
      if slotID and Equipment[slotID] ~= ItemID then
        IsExcluded = true
      -- Exclude trinket items if excludeTrinkets is true
      elseif excludeTrinkets and (Equipment[13] == ItemID or Equipment[14] == ItemID) then
        IsExcluded = true
      -- Check if the trinket is ready, unless it's blacklisted
      elseif Item:IsReady() and not Player:IsItemBlacklisted(Item) then
        for i=1, #ExcludedItems do
          if ExcludedItems[i] == ItemID then
            IsExcluded = true
            break
          end
        end

        if not IsExcluded then
          local ItemSlot = Item:SlotIDs()[1]
          local ItemSpell = Item:OnUseSpell()
          local ItemRange = (ItemSpell and ItemSpell.MaximumRange > 0 and ItemSpell.MaximumRange <= 100) and ItemSpell.MaximumRange or 100
          if RangeOverrides[ItemID] then ItemRange = RangeOverrides[ItemID] end
          return Item, ItemSlot, ItemRange
        end
      end
    end

    return nil
  end
end

-- Check if a tier set bonus is equipped
function Player:HasTier(Tier, Pieces)
  local DFS4Translate = {
    -- Warrior
    [1] = { [71] = 29, [72] = 30, [73] = 31 },
    -- Paladin
    [2] = { [66] = 29, [70] = 31 },
    -- Hunter
    [3] = { [253] = 31, [254] = 31, [255] = 29 },
    -- Rogue
    [4] = { [259] = 31, [260] = 31, [261] = 31 },
    -- Priest
    [5] = { [258] = 30 },
    -- Death Knight
    [6] = { [250] = 30, [251] = 30, [252] = 31 },
    -- Shaman
    [7] = { [262] = 31, [263] = 31 },
    -- Mage
    [8] = { [62] = 31, [63] = 30, [64] = 31 },
    -- Warlock
    [9] = { [265] = 31, [266] = 31, [267] = 29 },
    -- Monk
    [10] = { [268] = 31, [269] = 29 },
    -- Druid
    [11] = { [102] = 29, [103] = 31, [104] = 30 },
    -- Demon Hunter
    [12] = { [577] = 31, [581] = 31 },
    -- Evoker
    [13] = { [1467] = 30, [1473] = 31 }
  }
  local Class = Cache.Persistent.Player.Class[3]
  local Spec = Cache.Persistent.Player.Spec[1]
  if DFS4Translate[Class][Spec] and DFS4Translate[Class][Spec] == Tier then
    return Cache.Persistent.TierSets[Tier][Pieces.."pc"] or Cache.Persistent.TierSets["DFS4"][Pieces.."pc"]
  else
    return Cache.Persistent.TierSets[Tier][Pieces.."pc"]
  end
end
