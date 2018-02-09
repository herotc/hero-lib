--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Pet = Unit.Pet;
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
  local EventFrame = CreateFrame("Frame", "AethysCore_EventFrame", UIParent);
  local Events = {}; -- All Events
  local CombatEvents = {}; -- Combat Log Unfiltered
  local SelfCombatEvents = {}; -- Combat Log Unfiltered with SourceGUID == PlayerGUID filter
  local PetCombatEvents = {};  -- Combat Log Unfiltered with SourceGUID == PetGUID filter
  local PrefixCombatEvents = {};
  local SuffixCombatEvents = {};
  local CombatLogPrefixes = {
    "ENVIRONMENTAL",
    "RANGE",
    "SPELL_BUILDING",
    "SPELL_PERIODIC",
    "SPELL",
    "SWING"
  };
  local CombatLogPrefixesCount = #CombatLogPrefixes;
  local restoreDB = {};
  local overrideDB = {};


--- ============================ CONTENT ============================
--- ======= CORE FUNCTIONS =======
  -- Register a handler for an event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:RegisterForEvent (Handler, ...)
    local EventsTable = {...};
    for i = 1, #EventsTable do
      local Event = EventsTable[i];
      if not Events[Event] then
        Events[Event] = {Handler};
        EventFrame:RegisterEvent(Event);
      else
        tableinsert(Events[Event], Handler);
      end
    end
  end

  -- Register a handler for a combat event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:RegisterForCombatEvent (Handler, ...)
    local EventsTable = {...};
    for i = 1, #EventsTable do
      local Event = EventsTable[i];
      if not CombatEvents[Event] then
        CombatEvents[Event] = {Handler};
      else
        tableinsert(CombatEvents[Event], Handler);
      end
    end
  end

  -- Register a handler for a self combat event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:RegisterForSelfCombatEvent (Handler, ...)
    local EventsTable = {...};
    for i = 1, #EventsTable do
      local Event = EventsTable[i];
      if not SelfCombatEvents[Event] then
        SelfCombatEvents[Event] = {Handler};
      else
        tableinsert(SelfCombatEvents[Event], Handler);
      end
    end
  end

  -- Register a handler for a pet combat event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:RegisterForPetCombatEvent (Handler, ...)
    local EventsTable = {...};
    for i = 1, #EventsTable do
      local Event = EventsTable[i];
      if not PetCombatEvents[Event] then
        PetCombatEvents[Event] = {Handler};
      else
        tableinsert(PetCombatEvents[Event], Handler);
      end
    end
  end

  -- Register a handler for a combat event prefix.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:RegisterForCombatPrefixEvent (Handler, ...)
    local EventsTable = {...};
    for i = 1, #EventsTable do
      local Event = EventsTable[i];
      if not PrefixCombatEvents[Event] then
        PrefixCombatEvents[Event] = {Handler};
      else
        tableinsert(PrefixCombatEvents[Event], Handler);
      end
    end
  end

  -- Register a handler for a combat event suffix.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:RegisterForCombatSuffixEvent (Handler, ...)
    local EventsTable = {...};
    for i = 1, #EventsTable do
      local Event = EventsTable[i];
      if not SuffixCombatEvents[Event] then
        SuffixCombatEvents[Event] = {Handler};
      else
        tableinsert(SuffixCombatEvents[Event], Handler);
      end
    end
  end

  -- Unregister a handler from an event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:UnregisterForEvent (Handler, Event)
    if Events[Event] then
      for Index, Function in pairs(Events[Event]) do
        if Function == Handler then
          tableremove(Events[Event], Index);
          if #Events[Event] == 0 then
            EventFrame:UnregisterEvent(Event);
          end
          return;
        end
      end
    end
  end

  -- Unregister a handler from a combat event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:UnregisterForCombatEvent (Handler, Event)
    if CombatEvents[Event] then
      for Index, Function in pairs(CombatEvents[Event]) do
        if Function == Handler then
          tableremove(CombatEvents[Event], Index);
          return;
        end
      end
    end
  end

  -- Unregister a handler from a self combat event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:UnregisterForSelfCombatEvent (Handler, Event)
    if SelfCombatEvents[Event] then
      for Index, Function in pairs(SelfCombatEvents[Event]) do
        if Function == Handler then
          tableremove(SelfCombatEvents[Event], Index);
          return;
        end
      end
    end
  end

  -- Unregister a handler from a pet combat event.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:UnregisterForPetCombatEvent (Handler, Event)
    if PetCombatEvents[Event] then
      for Index, Function in pairs(PetCombatEvents[Event]) do
        if Function == Handler then
          tableremove(PetCombatEvents[Event], Index);
          return;
        end
      end
    end
  end

  -- Unregister a handler from a combat event prefix.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:UnregisterForCombatPrefixEvent (Handler, Event)
    if PrefixCombatEvents[Event] then
      for Index, Function in pairs(PrefixCombatEvents[Event]) do
        if Function == Handler then
          tableremove(PrefixCombatEvents, Index);
          return;
        end
      end
    end
  end

  -- Unregister a handler from a combat event suffix.
  -- @param Handler The handler function.
  -- @param Events The events name.
  function AC:UnregisterForCombatSuffixEvent (Handler, Event)
    if SuffixCombatEvents[Event] then
      for Index, Function in pairs(SuffixCombatEvents[Event]) do
        if Function == Handler then
          tableremove(SuffixCombatEvents[Event], Index);
          return;
        end
      end
    end
  end

  -- OnEvent Frame Listener
  EventFrame:SetScript("OnEvent", 
    function (self, Event, ...)
      for _, Handler in pairs(Events[Event]) do
        Handler(Event, ...);
      end
    end
  );

  -- Combat Log Event Unfiltered Listener
  AC:RegisterForEvent(
    function (Event, TimeStamp, SubEvent, ...)
      if CombatEvents[SubEvent] then
        -- Unfiltered Combat Log
        for _, Handler in pairs(CombatEvents[SubEvent]) do
          Handler(TimeStamp, SubEvent, ...);
        end
      end
      if SelfCombatEvents[SubEvent] then
        -- Unfiltered Combat Log with SourceGUID == PlayerGUID filter
        if select(2, ...) == Player:GUID() then
          for _, Handler in pairs(SelfCombatEvents[SubEvent]) do
            Handler(TimeStamp, SubEvent, ...);
          end
        end
      end
      if PetCombatEvents[SubEvent] then
        -- Unfiltered Combat Log with SourceGUID == PetGUID filter
        if select(2, ...) == Pet:GUID() then
          for _, Handler in pairs(SelfCombatEvents[SubEvent]) do
            Handler(TimeStamp, SubEvent, ...);
          end
        end
      end
      for i = 1, CombatLogPrefixesCount do
        -- TODO : Optimize the str find
        local Start, End = stringfind(SubEvent, CombatLogPrefixes[i]);
        if Start and End then
          -- TODO: Optimize the double str sub
          local Prefix, Suffix = stringsub(SubEvent, Start, End), stringsub(SubEvent, End + 1);
          if PrefixCombatEvents[Prefix] then
            -- Unfiltered Combat Log with Prefix only
            for _, Handler in pairs(PrefixCombatEvents[Prefix]) do
              Handler(TimeStamp, SubEvent, ...);
            end
          end
          if SuffixCombatEvents[Suffix] then
            -- Unfiltered Combat Log with Suffix only
            for _, Handler in pairs(SuffixCombatEvents[Suffix]) do
              Handler(TimeStamp, SubEvent, ...);
            end
          end
        end
      end
    end
    , "COMBAT_LOG_EVENT_UNFILTERED"
  );

  -- Core Override System
  function AC.AddCoreOverride (target, newfunction, specKey)
    local loadOverrideFunc = assert(loadstring([[
      return function (func)
      ]]..target..[[ = func;
      end, ]]..target..[[
      ]]));
    setfenv(loadOverrideFunc, {AC = AC, Player = Player, Spell = Spell, Item = Item, Target = Target, Unit = Unit, Pet = Pet})
    local overrideFunc, oldfunction = loadOverrideFunc();
    if overrideDB[specKey] == nil then
      overrideDB[specKey] = {}
    end
    tableinsert(overrideDB[specKey], {overrideFunc, newfunction})
    tableinsert(restoreDB, {overrideFunc, oldfunction})
    return oldfunction;
  end
  function AC.LoadRestores ()
    for k, v in pairs(restoreDB) do
      v[1](v[2]);
    end
  end
  function AC.LoadOverrides (specKey)
    if type(overrideDB[specKey]) == "table" then
      for k, v in pairs(overrideDB[specKey]) do
        v[1](v[2]);
      end
    end
  end
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
        elseif Prefix == "BigWigs" and string.find(Message, "Pull") then
          AC.BossModTime = tonumber(stringsub(Message, 8, 9));
          AC.BossModEndTime = AC.GetTime() + AC.BossModTime;
        end
      end
      , "CHAT_MSG_ADDON"
    );

  -- OnSpecGearTalentUpdate
    -- Player Inspector
    -- TODO : Split based on events
    AC:RegisterForEvent(
      function (Event, Arg1)
        -- Prevent execute if not initiated by the player
        if Event == "PLAYER_SPECIALIZATION_CHANGED" and Arg1 ~= "player" then
          return;
        end

        -- Refresh Player
        local PrevSpec = Cache.Persistent.Player.Spec[1];
        Cache.Persistent.Player.Class = {UnitClass("player")};
        Cache.Persistent.Player.Spec = {GetSpecializationInfo(GetSpecialization())};

        -- Wipe the texture from Persistent Cache
        wipe(Cache.Persistent.Texture.Spell);
        wipe(Cache.Persistent.Texture.Item);

        -- Refresh Gear
        if Event == "PLAYER_EQUIPMENT_CHANGED" 
        or Event == "PLAYER_LOGIN" then
          AC.GetEquipment();
          
          -- WoD (They are working but not used, so I'll comment them)
          --AC.Tier18_2Pc, AC.Tier18_4Pc = AC.HasTier("T18");
          --AC.Tier18_ClassTrinket = AC.HasTier("T18_ClassTrinket");
          -- Legion
          AC.Tier19_2Pc, AC.Tier19_4Pc = AC.HasTier("T19");
          AC.Tier20_2Pc, AC.Tier20_4Pc = AC.HasTier("T20");
          AC.Tier21_2Pc, AC.Tier21_4Pc = AC.HasTier("T21");
        end
    
        -- Refresh Artifact
        if Event == "PLAYER_LOGIN"
        or (Event == "PLAYER_EQUIPMENT_CHANGED" and Arg1 == 16) 
        or PrevSpec ~= Cache.Persistent.Player.Spec[1] then
          Spell:ArtifactScan();
        end

        -- Load / Refresh Core Overrides
        if Event == "PLAYER_LOGIN" then
          C_Timer.After(3, function() AC.LoadOverrides(Cache.Persistent.Player.Spec[1]) end) -- TODO: fix timing issue via event?
        end
        if Event == "PLAYER_SPECIALIZATION_CHANGED" then
          AC.LoadRestores();
          AC.LoadOverrides(Cache.Persistent.Player.Spec[1]);
        end
      end
      , "ZONE_CHANGED_NEW_AREA"
      , "PLAYER_SPECIALIZATION_CHANGED"
      , "PLAYER_TALENT_UPDATE"
      , "PLAYER_EQUIPMENT_CHANGED"
      , "PLAYER_LOGIN"
    );

  -- Spell Book Scanner
    -- Checks the same event as Blizzard Spell Book, from SpellBookFrame_OnLoad in SpellBookFrame.lua
    AC:RegisterForEvent(
      function (Event, Arg1)
        -- Prevent execute if not initiated by the player
        if Event == "PLAYER_SPECIALIZATION_CHANGED" and Arg1 ~= "player" then
          return;
        end
        
        -- TODO: FIXME workaround to prevent Lua errors when Blizz do some shenanigans with book in Arena/Timewalking
        if pcall(
          function ()
            Spell.BookScan(true);
          end
        ) then
          wipe(Cache.Persistent.SpellLearned.Player);
          wipe(Cache.Persistent.SpellLearned.Pet);
          Spell:BookScan();
        end
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
  
