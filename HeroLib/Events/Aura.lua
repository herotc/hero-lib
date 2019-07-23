--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache = HeroCache
local Unit, UnitGUIDMap = HL.Unit, HL.UnitGUIDMap
local Player = Unit.Player
local Pet = Unit.Pet
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local pairs = pairs
local tableinsert = table.insert
local tableremove = table.remove
local tablesort = table.sort
-- File Locals
local ListenedAuras = {}


--- ============================ CONTENT ============================

local function AddAuraToUnit(SpellID, UnitGUID)
  local Aura = ListenedAuras[SpellID]
  if Aura then
    if not Aura.Units[UnitGUID] then
      Aura.Units[UnitGUID] = true
      Aura.ActiveCount = Aura.ActiveCount + 1
      -- HL.Print("AddAuraToUnit " .. SpellID .. " " .. UnitGUID .. " " .. Aura.ActiveCount)
    else
      -- HL.Print("AddAuraToUnit Refresh " .. SpellID .. " " .. UnitGUID .. " " .. Aura.ActiveCount)
      -- Refresh
    end
  end
end

local function RemoveAuraFromUnit(SpellID, UnitGUID)
  local Aura = ListenedAuras[SpellID]
  if Aura and Aura.Units[UnitGUID] then
    Aura.Units[UnitGUID] = nil
    Aura.ActiveCount = Aura.ActiveCount - 1
    -- HL.Print("RemoveAuraFromUnit " .. SpellID .. " " .. UnitGUID .. " " .. Aura.ActiveCount)
    if Aura.ActiveCount < 0 then
      error("RemoveAuraFromUnit - Aura tracking count is less than zero")
    end
  end
end

local function RemoveAurasFromUnit(UnitGUID)
  for SpellID, Aura in pairs(ListenedAuras) do
    if Aura.Units[UnitGUID] then
      Aura.Units[UnitGUID] = nil
      Aura.ActiveCount = Aura.ActiveCount - 1
      -- HL.Print("RemoveAurasFromUnit " .. SpellID .. " " .. UnitGUID .. " " .. Aura.ActiveCount)
      if Aura.ActiveCount < 0 then
        error("RemoveAurasFromUnit - Aura tracking count is less than zero")
      end
    end
  end
end

-- PMultiplier OnApply/OnRefresh Listener
HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
  AddAuraToUnit(SpellID, DestGUID)
end, "SPELL_AURA_APPLIED", "SPELL_AURA_REFRESH", "SPELL_AURA_APPLIED_DOSE")

HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
  RemoveAuraFromUnit(SpellID, DestGUID)
end, "SPELL_AURA_REMOVED")

HL:RegisterForCombatEvent(function(_, _, _, _, _, _, _, DestGUID)
  RemoveAurasFromUnit(DestGUID)
end, "UNIT_DIED", "UNIT_DESTROYED")

-- Register a spell to watch the aura status across multiple target units
function Spell:RegisterAuraTracking()
  if ListenedAuras[self.SpellID] then
    error("Attempted to register spell " .. self.SpellID .. " multiple times, aborting!")
    return
  end
  ListenedAuras[self.SpellID] = {
    ActiveCount = 0,
    Units = {}
  }
  HL.Debug("RegisterAuraTracking " .. self.SpellID)
end

local function GetAuraUnit(UnitGUID)
  if UnitGUIDMap[UnitGUID] then
    -- Just return the first valid entry, as they should all point to the same object
    for _, AuraUnit in pairs(UnitGUIDMap[UnitGUID]) do
      if AuraUnit then
        return AuraUnit
      end
    end
  end
  return nil
end

local function SpellRegisterError(ErrorSpell)
  local SpellName = ErrorSpell:Name()
  if SpellName then
    return "You forgot to register the spell: " .. SpellName .. " in RegisterAura handler."
  else
    return "You forgot to register the spell: " .. ErrorSpell.SpellID .. " in RegisterAura handler."
  end
