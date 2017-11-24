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
  local TriggerGCD = AC.Enum.TriggerGCD; -- TriggerGCD table until it has been filtered.
  local LastRecord = 15;
  local PrevGCDPredicted = 0;
  local Prev = {
    GCD = {},
    OffGCD = {},
    PetGCD = {},
    PetOffGCD = {},
  };
  local Custom = {
    Whitelist = {},
    Blacklist = {}
  };


--- ============================ CONTENT ============================
  
  -- Init all the records at 0, so it saves one check on PrevGCD method.
  for i = 1, LastRecord do
    for _, Table in pairs(Prev) do
      tableinsert(Table, 0);
    end
  end

  -- Clear Old Records
  local function RemoveOldRecords ()
    for _, Table in pairs(Prev) do
      local n = #Table;
      while n > LastRecord do
        Table[n] = nil;
        n = n - 1;
      end
    end
  end

  -- Player On Cast Success Listener
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      if TriggerGCD[SpellID] then
        tableinsert(Prev.GCD, 1, SpellID);
        Prev.OffGCD = {};
        PrevGCDPredicted = 0;
      elseif TriggerGCD[SpellID] == false then -- Prevents unwanted spells to be registered as OffGCD.
        tableinsert(Prev.OffGCD, 1, SpellID);
      end
      RemoveOldRecords();
    end
    , "SPELL_CAST_SUCCESS"
  )
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      if TriggerGCD[SpellID] then
        PrevGCDPredicted = SpellID;
      end
    end
    , "SPELL_CAST_START"
  )
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      if PrevGCDPredicted == SpellID then
        PrevGCDPredicted = 0;
      end
    end
    , "SPELL_CAST_FAILED"
  )
  -- Pet On Cast Success Listener
  AC:RegisterForPetCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      if TriggerGCD[SpellID] then
        tableinsert(Prev.PetGCD, 1, SpellID);
        Prev.PetOffGCD = {};
      elseif TriggerGCD[SpellID] == false then -- Prevents unwanted spells to be registered as OffGCD.
        tableinsert(Prev.PetOffGCD, 1, SpellID);
      end
      RemoveOldRecords();
    end
    , "SPELL_CAST_SUCCESS"
  )

  -- Filter the Enum TriggerGCD table to keep only registered spells for a given class (based on SpecID).
  function Player:FilterTriggerGCD (SpecID)
    local RegisteredSpells = {};
    local BaseTriggerGCD = AC.Enum.TriggerGCD; -- In case FilterTriggerGCD is called multiple time, we take the Enum table as base.
    -- Fetch registered spells during the init
    for Spec, Spells in pairs(AC.Spell[AC.SpecID_ClassesSpecs[SpecID][1]]) do
      for _, Spell in pairs(Spells) do
        local SpellID = Spell:ID();
        local TriggerGCDInfo = BaseTriggerGCD[SpellID];
        if TriggerGCDInfo ~= nil then
          RegisteredSpells[SpellID] = TriggerGCDInfo;
        end
      end
    end
    -- Add Spells based on the Whitelist
    for SpellID, Value in pairs(Custom.Whitelist) do
      RegisteredSpells[SpellID] = Value;
    end
    -- Remove Spells based on the Blacklist
    for i = 1, #Custom.Blacklist do
      local SpellID = Custom.Blacklist[i];
      if RegisteredSpells[SpellID] then
        RegisteredSpells[SpellID] = nil;
      end
    end
    TriggerGCD = RegisteredSpells;
  end

  -- Add spells in the Trigger GCD Whitelist
  function Spell:AddToTriggerGCD (Value)
    if type(Value) ~= "boolean" then error("You must give a boolean as argument."); end
    Custom.Whitelist[self.SpellID] = Value;
  end

  -- Add spells in the Trigger GCD Blacklist
  function Spell:RemoveFromTriggerGCD ()
    tableinsert(Custom.Blacklist, self.SpellID);
  end

  -- prev_gcd.x.foo
  function Player:PrevGCD (Index, Spell)
    if Index > LastRecord then error("Only the last " .. LastRecord  .. " GCDs can be checked."); end
    if Spell then
      return Prev.GCD[Index] == Spell:ID()
    else 
      return Prev.GCD[Index];
    end
  end

  -- Player:PrevGCD with cast start prediction
  function Player:PrevGCDP (Index, Spell, ForcePred)
    if Index > LastRecord then error("Only the last " .. (LastRecord)  .. " GCDs can be checked."); end
    if PrevGCDPredicted > 0 and Index == 1 or ForcePred then
      return PrevGCDPredicted == Spell:ID();
    elseif PrevGCDPredicted > 0 then
      return Player:PrevGCD(Index - 1, Spell);
    else
      return Player:PrevGCD(Index, Spell);
    end
  end

  -- prev_off_gcd.x.foo
  function Player:PrevOffGCD (Index, Spell)
    if Index > LastRecord then error("Only the last " .. LastRecord  .. " OffGCDs can be checked."); end
    return Prev.OffGCD[Index] == Spell:ID();
  end

  -- Player:PrevOffGCD with cast start prediction
  function Player:PrevOffGCDP (Index, Spell)
    if Index > LastRecord then error("Only the last " .. (LastRecord)  .. " GCDs can be checked."); end
    if PrevGCDPredicted > 0 and Index == 1 then
      return false;
    elseif PrevGCDPredicted > 0 then
      return Player:PrevOffGCD (Index - 1, Spell);
    else
      return Player:PrevOffGCD (Index, Spell);
    end
  end

  -- "pet.prev_gcd.x.foo"
  function Pet:PrevGCD (Index, Spell)
    if Index > LastRecord then error("Only the last " .. LastRecord  .. " GCDs can be checked."); end
    return Prev.PetGCD[Index] == Spell:ID();
  end

  -- "pet.prev_off_gcd.x.foo"
  function Pet:PrevOffGCD (Index, Spell)
    if Index > LastRecord then error("Only the last " .. LastRecord  .. " OffGCDs can be checked."); end
    return Prev.PetOffGCD[Index] == Spell:ID();
  end
