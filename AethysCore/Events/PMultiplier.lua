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


--- ============================ CONTENT ============================

  -- PMultiplier OnCast Listener
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
      local ListenedSpell = ListenedSpells[SpellID];
      if ListenedSpell then
        local PMultiplier = 1;
        for j = 1, #ListenedSpell.Buffs do
          local Buff = ListenedSpell.Buffs[j];
          local Spell = Buff[1];
          local Modifier = Buff[2];
          -- Check if we did registered a Buff to check + a modifier (as a number or through a function).
          if Modifier then
            if Player:Buff(Spell) or Spell:TimeSinceLastRemovedOnPlayer() < 0.1 then
              local ModifierType = type(Modifier);
              if ModifierType == "number" then
                PMultiplier = PMultiplier * Modifier;
              elseif ModifierType == "function" then
                PMultiplier = PMultiplier * Modifier();
              end
            end
          else
            -- If there is only one element, then check if it's an AIO function and call it.
            if type(Spell) == "function" then
              PMultiplier = PMultiplier * Spell();
            end
          end
        end
        ListenedSpell.PMultiplier[DestGUID] = {PMultiplier = PMultiplier, Time = AC.GetTime(), Applied = false};
      end
    end
    , "SPELL_CAST_SUCCESS"
  );
  -- Nightblade OnApply/OnRefresh Listener
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
      local ListenedSpell = ListenedSpells[SpellID];
      if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
        ListenedSpell.PMultiplier[DestGUID].Applied = true;
      end
    end
    , "SPELL_AURA_APPLIED"
    , "SPELL_AURA_REFRESH"
  );
  AC:RegisterForSelfCombatEvent(
    function (_, _, _, _, _, _, _, DestGUID, _, _, _, SpellID)
      local ListenedSpell = ListenedSpells[SpellID];
      if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
        ListenedSpell.PMultiplier[DestGUID] = nil;
      end
    end
    , "SPELL_AURA_REMOVED"
  );
  -- PMultiplier OnRemove & OnUnitDeath Listener
  AC:RegisterForCombatEvent(
    function (_, _, _, _, _, _, _, DestGUID)
      for SpellID, Spell in pairs(ListenedSpells) do
        if Spell.PMultiplier[DestGUID] then
          Spell.PMultiplier[DestGUID] = nil;
        end
      end
    end
    , "UNIT_DIED"
    , "UNIT_DESTROYED"
  );

  -- Register a spell to watch and his multipliers.
  -- Examples:
    --- Buff + Modifier as a function
      -- S.Nightblade:RegisterPMultiplier({S.FinalityNightblade,
      --   function ()
      --     return Player:Buff(S.FinalityNightblade, 17) and 1 + Player:Buff(S.FinalityNightblade, 17)/100 or 1;
      --   end}
      -- );
    --- 3x Buffs & Modifier as a number
      -- S.Rip:RegisterPMultiplier({S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15});
      -- S.Thrash:RegisterPMultiplier({S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15});
    --- AIO function + 3x Buffs & Modifier as a number
      -- S.Rake:RegisterPMultiplier(
      --   {function ()
      --     return Player:IsStealthed(true, true) and 2 or 1;
      --   end},
      --   {S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15}
      -- );
  function Spell:RegisterPMultiplier (...)
    ListenedSpells[self.SpellID] = {Buffs = {...}, PMultiplier = {}};
  end

  -- dot.foo.pmultiplier
  function Unit:PMultiplier (Spell)
    if ListenedSpells[Spell.SpellID].PMultiplier then
      local UnitDot = ListenedSpells[Spell.SpellID].PMultiplier[self:GUID()];
      return UnitDot and UnitDot.Applied and UnitDot.PMultiplier or 0;
    else
      error("You forgot to register the spell.");
    end
  end