end

-- Returns the total count this aura across all active targets
-- Only works with spells using Spell:RegisterAuraTracking()
function Spell:ActiveCount()
  local Aura = ListenedAuras[self.SpellID]
  if Aura then
    return Aura.ActiveCount
  else
    error(SpellRegisterError(Spell))
  end
  return 0
end

-- Returns if an instance of this debuff is present on any active target
-- Only works with spells using Spell:RegisterAuraTracking()
function Spell:AnyDebuffP(Offset)
  local Aura = ListenedAuras[self.SpellID]
  if Aura then
    for AuraUnitGUID, _ in pairs(Aura.Units) do
      local AuraUnit = GetAuraUnit(AuraUnitGUID)
      if AuraUnit and AuraUnit:DebuffP(self, nil, Offset) then
        return true
      end
    end
  else
    error(SpellRegisterError(Spell))
  end
  return false
end

-- Returns the maximum duration of this debuff that is present on any active target
-- Only works with spells using Spell:RegisterAuraTracking()
function Spell:MaxDebuffRemainsP(Offset)
  local Aura = ListenedAuras[self.SpellID]
  if Aura then
    local MaxRemains = 0
    for AuraUnitGUID, _ in pairs(Aura.Units) do
      local AuraUnit = GetAuraUnit(AuraUnitGUID)
      if AuraUnit then
        MaxRemains = math.max(MaxRemains, AuraUnit:DebuffRemainsP(self, nil, Offset))
      end
    end
    return MaxRemains
  else
    error(SpellRegisterError(Spell))
  end
  return 0
end

-- Returns the unit which has the maximum duration instance of this debuff
-- Only works with spells using Spell:RegisterAuraTracking()
function Spell:MaxDebuffRemainsPUnit()
  local Aura = ListenedAuras[self.SpellID]
  if Aura then
    local MaxRemains, MaxRemainsUnit = 0, nil
    for AuraUnitGUID, _ in pairs(Aura.Units) do
      local AuraUnit = GetAuraUnit(AuraUnitGUID)
      if AuraUnit then
        local UnitRemains = AuraUnit:DebuffRemainsP(self, nil, Offset)
        if UnitRemains > MaxRemains then
          MaxRemains = UnitRemains
          MaxRemainsUnit = AuraUnit
        end
      end
    end
    return MaxRemainsUnit
  else
    error(SpellRegisterError(Spell))
  end
  return nil
end

-- Returns the maximum stack count of this debuff that is present on any active target
-- Only works with spells using Spell:RegisterAuraTracking()
function Spell:MaxDebuffStackP()
  local MaxStack = 0
  local Aura = ListenedAuras[self.SpellID]
  if Aura then
    for AuraUnitGUID, _ in pairs(Aura.Units) do
      local AuraUnit = GetAuraUnit(AuraUnitGUID)
      if AuraUnit then
        MaxStack = math.max(MaxStack, AuraUnit:DebuffStackP(self))
      end
    end
  else
    error(SpellRegisterError(Spell))
  end
  return MaxStack
end

-- Returns the unit which has the maximum stack count instance of this debuff
-- Only works with spells using Spell:RegisterAuraTracking()
function Spell:MaxDebuffStackPUnit()
  local Aura = ListenedAuras[self.SpellID]
  if Aura then
    local MaxStack, MaxStackUnit = 0, nil
    for AuraUnitGUID, _ in pairs(Aura.Units) do
      local AuraUnit = GetAuraUnit(AuraUnitGUID)
      if AuraUnit then
        local UnitStack = AuraUnit:DebuffStackP(self)
        if UnitStack > MaxStack then
          MaxStack = UnitStack
          MaxStackUnit = AuraUnit
        end
      end
    end
    return MaxStackUnit
  else
    error(SpellRegisterError(Spell))
  end
  return nil
end

