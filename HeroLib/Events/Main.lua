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
local select = select
local stringsub = string.sub
local stringfind = string.find
local tableinsert = table.insert
local tableremove = table.remove
local tonumber = tonumber
local wipe = table.wipe
-- File Locals
local EventFrame = CreateFrame("Frame", "HeroLib_EventFrame", UIParent)
local Events = {} -- All Events
local CombatEvents = {} -- Combat Log Unfiltered
local SelfCombatEvents = {} -- Combat Log Unfiltered with SourceGUID == PlayerGUID filter
local PetCombatEvents = {} -- Combat Log Unfiltered with SourceGUID == PetGUID filter
local PrefixCombatEvents = {}
local SuffixCombatEvents = {}
local CombatLogPrefixes = {
  "ENVIRONMENTAL",
  "RANGE",
  "SPELL_BUILDING",
  "SPELL_PERIODIC",
  "SPELL",
  "SWING"
}
local CombatLogPrefixesCount = #CombatLogPrefixes
local restoreDB = {}
local overrideDB = {}


--- ============================ CONTENT ============================
--- ======= CORE FUNCTIONS =======
-- Register a handler for an event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not Events[Event] then
      Events[Event] = { Handler }
      EventFrame:RegisterEvent(Event)
    else
      tableinsert(Events[Event], Handler)
    end
  end
end

-- Register a handler for a combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:RegisterForCombatEvent(Handler, ...)
  local EventsTable = { ... }
  for i = 1, #EventsTable do
    local Event = EventsTable[i]
    if not CombatEvents[Event] then
      CombatEvents[Event] = { Handler }
    else
      tableinsert(CombatEvents[Event], Handler)
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
    if not SelfCombatEvents[Event] then
      SelfCombatEvents[Event] = { Handler }
    else
      tableinsert(SelfCombatEvents[Event], Handler)
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
    if not PetCombatEvents[Event] then
      PetCombatEvents[Event] = { Handler }
    else
      tableinsert(PetCombatEvents[Event], Handler)
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
    if not PrefixCombatEvents[Event] then
      PrefixCombatEvents[Event] = { Handler }
    else
      tableinsert(PrefixCombatEvents[Event], Handler)
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
    if not SuffixCombatEvents[Event] then
      SuffixCombatEvents[Event] = { Handler }
    else
      tableinsert(SuffixCombatEvents[Event], Handler)
    end
  end
end

-- Unregister a handler from an event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForEvent(Handler, Event)
  if Events[Event] then
    for Index, Function in pairs(Events[Event]) do
      if Function == Handler then
        tableremove(Events[Event], Index)
        if #Events[Event] == 0 then
          EventFrame:UnregisterEvent(Event)
        end
        return
      end
    end
  end
end

-- Unregister a handler from a combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForCombatEvent(Handler, Event)
  if CombatEvents[Event] then
    for Index, Function in pairs(CombatEvents[Event]) do
      if Function == Handler then
        tableremove(CombatEvents[Event], Index)
        return
      end
    end
  end
end

-- Unregister a handler from a self combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForSelfCombatEvent(Handler, Event)
  if SelfCombatEvents[Event] then
    for Index, Function in pairs(SelfCombatEvents[Event]) do
      if Function == Handler then
        tableremove(SelfCombatEvents[Event], Index)
        return
      end
    end
  end
end

-- Unregister a handler from a pet combat event.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForPetCombatEvent(Handler, Event)
  if PetCombatEvents[Event] then
    for Index, Function in pairs(PetCombatEvents[Event]) do
      if Function == Handler then
        tableremove(PetCombatEvents[Event], Index)
        return
      end
    end
  end
end

-- Unregister a handler from a combat event prefix.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForCombatPrefixEvent(Handler, Event)
  if PrefixCombatEvents[Event] then
    for Index, Function in pairs(PrefixCombatEvents[Event]) do
      if Function == Handler then
        tableremove(PrefixCombatEvents, Index)
        return
      end
    end
  end
end

-- Unregister a handler from a combat event suffix.
-- @param Handler The handler function.
-- @param Events The events name.
function HL:UnregisterForCombatSuffixEvent(Handler, Event)
  if SuffixCombatEvents[Event] then
    for Index, Function in pairs(SuffixCombatEvents[Event]) do
      if Function == Handler then
        tableremove(SuffixCombatEvents[Event], Index)
        return
      end
    end
  end
