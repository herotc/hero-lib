--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache, Utils = AethysCache, AC.Utils;
  local Unit = AC.Unit;
  local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target;
  local Focus, MouseOver = Unit.Focus, Unit.MouseOver;
  local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate;
  local Party, Raid = Unit.Party, Unit.Raid;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  
  -- File Locals
  


--- ============================ CONTENT ============================
  
  -- Get if the player is mounted on a non-combat mount.
  function Player:IsMounted ()
    return IsMounted() and not self:IsOnCombatMount();
  end

  -- Get the player race.
    -- Dwarf, Draenei, Gnome, Human, NightElf, Worgen
    -- BloodElf, Goblin, Orc, Tauren, Troll, Scourge
    -- Pandaren
  do
    -- race, raceEn
    local UnitRace = UnitRace; 
    function Player:Race ()
      local GUID = self:GUID();
      if GUID then
        return select(2, UnitRace(self.UnitID));
      end
      return nil;
    end
    
    -- Test if the unit is of race unit_race
    function Player:IsRace (unit_race)
      return unit_race and self:Race() == unit_race or false;
    end
  end

  -- Get if the player is on a combat mount or not.
  local CombatMountBuff = {
    --- Classes
      Spell(131347),  -- Demon Hunter Glide
      Spell(783),     -- Druid Travel Form
      Spell(165962),  -- Druid Flight Form
      Spell(220509),  -- Paladin Divine Steed
      Spell(221883),  -- Paladin Divine Steed
      Spell(221885),  -- Paladin Divine Steed
      Spell(221886),  -- Paladin Divine Steed
      Spell(221887),  -- Paladin Divine Steed
      Spell(254471),  -- Paladin Divine Steed
      Spell(254472),  -- Paladin Divine Steed
      Spell(254473),  -- Paladin Divine Steed
      Spell(254474),  -- Paladin Divine Steed
    --- Legion
      -- Class Order Hall
      Spell(220480),  -- Death Knight Ebon Blade Deathcharger
      Spell(220484),  -- Death Knight Nazgrim's Deathcharger
      Spell(220488),  -- Death Knight Trollbane's Deathcharger
      Spell(220489),  -- Death Knight Whitemane's Deathcharger
      Spell(220491),  -- Death Knight Mograine's Deathcharger
      Spell(220504),  -- Paladin Silver Hand Charger
      Spell(220507),  -- Paladin Silver Hand Charger
      -- Stormheim PVP Quest (Bareback Brawl)
      Spell(221595),  -- Storm's Reach Cliffwalker
      Spell(221671),  -- Storm's Reach Warbear
      Spell(221672),  -- Storm's Reach Greatstag
      Spell(221673),  -- Storm's Reach Worg
      Spell(218964),  -- Stormtalon
    --- Warlord of Draenor (WoD)
      -- Nagrand
      Spell(164222),  -- Frostwolf War Wolf
      Spell(165803)   -- Telaari Talbuk
  };
  function Player:IsOnCombatMount ()
    for i = 1, #CombatMountBuff do
      if self:Buff(CombatMountBuff[i], nil, true) then
        return true;
      end
    end
    return false;
  end

  -- Get if the player is in a valid vehicle.
  function Player:IsInVehicle ()
    return UnitInVehicle(self.UnitID) and not self:IsInWhitelistedVehicle();
  end

  -- Get if the player is in a vhehicle that is not really a vehicle.
  local InVehicleWhitelist = {
    Spell = {
      --- Warlord of Draenor (WoD)
        -- Hellfire Citadel (T18 - 6.2 Patch)
        Spell(187819),  -- Crush (Kormrok's Hands)
        Spell(181345),  -- Foul Crush (Kormrok's Tank Hand)
        -- Blackrock Foundry (T17 - 6.0 Patch)
        Spell(157059)   -- Rune of Grasping Earth (Kromog's Hand)
    },
    PetMount = {
      --- Warlord of Draenor (WoD)
        -- Garrison Stables Quest (6.0 Patch)
        87082,  -- Silverperlt
        87078,  -- Icehoof
        87081,  -- Rocktusk
        87080,  -- Riverwallow
        87079,  -- Meadowstomper
        87076,  -- Snarler
      --- Legion
        -- Karazhan
        116802  -- Rodent of Usual Size
    }
  };
  function Player:IsInWhitelistedVehicle ()
    -- Spell
    for i = 1, #InVehicleWhitelist.Spell do
      if self:Debuff(InVehicleWhitelist.Spell[i], nil, true) then
        return true;
      end
    end
    -- PetMount
    if Pet:IsActive() then
      for i = 1, #InVehicleWhitelist.PetMount do
        if Pet:NPCID() == InVehicleWhitelist.PetMount[i] then
          return true;
        end
      end
    end
    return false;
  end
