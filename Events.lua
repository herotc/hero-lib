--- Localize Vars
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


-- Used for every Events
AC.Events = {};
AC.EventFrame = CreateFrame("Frame", "EasyRaid_EventFrame", UIParent);

-- Used for Combat Log Events
-- To be used with Combat Log Unfiltered
AC.CombatEvents = {};
-- To be used with Combat Log Unfiltered with SourceGUID == PlayerGUID filter
AC.SelfCombatEvents = {};

--- Register a handler for an event.
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

--- Register a handler for a combat event.
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

--- Register a handler for a self combat event.
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

--- Unregister a handler from an event.
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

--- Unregister a handler from a combat event.
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

--- Unregister a handler from a combat event.
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

-- OnEvent Frame
AC.EventFrame:SetScript("OnEvent", 
  function (self, Event, ...)
    for Index, Handler in pairs(AC.Events[Event]) do
      Handler(Event, ...);
    end
  end
);

-- Combat Log Event Unfiltered
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

--- ============== NON-COMBATLOG ==============

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
        -- WoD
        AC.Tier18_2Pc, AC.Tier18_4Pc = AC.HasTier("T18");
        AC.Tier18_ClassTrinket = AC.HasTier("T18_ClassTrinket");
        -- Legion
        Spell:ArtifactScan();
        AC.Tier19_2Pc, AC.Tier19_4Pc = AC.HasTier("T19");
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