end

-- OnEvent Frame Listener
EventFrame:SetScript("OnEvent",
  function(self, Event, ...)
    for _, Handler in pairs(Events[Event]) do
      Handler(Event, ...)
    end
  end)

-- Combat Log Event Unfiltered Listener
local function ListenerCombatLogEventUnfiltered(Event, TimeStamp, SubEvent, ...)
  if CombatEvents[SubEvent] then
    -- Unfiltered Combat Log
    for _, Handler in pairs(CombatEvents[SubEvent]) do
      Handler(TimeStamp, SubEvent, ...)
    end
  end
  if SelfCombatEvents[SubEvent] then
    -- Unfiltered Combat Log with SourceGUID == PlayerGUID filter
    if select(2, ...) == Player:GUID() then
      for _, Handler in pairs(SelfCombatEvents[SubEvent]) do
        Handler(TimeStamp, SubEvent, ...)
      end
    end
  end
  if PetCombatEvents[SubEvent] then
    -- Unfiltered Combat Log with SourceGUID == PetGUID filter
    if select(2, ...) == Pet:GUID() then
      for _, Handler in pairs(SelfCombatEvents[SubEvent]) do
        Handler(TimeStamp, SubEvent, ...)
      end
    end
  end
  for i = 1, CombatLogPrefixesCount do
    -- TODO : Optimize the str find
    if SubEvent then
      local Start, End = stringfind(SubEvent, CombatLogPrefixes[i])
      if Start and End then
        -- TODO: Optimize the double str sub
        local Prefix, Suffix = stringsub(SubEvent, Start, End), stringsub(SubEvent, End + 1)
        if PrefixCombatEvents[Prefix] then
          -- Unfiltered Combat Log with Prefix only
          for _, Handler in pairs(PrefixCombatEvents[Prefix]) do
            Handler(TimeStamp, SubEvent, ...)
          end
        end
        if SuffixCombatEvents[Suffix] then
          -- Unfiltered Combat Log with Suffix only
          for _, Handler in pairs(SuffixCombatEvents[Suffix]) do
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

-- Core Override System
function HL.AddCoreOverride(target, newfunction, specKey)
  local loadOverrideFunc = assert(loadstring([[
      return function (func)
      ]] .. target .. [[ = func
      end, ]] .. target .. [[
      ]]))
  setfenv(loadOverrideFunc, { HL = HL, Player = Player, Spell = Spell, Item = Item, Target = Target, Unit = Unit, Pet = Pet })
  local overrideFunc, oldfunction = loadOverrideFunc()
  if overrideDB[specKey] == nil then
    overrideDB[specKey] = {}
  end
  tableinsert(overrideDB[specKey], { overrideFunc, newfunction })
  tableinsert(restoreDB, { overrideFunc, oldfunction })
  return oldfunction
end

function HL.LoadRestores()
  for k, v in pairs(restoreDB) do
    v[1](v[2])
  end
end

function HL.LoadOverrides(specKey)
  if type(overrideDB[specKey]) == "table" then
    for k, v in pairs(overrideDB[specKey]) do
      v[1](v[2])
    end
  end
end

--- ======= NON-COMBATLOG =======
-- PLAYER_REGEN_DISABLED
HL.CombatStarted = 0
HL.CombatEnded = 1
-- Entering Combat
HL:RegisterForEvent(function()
  HL.CombatStarted = HL.GetTime()
  HL.CombatEnded = 0
end, "PLAYER_REGEN_DISABLED")

-- PLAYER_REGEN_ENABLED
-- Leaving Combat
HL:RegisterForEvent(function()
  HL.CombatStarted = 0
  HL.CombatEnded = HL.GetTime()
end, "PLAYER_REGEN_ENABLED")

-- CHAT_MSG_ADDON
-- DBM/BW Pull Timer
HL:RegisterForEvent(function(Event, Prefix, Message)
  if Prefix == "D4" and stringfind(Message, "PT") then
    HL.BossModTime = tonumber(stringsub(Message, 4, 5))
    HL.BossModEndTime = HL.GetTime() + HL.BossModTime
  elseif Prefix == "BigWigs" and string.find(Message, "Pull") then
    HL.BossModTime = tonumber(stringsub(Message, 8, 9))
    HL.BossModEndTime = HL.GetTime() + HL.BossModTime
  end
end, "CHAT_MSG_ADDON")

