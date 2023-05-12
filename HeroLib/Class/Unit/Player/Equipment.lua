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
local GetInventoryItemID = GetInventoryItemID
local ItemLocation = ItemLocation
local select = select
local wipe = wipe
-- File Locals
local Equipment = {}
local UseableItems = {}

--- ============================ CONTENT =============================
-- Retrieve the current player's equipment.
function Player:GetEquipment()
  return Equipment
end

-- Retrieve the current player's usable items
function Player:GetOnUseItems()
  return UseableItems
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
      if ItemObject:IsUsable() then
        table.insert(UseableItems, ItemObject)
      end
    end
  end

  self:RegisterListenedItemSpells()
end

do
  -- Global Custom Trinkets
  -- Note: Can still be overriden on a per-module basis by passing in to ExcludedTrinkets
  local CustomItems = {
    -- Shadowlands
    BargastsLeash                   = Item(184017, {13, 14}),
    FlayedwingToxin                 = Item(178742, {13, 14}),
    MistcallerOcarina               = Item(178715, {13, 14}),
    SoulIgniter                     = Item(184019, {13, 14}),
    DarkmoonDeckIndomitable         = Item(173096, {13, 14}),
    ShardofAnnhyldesAegis           = Item(186424, {13, 14}),
    TomeofMonstruousConstructions   = Item(186422, {13, 14}),
    SoleahsSecretTechnique          = Item(185818, {13, 14}),
    SoleahsSecretTechnique2         = Item(190958, {13, 14}),
    -- Dragonflight
    GlobeofJaggedIce                = Item(193732, {13, 14}),
    PrimalRitualShell               = Item(200563, {13, 14}),
    RubyWhelpShell                  = Item(193757, {13, 14}),
    TreemouthsFesteringSplinter     = Item(193652, {13, 14}),
    UncannyPocketwatch              = Item(195220, {13, 14}),
  }
  local CustomItemSpells = {
    -- Shadowlands
    FlayedwingToxinBuff               = Spell(345545),
    MistcallerVers                    = Spell(330067),
    MistcallerCrit                    = Spell(332299),
    MistcallerHaste                   = Spell(332300),
    MistcallerMastery                 = Spell(332301),
    SoulIgniterBuff                   = Spell(345211),
    IndomitableFive                   = Spell(311496),
    IndomitableSix                    = Spell(311497),
    IndomitableSeven                  = Spell(311498),
    IndomitableEight                  = Spell(311499),
    TomeofMonstruousConstructionsBuff = Spell(357163),
    SoleahsSecretTechniqueBuff        = Spell(351952),
    SoleahsSecretTechnique2Buff       = Spell(368512),
    -- Dragonflight
    SkeweringColdDebuff               = Spell(388929),
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
    if IsUserItemBlacklisted(Item) then
      return true
    end

    local ItemID = Item:ID()
    
    -- Shadowlands
    if ItemID == CustomItems.BargastsLeash:ID() then
      return not (Player:IsInParty() or Player:IsInRaid())
    end

    if ItemID == CustomItems.FlayedwingToxin:ID() then
      return Player:AuraInfo(CustomItemSpells.FlayedwingToxinBuff)
    end

    if ItemID == CustomItems.MistcallerOcarina:ID() then
      return Player:BuffUp(CustomItemSpells.MistcallerCrit) or Player:BuffUp(CustomItemSpells.MistcallerHaste)
        or Player:BuffUp(CustomItemSpells.MistcallerMastery) or Player:BuffUp(CustomItemSpells.MistcallerVers)
    end

    if ItemID == CustomItems.SoulIgniter:ID() then
      return not (Player:BuffDown(CustomItemSpells.SoulIgniterBuff) and Target:IsInRange(40))
    end

    if ItemID == CustomItems.DarkmoonDeckIndomitable:ID() then
      return not ((Player:BuffUp(CustomItemSpells.IndomitableFive) or Player:BuffUp(CustomItemSpells.IndomitableSix) or Player:BuffUp(CustomItemSpells.IndomitableSeven)
        or Player:BuffUp(CustomItemSpells.IndomitableEight)) and (Player:IsTankingAoE(8) or Player:IsTanking(Target)))
    end

    if ItemID == CustomItems.ShardofAnnhyldesAegis:ID() then
      return not (Player:IsTankingAoE(8) or Player:IsTanking(Target))
    end

    if ItemID == CustomItems.TomeofMonstruousConstructions:ID() then
      return Player:AuraInfo(CustomItemSpells.TomeofMonstruousConstructionsBuff)
    end

    if ItemID == CustomItems.SoleahsSecretTechnique:ID() or ItemID == CustomItems.SoleahsSecretTechnique2:ID() then
      return Player:BuffUp(CustomItemSpells.SoleahsSecretTechniqueBuff) or Player:BuffUp(CustomItemSpells.SoleahsSecretTechnique2Buff)
    end

    -- Dragonflight
    if ItemID == CustomItems.GlobeofJaggedIce:ID() then
      return Target:DebuffStack(CustomItemSpells.SkeweringColdDebuff) < 4
    end

    if ItemID == CustomItems.TreemouthsFesteringSplinter:ID() then
      return not (Player:IsTankingAoE(8) or Player:IsTanking(Target))
    end

    if ItemID == CustomItems.RubyWhelpShell:ID()
    or ItemID == CustomItems.PrimalRitualShell:ID()
    or ItemID == CustomItems.UncannyPocketwatch:ID() then
      return true
    end

    -- Return false by default
    return false
  end

  -- Return the trinket item of the first usable trinket that is not blacklisted or excluded
  function Player:GetUseableItems(ExcludedItems, slotID)
    for _, Item in ipairs(UseableItems) do
      local ItemID = Item:ID()
      local IsExcluded = false

      -- Did we specify a slotID? If so, mark as excluded if this trinket isn't in that slot
      if slotID and Equipment[slotID] ~= ItemID then
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
          local ItemRange = (ItemSpell and ItemSpell.MaximumRange > 0) and ItemSpell.MaximumRange or 1000
          return Item, ItemSlot, ItemRange
        end
      end
    end

    return nil
  end
end

-- Define our tier set tables
-- TierSets[TierNumber][ClassID][ItemSlot] = Item ID
local TierSets = {
  -- Item Slot IDs: 1 - Head, 3 - Shoulders, 5 - Chest, 7 - Legs, 10 - Hands
  [28] = {
    -- Warrior
    [1]  = {[1] = 188942, [3] = 188941, [5] = 188938, [7] = 188940, [10] = 188937},
    -- Paladin
    [2]  = {[1] = 188933, [3] = 188932, [5] = 188929, [7] = 188931, [10] = 188928},
    -- Hunter
    [3]  = {[1] = 188859, [3] = 188856, [5] = 188858, [7] = 188860, [10] = 188861},
    -- Rogue
    [4]  = {[1] = 188901, [3] = 188905, [5] = 188903, [7] = 188902, [10] = 188907},
    -- Priest
    [5]  = {[1] = 188880, [3] = 188879, [5] = 188875, [7] = 188878, [10] = 188881},
    -- Death Knight
    [6]  = {[1] = 188868, [3] = 188867, [5] = 188864, [7] = 188866, [10] = 188863},
    -- Shaman
    [7]  = {[1] = 188923, [3] = 188920, [5] = 188922, [7] = 188924, [10] = 188925},
    -- Mage
    [8]  = {[1] = 188844, [3] = 188843, [5] = 188839, [7] = 188842, [10] = 188845},
    -- Warlock
    [9]  = {[1] = 188889, [3] = 188888, [5] = 188884, [7] = 188887, [10] = 188890},
    -- Monk
    [10] = {[1] = 188910, [3] = 188914, [5] = 188912, [7] = 188911, [10] = 188916},
    -- Druid
    [11] = {[1] = 188847, [3] = 188851, [5] = 188849, [7] = 188848, [10] = 188853},
    -- Demon Hunter
    [12] = {[1] = 188892, [3] = 188896, [5] = 188894, [7] = 188893, [10] = 188898},
    -- Evoker
    [13] = {[1] = nil,    [3] = nil,    [5] = nil,    [7] = nil,    [10] = nil}
  },
  [29] = {
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
  [30] = {
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
}

-- Check if a tier set bonus is equipped
function Player:HasTier(Tier, Pieces)
  if TierSets[Tier][Cache.Persistent.Player.Class[3]] then
    local Count = 0
    local Item
    for Slot, ItemID in pairs(TierSets[Tier][Cache.Persistent.Player.Class[3]]) do
      Item = Equipment[Slot]
      if Item and Item == ItemID then
        Count = Count + 1
      end
    end
    return Count >= Pieces
  else
    return false
  end
end
