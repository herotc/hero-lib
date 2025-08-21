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
  ["TWW2"] = {
    -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
    -- Warrior
    [1]  = {[1] = 229235, [3] = 229233, [5] = 229238, [7] = 229234, [10] = 229236},
    -- Paladin
    [2]  = {[1] = 229244, [3] = 229242, [5] = 229247, [7] = 229243, [10] = 229245},
    -- Hunter
    [3]  = {[1] = 229271, [3] = 229269, [5] = 229274, [7] = 229270, [10] = 229272},
    -- Rogue
    [4]  = {[1] = 229289, [3] = 229287, [5] = 229292, [7] = 229288, [10] = 229290},
    -- Priest
    [5]  = {[1] = 229334, [3] = 229332, [5] = 229337, [7] = 229333, [10] = 229335},
    -- Death Knight
    [6]  = {[1] = 229253, [3] = 229251, [5] = 229256, [7] = 229252, [10] = 229254},
    -- Shaman
    [7]  = {[1] = 229262, [3] = 229260, [5] = 229265, [7] = 229261, [10] = 229263},
    -- Mage
    [8]  = {[1] = 229343, [3] = 229341, [5] = 229346, [7] = 229342, [10] = 229344},
    -- Warlock
    [9]  = {[1] = 229325, [3] = 229323, [5] = 229328, [7] = 229324, [10] = 229326},
    -- Monk
    [10] = {[1] = 229298, [3] = 229296, [5] = 229301, [7] = 229297, [10] = 229299},
    -- Druid
    [11] = {[1] = 229307, [3] = 229305, [5] = 229310, [7] = 229306, [10] = 229308},
    -- Demon Hunter
    [12] = {[1] = 229316, [3] = 229314, [5] = 229319, [7] = 229315, [10] = 229317},
    -- Evoker
    [13] = {[1] = 229280, [3] = 229278, [5] = 229283, [7] = 229279, [10] = 229281}
  },
  ["TWW3"] = {
    -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
    -- Warrior
    [1]  = {[1] = 237610, [3] = 237608, [5] = 237613, [7] = 237609, [10] = 237611},
    -- Paladin
    [2]  = {[1] = 237619, [3] = 237617, [5] = 237622, [7] = 237618, [10] = 237620},
    -- Hunter
    [3]  = {[1] = 237646, [3] = 237644, [5] = 237649, [7] = 237645, [10] = 237647},
    -- Rogue
    [4]  = {[1] = 237664, [3] = 237662, [5] = 237667, [7] = 237663, [10] = 237665},
    -- Priest
    [5]  = {[1] = 237709, [3] = 237707, [5] = 237712, [7] = 237708, [10] = 237710},
    -- Death Knight
    [6]  = {[1] = 237628, [3] = 237626, [5] = 237631, [7] = 237627, [10] = 237629},
    -- Shaman
    [7]  = {[1] = 237637, [3] = 237635, [5] = 237640, [7] = 237636, [10] = 237638},
    -- Mage
    [8]  = {[1] = 237718, [3] = 237716, [5] = 237721, [7] = 237717, [10] = 237719},
    -- Warlock
    [9]  = {[1] = 237700, [3] = 237698, [5] = 237703, [7] = 237699, [10] = 237701},
    -- Monk
    [10] = {[1] = 237673, [3] = 237671, [5] = 237676, [7] = 237672, [10] = 237674},
    -- Druid
    [11] = {[1] = 237682, [3] = 237680, [5] = 237685, [7] = 237681, [10] = 237683},
    -- Demon Hunter
    [12] = {[1] = 237691, [3] = 237689, [5] = 237694, [7] = 237690, [10] = 237692},
    -- Evoker
    [13] = {[1] = 237655, [3] = 237653, [5] = 237658, [7] = 237654, [10] = 237656}
  },
}

