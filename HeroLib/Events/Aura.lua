--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL     = ...
-- HeroLib
local Cache             = HeroCache
local Unit, UnitGUIDMap = HL.Unit, HL.UnitGUIDMap
local Player            = Unit.Player
local Pet               = Unit.Pet
local Target            = Unit.Target
local Nameplates        = Unit["Nameplate"]
local Spell             = HL.Spell
local Item              = HL.Item

-- Lua locals
local pairs             = pairs
local tableinsert       = table.insert

-- File Locals
local ListenedAuras = {}


--- ============================ CONTENT ============================
-- Register a spell to watch the aura status across multiple target units
function Spell:RegisterAuraTracking()
  local SpellID = self:ID()

  if ListenedAuras[SpellID] then
    error("Attempted to register spell " .. SpellID .. " multiple times, aborting!")
  end

  ListenedAuras[SpellID] = { Spell = self, Units = {} }
  HL.Debug("RegisterAuraTracking " .. SpellID)
end

-- Unregister all tracked spells
function HL.UnregisterAuraTracking()
  HL.Debug("UnregisterAuraTracking()")
  ListenedAuras = {}
end

-- AddAuraToUnit
HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
    local Aura = ListenedAuras[SpellID]
    if not Aura then return end

    local AuraUnits = Aura.Units
    if not AuraUnits[DestGUID] then
      AuraUnits[DestGUID] = true
      -- HL.Print("AddAuraToUnit " .. SpellID .. " " .. DestGUID)
    else
      -- HL.Print("AddAuraToUnit Refresh " .. SpellID .. " " .. DestGUID)
      -- Refresh
    end
  end,
  "SPELL_AURA_APPLIED", "SPELL_AURA_REFRESH", "SPELL_AURA_APPLIED_DOSE"
)

-- RemoveAuraFromUnit
HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
    local Aura = ListenedAuras[SpellID]
    if not Aura then return end

    local AuraUnits = Aura.Units
    if AuraUnits[DestGUID] then
      AuraUnits[DestGUID] = nil
      -- HL.Print("RemoveAuraFromUnit " .. Aura.Spell:Name() .. " " .. DestGUID)
    end
  end,
  "SPELL_AURA_REMOVED"
)

-- RemoveAurasFromUnit
HL:RegisterForCombatEvent(
  function(_, _, _, _, _, _, _, DestGUID)
    for _, Aura in pairs(ListenedAuras) do
      local AuraUnits = Aura.Units
      if AuraUnits[DestGUID] then
        AuraUnits[DestGUID] = nil
        -- HL.Print("RemoveAurasFromUnit " .. Aura.Spell:Name() .. " " .. DestGUID)
      end
    end
  end,
  "UNIT_DIED", "UNIT_DESTROYED"
)

-- ScanAurasOnUnit
do
  local function ScanAurasOnUnit(ThisUnit)
    local GUID = ThisUnit:GUID()
    if not GUID then
      -- HL.Print("ScanAurasForUnit - Invalid Unit")
      return
    end

    for _, Aura in pairs(ListenedAuras) do
      local ThisSpell = Aura.Spell
      local AuraUnits = Aura.Units
      if ThisUnit:DebuffUp(ThisSpell, nil, true) or ThisUnit:BuffUp(ThisSpell, nil, true) then
        if not AuraUnits[GUID] then
          AuraUnits[GUID] = true
          -- HL.Print("ScanAurasForUnit - Adding " .. Aura.Spell:Name() .. " to unit " .. GUID)
        end
      else
        if AuraUnits[GUID] then
          AuraUnits[GUID] = nil
          -- HL.Print("ScanAurasForUnit - Removing " .. Aura.Spell:Name() .. " from unit " .. GUID)
        end
      end
    end
  end

  HL:RegisterForEvent(function(_, UnitID) ScanAurasOnUnit(Nameplates[UnitID]) end, "NAME_PLATE_UNIT_ADDED")
  HL:RegisterForEvent(function() ScanAurasOnUnit(Target) end, "PLAYER_TARGET_CHANGED")
end

