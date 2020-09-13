--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Pet = Unit.Pet
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local pairs = pairs
-- File Locals


--- ============================ CONTENT ============================
-- Nameplate Updated
do
  local NameplateUnits = Unit.Nameplate
  -- Name Plate Added
  HL:RegisterForEvent(function(Event, UnitId) NameplateUnits[UnitId]:Cache() end, "NAME_PLATE_UNIT_ADDED")
  -- Name Plate Removed
  HL:RegisterForEvent(function(Event, UnitId) NameplateUnits[UnitId]:Init() end, "NAME_PLATE_UNIT_REMOVED")
end

-- Player Target Updated
HL:RegisterForEvent(function() Target:Cache() end, "PLAYER_TARGET_CHANGED")

-- Player Focus Target Updated
do
  local Focus = Unit.Focus
  HL:RegisterForEvent(function() Focus:Cache() end, "PLAYER_FOCUS_CHANGED")
end

-- Arena Unit Updated
do
  local ArenaUnits = Unit.Arena
  HL:RegisterForEvent(function(Event, UnitId)
    local ArenaUnit = ArenaUnits[UnitId]
    if ArenaUnit then ArenaUnit:Cache() end
  end, "ARENA_OPPONENT_UPDATE")
end

-- Boss Unit Updated
do
  local BossUnits = Unit.Boss
  HL:RegisterForEvent(function()
    for _, BossUnit in pairs(BossUnits) do BossUnit:Cache() end
  end, "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
end

-- Party/Raid Unit Updated
do
  HL:RegisterForEvent(function()
    for _, PartyUnit in pairs(Unit.Party) do PartyUnit:Cache() end
    for _, RaidUnit in pairs(Unit.Raid) do RaidUnit:Cache() end
  end, "GROUP_ROSTER_UPDATE")
  -- TODO: Need to maybe also update friendly units with:
  -- PARTY_MEMBER_ENABLE
  -- PARTY_MEMBER_DISABLE
end

-- General Unit Target Updated
-- Not really sure we need this event... haven't actually seen it fire yet. But just in case...
do
  local Focus = Unit.Focus
  local BossUnits, PartyUnits, RaidUnits, NameplateUnits = Unit.Boss, Unit.Party, Unit.Raid, Unit.Nameplate
  HL:RegisterForEvent(function(Event, UnitId)
    if UnitId == Target:ID() then
      Target:Cache()
    elseif UnitId == Focus:ID() then
      Focus:Cache()
    else
      local FoundUnit = PartyUnits[UnitId] or RaidUnits[UnitId] or BossUnits[UnitId] or NameplateUnits[UnitId]
      if FoundUnit then FoundUnit:Cache() end
    end
  end, "UNIT_TARGETABLE_CHANGED", "UNIT_FACTION")
end
