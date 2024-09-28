--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL   = ...
-- HeroDBC
local DBC             = HeroDBC.DBC
-- HeroLib
local Cache           = HeroCache
local Unit            = HL.Unit
local Player          = Unit.Player
local Target          = Unit.Target
local Spell           = HL.Spell
local Item            = HL.Item

-- C_Item locals
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
-- Accepts: itemInfo; Returns: actualItemLevel (number), previewLevel (bool), sparseItemLevel (number)
local GetItemCooldown = C_Item.GetItemCooldown
-- Accepts: itemInfo; Returns: startTimeSeconds (number), durationSeconds (number), enableCooldownTimer (bool)
local GetItemCount    = C_Item.GetItemCount
-- Accepts: itemInfo, includeBank, includeUses, includeReagentBank; Returns: count (number)
local GetItemInfo     = C_Item.GetItemInfo
-- Accepts: itemInfo
-- Returns: itemName (cstring), itemLink (cstring), itemQuality (ItemQuality), itemLevel (number), itemMinLevel(number), itemType (cstring), itemSubType (cstring), itemStackCound (number),
-- itemEquipLoc (cstring), itemTexture (fileID), sellPrice (number), classID (number), subclassID (number), bindType (number), expansionID (number), setID (number), isCraftingReagent(bool)
local GetItemLink     = C_Item.GetItemLink
--Accepts: itemLocation; Returns: itemLink (string)
local IsUsableItem    = C_Item.IsUsableItem
-- Accepts: itemInfo; Returns: usable (bool), noMana (bool)

-- Base API locals
local GetSpellBaseCooldown = GetSpellBaseCooldown
local ItemLocation    = ItemLocation
-- lua locals
local GetTime         = GetTime
-- File Locals


--- ============================ CONTENT ============================
-- Get the item ID.
function Item:ID()
  return self.ItemID
end

-- Get the item Name.
function Item:Name()
  return self.ItemName
end

-- Get the item Rarity.
-- Item Rarity
-- 0 = Poor
-- 1 = Common
-- 2 = Uncommon
-- 3 = Rare
-- 4 = Epic
-- 5 = Legendary
-- 6 = Artifact
-- 7 = Heirloom
-- 8 = WoW Token
function Item:Rarity()
  return self.ItemRarity
end

-- Get the item Level.
function Item:Level()
  if not self:IsEquipped() then return self.ItemLevel or 0 end
  local Equipment = Player:GetEquipment()
  for _,i in pairs(self:SlotIDs()) do
    if self:ID() == Equipment[i] then
      local Location = ItemLocation:CreateFromEquipmentSlot(i)
      local ItemLink = GetItemLink(Location)
      return GetDetailedItemLevelInfo(ItemLink) or self.ItemLevel or 0
    end
  end
  -- Safety
  return self.ItemLevel or 0
end

-- Get the item level requirement.
function Item:MinLevel()
  return self.ItemMinLevel
end

-- Get the item slot IDs (derived from ItemEquipLoc).
function Item:SlotIDs()
  return self.ItemSlotIDs
end

-- Get the item Info from the item ID.
function Item:InfoByID()
  return GetItemInfo(self:ID())
end

-- Get the item Info from the item Name.
function Item:InfoByName()
  return GetItemInfo(self:Name())
end

-- Get wether an item is legendary.
function Item:IsLegendary()
  return self.ItemRarity == 5
end

-- Check whether the item exists in our inventory
function Item:Exists()
  return GetItemCount(self:ID()) > 0
end

-- Get wether an item is usable currently.
function Item:IsUsable()
  return IsUsableItem(self:ID())
end

function Item:OnUseSpell()
  return self.ItemUseSpell
end

