--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache = HeroCache
-- Lua
local error = error
local GetItemInfo = GetItemInfo
local GetSpellInfo = GetSpellInfo
local setmetatable = setmetatable
local stringformat = string.format
local tableinsert = table.insert
-- File Locals



--- ============================ CONTENT ============================
--- ======= PSEUDO-CLASS =======
local function Class()
  local Class = {}
  Class.__index = Class
  setmetatable(Class, {
    __call =
    function(self, ...)
      local Object = {}
      setmetatable(Object, self)
      Object:New(...)
      return Object
    end
  })
  return Class
end

--- ======= UNIT =======
do
  local Unit = Class()
  HL.Unit = Unit
  function Unit:New(UnitID, UseCache)
    if type(UnitID) ~= "string" then error("Invalid UnitID.") end
    self.UnitID = UnitID
    self.UseCache = UseCache or false
    self:Init()
  end

  local UnitGUIDMap = {}
  HL.UnitGUIDMap = UnitGUIDMap
  function Unit:RemoveUnitGUIDMapEntry()
    if UnitGUIDMap[self.UnitGUID] and UnitGUIDMap[self.UnitGUID][self.UnitID] then
      UnitGUIDMap[self.UnitGUID][self.UnitID] = nil;
      if next(UnitGUIDMap[self.UnitGUID]) == nil then
        UnitGUIDMap[self.UnitGUID] = nil
      end
    end
  end

  function Unit:AddUnitGUIDMapEntry()
    if not self.UnitGUID or not self.UnitID then
      return
    end
    if not UnitGUIDMap[self.UnitGUID] then
      UnitGUIDMap[self.UnitGUID] = {}
    end
    if not UnitGUIDMap[self.UnitGUID][self.UnitID] then
      UnitGUIDMap[self.UnitGUID][self.UnitID] = self
    end
  end

  function Unit:Init()
    self:RemoveUnitGUIDMapEntry()
    self.UnitExists = false
    self.UnitGUID = nil
    self.UnitNPCID = nil
    self.UnitName = nil
    self.UnitCanBeAttacked = false
  end

  -- Unique Units
  Unit.Player = Unit("player", true)
  Unit.Pet = Unit("pet")
  Unit.Target = Unit("target", true)
  Unit.Focus = Unit("focus", true)
  Unit.MouseOver = Unit("mouseover")
  Unit.Vehicle = Unit("vehicle")
  -- Iterable Units
  local UnitIDs = {
    -- Type,        Count,      UseCache
    { "Arena",      5,          true    },
    { "Boss",       4,          true    },
    { "Nameplate",  HL.MAXIMUM, true    },
    { "Party",      5,          true    },
    { "Raid",       40,         true    }
  }
  for _, UnitID in pairs(UnitIDs) do
    local UnitType = UnitID[1]
    local UnitCount = UnitID[2]
    local UnitUseCache = UnitID[3]
    Unit[UnitType] = {}
    for i = 1, UnitCount do
      local UnitKey = stringformat("%s%d", UnitType, i)
      Unit[UnitType][UnitKey:lower()] = Unit(UnitKey, UnitUseCache)
    end
  end
end

--- ======= SPELL =======
do
  local Spell = Class()
  HL.Spell = Spell
  function Spell:New(SpellID, SpellType)
    if type(SpellID) ~= "number" then error("Invalid SpellID.") end
    if SpellType and type(SpellType) ~= "string" then error("Invalid Spell Type.") end

    -- Attributes
    local SpellName, _, _, _, MinimumRange, MaximumRange = GetSpellInfo(SpellID)
    self.SpellID = SpellID
    self.SpellType = SpellType or "Player" -- For Pet, put "Pet". Default is "Player". Related to HeroCache.Persistent.SpellLearned.
    self.SpellName = SpellName
    self.MinimumRange = MinimumRange
    self.MaximumRange = MaximumRange
    self.IsMelee = MinimumRange == 0 and MaximumRange == 0
    -- Variables
    self.LastCastTime = 0
    self.LastDisplayTime = 0
    self.LastHitTime = 0
    self.LastAppliedOnPlayerTime = 0
    self.LastRemovedFromPlayerTime = 0
  end
