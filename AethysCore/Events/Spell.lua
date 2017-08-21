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
  local tableinsert = table.insert;
  -- File Locals
  local PlayerSpecs = {};
  local ListenedSpells = {};
  local Custom = {
    Whitelist = {},
    Blacklist = {}
  };


--- ============================ CONTENT ============================

  -- Player On Cast Success Listener
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      for i = 1, #PlayerSpecs do
        local ListenedSpell = ListenedSpells[PlayerSpecs[i]][SpellID];
        if ListenedSpell then
          ListenedSpell.LastCastTime = AC.GetTime();
          ListenedSpell.LastHitTime = AC.GetTime() + ListenedSpell:TravelTime();
        end
      end
    end
    , "SPELL_CAST_SUCCESS"
  )

  -- Pet On Cast Success Listener
  AC:RegisterForPetCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      for i = 1, #PlayerSpecs do
        local ListenedSpell = ListenedSpells[PlayerSpecs[i]][SpellID];
        if ListenedSpell then
          ListenedSpell.LastCastTime = AC.GetTime();
          ListenedSpell.LastHitTime = AC.GetTime() + ListenedSpell:TravelTime();
        end
      end
    end
    , "SPELL_CAST_SUCCESS"
  )
  
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      for i = 1, #PlayerSpecs do
        local ListenedSpell = ListenedSpells[PlayerSpecs[i]][SpellID];
        if ListenedSpell then
          ListenedSpell.LastBuffTime = AC.GetTime();
        end
      end
    end
    , "SPELL_AURA_APPLIED"
  )

  -- Register spells to listen for a given class (based on SpecID).
  function Player:RegisterListenedSpells (SpecID)
    PlayerSpecs = {};
    ListenedSpells = {};
    -- Fetch registered spells during the init
    local PlayerClass = AC.SpecID_ClassesSpecs[SpecID][1];
    for Spec, Spells in pairs(AC.Spell[PlayerClass]) do
      tableinsert(PlayerSpecs, Spec);
      ListenedSpells[Spec] = {};
      for _, Spell in pairs(Spells) do
        ListenedSpells[Spec][Spell:ID()] = Spell;
      end
    end
    -- Add Spells based on the Whitelist
    for SpellID, Spell in pairs(Custom.Whitelist) do
      for i = 1, #PlayerSpecs do
        ListenedSpells[PlayerSpecs[i]][SpellID] = Spell;
      end
    end
    -- Remove Spells based on the Blacklist
    for i = 1, #Custom.Blacklist do
      local SpellID = Custom.Blacklist[i];
      for k = 1, #PlayerSpecs do
        local Spec = PlayerSpecs[k];
        if ListenedSpells[Spec][SpellID] then
          ListenedSpells[Spec][SpellID] = nil;
        end
      end
    end
  end

  -- Add spells in the Listened Spells Whitelist
  function Spell:AddToListenedSpells ()
    Custom.Whitelist[self.SpellID] = self;
  end

  -- Add spells in the Listened Spells Blacklist
  function Spell:RemoveFromListenedSpells ()
    tableinsert(Custom.Blacklist, self.SpellID);
  end