local GladiatorBadges = {
  -- DF Badges
  201807, -- Crimson
  205708, -- Obsidian
  209343, -- Verdant
  216279, -- Draconic
  -- TWW Badges
  218713, -- Forged
  229780, -- Prized
  230638, -- Astral
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
function Player:GetTrinketData(OnUseExcludes)
  local Equip = Player:GetEquipment()
  local Trinket1 = Equip[13] and Item(Equip[13]) or Item(0)
  local Trinket2 = Equip[14] and Item(Equip[14]) or Item(0)
  local Trinket1Spell = Trinket1:OnUseSpell()
  local Trinket2Spell = Trinket2:OnUseSpell()
  local Trinket1SpellID = Trinket1Spell and Trinket1Spell:ID() or 0
  local Trinket2SpellID = Trinket2Spell and Trinket2Spell:ID() or 0
  local Trinket1Range = (Trinket1Spell and Trinket1Spell.MaximumRange > 0 and Trinket1Spell.MaximumRange <= 100) and Trinket1Spell.MaximumRange or 100
  local Trinket2Range = (Trinket2Spell and Trinket2Spell.MaximumRange > 0 and Trinket2Spell.MaximumRange <= 100) and Trinket2Spell.MaximumRange or 100
  local Trinket1CastTime = Trinket1Spell and Trinket1Spell:CastTime() or 0
  local Trinket2CastTime = Trinket2Spell and Trinket2Spell:CastTime() or 0
  local Trinket1Usable = Trinket1:IsUsable()
  local Trinket2Usable = Trinket2:IsUsable()
  local T1Excluded = false
  local T2Excluded = false
  if OnUseExcludes then
    for _, Item in pairs(OnUseExcludes) do
      if Item and Trinket1:ID() == Item then
        T1Excluded = true
      end
      if Item and Trinket2:ID() == Item then
        T2Excluded = true
      end
    end
  end
  local T1 = {
    Object = Trinket1,
    ID = Trinket1:ID(),
    Level = Trinket1:Level(),
    Spell = Trinket1Spell,
    SpellID = Trinket1SpellID,
    Range = Trinket1Range,
    Usable = Trinket1Usable,
    CastTime = Trinket1CastTime,
    Cooldown = Trinket1:Cooldown(),
    Excluded = T1Excluded
  }
  local T2 = {
    Object = Trinket2,
    ID = Trinket2:ID(),
    Level = Trinket2:Level(),
    Spell = Trinket2Spell,
    SpellID = Trinket2SpellID,
    Range = Trinket2Range,
    Usable = Trinket2Usable,
    CastTime = Trinket2CastTime,
    Cooldown = Trinket2:Cooldown(),
    Excluded = T2Excluded
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
    -- 11.2 Belt
    [242664] = true, -- Cloth DISC
    [245964] = true, -- Leather DISC
    [245965] = true, -- Mail DISC
    [245966] = true, -- Plate DISC
    -- TWW Generic Items
    [215133] = true, -- Binding of Binding
    [218422] = true, -- Forged Aspirant's Medallion
    [218716] = true, -- Forged Gladiator's Medallion
    [218717] = true, -- Forged Gladiator's Sigil of Adaptation
    [219381] = true, -- Fate Weaver
    [219931] = true, -- Algari Competitor's Medallion
    [228844] = true, -- Test Pilot's Go-Pack
    [230193] = true, -- Mister Lock-N-Stalk
    [235222] = true, -- Apogee Invengor's Goggles
    [235223] = true, -- Psychogenic Prognosticator's Lenses
    [235224] = true, -- Mekgineer's Mindbending Headgear
    [235226] = true, -- Inventor's Ingenious Trifocals
    [237494] = true, -- Hallowed Tome
    [237495] = true, -- Baleful Excerpt
    [243365] = true, -- Maw of the Void
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
    -- Shadowlands
    BottledFlayedwingToxin          = Item(178742, {13, 14}),
    -- Dragonflight
    GlobeofJaggedIce                = Item(193732, {13, 14}),
    TreemouthsFesteringSplinter     = Item(193652, {13, 14}),
    -- The War Within
    ChromebustibleBombSuit          = Item(230029, {13, 14}),
    ConcoctionKissofDeath           = Item(215174, {13, 14}),
    FoulBehemothsChelicera          = Item(219915, {13, 14}),
    JunkmaestrosMegaMagnet          = Item(230189, {13, 14}),
    KahetiEmblem                    = Item(225651, {13, 14}),
    RingingRitualMud                = Item(232543, {13, 14}),
    SwarmlordsAuthority             = Item(212450, {13, 14}),
  }

  local CustomItemSpells = {
    -- Shadowlands
    FlayedwingToxinBuff             = Spell(345545),
    -- Dragonflight
    SkeweringColdDebuff             = Spell(388929),
    -- The War Within
    ConcoctionKissofDeathBuff       = Spell(435493),
    JunkmaestrosBuff                = Spell(1219661),
    KahetiEmblemBuff                = Spell(455464),
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

    -- Shadowlands items being excluded with custom checks.
    if ItemID == CustomItems.BottledFlayedwingToxin:ID() then
      return Player:BuffUp(CustomItemSpells.FlayedwingToxinBuff)
    end

    -- Dragonflight items being excluded with custom checks.
    if ItemID == CustomItems.GlobeofJaggedIce:ID() then
      return Target:DebuffStack(CustomItemSpells.SkeweringColdDebuff) < 4
    end

    if ItemID == CustomItems.TreemouthsFesteringSplinter:ID() then
      return not (Player:IsTankingAoE(8) or Player:IsTanking(Target))
    end

    -- The War Within items being excluded with custom checks.
    if ItemID == CustomItems.ConcoctionKissofDeath:ID() then
      return Player:BuffUp(CustomItemSpells.ConcoctionKissofDeathBuff)
    end

    if ItemID == CustomItems.JunkmaestrosMegaMagnet:ID() then
      return Player:BuffDown(CustomItemSpells.JunkmaestrosBuff)
    end

    if ItemID == CustomItems.KahetiEmblem:ID() then
      return Player:BuffStack(CustomItemSpells.KahetiEmblemBuff) < 4 and not (Player:BuffUp(CustomItemSpells.KahetiEmblemBuff) and Player:BuffRemains(CustomItemSpells.KahetiEmblemBuff) < 3) or Player:BuffDown(CustomItemSpells.KahetiEmblemBuff)
    end

    if ItemID == CustomItems.SwarmlordsAuthority:ID() or ItemID == CustomItems.FoulBehemothsChelicera:ID() or ItemID == CustomItems.RingingRitualMud:ID() or ItemID == CustomItems.ChromebustibleBombSuit:ID() then
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

-- Check if a Gladiator's Badge is equipped
function Player:GladiatorsBadgeIsEquipped()
  local Trinket1, Trinket2 = Player:GetTrinketItems()
  for _, v in pairs(GladiatorBadges) do
    if Trinket1:ID() == v or Trinket2:ID() == v then
      return true
    end
  end
  return false
end