-- OnSpecGearTalentUpdate
-- Player Inspector
-- TODO : Split based on events
HL:RegisterForEvent(function(Event, Arg1)
  -- Prevent execute if not initiated by the player
  if Event == "PLAYER_SPECIALIZATION_CHANGED" and Arg1 ~= "player" then
    return
  end

  -- Refresh Player
  --local PrevSpec = Cache.Persistent.Player.Spec[1]
  Cache.Persistent.Player.Class = { UnitClass("player") }
  Cache.Persistent.Player.Spec = { GetSpecializationInfo(GetSpecialization()) }

  -- Wipe the texture from Persistent Cache
  wipe(Cache.Persistent.Texture.Spell)
  wipe(Cache.Persistent.Texture.Item)

  -- Refresh Gear
  if Event == "PLAYER_EQUIPMENT_CHANGED"
    or Event == "PLAYER_LOGIN" then
    HL.GetEquipment()

    -- WoD (They are working but not used, so I'll comment them)
    --HL.Tier18_2Pc, HL.Tier18_4Pc = HL.HasTier("T18")
    --HL.Tier18_ClassTrinket = HL.HasTier("T18_ClassTrinket")
    -- Legion
    HL.Tier19_2Pc, HL.Tier19_4Pc = HL.HasTier("T19")
    HL.Tier20_2Pc, HL.Tier20_4Pc = HL.HasTier("T20")
    HL.Tier21_2Pc, HL.Tier21_4Pc = HL.HasTier("T21")
  end

  -- Refresh Artifact
  --if Event == "PLAYER_LOGIN"
  --  or (Event == "PLAYER_EQUIPMENT_CHANGED" and Arg1 == 16)
  --  or PrevSpec ~= Cache.Persistent.Player.Spec[1] then
  --  Spell:ArtifactScan()
  --end

  -- Load / Refresh Core Overrides
  if Event == "PLAYER_LOGIN" then
    -- TODO: fix timing issue via event?
    C_Timer.After(3, function()
      HL.LoadOverrides(Cache.Persistent.Player.Spec[1])
    end)
    Player:Cache()
  elseif Event == "PLAYER_SPECIALIZATION_CHANGED" then
    HL.LoadRestores()
    HL.LoadOverrides(Cache.Persistent.Player.Spec[1])
  end
end, "ZONE_CHANGED_NEW_AREA", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LOGIN")

-- Spell Book Scanner
-- Checks the same event as Blizzard Spell Book, from SpellBookFrame_OnLoad in SpellBookFrame.lua
HL:RegisterForEvent(function(Event, Arg1)
  -- Prevent execute if not initiated by the player
  if Event == "PLAYER_SPECIALIZATION_CHANGED" and Arg1 ~= "player" then
    return
  end

  -- TODO: FIXME workaround to prevent Lua errors when Blizz do some shenanigans with book in Arena/Timewalking
  if pcall(function()
    Spell.BookScan(true)
  end) then
    wipe(Cache.Persistent.SpellLearned.Player)
    wipe(Cache.Persistent.SpellLearned.Pet)
    Spell:BookScan()
  end
end, "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "SKILL_LINES_CHANGED", "PLAYER_GUILD_UPDATE", "PLAYER_SPECIALIZATION_CHANGED", "USE_GLYPH", "CANCEL_GLYPH_CAST", "ACTIVATE_GLYPH")

-- Not Facing Unit Blacklist
HL.UnitNotInFront = Player
HL.UnitNotInFrontTime = 0
HL.LastUnitCycled = Player
HL.LastUnitCycledTime = 0
HL:RegisterForEvent(function(Event, MessageType, Message)
  if MessageType == 50 and Message == SPELL_FAILED_UNIT_NOT_INFRONT then
    HL.UnitNotInFront = HL.LastUnitCycled
    HL.UnitNotInFrontTime = HL.LastUnitCycledTime
  end
end, "UI_ERROR_MESSAGE")

--- ========================= UNIT UPDATE FUNCTIONS ============================

-- Nameplate Updated
do
  local NameplateUnits = Unit["Nameplate"]
  -- Name Plate Added
  HL:RegisterForEvent(function(Event, UnitId)
    NameplateUnits[UnitId]:Cache()
  end, "NAME_PLATE_UNIT_ADDED")

  -- Name Plate Removed
  HL:RegisterForEvent(function(Event, UnitId)
    NameplateUnits[UnitId]:Init()
  end, "NAME_PLATE_UNIT_REMOVED")
end

-- Player Target Updated
HL:RegisterForEvent(function()
  Target:Cache()
end, "PLAYER_TARGET_CHANGED")

-- Player Focus Target Updated
do
  local Focus = Unit.Focus
  HL:RegisterForEvent(function()
    Focus:Cache()
  end, "PLAYER_FOCUS_CHANGED")
end

-- Player Mouseover Updated
do
  local MouseOver = Unit.MouseOver
  HL:RegisterForEvent(function(Event)
    if Event == "UPDATE_MOUSEOVER_UNIT" then
      MouseOver:Cache()
    elseif MouseOver:GUID() then
      MouseOver:Init()
    end
  end, "UPDATE_MOUSEOVER_UNIT", "CURSOR_UPDATE")
end

-- Arena Unit Updated
do
  local ArenaUnits = Unit["Arena"]
  HL:RegisterForEvent(function(Event, UnitId)
    local ArenaUnit = ArenaUnits[UnitId]
    if ArenaUnit then
      ArenaUnit:Cache()
    end
  end, "ARENA_OPPONENT_UPDATE")
end

-- Boss Unit Updated
do
  local BossUnits = Unit["Boss"]
  HL:RegisterForEvent(function()
    for _, BossUnit in pairs(BossUnits) do
      BossUnit:Cache()
    end
  end, "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
end

-- Party/Raid Unit Updated
do
  local PartyUnits = Unit["Party"]
  local RaidUnits = Unit["Raid"]
  HL:RegisterForEvent(function()
    for _, PartyUnit in pairs(PartyUnits) do
      PartyUnit:Cache()
    end
    for _, RaidUnit in pairs(RaidUnits) do
      RaidUnit:Cache()
    end
  end, "GROUP_ROSTER_UPDATE")
  -- TODO: Need to maybe also update friendly units with:
  -- PARTY_MEMBER_ENABLE
  -- PARTY_MEMBER_DISABLE
end

-- General Unit Target Updated
-- Not really sure we need this event... haven't actually seen it fire yet. But just in case...
do
  local Focus = Unit.Focus
  local BossUnits, PartyUnits, RaidUnits, NameplateUnits = Unit["Boss"], Unit["Party"], Unit["Raid"], Unit["Nameplate"]
  HL:RegisterForEvent(function(Event, UnitId)
    if UnitId == Target:ID() then
      Target:Cache()
      --HL.Print("Unit " .. UnitId .. " Updated, Exists: " .. Target.UnitExists )
    elseif UnitId == Focus:ID() then
      Focus:Cache()
      --HL.Print("Unit " .. UnitId .. " Updated, Exists: " .. Focus.UnitExists )
    else
      local FoundUnit = BossUnits[UnitId] or PartyUnits[UnitId] or RaidUnits[UnitId] or NameplateUnits[UnitId]
      if FoundUnit then
        FoundUnit:Cache()
        --HL.Print("Unit " .. UnitId .. " Updated, Exists: " .. (FoundUnit.UnitExists and "true" or "false") )
      else
        --HL.Print("Unit " .. UnitId .. " ???")
      end
    end
  end, "UNIT_TARGETABLE_CHANGED")
end

--- ======= COMBATLOG =======
--- Combat Log Arguments
------- Base -------
-- 1        2         3           4           5           6              7             8         9        10           11
-- TimeStamp, Event, HideCaster, SourceGUID, SourceName, SourceFlags, SourceRaidFlags, DestGUID, DestName, DestFlags, DestRaidFlags

------- Prefixes -------
--- SWING
-- N/A

--- SPELL & SPELL_PACIODIC
-- 12        13          14
-- SpellID, SpellName, SpellSchool

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
-- 15       16
-- AuraType, Charges

--- _INTERRUPT
-- 15            16             17
-- ExtraSpellID, ExtraSpellName, ExtraSchool

--- _HEAL
-- 15         16         17        18
-- Amount, Overhealing, Absorbed, Critical

--- _DAMAGE
-- 15       16       17       18        19       20        21        22        23
-- Amount, Overkill, School, Resisted, Blocked, Absorbed, Critical, Glancing, Crushing

--- _MISSED
-- 15        16           17
-- MissType, IsOffHand, AmountMissed

------- Special -------
--- UNIT_DIED, UNIT_DESTROYED
-- N/A

--- End Combat Log Arguments

-- Arguments Variables

