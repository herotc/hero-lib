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
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame = CreateFrame
local pairs = pairs
local select = select
local stringfind = string.find
local stringsub = string.sub
local tableinsert = table.insert
local tableremove = table.remove
-- File Locals
local EventFrame = CreateFrame("Frame", "HeroLib_EventFrame", UIParent)
local Handlers = {} -- All Events
local CombatHandlers = {} -- Combat Log Unfiltered
local SelfCombatHandlers = {} -- Combat Log Unfiltered with SourceGUID == PlayerGUID filter
local PetCombatHandlers = {} -- Combat Log Unfiltered with SourceGUID == PetGUID filter
local PrefixCombatHandlers = {}
local SuffixCombatHandlers = {}
local CombatPrefixes = {
  "ENVIRONMENTAL",
  "RANGE",
  "SPELL_BUILDING",
  "SPELL_PERIODIC",
  "SPELL",
  "SWING"
}
local CombatPrefixesCount = #CombatPrefixes


--- ============================ CONTENT ============================
--- ======= CORE FUNCTIONS =======
-- Register a handler for an event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not Handlers[Event] then
      Handlers[Event] = { Handler }
      EventFrame:RegisterEvent(Event)
    else
      tableinsert(Handlers[Event], Handler)
    end
  end
end

-- Unregister a handler from an event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForEvent(Handler, Event)
  if Handlers[Event] then
    for Index, Function in pairs(Handlers[Event]) do
      if Function == Handler then
        tableremove(Handlers[Event], Index)
        if #Handlers[Event] == 0 then
          EventFrame:UnregisterEvent(Event)
        end
        return
      end
    end
  end
end

-- OnEvent Frame Listener
EventFrame:SetScript("OnEvent",
  function(self, Event, ...)
    for _, Handler in pairs(Handlers[Event]) do
      Handler(Event, ...)
    end
  end
)

-- Register a handler for a combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForCombatEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not CombatHandlers[Event] then
      CombatHandlers[Event] = { Handler }
    else
      tableinsert(CombatHandlers[Event], Handler)
    end
  end
end

-- Register a handler for a self combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForSelfCombatEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not SelfCombatHandlers[Event] then
      SelfCombatHandlers[Event] = { Handler }
    else
      tableinsert(SelfCombatHandlers[Event], Handler)
    end
  end
end

-- Register a handler for a pet combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForPetCombatEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not PetCombatHandlers[Event] then
      PetCombatHandlers[Event] = { Handler }
    else
      tableinsert(PetCombatHandlers[Event], Handler)
    end
  end
end

-- Register a handler for a combat event prefix.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForCombatPrefixEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not PrefixCombatHandlers[Event] then
      PrefixCombatHandlers[Event] = { Handler }
    else
      tableinsert(PrefixCombatHandlers[Event], Handler)
    end
  end
end

-- Register a handler for a combat event suffix.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForCombatSuffixEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not SuffixCombatHandlers[Event] then
      SuffixCombatHandlers[Event] = { Handler }
    else
      tableinsert(SuffixCombatHandlers[Event], Handler)
    end
  end
end

-- Unregister a handler from a combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForCombatEvent(Handler, Event)
  if CombatHandlers[Event] then
    for Index, Function in pairs(CombatHandlers[Event]) do
      if Function == Handler then
        tableremove(CombatHandlers[Event], Index)
        return
      end
    end
  end
end

-- Unregister a handler from a self combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForSelfCombatEvent(Handler, Event)
  if SelfCombatHandlers[Event] then
    for Index, Function in pairs(SelfCombatHandlers[Event]) do
      if Function == Handler then
        tableremove(SelfCombatHandlers[Event], Index)
        return
      end
    end
  end
end

-- Unregister a handler from a pet combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForPetCombatEvent(Handler, Event)
  if PetCombatHandlers[Event] then
    for Index, Function in pairs(PetCombatHandlers[Event]) do
      if Function == Handler then
        tableremove(PetCombatHandlers[Event], Index)
        return
      end
    end
  end
end

-- Unregister a handler from a combat event prefix.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForCombatPrefixEvent(Handler, Event)
  if PrefixCombatHandlers[Event] then
    for Index, Function in pairs(PrefixCombatHandlers[Event]) do
      if Function == Handler then
        tableremove(PrefixCombatHandlers, Index)
        return
      end
    end
  end
end

-- Unregister a handler from a combat event suffix.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForCombatSuffixEvent(Handler, Event)
  if SuffixCombatHandlers[Event] then
    for Index, Function in pairs(SuffixCombatHandlers[Event]) do
      if Function == Handler then
        tableremove(SuffixCombatHandlers[Event], Index)
        return
      end
    end
  end
