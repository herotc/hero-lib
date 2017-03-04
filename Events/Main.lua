--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCore_Cache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local pairs = pairs;
  local select = select;
  local stringsub = string.sub;
  local stringfind = string.find;
  local tableinsert = table.insert;
  local tableremove = table.remove;
  local tonumber = tonumber;
  local wipe = table.wipe;
  -- File Locals
  AC.EventFrame = CreateFrame("Frame", "AethysCore_EventFrame", UIParent);
  AC.Events = {}; -- All Events
  AC.CombatEvents = {}; -- Combat Log Unfiltered
  AC.SelfCombatEvents = {}; -- Combat Log Unfiltered with SourceGUID == PlayerGUID filter


--- ============================ CONTENT ============================
--- ======= CORE FUNCTIONS =======
  -- Register a handler for an event.
  -- @param Event The event name.
  -- @param Handler The handler function.
  function AC:RegisterForEvent (Handler, ...)
    local EventsTable = {...};
    local Event;
    for i = 1, #EventsTable do
      Event = EventsTable[i];
      if not AC.Events[Event] then
        AC.Events[Event] = {Handler};
        AC.EventFrame:RegisterEvent(Event);
      else
        tableinsert(AC.Events[Event], Handler);
      end
    end
  end

  -- Register a handler for a combat event.
  -- @param Event The combat event name.
  -- @param Handler The handler function.
  function AC:RegisterForCombatEvent (Handler, ...)
    local EventsTable = {...};
    local Event;
    for i = 1, #EventsTable do
      Event = EventsTable[i];
      if not AC.CombatEvents[Event] then
        AC.CombatEvents[Event] = {Handler};
      else
        tableinsert(AC.CombatEvents[Event], Handler);
      end
    end
  end

  -- Register a handler for a self combat event.
  -- @param Event The combat event name.
  -- @param Handler The handler function.
  function AC:RegisterForSelfCombatEvent (Handler, ...)
    local EventsTable = {...};
    local Event;
    for i = 1, #EventsTable do
      Event = EventsTable[i];
      if not AC.SelfCombatEvents[Event] then
        AC.SelfCombatEvents[Event] = {Handler};
      else
        tableinsert(AC.SelfCombatEvents[Event], Handler);
      end
    end
  end

  -- Unregister a handler from an event.
  -- @param Event The event name.
  -- @param Handler The handler function.
  function AC:UnregisterForEvent (Handler, Event)
    if AC.Events[Event] then
      for Index, Function in pairs(AC.Events[Event]) do
        if Function == Handler then
          tableremove(AC.Events[Event], Index);
          if #AC.Events[Event] == 0 then
            AC.EventFrame:UnregisterEvent(Event);
          end
          return;
        end
      end
    end
  end

  -- Unregister a handler from a combat event.
  -- @param Event The combat event name.
  -- @param Handler The handler function.
  function AC:UnregisterForCombatEvent (Handler, Event)
    if AC.CombatEvents[Event] then
      for Index, Function in pairs(AC.CombatEvents[Event]) do
        if Function == Handler then
          tableremove(AC.CombatEvents[Event], Index);
          return;
        end
      end
    end
  end

  -- Unregister a handler from a combat event.
  -- @param Event The combat event name.
  -- @param Handler The handler function.
  function AC:UnregisterForSelfCombatEvent (Handler, Event)
    if AC.SelfCombatEvents[Event] then
      for Index, Function in pairs(AC.SelfCombatEvents[Event]) do
        if Function == Handler then
          tableremove(AC.SelfCombatEvents[Event], Index);
          return;
        end
      end
    end
  end

  -- OnEvent Frame Listener
  AC.EventFrame:SetScript("OnEvent", 
    function (self, Event, ...)
      for Index, Handler in pairs(AC.Events[Event]) do
        Handler(Event, ...);
      end
    end
  );

  -- Combat Log Event Unfiltered Listener
  AC:RegisterForEvent(
    function (Event, TimeStamp, SubEvent, ...)
      if AC.CombatEvents[SubEvent] then
        -- Unfiltered Combat Log
        for Index, Handler in pairs(AC.CombatEvents[SubEvent]) do
          Handler(TimeStamp, SubEvent, ...);
        end
      end
      if AC.SelfCombatEvents[SubEvent] then
        -- Unfiltered Combat Log with SourceGUID == PlayerGUID filter
        if select(2, ...) == Player:GUID() then
          for Index, Handler in pairs(AC.SelfCombatEvents[SubEvent]) do
            Handler(TimeStamp, SubEvent, ...);
          end
        end
      end
    end
    , "COMBAT_LOG_EVENT_UNFILTERED"
  );