end

-- TODO: Refactor to merge it into Spell
do
  local MultiSpell = Class()
  HL.MultiSpell = MultiSpell

  function MultiSpell:New(...)
    local Arg = {...}
    self.SpellTable = {}

    for _, Spell in pairs(Arg) do
      if type(Spell) == "number" then
        Spell = HL.Spell(Spell)
      end
      if type(Spell.SpellID) ~= "number" then error("Invalid SpellID.") end
      tableinsert(self.SpellTable, Spell)
    end

    function MultiSpell:Update()
      for i, Spell in pairs(self.SpellTable) do
        if Spell:IsLearned() or (i == #self.SpellTable) then
          Spell.Update = self.Update
          setmetatable(self, {__index = Spell})
          break
        end
      end
    end

    self:AddToMultiSpells()
    self:Update()
  end
end

--- ======= ITEM =======
do
  local ItemSlotTable = {
    -- Source: http://wowwiki.wikia.com/wiki/ItemEquipLoc
    [""] = nil, -- "" value is the value of ItemEquipLoc if not equippable
    ["INVTYPE_AMMO"] = { 0 },
    ["INVTYPE_HEAD"] = { 1 },
    ["INVTYPE_NECK"] = { 2 },
    ["INVTYPE_SHOULDER"] = { 3 },
    ["INVTYPE_BODY"] = { 4 },
    ["INVTYPE_CHEST"] = { 5 },
    ["INVTYPE_ROBE"] = { 5 },
    ["INVTYPE_WAIST"] = { 6 },
    ["INVTYPE_LEGS"] = { 7 },
    ["INVTYPE_FEET"] = { 8 },
    ["INVTYPE_WRIST"] = { 9 },
    ["INVTYPE_HAND"] = { 10 },
    ["INVTYPE_FINGER"] = { 11, 12 },
    ["INVTYPE_TRINKET"] = { 13, 14 },
    ["INVTYPE_CLOAK"] = { 15 },
    ["INVTYPE_WEAPON"] = { 16, 17 },
    ["INVTYPE_SHIELD"] = { 17 },
    ["INVTYPE_2HWEAPON"] = { 16 },
    ["INVTYPE_WEAPONMAINHAND"] = { 16 },
    ["INVTYPE_WEAPONOFFHAND"] = { 17 },
    ["INVTYPE_HOLDABLE"] = { 17 },
    ["INVTYPE_RANGED"] = { 18 },
    ["INVTYPE_THROWN"] = { 18 },
    ["INVTYPE_RANGEDRIGHT"] = { 18 },
    ["INVTYPE_RELIC"] = { 18 },
    ["INVTYPE_TABARD"] = { 19 },
    ["INVTYPE_BAG"] = { 20, 21, 22, 23 },
    ["INVTYPE_QUIVER"] = { 20, 21, 22, 23 },
  }

  local Item = Class()
  HL.Item = Item

  function Item:New(ItemID, ItemSlotIDs)
    if type(ItemID) ~= "number" then error("Invalid ItemID.") end
    if ItemSlotIDs and type(ItemSlotIDs) ~= "table" then error("Invalid ItemSlotIDs.") end

    -- Attributes
    local ItemName, _, ItemRarity, ItemLevel, ItemMinLevel, _, _, _, ItemEquipLoc = GetItemInfo(ItemID)
    self.ItemID = ItemID
    self.ItemName = ItemName
    self.ItemRarity = ItemRarity
    self.ItemLevel = ItemLevel
    self.ItemMinLevel = ItemMinLevel
    self.ItemSlotIDs = ItemSlotIDs or ItemSlotTable[ItemEquipLoc]
    -- Variables
    self.LastCastTime = 0
    self.LastDisplayTime = 0
    self.LastHitTime = 0
  end
end