end

-- Combat Log Event Unfiltered Listener
local function ListenerCombatLogEventUnfiltered(Event, TimeStamp, SubEvent, ...)
  if CombatHandlers[SubEvent] then
    -- Unfiltered Combat Log
    for _, Handler in pairs(CombatHandlers[SubEvent]) do
      Handler(TimeStamp, SubEvent, ...)
    end
  end
  if SelfCombatHandlers[SubEvent] then
    -- Unfiltered Combat Log with SourceGUID == PlayerGUID filter
    if select(2, ...) == Player:GUID() then
      for _, Handler in pairs(SelfCombatHandlers[SubEvent]) do
        Handler(TimeStamp, SubEvent, ...)
      end
    end
  end
  if PetCombatHandlers[SubEvent] then
    -- Unfiltered Combat Log with SourceGUID == PetGUID filter
    if select(2, ...) == Pet:GUID() then
      for _, Handler in pairs(PetCombatHandlers[SubEvent]) do
        Handler(TimeStamp, SubEvent, ...)
      end
    end
  end
  for i = 1, CombatPrefixesCount do
    -- TODO : Optimize the str find
    if SubEvent then
      local Start, End = stringfind(SubEvent, CombatPrefixes[i])
      if Start and End then
        -- TODO: Optimize the double str sub
        local Prefix, Suffix = stringsub(SubEvent, Start, End), stringsub(SubEvent, End + 1)
        if PrefixCombatHandlers[Prefix] then
          -- Unfiltered Combat Log with Prefix only
          for _, Handler in pairs(PrefixCombatHandlers[Prefix]) do
            Handler(TimeStamp, SubEvent, ...)
          end
        end
        if SuffixCombatHandlers[Suffix] then
          -- Unfiltered Combat Log with Suffix only
          for _, Handler in pairs(SuffixCombatHandlers[Suffix]) do
            Handler(TimeStamp, SubEvent, ...)
          end
        end
      end
    end
  end
end
HL:RegisterForEvent(function(Event)
  ListenerCombatLogEventUnfiltered(Event, CombatLogGetCurrentEventInfo())
end, "COMBAT_LOG_EVENT_UNFILTERED")

--- ======= COMBATLOG =======
--- Combat Log Arguments
------- Base -------
-- 1          2      3           4           5           6            7                8         9         10         11
-- TimeStamp, Event, HideCaster, SourceGUID, SourceName, SourceFlags, SourceRaidFlags, DestGUID, DestName, DestFlags, DestRaidFlags

------- Prefixes -------
--- SWING
-- N/A

--- SPELL & SPELL_PERIODIC
-- 12        13          14
-- SpellID, SpellName, SpellSchool

--- SPELL_ABSORBED* - When absorbed damage originated from a spell, will have additional 3 columns with spell info.
-- 12                13                14                 15                     16       17         18           19
-- AbsorbSourceGUID, AbsorbSourceName, AbsorbSourceFlags, AbsorbSourceRaidFlags, SpellID, SpellName, SpellSchool, Amount

--- SPELL_ABSORBED
-- 12             13               14                 15                16                17                 18                     19       20         21           22
-- AbsorbSpellId, AbsorbSpellName, AbsorbSpellSchool, AbsorbSourceGUID, AbsorbSourceName, AbsorbSourceFlags, AbsorbSourceRaidFlags, SpellID, SpellName, SpellSchool, Amount

------- Suffixes -------
--- _CAST_START & _CAST_SUCCESS & _SUMMON & _RESURRECT
-- N/A

--- _CAST_FAILED
-- 15
-- FailedType

--- _AURA_APPLIED & _AURA_REMOVED & _AURA_REFRESH
-- 15
-- AuraType

--- _AURA_APPLIED_DOSE
-- 15        16
-- AuraType, Charges

--- _INTERRUPT
-- 15            16              17
-- ExtraSpellID, ExtraSpellName, ExtraSchool

--- _HEAL
-- 15      16           17        18
-- Amount, Overhealing, Absorbed, Critical

--- _DAMAGE
-- 15      16        17      18        19       20        21        22        23
-- Amount, Overkill, School, Resisted, Blocked, Absorbed, Critical, Glancing, Crushing

--- _MISSED
-- 15        16         17
-- MissType, IsOffHand, AmountMissed

------- Special -------
--- UNIT_DIED, UNIT_DESTROYED
-- N/A

--- End Combat Log Arguments

-- Arguments Variables