do
  local function SpellRegisterError(ErrorSpell)
    return "You forgot to register the spell: " .. ErrorSpell:Name() or ErrorSpell:ID() .. " in RegisterAura handler."
  end

  local function GetAuraUnit(Units, GUID)
    if UnitGUIDMap[GUID] then
      -- Just return the first valid entry, as they should all point to the same object
      for _, AuraUnit in pairs(UnitGUIDMap[GUID]) do
        if AuraUnit then
          return AuraUnit
        end
      end
    end

    -- Purge stale entry from the table
    Units[GUID] = nil
    -- HL.Print("GetAuraUnit - Purging Unit " .. UnitGUID)

    return nil
  end

  -- active_dot.foo
  -- Returns the total count this aura across all active targets
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:AuraActiveCount()
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local Count = 0
    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      if GetAuraUnit(AuraUnits, AuraUnitGUID) then
        Count = Count + 1
      end
    end

    return Count
  end

  -- Returns an array of the units with this aura across all active targets
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:AuraActiveUnits()
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local Units = {}
    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      local AuraUnit = GetAuraUnit(AuraUnits, AuraUnitGUID)
      if AuraUnit then
        tableinsert(Units, AuraUnit)
      end
    end

    return Units
  end

  -- Returns if an instance of this debuff is present on any active target
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:AnyBuffUp(BypassRecovery)
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      local AuraUnit = GetAuraUnit(AuraUnits, AuraUnitGUID)
      if AuraUnit and AuraUnit:Buff(self, nil, BypassRecovery) then
        return true
      end
    end

    return false
  end

  -- Returns if an instance of this debuff is present on any active target
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:AnyDebuffUp(BypassRecovery)
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      local AuraUnit = GetAuraUnit(AuraUnits, AuraUnitGUID)
      if AuraUnit and AuraUnit:DebuffUp(self, nil, BypassRecovery) then
        return true
      end
    end

    return false
  end

  -- Returns the maximum duration of this debuff that is present on any active target
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:MaxDebuffRemains(BypassRecovery)
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local MaxRemains = 0
    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      local AuraUnit = GetAuraUnit(AuraUnits, AuraUnitGUID)
      if AuraUnit then
        MaxRemains = math.max(MaxRemains, AuraUnit:DebuffRemains(self, nil, BypassRecovery))
      end
    end

    return MaxRemains
  end

  -- Returns the unit which has the maximum duration instance of this debuff
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:MaxDebuffRemainsUnit(BypassRecovery)
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local MaxRemains, MaxRemainsUnit = 0, nil
    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      local AuraUnit = GetAuraUnit(AuraUnits, AuraUnitGUID)
      if AuraUnit then
        local UnitRemains = AuraUnit:DebuffRemains(self, nil, BypassRecovery)
        if UnitRemains > MaxRemains then
          MaxRemains = UnitRemains
          MaxRemainsUnit = AuraUnit
        end
      end
    end

    return MaxRemainsUnit
  end

  -- Returns the maximum stack count of this debuff that is present on any active target
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:MaxDebuffStack(BypassRecovery)
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local MaxStack = 0
    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      local AuraUnit = GetAuraUnit(AuraUnits, AuraUnitGUID)
      if AuraUnit then
        MaxStack = math.max(MaxStack, AuraUnit:DebuffStack(self, nil, BypassRecovery))
      end
    end

    return MaxStack
  end

  -- Returns the unit which has the maximum stack count instance of this debuff
  -- Only works with spells using Spell:RegisterAuraTracking()
  function Spell:MaxDebuffStackUnit(BypassRecovery)
    local Aura = ListenedAuras[self:ID()]
    if not Aura then error(SpellRegisterError(self)) end

    local MaxStack, MaxStackUnit = 0, nil
    local AuraUnits = Aura.Units
    for AuraUnitGUID, _ in pairs(AuraUnits) do
      local AuraUnit = GetAuraUnit(AuraUnits, AuraUnitGUID)
      if AuraUnit then
        local UnitStack = AuraUnit:DebuffStack(self, nil, BypassRecovery)
        if UnitStack > MaxStack then
          MaxStack = UnitStack
          MaxStackUnit = AuraUnit
        end
      end
    end

    return MaxStackUnit
  end
end
