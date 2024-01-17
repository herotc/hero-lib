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
local GetProfessionInfo = GetProfessionInfo
local GetProfessions = GetProfessions
local ItemLocation = ItemLocation
local select = select
local wipe = wipe
-- File Locals
local Equipment = {}
local UseableItems = {}

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
}

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
    -- Generic items that we always want to exclude
    -- Dragonflight
    CruelDreamcarver                = Item(207783, {16, 17}),
    DraconicCauterizingMagma        = Item(204388, {13, 14}),
    HeatofPrimalWinter              = Item(201962, {2}),
    OminousChromaticEssence         = Item(203729, {13, 14}),
    PrimalRitualShell               = Item(200563, {13, 14}),
    RingBoundHourglass              = Item(193000, {13, 14}),
    RubyWhelpShell                  = Item(193757, {13, 14}),
    ScreamingBlackDragonscale       = Item(202612, {13, 14}),
    UncannyPocketwatch              = Item(195220, {13, 14}),
    -- Engineering Epic Quality Wrists
    ComplicatedCuffs                = Item(198332),
    DifficultWristProtectors        = Item(198333),
    NeedlesslyComplexWristguards    = Item(198327),
    OverengineeredSleeveExtenders   = Item(198322),
  }
  local EngItems = {
    -- Dragonflight Engineering excludes
    -- Most tinkers are situational at best, so let's exclude every item with a tinker slot
    -- Epic Quality Goggles
    BattleReadyGoggles              = Item(198326),
    LightweightOcularLenses         = Item(198323),
    OscillatingWildernessOpticals   = Item(198325),
    PeripheralVisionProjectors      = Item(198324),
    -- Rare Quality Goggles
    DeadlineDeadeyes                = Item(198330),
    MilestoneMagnifiers             = Item(198329),
    QualityAssuredOptics            = Item(198328),
    SentrysStabilizedSpecs          = Item(198331),
    -- Uncommon Quality Goggles
    ClothGoggles                    = Item(205278),
    LeatherGoggles                  = Item(205279),
    MailGoggles                     = Item(205280),
    PlateGoggles                    = Item(205281),
  }
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
    TreemouthsFesteringSplinter     = Item(193652, {13, 14}),
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

    -- Dragonflight items being excluded with custom checks.
    if ItemID == CustomItems.GlobeofJaggedIce:ID() then
      return Target:DebuffStack(CustomItemSpells.SkeweringColdDebuff) < 4
    end

    if ItemID == CustomItems.TreemouthsFesteringSplinter:ID() then
      return not (Player:IsTankingAoE(8) or Player:IsTanking(Target))
    end

    -- Any generic items we always want to exclude from suggestions.
    for _, GenItem in pairs(GenericItems) do
      if ItemID == GenItem:ID() then
        return true
      end
    end

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
        for _, EngItem in pairs(EngItems) do
          if ItemID == EngItem:ID() then
            return true
          end
        end
      end
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
  return Cache.Persistent.TierSets[Tier][Pieces.."pc"]
end