--- ============== COMBATLOG ==============

  --- Combat Log Arguments


    ------- Base -------
      --    1      2      3        4        5        6          7        8      9      10        11
      -- TimeStamp, Event, HideCaster, SourceGUID, SourceName, SourceFlags, SourceRaidFlags, DestGUID, DestName, DestFlags, DestRaidFlags


    ------- Prefixes -------

      --- SWING
      -- N/A

      --- SPELL & SPELL_PACIODIC
      --   12      13      14
      -- SpellID, SpellName, SpellSchool


    ------- Suffixes -------

      --- _CAST_START & _CAST_SUCCESS & _SUMMON & _RESURRECT
      -- N/A

      --- _CAST_FAILED
      --    15
      -- FailedType

      --- _AURA_APPLIED & _AURA_REMOVED & _AURA_REFRESH
      --   15
      -- AuraType

      --- _AURA_APPLIED_DOSE
      --   15      16
      -- AuraType, Charges

      --- _INTACRUPT
      --    15        16          17
      -- ExtraSpellID, ExtraSpellName, ExtraSchool

      --- _HEAL
      --  15      16       17      18
      -- Amount, Overhealing, Absorbed, Critical

      --- _DAMAGE
      --  15     16     17     18     19      20      21      22      23
      -- Amount, Overkill, School, Resisted, Blocked, Absorbed, Critical, Glancing, Crushing

      --- _MISSED
      --   15      16        17
      -- MissType, IsOffHand, AmountMissed


    ------- Special -------

      --- UNIT_DIED, UNIT_DESTROYED
      -- N/A

  --- End Combat Log Arguments

  -- Arguments Variables
  local DestGUID, SpellID;

  -- Rogue
  if Cache.Persistent.Player.Class[3] == 4 then
    AC.BleedTable = {
      -- Assassination
      Assassination = {
        Garrote = {},
        Rupture = {}
      },
      -- Subtlety
      Subtlety = {
        Nightblade = {},
        FinalityNightblade = false,
        FinalityNightbladeTime = 0
      }
    };
    local BleedGUID;
    --- Exsanguinated Handler
      local BleedDuration, BleedExpires;
      function AC.Exsanguinated (Unit, SpellName)
        BleedGUID = Unit:GUID();
        if BleedGUID then
          if SpellName == "Garrote" then
            if AC.BleedTable.Assassination.Garrote[BleedGUID] then
              return AC.BleedTable.Assassination.Garrote[BleedGUID][3];
            end
          elseif SpellName == "Rupture" then
            if AC.BleedTable.Assassination.Rupture[BleedGUID] then
              return AC.BleedTable.Assassination.Rupture[BleedGUID][3];
            end
          end
        end
        return false;
      end
      -- Exsanguinate Cast
      AC:RegisterForSelfCombatEvent(
        function (...)
          DestGUID, _, _, _, SpellID = select(8, ...);

          -- Exsanguinate
          if SpellID == 200806 then
            for Key, _ in pairs(AC.BleedTable.Assassination) do
              for Key2, _ in pairs(AC.BleedTable.Assassination[Key]) do
                if Key2 == DestGUID then
                  -- Change the Exsanguinate info to true
                  AC.BleedTable.Assassination[Key][Key2][3] = true;
                end
              end
            end
          end
        end
        , "SPELL_CAST_SUCCESS"
      );
      -- Bleed infos
      local function GetBleedInfos (GUID, Spell)
        -- Core API is not used since we don't want cached informations
        return select(6, UnitAura(GUID, ({GetSpellInfo(Spell)})[1], nil, "HARMFUL|PLAYER"));
      end
      -- Record the bleed state if it is successfully applied on an unit
      AC:RegisterForSelfCombatEvent(
        function (...)
          DestGUID, _, _, _, SpellID = select(8, ...);

          --- Record the Bleed Target and its Infos
          -- Garrote
          if SpellID == 703 then
            BleedDuration, BleedExpires = GetBleedInfos(DestGUID, SpellID);
            AC.BleedTable.Assassination.Garrote[DestGUID] = {BleedDuration, BleedExpires, false};
          -- Rupture
          elseif SpellID == 1943 then
            BleedDuration, BleedExpires = GetBleedInfos(DestGUID, SpellID);
            AC.BleedTable.Assassination.Rupture[DestGUID] = {BleedDuration, BleedExpires, false};
          end
        end
        , "SPELL_AURA_APPLIED"
        , "SPELL_AURA_REFRESH"
      );
      -- Bleed Remove
      AC:RegisterForSelfCombatEvent(
        function (...)
          DestGUID, _, _, _, SpellID = select(8, ...);

          -- Removes the Unit from Garrote Table
          if SpellID == 703 then
            if AC.BleedTable.Assassination.Garrote[DestGUID] then
              AC.BleedTable.Assassination.Garrote[DestGUID] = nil;
            end
          -- Removes the Unit from Rupture Table
          elseif SpellID == 1943 then
            if AC.BleedTable.Assassination.Rupture[DestGUID] then
              AC.BleedTable.Assassination.Rupture[DestGUID] = nil;
            end
          end
        end
        , "SPELL_AURA_REMOVED"
      );
      AC:RegisterForCombatEvent(
        function (...)
          DestGUID = select(8, ...);

          -- Removes the Unit from Garrote Table
          if AC.BleedTable.Assassination.Garrote[DestGUID] then
            AC.BleedTable.Assassination.Garrote[DestGUID] = nil;
          end
          -- Removes the Unit from Rupture Table
          if AC.BleedTable.Assassination.Rupture[DestGUID] then
            AC.BleedTable.Assassination.Rupture[DestGUID] = nil;
          end
        end
        , "UNIT_DIED"
        , "UNIT_DESTROYED"
      );
    --- Finality Nightblade Handler
      function AC.Finality (Unit)
        BleedGUID = Unit:GUID();
        if BleedGUID then
          if AC.BleedTable.Subtlety.Nightblade[BleedGUID] then
            return AC.BleedTable.Subtlety.Nightblade[BleedGUID];
          end
        end
        return false;
      end
      -- Check the Finality buff on cast (because it disappears after) but don't record it until application (because it can miss)
      AC:RegisterForSelfCombatEvent(
        function (...)
          SpellID = select(12, ...);

          -- Nightblade
          if SpellID == 195452 then
            AC.BleedTable.Subtlety.FinalityNightblade = Player:Buff(Spell.Rogue.Subtlety.FinalityNightblade) and true or false;
            AC.BleedTable.Subtlety.FinalityNightbladeTime = AC.GetTime() + 0.3;
          end
        end
        , "SPELL_CAST_SUCCESS"
      );
      -- Record the bleed state if it is successfully applied on an unit
      AC:RegisterForSelfCombatEvent(
        function (...)
          DestGUID, _, _, _, SpellID = select(8, ...);

          if SpellID == 195452 then
            AC.BleedTable.Subtlety.Nightblade[DestGUID] = AC.GetTime() < AC.BleedTable.Subtlety.FinalityNightbladeTime and AC.BleedTable.Subtlety.FinalityNightblade;
          end
        end
        , "SPELL_AURA_APPLIED"
        , "SPELL_AURA_REFRESH"
      );
      -- Remove the bleed when it expires or the unit dies
      AC:RegisterForSelfCombatEvent(
        function (...)
          DestGUID, _, _, _, SpellID = select(8, ...);

          if SpellID == 195452 then
            if AC.BleedTable.Subtlety.Nightblade[DestGUID] then
              AC.BleedTable.Subtlety.Nightblade[DestGUID] = nil;
            end
          end
        end
        , "SPELL_AURA_REMOVED"
      );
      AC:RegisterForCombatEvent(
        function (...)
          DestGUID = select(8, ...);

          if AC.BleedTable.Subtlety.Nightblade[DestGUID] then
            AC.BleedTable.Subtlety.Nightblade[DestGUID] = nil;
          end
        end
        , "UNIT_DIED"
        , "UNIT_DESTROYED"
      );
    --- Just Stealthed
      -- TODO: Add Assassination Spells when it'll be done
      AC:RegisterForSelfCombatEvent(
        function (...)
          SpellID = select(12, ...);

          -- TODO: Remove Spell.Rogue check when Events will be in Class Module
          if Spell.Rogue then
            -- Shadow Dance
            if SpellID == Spell.Rogue.Subtlety.ShadowDance:ID() then
              Spell.Rogue.Subtlety.ShadowDance.LastCastTime = AC.GetTime();
            -- Shadowmeld
            elseif SpellID == Spell.Rogue.Subtlety.Shadowmeld:ID() then
              Spell.Rogue.Outlaw.Shadowmeld.LastCastTime = AC.GetTime();
              Spell.Rogue.Subtlety.Shadowmeld.LastCastTime = AC.GetTime();
            -- Vanish
            elseif SpellID == Spell.Rogue.Subtlety.Vanish:ID() then
              Spell.Rogue.Outlaw.Vanish.LastCastTime = AC.GetTime();
              Spell.Rogue.Subtlety.Vanish.LastCastTime = AC.GetTime();
            end
          end
        end
        , "SPELL_CAST_SUCCESS"
      );
  end
