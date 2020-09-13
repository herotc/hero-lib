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
local pairs = pairs
local select = select
-- File Locals


--- ============================ CONTENT ============================
-- Save the current player's equipment.
HL.Equipment = {}
HL.OnUseTrinkets = {}
function HL.GetEquipment()
  local ItemID
  HL.Equipment = {}
  HL.OnUseTrinkets = {}

  for i = 1, 19 do
    ItemID = select(1, GetInventoryItemID("player", i))
    -- If there is an item in that slot
    if ItemID ~= nil then
      HL.Equipment[i] = ItemID
      if (i == 13 or i == 14) then
        local TrinketItem = HL.Item(ItemID, {i})
        if TrinketItem:IsUsable() then
          table.insert(HL.OnUseTrinkets, TrinketItem)
        end
      end
    end
  end
end

-- Check if the trinket is coded as blacklisted by the user or not.
local function IsUserTrinketBlacklisted(TrinketItem)
  if not TrinketItem then return false end
  if HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItem:ID()] then
    if type(HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItem:ID()]) == "boolean" then
      return true
    else
      return HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItem:ID()](TrinketItem)
    end
  end
  return false
end

-- Function to be called against SimC's use_items
function HL.UseTrinkets(ExcludedTrinkets)
  for _, TrinketItem in ipairs(HL.OnUseTrinkets) do
  local isExcluded = false
    -- Check if the trinket is ready, unless it's blacklisted
    if TrinketItem:IsReady() and not IsUserTrinketBlacklisted(TrinketItem) then
      for i=1,#ExcludedTrinkets do
        if (ExcludedTrinkets[i] == TrinketItem:ID()) then
          isExcluded = true
          break
        end
      end
      if (not isExcluded) then
        return TrinketItem
      end
    end
  end
  return nil
end
