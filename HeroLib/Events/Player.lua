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
local BOOKTYPE_PET, BOOKTYPE_SPELL = BOOKTYPE_PET, BOOKTYPE_SPELL
local C_Timer = C_Timer
local GetFlyoutInfo, GetFlyoutSlotInfo = GetFlyoutInfo, GetFlyoutSlotInfo
local GetNumFlyouts, GetFlyoutID = GetNumFlyouts, GetFlyoutID
local GetNumSpellTabs = GetNumSpellTabs
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellInfo, GetSpellTabInfo = GetSpellInfo, GetSpellTabInfo
local GetTime = GetTime
local HasPetSpells = HasPetSpells
local IsTalentSpell = IsTalentSpell
local stringfind = string.find
local stringsub = string.sub
local UnitClass = UnitClass
local wipe = wipe
local SPELL_FAILED_UNIT_NOT_INFRONT = SPELL_FAILED_UNIT_NOT_INFRONT
-- File Locals


--- ============================ CONTENT ============================
-- Scan the Book to cache every Spell Learned.
local function BookScan(BlankScan)
  -- Pet Book
  do
    local NumPetSpells = HasPetSpells()
    if NumPetSpells then
      local SpellLearned = Cache.Persistent.SpellLearned.Pet
      for i = 1, NumPetSpells do
        local CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET))
        if CurrentSpellID then
          local CurrentSpell = Spell(CurrentSpellID, "Pet")
          if CurrentSpell:IsAvailable(true) and (CurrentSpell:IsKnown(true) or IsTalentSpell(i, BOOKTYPE_PET)) then
            if not BlankScan then
              SpellLearned[CurrentSpell:ID()] = true
            end
          end
        end
      end
    end
  end
  -- Player Book
  do
    local SpellLearned = Cache.Persistent.SpellLearned.Player

    for i = 1, GetNumSpellTabs() do
      local Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i))
      -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
      -- If the OffSpec ID is set to 0, then it's the Main Spec.
      if OffSpec == 0 then
        for j = 1, (Offset + NumSpells) do
          local CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL))
          if CurrentSpellID and GetSpellBookItemInfo(j, BOOKTYPE_SPELL) == "SPELL" then
            if not BlankScan then
              SpellLearned[CurrentSpellID] = true
            end
          end
        end
      end
    end

    -- Flyout Spells
    for i = 1, GetNumFlyouts() do
      local FlyoutID = GetFlyoutID(i)
      local NumSlots, IsKnown = select(3, GetFlyoutInfo(FlyoutID))
      if IsKnown and NumSlots > 0 then
        for j = 1, NumSlots do
          local CurrentSpellID, _, IsKnownSpell = GetFlyoutSlotInfo(FlyoutID, j)
          if CurrentSpellID and IsKnownSpell then
            SpellLearned[CurrentSpellID] = true
          end
        end
      end
    end
  end
end

-- Avoid creating garbage for pcall calls
local function BlankBookScan ()
  BookScan(true)
end

-- PLAYER_REGEN_DISABLED
HL.CombatStarted = 0
HL.CombatEnded = 1
-- Entering Combat
HL:RegisterForEvent(
  function()
    HL.CombatStarted = GetTime()
    HL.CombatEnded = 0
  end,
  "PLAYER_REGEN_DISABLED"
)

-- PLAYER_REGEN_ENABLED
-- Leaving Combat
HL:RegisterForEvent(
  function()
    HL.CombatStarted = 0
    HL.CombatEnded = GetTime()
  end,
  "PLAYER_REGEN_ENABLED"
)

-- CHAT_MSG_ADDON
-- DBM/BW Pull Timer
HL:RegisterForEvent(
  function(Event, Prefix, Message)
    if Prefix == "D4" and stringfind(Message, "PT") then
      HL.BossModTime = tonumber(stringsub(Message, 4, 5))
      HL.BossModEndTime = GetTime() + HL.BossModTime
    elseif Prefix == "BigWigs" and string.find(Message, "Pull") then
      HL.BossModTime = tonumber(stringsub(Message, 8, 9))
      HL.BossModEndTime = GetTime() + HL.BossModTime
    end
  end,
  "CHAT_MSG_ADDON"
)

