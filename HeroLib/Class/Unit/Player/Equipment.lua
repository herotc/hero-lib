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
    FlayedwingToxin       = Item(178742, {13, 14}),
    MistcallerOcarina     = Item(178715, {13, 14}),
  }
  local CustomTrinketsSpells = {
    FlayedwingToxinBuff   = Spell(345545),
    MistcallerVers        = Spell(330067),
    MistcallerCrit        = Spell(332299),
    MistcallerHaste       = Spell(332300),
    MistcallerMastery     = Spell(332301),
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

  function Player:GetUseableTrinkets(ExcludedTrinkets)
    for _, TrinketItem in ipairs(UseableTrinkets) do
      local TrinketItemID = TrinketItem:ID()
      local IsExcluded = false

      -- Check if the trinket is ready, unless it's blacklisted
      if TrinketItem:IsReady() and not IsUserTrinketBlacklisted(TrinketItem) then
        for i=1, #ExcludedTrinkets do
          if ExcludedTrinkets[i] == TrinketItemID then
            IsExcluded = true
            break
          end
        end

        if not IsExcluded then
          -- Global custom trinket handlers
          if TrinketItemID == CustomTrinketItems.FlayedwingToxin:ID() then
            if not Player:BuffUp(CustomTrinketsSpells.FlayedwingToxinBuff) then return TrinketItem end
          elseif TrinketItemID == CustomTrinketItems.MistcallerOcarina:ID() then
            if not (Player:BuffUp(CustomTrinketsSpells.MistcallerCrit) or Player:BuffUp(CustomTrinketsSpells.MistcallerHaste) or Player:BuffUp(CustomTrinketsSpells.MistcallerMastery) or Player:BuffUp(CustomTrinketsSpells.MistcallerVers)) then return TrinketItem end
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
