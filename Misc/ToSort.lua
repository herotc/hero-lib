--- ============== HEADER ==============
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
  local select = select;
  -- File Locals
  


--- ============== CONTENT ==============
  -- Get the Latency (it's updated every 30s).
  -- TODO: Cache it in Persistent Cache and update it only when it changes
  function AC.Latency ()
    return select(4, GetNetStats());
  end

  -- Retrieve the Recovery Timer based on Settings.
  -- TODO: Optimize, to see how we'll implement it in the GUI.
  function AC.RecoveryTimer ()
    return AC.GUISettings.General.RecoveryMode == "GCD" and Player:GCDRemains()*1000 or AC.GUISettings.General.RecoveryTimer;
  end

  -- Compute the Recovery Offset with Lag Compensation.
  function AC.RecoveryOffset ()
    return (AC.Latency() + AC.RecoveryTimer())/1000;
  end

  -- Get the time since combat has started.
  function AC.CombatTime ()
    return AC.CombatStarted ~= 0 and AC.GetTime()-AC.CombatStarted or 0;
  end

  -- Get the time since combat has ended.
  function AC.OutOfCombatTime ()
    return AC.CombatEnded ~= 0 and AC.GetTime()-AC.CombatEnded or 0;
  end

  -- Get the Boss Mod Pull Timer.
  function AC.BMPullTime ()
    if not AC.BossModTime or AC.BossModTime == 0 or AC.BossModEndTime-AC.GetTime() < 0 then
      return 60;
    else
      return AC.BossModEndTime-AC.GetTime();
    end
  end

  AC.SpecID_ClassesSpecs = {
  -- Death Knight
    [250]   = {"DeathKnight", "Blood"},
    [251]   = {"DeathKnight", "Frost"},
    [252]   = {"DeathKnight", "Unholy"},
  -- Demon Hunter
    [577]   = {"DemonHunter", "Havoc"},
    [581]   = {"DemonHunter", "Vengeance"};
  -- Druid
    [102]   = {"Druid", "Balance"},
    [103]   = {"Druid", "Feral"},
    [104]   = {"Druid", "Guardian"},
    [105]   = {"Druid", "Restoration"},
  -- Hunter
    [253]   = {"Hunter", "Beast Mastery"},
    [254]   = {"Hunter", "Marksmanship"},
    [255]   = {"Hunter", "Survival"},
  -- Mage
    [62]    = {"Mage", "Arcane"},
    [63]    = {"Mage", "Fire"},
    [64]    = {"Mage", "Frost"},
  -- Monk
    [268]   = {"Monk", "Brewmaster"},
    [269]   = {"Monk", "Windwalker"},
    [270]   = {"Monk", "Mistweaver"},
  -- Paladin
    [65]    = {"Paladin", "Holy"},
    [66]    = {"Paladin", "Protection"},
    [70]    = {"Paladin", "Retribution"},
  -- Priest
    [256]   = {"Priest", "Discipline"},
    [257]   = {"Priest", "Holy"},
    [258]   = {"Priest", "Shadow"},
  -- Rogue
    [259]   = {"Rogue", "Assassination"},
    [260]   = {"Rogue", "Outlaw"},
    [261]   = {"Rogue", "Subtlety"},
  -- Shaman
    [262]   = {"Shaman", "Elemental"},
    [263]   = {"Shaman", "Enhancement"},
    [264]   = {"Shaman", "Restoration"},
  -- Warlock
    [265]   = {"Warlock", "Affliction"},
    [266]   = {"Warlock", "Demonology"},
    [267]   = {"Warlock", "Destruction"},
  -- Warrior
    [71]    = {"Warrior", "Arms"},
    [72]    = {"Warrior", "Fury"},
    [73]    = {"Warrior", "Protection"}
  };