-- Player Inspector
HL:RegisterForEvent(
  function(Event, Arg1)
    -- Prevent execute if not initiated by the player
    if Event == "PLAYER_SPECIALIZATION_CHANGED" and Arg1 ~= "player" then
      return
    end

    -- Refresh Player
    local PrevSpec = Cache.Persistent.Player.Spec[1]
    Cache.Persistent.Player.Class = { UnitClass("player") }
    Cache.Persistent.Player.Spec = { GetSpecializationInfo(GetSpecialization()) }

    -- Wipe the texture from Persistent Cache
    wipe(Cache.Persistent.Texture.Spell)
    wipe(Cache.Persistent.Texture.Item)

    -- Refresh Gear
    if Event == "PLAYER_EQUIPMENT_CHANGED" or Event == "PLAYER_LOGIN" then
      HL.GetEquipment()
    end

    --Refresh Azerite
    if Event == "PLAYER_LOGIN"
    or Event == "AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED"
    or (Event == "PLAYER_EQUIPMENT_CHANGED" and (Arg1 == 1 or Arg1 == 3 or Arg1 == 5))
    or PrevSpec ~= Cache.Persistent.Player.Spec[1] then
    Spell:AzeriteScan()
    end
    if Event == "PLAYER_LOGIN"
    or Event == "AZERITE_ESSENCE_CHANGED"
    or Event == "AZERITE_ESSENCE_ACTIVATED"
    or PrevSpec ~= Cache.Persistent.Player.Spec[1] then
    Spell:AzeriteEssenceScan()
    end
    if Event == "PLAYER_LOGIN"
    or (Event == "PLAYER_EQUIPMENT_CHANGED" and (Arg1 ~= 13 and Arg1 ~= 14))
    or PrevSpec ~= Cache.Persistent.Player.Spec[1] then
      HL.GetLegendaries()
    end

    -- Load / Refresh Core Overrides
    if Event == "PLAYER_LOGIN" then
      Player:Cache()
      -- TODO: fix timing issue via event?
      C_Timer.After(3, function() Player:Cache() end)
    elseif Event == "PLAYER_SPECIALIZATION_CHANGED" then
      local UpdateOverrides
      UpdateOverrides = function()
        if Cache.Persistent.Player.Spec[1] ~= nil then
          HL.LoadRestores()
          HL.LoadOverrides(Cache.Persistent.Player.Spec[1])
        else
          C_Timer.After(2, UpdateOverrides)
        end
      end
      UpdateOverrides()
    end
  end,
  "ZONE_CHANGED_NEW_AREA", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LOGIN", "AZERITE_ESSENCE_ACTIVATED", "AZERITE_ESSENCE_CHANGED"
)

-- Spell Book Scanner
-- Checks the same event as Blizzard Spell Book, from SpellBookFrame_OnLoad in SpellBookFrame.lua
HL:RegisterForEvent(
  function(Event, Arg1)
    -- Prevent execute if not initiated by the player
    if Event == "PLAYER_SPECIALIZATION_CHANGED" and Arg1 ~= "player" then
      return
    end

    -- FIXME: workaround to prevent Lua errors when Blizz do some shenanigans with book in Arena/Timewalking
    if pcall(BlankBookScan) then
      wipe(Cache.Persistent.BookIndex.Player)
      wipe(Cache.Persistent.BookIndex.Pet)
      wipe(Cache.Persistent.SpellLearned.Player)
      wipe(Cache.Persistent.SpellLearned.Pet)
      BookScan()
    end
  end,
  "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "SKILL_LINES_CHANGED", "PLAYER_GUILD_UPDATE", "PLAYER_SPECIALIZATION_CHANGED", "USE_GLYPH", "CANCEL_GLYPH_CAST", "ACTIVATE_GLYPH", "AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED"
)

-- Not Facing Unit Blacklist
HL.UnitNotInFront = Player
HL.UnitNotInFrontTime = 0
HL.LastUnitCycled = Player
HL.LastUnitCycledTime = 0
HL:RegisterForEvent(
  function(Event, MessageType, Message)
    if MessageType == 50 and Message == SPELL_FAILED_UNIT_NOT_INFRONT then
      HL.UnitNotInFront = HL.LastUnitCycled
      HL.UnitNotInFrontTime = HL.LastUnitCycledTime
    end
  end,
  "UI_ERROR_MESSAGE"
)