-- Check if a given item is currently equipped.
-- Inventory slots
-- INVSLOT_HEAD       = 1
-- INVSLOT_NECK       = 2
-- INVSLOT_SHOULDAC   = 3
-- INVSLOT_BODY       = 4
-- INVSLOT_CHEST      = 5
-- INVSLOT_WAIST      = 6
-- INVSLOT_LEGS       = 7
-- INVSLOT_FEET       = 8
-- INVSLOT_WRIST      = 9
-- INVSLOT_HAND       = 10
-- INVSLOT_FINGAC1    = 11
-- INVSLOT_FINGAC2    = 12
-- INVSLOT_TRINKET1   = 13
-- INVSLOT_TRINKET2   = 14
-- INVSLOT_BACK       = 15
-- INVSLOT_MAINHAND   = 16
-- INVSLOT_OFFHAND    = 17
-- INVSLOT_RANGED     = 18
-- INVSLOT_TABARD     = 19
function Item:IsEquipped()
  local ItemSlotIDs = self:SlotIDs()
  if not ItemSlotIDs then return false end

  local ItemID = self:ID()
  local ItemInfo = Cache.ItemInfo[ItemID]
  if not ItemInfo then
    ItemInfo = {}
    Cache.SpellInfo[ItemID] = ItemInfo
  end

  if ItemInfo.IsEquipped == nil then
    local ItemIsEquipped = false
    local Equipment = Player:GetEquipment()

    for i = 0, #ItemSlotIDs do
      local ItemSlotID = ItemSlotIDs[i]
      if Equipment[ItemSlotID] == self.ItemID then
        ItemIsEquipped = true
        break
      end
    end

    ItemInfo.IsEquipped = ItemIsEquipped
  end
  return ItemInfo.IsEquipped
end

-- Get the item's base Cooldown (from GetSpellBaseCooldown and DBC data)
function Item:Cooldown()
  return (DBC.ItemSpell[self:ID()] and GetSpellBaseCooldown(DBC.ItemSpell[self:ID()]) / 1000 or 0)
end

-- Get the CooldownInfo (from GetItemCooldown).
function Item:CooldownInfo()
  return GetItemCooldown(self:ID())
end

do
  -- Computes any item cooldown (using GetItemCooldown).
  local function ComputeCooldown(ThisItem)
    -- Get Item cooldown infos
    local CDTime, CDValue = ThisItem:CooldownInfo()
    -- Return 0 if the Item isn't in CD.
    if CDTime == 0 then return 0 end
    -- Compute the CD.
    local CD = CDTime + CDValue - GetTime() - HL.Latency()
    -- Return the Item CD
    return CD > 0 and CD or 0
  end

  -- cooldown.foo.remains
  function Item:CooldownRemains()
    local ItemID = self:ID()

    local ItemInfo = Cache.ItemInfo[ItemID]
    if not ItemInfo then
      ItemInfo = {}
      Cache.SpellInfo[ItemID] = ItemInfo
    end

    local Cooldown = ItemInfo.Cooldown
    if not Cooldown then
      Cooldown = ComputeCooldown(self)
      ItemInfo.Cooldown = Cooldown
    end

    return Cooldown
  end
end

-- trinket.foo.has_cooldown or item.foo.has_cooldown
function Item:HasCooldown()
  return self:Cooldown() > 0
end

-- cooldown.foo.up
function Item:CooldownUp()
  return self:CooldownRemains() == 0
end

-- "cooldown.foo.down"
-- Since it doesn't exists in SimC, I think it's better to use 'not Spell:CooldownUp' for consistency with APLs.
function Item:CooldownDown()
  return self:CooldownRemains() ~= 0
end

-- trinket.foo.cast_time
function Item:CastTime()
  if not self:OnUseSpell() then return 0 end
  return self:OnUseSpell():CastTime() or 0
end

-- Get wether an item is ready to be used
function Item:IsReady()
  if not self:IsUsable() or not self:OnUseSpell() then return false end
  return self:CooldownUp() or self:CooldownRemains() <= Player:GCDRemains()
end

-- Get whether an item is equipped and ready to be used
function Item:IsEquippedAndReady()
  return (self:IsEquipped() and self:IsReady())
end

-- Get the item Last Cast Time.
function Item:TimeSinceLastCast()
  return self:OnUseSpell() and self:OnUseSpell():TimeSinceLastCast() or 0
end

-- trinket.foo.has_stat.any_dps
function Item:HasStatAnyDps()
  if not self:OnUseSpell() then return false end
  return DBC.SpellAuraStat[self:OnUseSpell():ID()]
end

-- trinket.foo.has_use_buff
function Item:HasUseBuff()
  return self:IsUsable() and self:HasStatAnyDps()
end

-- buff.potion.duration
function Item:BuffDuration()
  if not self:IsUsable() then return 0 end
  if not self:OnUseSpell() then return 0 end
  local BuffLength
  if DBC.SpellDuration[self:OnUseSpell():ID()] then
    BuffLength = DBC.SpellDuration[self:OnUseSpell():ID()][1]
  end
  if not BuffLength then return 0 end
  if BuffLength > 1000 then BuffLength = BuffLength / 1000 end
  return BuffLength
end
