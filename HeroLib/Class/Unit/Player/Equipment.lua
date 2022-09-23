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
local GetRuneforgeLegendaryComponentInfo = C_LegendaryCrafting.GetRuneforgeLegendaryComponentInfo
local IsRuneforgeLegendary = C_LegendaryCrafting.IsRuneforgeLegendary
local GetInventoryItemID = GetInventoryItemID
local ItemLocation = ItemLocation
local select = select
local wipe = wipe
-- File Locals
local Equipment = {}
local UseableTrinkets = {}
local ActiveLegendaryEffects = {}

--- ============================ CONTENT =============================
-- Retrieve the current player's equipment.
function Player:GetEquipment()
  return Equipment
end

-- Save the current player's equipment.
function Player:UpdateEquipment()
  wipe(Equipment)
  wipe(UseableTrinkets)

  for i = 1, 19 do
    local ItemID = select(1, GetInventoryItemID("player", i))
    -- If there is an item in that slot
    if ItemID ~= nil then
      -- Equipment
      Equipment[i] = ItemID
      -- Useable Trinkets
      if i == 13 or i == 14 then
        local TrinketItem = Item(ItemID, {i})
        if TrinketItem:IsUsable() then
          table.insert(UseableTrinkets, TrinketItem)
        end
      end
    end
  end
end

do
  -- Global Custom Trinkets
  -- Note: Can still be overriden on a per-module basis by passing in to ExcludedTrinkets
  local CustomTrinketItems = {
    FlayedwingToxin                 = Item(178742, {13, 14}),
    MistcallerOcarina               = Item(178715, {13, 14}),
    SoulIgniter                     = Item(184019, {13, 14}),
    DarkmoonDeckIndomitable         = Item(173096, {13, 14}),
    ShardofAnnhyldesAegis           = Item(186424, {13, 14}),
    TomeofMonstruousConstructions   = Item(186422, {13, 14}),
    SoleahsSecretTechnique          = Item(185818, {13, 14}),
    SoleahsSecretTechnique2         = Item(190958, {13, 14}),
  }
  local CustomTrinketsSpells = {
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
  }

  -- Check if the trinket is coded as blacklisted by the user or not.
  local function IsUserTrinketBlacklisted(TrinketItem)
    if not TrinketItem then return false end

    local TrinketItemID = TrinketItem:ID()
    if HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItemID] then
      if type(HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItemID]) == "boolean" then
        return true
      else
        return HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItemID](TrinketItem)
      end
    end

    return false
  end

  function Player:GetUseableTrinkets(ExcludedTrinkets, slotID)
    for _, TrinketItem in ipairs(UseableTrinkets) do
      local TrinketItemID = TrinketItem:ID()
      local IsExcluded = false

      -- Did we specify a slotID? If so, mark as excluded if this trinket isn't in that slot
      if slotID and Equipment[slotID] ~= TrinketItemID then
        IsExcluded = true
      -- Check if the trinket is ready, unless it's blacklisted
      elseif TrinketItem:IsReady() and not IsUserTrinketBlacklisted(TrinketItem) then
        for i=1, #ExcludedTrinkets do
          if ExcludedTrinkets[i] == TrinketItemID then
            IsExcluded = true
            break
          end
        end

        if not IsExcluded then
          -- Global custom trinket handlers
          if TrinketItemID == CustomTrinketItems.FlayedwingToxin:ID() then
            if not Player:AuraInfo(CustomTrinketsSpells.FlayedwingToxinBuff) then return TrinketItem end
          elseif TrinketItemID == CustomTrinketItems.MistcallerOcarina:ID() then
            if not (Player:BuffUp(CustomTrinketsSpells.MistcallerCrit) or Player:BuffUp(CustomTrinketsSpells.MistcallerHaste) or Player:BuffUp(CustomTrinketsSpells.MistcallerMastery) or Player:BuffUp(CustomTrinketsSpells.MistcallerVers)) then return TrinketItem end
          elseif TrinketItemID == CustomTrinketItems.SoulIgniter:ID() then
            if Player:BuffDown(CustomTrinketsSpells.SoulIgniterBuff) and Target:IsInRange(40) then return TrinketItem end
          elseif TrinketItemID == CustomTrinketItems.DarkmoonDeckIndomitable:ID() then
            if (Player:BuffUp(CustomTrinketsSpells.IndomitableFive) or Player:BuffUp(CustomTrinketsSpells.IndomitableSix) or Player:BuffUp(CustomTrinketsSpells.IndomitableSeven) or Player:BuffUp(CustomTrinketsSpells.IndomitableEight)) and (Player:IsTankingAoE(8) or Player:IsTanking(Target)) then return TrinketItem end
          elseif TrinketItemID == CustomTrinketItems.ShardofAnnhyldesAegis:ID() then
            if (Player:IsTankingAoE(8) or Player:IsTanking(Target)) then return TrinketItem end
          elseif TrinketItemID == CustomTrinketItems.TomeofMonstruousConstructions:ID() then
            if not Player:AuraInfo(CustomTrinketsSpells.TomeofMonstruousConstructionsBuff) then return TrinketItem end
          elseif TrinketItemID == CustomTrinketItems.SoleahsSecretTechnique:ID() or TrinketItemID == CustomTrinketItems.SoleahsSecretTechnique2:ID() then
            if not (Player:BuffUp(CustomTrinketsSpells.SoleahsSecretTechniqueBuff) or Player:BuffUp(CustomTrinketsSpells.SoleahsSecretTechnique2Buff)) then return TrinketItem end
          else
            return TrinketItem
          end
        end
      end
    end

    return nil
  end
end

-- Create a table of active Shadowlands legendaries
function Player:UpdateActiveLegendaryEffects()
  wipe(ActiveLegendaryEffects)

  for i = 1, 15, 1 do
    if i ~= 13 and i ~= 14 then -- Skip trinket slots since there is no trinket legendary
      local SlotItem = ItemLocation:CreateFromEquipmentSlot(i)
      if SlotItem:IsValid() and IsRuneforgeLegendary(SlotItem) then
        local LegendaryInfo = GetRuneforgeLegendaryComponentInfo(SlotItem)
        ActiveLegendaryEffects[LegendaryInfo.powerID] = true
      end
    end
  end
end

-- Check if a specific legendary is active, using the effect's ID
-- See HeroDBC/scripts/DBC/parsed/Legendaries.lua for a reference of Legendary Effect IDs
function Player:HasLegendaryEquipped(LegendaryID)
  return ActiveLegendaryEffects[LegendaryID] ~= nil
end

local UnityLegendaryIDs = {
  264,
  267,
  268,
  269,
  270,
  271,
  272,
  273,
  274,
  275,
  276,
  277
}

local UnityBeltIDs = {
  -- mage
  190464,
  -- druid
  190465,
  -- hunter
  190466,
  -- death knight
  190467,
  -- priest
  190468,
  -- warlock
  190469,
  -- demon hunter
  190470,
  -- rogue
  190471,
  -- monk
  190472,
  -- shaman
  190473,
  -- paladin
  190474,
  -- warrior
  190475
}

function Player:HasUnity()
  for _,LegendaryID in pairs(UnityLegendaryIDs) do
    if Player:HasLegendaryEquipped(LegendaryID) then return true end
  end
  local Belt = Equipment[6]
  for _,BeltID in pairs(UnityBeltIDs) do
    if Belt and Belt == BeltID then return true end
  end
  return false
end

local TierSets = {
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
    [12] = {[1] = 188892, [3] = 188896, [5] = 188894, [7] = 188893, [10] = 188898}
  }
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
    return Count > Pieces - 1
  else
    return false
  end
end
