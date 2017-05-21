--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local tableinsert = table.insert;
  -- File Locals
  local TriggerGCD = AC.Enum.TriggerGCD; -- TriggerGCD table until it has been filtered.
  local LastRecord = 15;
  local PrevGCD, PrevOffGCD = {}, {};


--- ============================ CONTENT ============================
  
  -- Init all the records at 0, so it saves one check on PrevGCD method.
  for i = 1, LastRecord do
    tableinsert(PrevGCD, 0);
    tableinsert(PrevOffGCD, 0);
  end

  -- Clear Old Records
  local function RemoveOldRecords ()
    local n = #PrevGCD;
    while n > LastRecord do
      PrevGCD[n] = nil;
      n = n - 1;
    end
  end

  -- On Cast Success Listener
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, _, _, _, _, SpellID)
      if TriggerGCD[SpellID] then
        tableinsert(PrevGCD, 1, SpellID);
      elseif TriggerGCD[SpellID] == false then -- Prevents unwanted spells to be registered as OffGCD.
        tableinsert(PrevOffGCD, 1, SpellID);
      end
      RemoveOldRecords();
    end
    , "SPELL_CAST_SUCCESS"
  )

  -- Filter the Enum TriggerGCD table to keep only registered spells for a given class (based on SpecID).
  function Unit:FilterTriggerGCD (SpecID)
    local RegisteredSpells = {};
    local BaseTriggerGCD = AC.Enum.TriggerGCD; -- In case FilterTriggerGCD is called multiple time, we take the Enum table as base.
    for Spec, Spells in pairs(AC.Spell[AC.SpecID_ClassesSpecs[SpecID][1]]) do
      for _, Spell in pairs(Spells) do
        local SpellID = Spell:ID();
        RegisteredSpells[SpellID] = BaseTriggerGCD[SpellID];
      end
    end
    TriggerGCD = RegisteredSpells;
  end

  -- prev_gcd.x.foo
  function Unit:PrevGCD (Index, Spell)
    if Index > LastRecord then error("Only the lasts " .. LastRecord  .. " GCDs can be checked."); end
    return PrevGCD[Index] == Spell:ID();
  end

  -- prev_off_gcd.x.foo
  function Unit:PrevOffGCD (Index, Spell)
    if Index > LastRecord then error("Only the lasts " .. LastRecord  .. " OffGCDs can be checked."); end
    return PrevOffGCD[Index] == Spell:ID();
  end