--- ======= NON-COMBATLOG =======
  -- PLAYER_REGEN_DISABLED
    AC.CombatStarted = 0;
    AC.CombatEnded = 1;
    -- Entering Combat
    AC:RegisterForEvent(
      function ()
        AC.CombatStarted = AC.GetTime();
        AC.CombatEnded = 0;
      end
      , "PLAYER_REGEN_DISABLED"
    );

  -- PLAYER_REGEN_ENABLED
    -- Leaving Combat
    AC:RegisterForEvent(
      function ()
        AC.CombatStarted = 0;
        AC.CombatEnded = AC.GetTime();
      end
      , "PLAYER_REGEN_ENABLED"
    );

  -- CHAT_MSG_ADDON
    -- DBM/BW Pull Timer
    AC:RegisterForEvent(
      function (Event, Prefix, Message)
        if Prefix == "D4" and stringfind(Message, "PT") then
          AC.BossModTime = tonumber(stringsub(Message, 4, 5));
          AC.BossModEndTime = AC.GetTime() + AC.BossModTime;
        end
      end
      , "CHAT_MSG_ADDON"
    );

  -- OnSpecGearTalentUpdate
    -- Player Inspector
    -- TODO : Split based on events
    AC:RegisterForEvent(
      function ()
        -- Refresh Player
          Cache.Persistent.Player.Class = {UnitClass("player")};
          Cache.Persistent.Player.Spec = {GetSpecializationInfo(GetSpecialization())};

        -- Wipe the texture from Persistent Cache
          wipe(Cache.Persistent.Texture.Spell);
          wipe(Cache.Persistent.Texture.Item);

        -- Refresh Gear
          AC.GetEquipment();
        -- WoD (They are working but not used, so I'll comment them)
          --AC.Tier18_2Pc, AC.Tier18_4Pc = AC.HasTier("T18");
          --AC.Tier18_ClassTrinket = AC.HasTier("T18_ClassTrinket");
        -- Legion
          Spell:ArtifactScan();
          AC.Tier19_2Pc, AC.Tier19_4Pc = AC.HasTier("T19");
          AC.Tier20_2Pc, AC.Tier20_4Pc = AC.HasTier("T20");
      end
      , "ZONE_CHANGED_NEW_AREA"
      , "PLAYER_SPECIALIZATION_CHANGED"
      , "PLAYER_TALENT_UPDATE"
      , "PLAYER_EQUIPMENT_CHANGED"
    );

  -- Spell Book Scanner
    -- Checks the same event as Blizzard Spell Book, from SpellBookFrame_OnLoad in SpellBookFrame.lua
    AC:RegisterForEvent(
      function ()
        wipe(Cache.Persistent.SpellLearned.Player);
        wipe(Cache.Persistent.SpellLearned.Pet);
        Spell:BookScan();
      end
      , "SPELLS_CHANGED"
      , "LEARNED_SPELL_IN_TAB"
      , "SKILL_LINES_CHANGED"
      , "PLAYER_GUILD_UPDATE"
      , "PLAYER_SPECIALIZATION_CHANGED"
      , "USE_GLYPH"
      , "CANCEL_GLYPH_CAST"
      , "ACTIVATE_GLYPH"
    );
  
  -- Not Facing Unit Blacklist
    AC.UnitNotInFront = Player;
    AC.UnitNotInFrontTime = 0;
    AC.LastUnitCycled = Player;
    AC.LastUnitCycledTime = 0;
    AC:RegisterForEvent(
      function (Event, MessageType, Message)
        if MessageType == 50 and Message == SPELL_FAILED_UNIT_NOT_INFRONT then
          AC.UnitNotInFront = AC.LastUnitCycled;
          AC.UnitNotInFrontTime = AC.LastUnitCycledTime;
        end
      end
      , "UI_ERROR_MESSAGE"
    );


--- ======= COMBATLOG =======
  --- Combat Log Arguments
    ------- Base -------
      --     1        2         3           4           5           6              7             8         9        10           11
      -- TimeStamp, Event, HideCaster, SourceGUID, SourceName, SourceFlags, SourceRaidFlags, DestGUID, DestName, DestFlags, DestRaidFlags

    ------- Prefixes -------
      --- SWING
      -- N/A

      --- SPELL & SPELL_PACIODIC
      --    12        13          14
      -- SpellID, SpellName, SpellSchool

    ------- Suffixes -------
      --- _CAST_START & _CAST_SUCCESS & _SUMMON & _RESURRECT
      -- N/A

      --- _CAST_FAILED
      --     15
      -- FailedType

      --- _AURA_APPLIED & _AURA_REMOVED & _AURA_REFRESH
      --    15
      -- AuraType

      --- _AURA_APPLIED_DOSE
      --    15       16
      -- AuraType, Charges

      --- _INTERRUPT
      --      15            16             17
      -- ExtraSpellID, ExtraSpellName, ExtraSchool

      --- _HEAL
      --   15         16         17        18
      -- Amount, Overhealing, Absorbed, Critical

      --- _DAMAGE
      --   15       16       17       18        19       20        21        22        23
      -- Amount, Overkill, School, Resisted, Blocked, Absorbed, Critical, Glancing, Crushing

      --- _MISSED
      --    15        16           17
      -- MissType, IsOffHand, AmountMissed

    ------- Special -------
      --- UNIT_DIED, UNIT_DESTROYED
      -- N/A

  --- End Combat Log Arguments

  -- Arguments Variables
  
