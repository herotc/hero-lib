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
  local ListenedSpells = {};
  local Custom = {
    Whitelist = {},
    Blacklist = {}
  };


--- ============================ CONTENT ============================

  -- Player On Cast Success Listener
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      if ListenedSpells[SpellID] then
        ListenedSpells[SpellID].LastCastTime = AC.GetTime();
      end
    end
    , "SPELL_CAST_SUCCESS"
  )

  -- Pet On Cast Success Listener
  AC:RegisterForPetCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      if ListenedSpells[SpellID] then
        ListenedSpells[SpellID].LastCastTime = AC.GetTime();
      end
    end
    , "SPELL_CAST_SUCCESS"
  )

  -- Register spells to listen for a given class (based on SpecID).
  function Player:RegisterListenedSpell (SpecID)
    ListenedSpells = {};
    -- Fetch registered spells during the init
    local PlayerClass = AC.SpecID_ClassesSpecs[SpecID][1];
    for Spec, Spells in pairs(AC.Spell[PlayerClass]) do
      for _, Spell in pairs(Spells) do
        ListenedSpells[Spell:ID()] = Spell;
      end
    end
    -- Add Spells based on the Whitelist
    for SpellID, Value in pairs(Custom.Whitelist) do
      ListenedSpells[SpellID] = Value;
    end
    -- Remove Spells based on the Blacklist
    for i = 1, #Custom.Blacklist do
      local SpellID = Custom.Blacklist[i];
      if ListenedSpells[SpellID] then
        ListenedSpells[SpellID] = nil;
      end
    end
  end

  -- Add spells in the Listened Spells Whitelist
  function Spell:AddToListenedSpells (Value)
    if type(Value) ~= "boolean" then error("You must gives a boolean as argument."); end
    Custom.Whitelist[self.SpellID] = Value;
  end

  -- Add spells in the Listened Spells Blacklist
  function Spell:RemoveFromListenedSpells ()
    tableinsert(Custom.Blacklist, self.SpellID);
  end
