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
  local tostring = tostring;
  -- File Locals
  


--- ============================ CONTENT ============================
  -- Get the instance information about the current area.
  -- Returns
    -- name - Name of the instance or world area (string)
    -- type - Type of the instance (string)
    --   arena - A PvP Arena instance
    --   none - Normal world area (e.g. Northrend, Kalimdor, Deeprun Tram)
    --   party - An instance for 5-man groups
    --   pvp - A PvP battleground instance
    --   raid - An instance for raid groups
    --   scenario - A scenario instance
    -- difficulty - Difficulty setting of the instance (number)
    --   0 - None; not in an Instance.
    --   1 - 5-player Instance.
    --   2 - 5-player Heroic Instance.
    --   3 - 10-player Raid Instance.
    --   4 - 25-player Raid Instance.
    --   5 - 10-player Heroic Raid Instance.
    --   6 - 25-player Heroic Raid Instance.
    --   7 - 25-player Raid Finder Instance.
    --   8 - Challenge Mode Instance.
    --   9 - 40-player Raid Instance.
    --   10 - Not used.
    --   11 - Heroic Scenario Instance.
    --   12 - Scenario Instance.
    --   13 - Not used.
    --   14 - 10-30-player Normal Raid Instance.
    --   15 - 10-30-player Heroic Raid Instance.
    --   16 - 20-player Mythic Raid Instance .
    --   17 - 10-30-player Raid Finder Instance.
    --   18 - 40-player Event raid (Used by the level 100 version of Molten Core for WoW's 10th anniversary).
    --   19 - 5-player Event instance (Used by the level 90 version of UBRS at WoD launch).
    --   20 - 25-player Event scenario (unknown usage).
    --   21 - Not used.
    --   22 - Not used.
    --   23 - Mythic 5-player Instance.
    --   24 - Timewalker 5-player Instance.
    -- difficultyName - String representing the difficulty of the instance. E.g. "10 Player" (string)
    -- maxPlayers - Maximum number of players allowed in the instance (number)
    -- playerDifficulty - Unknown (number)
    -- isDynamicInstance - True for raid instances that can support multiple maxPlayers values (10 and 25) - eg. ToC, DS, ICC, etc (boolean)
    -- mapID - (number)
    -- instanceGroupSize - maxPlayers for fixed size raids, holds the actual raid size for the new flexible raid (between (8?)10 and 25) (number)
  function Player:InstanceInfo (Index)
    if Index then
      return Cache.Get("UnitInfo", self:GUID(), "InstanceInfo",
                       function() return {GetInstanceInfo()}; end)[Index];
    else
      return unpack(Cache.Get("UnitInfo", self:GUID(), "InstanceInfo",
                       function() return {GetInstanceInfo()}; end));
    end
  end

  -- Get the player instance type.
  function Player:InstanceType ()
    return self:InstanceInfo(2);
  end

  -- Get the player instance difficulty.
  function Player:InstanceDifficulty ()
    return self:InstanceInfo(3);
  end

  -- Get wether the player is in an instanced pvp area.
  function Player:IsInInstancedPvP ()
    local InstanceType = self:InstanceType();
    return (InstanceType == "arena" or InstanceType == "pvp") or false;
  end

  -- Get wether the player is in a raid area.
  function Player:IsInRaid ()
    return self:InstanceType() == "raid" or false;
  end

  -- Get if the player is mounted on a non-combat mount.
  function Player:IsMounted ()
    return IsMounted() and not self:IsOnCombatMount();
  end

  -- Get if the player is on a combat mount or not.
  local CombatMountBuff = {
    --- Classes
      Spell(131347),  -- Demon Hunter Glide
      Spell(783),     -- Druid Travel Form
      Spell(165962),  -- Druid Flight Form
      Spell(220509),  -- Paladin Divine Steed
      Spell(221883),  -- Paladin Divine Steed
      Spell(221884),  -- Paladin Divine Steed
      Spell(221886),  -- Paladin Divine Steed
      Spell(221887),  -- Paladin Divine Steed
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
        87076   -- Snarler
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

  -- gcd
  local GCD_OneSecond = {
    [103] = true,   -- Feral
    [259] = true,   -- Assassination
    [260] = true,   -- Outlaw
    [261] = true,   -- Subtlety
    [268] = true,   -- Brewmaster
    [269] = true    -- Windwalker
  };
  local GCD_Value = 1.5;
  function Player:GCD ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.GCD then
        if GCD_OneSecond[Cache.Persistent.Player.Spec[1]] then
          UnitInfo.GCD = 1;
        else
          GCD_Value = 1.5/(1+self:HastePct()/100);
          UnitInfo.GCD = GCD_Value > 0.75 and GCD_Value or 0.75;
        end
      end
      return UnitInfo.GCD;
    end
  end
  
  -- gcd.remains
  local GCDSpell = Spell(61304);
  function Player:GCDRemains ()
    return GCDSpell:Cooldown(true);
  end

  -- attack_power
  -- TODO : Use Cache
  function Player:AttackPower ()
    return UnitAttackPower(self.UnitID);
  end

  -- crit_chance
  -- TODO : Use Cache
  function Player:CritChancePct ()
    return GetCritChance();
  end

  -- haste
  -- TODO : Use Cache
  function Player:HastePct ()
    return GetHaste();
  end

  -- mastery
  -- TODO : Use Cache
  function Player:MasteryPct ()
    return GetMasteryEffect();
  end

  -- versatility
  -- TODO : Use Cache
  function Player:VersatilityDmgPct ()
    return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
  end

  --------------------------
  --- 1 | Rage Functions ---
  --------------------------
  -- rage.max
  function Player:RageMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.RageMax then
        UnitInfo.RageMax = UnitPowerMax(self.UnitID, Enum.PowerType.Rage);
      end
      return UnitInfo.RageMax;
    end
  end
  -- rage
  function Player:Rage ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.Rage then
        UnitInfo.Rage = UnitPower(self.UnitID, Enum.PowerType.Rage);
      end
      return UnitInfo.Rage;
    end
  end
  -- rage.pct
  function Player:RagePercentage ()
    return (self:Rage() / self:RageMax()) * 100;
  end
  -- rage.deficit
  function Player:RageDeficit ()
    return self:RageMax() - self:Rage();
  end
  -- "rage.deficit.pct"
  function Player:RageDeficitPercentage ()
    return (self:RageDeficit() / self:RageMax()) * 100;
  end

  ---------------------------
  --- 2 | Focus Functions ---
  ---------------------------
  -- focus.max
  function Player:FocusMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.FocusMax then
        UnitInfo.FocusMax = UnitPowerMax(self.UnitID, Enum.PowerType.Focus);
      end
      return UnitInfo.FocusMax;
    end
  end
  -- focus
  function Player:Focus ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.Focus then
        UnitInfo.Focus = UnitPower(self.UnitID, Enum.PowerType.Focus);
      end
      return UnitInfo.Focus;
    end
  end
  -- focus.regen
  function Player:FocusRegen ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.FocusRegen then
        UnitInfo.FocusRegen = select(2, GetPowerRegen(self.UnitID));
      end
      return UnitInfo.FocusRegen;
    end
  end
  -- focus.pct
  function Player:FocusPercentage ()
    return (self:Focus() / self:FocusMax()) * 100;
  end
  -- focus.deficit
  function Player:FocusDeficit ()
    return self:FocusMax() - self:Focus();
  end
  -- "focus.deficit.pct"
  function Player:FocusDeficitPercentage ()
    return (self:FocusDeficit() / self:FocusMax()) * 100;
  end
  -- "focus.regen.pct"
  function Player:FocusRegenPercentage ()
    return (self:FocusRegen() / self:FocusMax()) * 100;
  end
  -- focus.time_to_max
  function Player:FocusTimeToMax ()
    if self:FocusRegen() == 0 then return -1; end
    return self:FocusDeficit() / self:FocusRegen();
  end
  -- "focus.time_to_x"
  function Player:FocusTimeToX (Amount)
    if self:FocusRegen() == 0 then return -1; end
    return Amount > self:Focus() and (Amount - self:Focus()) / self:FocusRegen() or 0;
  end
  -- "focus.time_to_x.pct"
  function Player:FocusTimeToXPercentage (Amount)
    if self:FocusRegen() == 0 then return -1; end
    return Amount > self:FocusPercentage() and (Amount - self:FocusPercentage()) / self:FocusRegenPercentage() or 0;
  end
  -- cast_regen
  function Player:FocusCastRegen (CastTime)
    if self:FocusRegen() == 0 then return -1; end
    return self:FocusRegen() * CastTime;
  end
  -- "remaining_cast_regen"
  function Player:FocusRemainingCastRegen (Offset)
    if self:FocusRegen() == 0 then return -1; end
    -- If we are casting, we check what we will regen until the end of the cast
    if self:IsCasting() then
      return self:FocusRegen() * (self:CastRemains() + (Offset or 0));
    -- Else we'll use the remaining GCD as "CastTime"
    else
      return self:FocusRegen() * (self:GCDRemains() + (Offset or 0));
    end
  end
  -- Get the Focus we will loose when our cast will end, if we cast.
  function Player:FocusLossOnCastEnd ()
    return self:IsCasting() and Spell(self:CastID()):Cost() or 0;
  end
  -- Predict the expected Focus at the end of the Cast/GCD.
  function Player:FocusPredicted (Offset)
    if self:FocusRegen() == 0 then return -1; end
    return self:Focus() + self:FocusRemainingCastRegen(Offset) - self:FocusLossOnCastEnd();
  end

  ----------------------------
  --- 3 | Energy Functions ---
  ----------------------------
  -- energy.max
  function Player:EnergyMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.EnergyMax then
        UnitInfo.EnergyMax = UnitPowerMax(self.UnitID, Enum.PowerType.Energy);
      end
      return UnitInfo.EnergyMax;
    end
  end
  -- energy
  function Player:Energy ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.Energy then
        UnitInfo.Energy = UnitPower(self.UnitID, Enum.PowerType.Energy);
      end
      return UnitInfo.Energy;
    end
  end
  -- energy.regen
  function Player:EnergyRegen ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.EnergyRegen then
        UnitInfo.EnergyRegen = select(2, GetPowerRegen(self.UnitID));
      end
      return UnitInfo.EnergyRegen;
    end
  end
  -- energy.pct
  function Player:EnergyPercentage ()
    return (self:Energy() / self:EnergyMax()) * 100;
  end
  -- energy.deficit
  function Player:EnergyDeficit ()
    return self:EnergyMax() - self:Energy();
  end
  -- "energy.deficit.pct"
  function Player:EnergyDeficitPercentage ()
    return (self:EnergyDeficit() / self:EnergyMax()) * 100;
  end
  -- "energy.regen.pct"
  function Player:EnergyRegenPercentage ()
    return (self:EnergyRegen() / self:EnergyMax()) * 100;
  end
  -- energy.time_to_max
  function Player:EnergyTimeToMax ()
    if self:EnergyRegen() == 0 then return -1; end
    return self:EnergyDeficit() / self:EnergyRegen();
  end
  -- "energy.time_to_x"
  function Player:EnergyTimeToX (Amount, Offset)
    if self:EnergyRegen() == 0 then return -1; end
    return Amount > self:Energy() and (Amount - self:Energy()) / (self:EnergyRegen() * (1 - (Offset or 0))) or 0;
  end
  -- "energy.time_to_x.pct"
  function Player:EnergyTimeToXPercentage (Amount)
    if self:EnergyRegen() == 0 then return -1; end
    return Amount > self:EnergyPercentage() and (Amount - self:EnergyPercentage()) / self:EnergyRegenPercentage() or 0;
  end

  ----------------------------------
  --- 4 | Combo Points Functions ---
  ----------------------------------
  -- combo_points.max
  function Player:ComboPointsMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.ComboPointsMax then
        UnitInfo.ComboPointsMax = UnitPowerMax(self.UnitID, Enum.PowerType.ComboPoints);
      end
      return UnitInfo.ComboPointsMax;
    end
  end
  -- combo_points
  function Player:ComboPoints ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.ComboPoints then
        UnitInfo.ComboPoints = UnitPower(self.UnitID, Enum.PowerType.ComboPoints);
      end
      return UnitInfo.ComboPoints;
    end
  end
  -- combo_points.deficit
  function Player:ComboPointsDeficit ()
    return self:ComboPointsMax() - self:ComboPoints();
  end

  ---------------------------------
  --- 5 | Runic Power Functions ---
  ---------------------------------
  -- runicpower.max
  function Player:RunicPowerMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.RunicPowerMax then
        UnitInfo.RunicPowerMax = UnitPowerMax(self.UnitID, Enum.PowerType.RunicPower);
      end
      return UnitInfo.RunicPowerMax;
    end
  end
  -- runicpower
  function Player:RunicPower ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.RunicPower then
        UnitInfo.RunicPower = UnitPower(self.UnitID, Enum.PowerType.RunicPower);
      end
      return UnitInfo.RunicPower;
    end
  end
  -- runicpower.pct
  function Player:RunicPowerPercentage ()
    return (self:RunicPower() / self:RunicPowerMax()) * 100;
  end
  -- runicpower.deficit
  function Player:RunicPowerDeficit ()
    return self:RunicPowerMax() - self:RunicPower();
  end
  -- "runicpower.deficit.pct"
  function Player:RunicPowerDeficitPercentage ()
    return (self:RunicPowerDeficit() / self:RunicPowerMax()) * 100;
  end

  ---------------------------
  --- 6 | Runes Functions ---
  ---------------------------

  -- TODO

  ------------------------
  --- 8 | Soul Shards  ---
  ------------------------
  -- SoulShardsMax
  function Player:SoulShardsMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.SoulShardsMax then
        UnitInfo.SoulShardsMax = UnitPowerMax(self.UnitID, Enum.PowerType.SoulShards);
      end
      return UnitInfo.SoulShardsMax;
    end
  end
  -- SoulShards
  function Player:SoulShards ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.SoulShards then
        UnitInfo.SoulShards = UnitPower(self.UnitID, Enum.PowerType.SoulShards);
      end
      return UnitInfo.SoulShards;
    end
  end
  -- SoulShards.deficit
  function Player:SoulShardsDeficit ()
    return self:SoulShardsMax() - self:SoulShards();
  end  
  
  ------------------------
  --- 8 | Astral Power ---
  ------------------------
  -- astral_power.Max
  function Player:AstralPowerMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.AstralPowerMax then
        UnitInfo.AstralPowerMax = UnitPowerMax(self.UnitID, Enum.PowerType.LunarPower);
      end
      return UnitInfo.AstralPowerMax;
    end
  end
  -- astral_power
  function Player:AstralPower ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.AstralPower then
        UnitInfo.AstralPower = UnitPower(self.UnitID, Enum.PowerType.LunarPower);
      end
      return UnitInfo.AstralPower;
    end
  end
  -- astral_power.pct
  function Player:AstralPowerPercentage ()
    return (self:AstralPower() / self:AstralPowerMax()) * 100;
  end
  -- astral_power.deficit
  function Player:AstralPowerDeficit ()
    return self:AstralPowerMax() - self:AstralPower();
  end
  -- "astral_power.deficit.pct"
  function Player:AstralPowerDeficitPercentage ()
    return (self:AstralPowerDeficit() / self:AstralPowerMax()) * 100;
  end

  --------------------------------
  --- 9 | Holy Power Functions ---
  --------------------------------
  -- holy_power.max
  function Player:HolyPowerMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.HolyPowerMax then
        UnitInfo.HolyPowerMax = UnitPowerMax(self.UnitID, Enum.PowerType.HolyPower);
      end
      return UnitInfo.HolyPowerMax;
    end
  end
  -- holy_power
  function Player:HolyPower ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.HolyPower then
        UnitInfo.HolyPower = UnitPower(self.UnitID, Enum.PowerType.HolyPower);
      end
      return UnitInfo.HolyPower;
    end
  end
  -- holy_power.pct
  function Player:HolyPowerPercentage ()
    return (self:HolyPower() / self:HolyPowerMax()) * 100;
  end
  -- holy_power.deficit
  function Player:HolyPowerDeficit ()
    return self:HolyPowerMax() - self:HolyPower();
  end
  -- "holy_power.deficit.pct"
  function Player:HolyPowerDeficitPercentage ()
    return (self:HolyPowerDeficit() / self:HolyPowerMax()) * 100;
  end

  ------------------------------
  -- 11 | Maelstrom Functions --
  ------------------------------
  -- maelstrom.max
  function Player:MaelstromMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.MaelstromMax then
        UnitInfo.MaelstromMax = UnitPowerMax(self.UnitID, Enum.PowerType.Maelstrom);
      end
      return UnitInfo.MaelstromMax;
    end
  end
  -- maelstrom
  function Player:Maelstrom ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.Maelstrom then
        UnitInfo.Maelstrom = UnitPower(self.UnitID, Enum.PowerType.Maelstrom);
      end
      return UnitInfo.Maelstrom;
    end
  end
  -- maelstrom.pct
  function Player:MaelstromPercentage ()
    return (self:Maelstrom() / self:MaelstromMax()) * 100;
  end
  -- maelstrom.deficit
  function Player:MaelstromDeficit ()
    return self:MaelstromMax() - self:Maelstrom();
  end
  -- "maelstrom.deficit.pct"
  function Player:MaelstromDeficitPercentage ()
    return (self:MaelstromDeficit() / self:MaelstromMax()) * 100;
  end

  ------------------------------
  -- 13 | Insanity Functions ---
  ------------------------------
  -- insanity.max
  function Player:InsanityMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.InsanityMax then
        UnitInfo.InsanityMax = UnitPowerMax(self.UnitID, Enum.PowerType.Insanity);
      end
      return UnitInfo.InsanityMax;
    end
  end
  -- insanity
  function Player:Insanity ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.Insanity then
        UnitInfo.Insanity = UnitPower(self.UnitID, Enum.PowerType.Insanity);
      end
      return UnitInfo.Insanity;
    end
  end
  -- insanity.pct
  function Player:InsanityPercentage ()
    return (self:Insanity() / self:InsanityMax()) * 100;
  end
  -- insanity.deficit
  function Player:InsanityDeficit ()
    return self:InsanityMax() - self:Insanity();
  end
  -- "insanity.deficit.pct"
  function Player:InsanityDeficitPercentage ()
    return (self:InsanityDeficit() / self:InsanityMax()) * 100;
  end
  -- Insanity Drain
  function Player:Insanityrain ()
    --TODO : calculate insanitydrain
    return 1;
  end

  ---------------------------
  --- 17 | Fury Functions ---
  ---------------------------
  -- fury.max
  function Player:FuryMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.FuryMax then
        UnitInfo.FuryMax = UnitPowerMax(self.UnitID, Enum.PowerType.Fury);
      end
      return UnitInfo.FuryMax;
    end
  end
  -- fury
  function Player:Fury ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.Fury then
        UnitInfo.Fury = UnitPower(self.UnitID, Enum.PowerType.Fury);
      end
      return UnitInfo.Fury;
    end
  end
  -- fury.pct
  function Player:FuryPercentage ()
    return (self:Fury() / self:FuryMax()) * 100;
  end
  -- fury.deficit
  function Player:FuryDeficit ()
    return self:FuryMax() - self:Fury();
  end
  -- "fury.deficit.pct"
  function Player:FuryDeficitPercentage ()
    return (self:FuryDeficit() / self:FuryMax()) * 100;
  end

  ---------------------------
  --- 18 | Pain Functions ---
  ---------------------------
  -- pain.max
  function Player:PainMax ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.PainMax then
        UnitInfo.PainMax = UnitPowerMax(self.UnitID, Enum.PowerType.Pain);
      end
      return UnitInfo.PainMax;
    end
  end
  -- pain
  function Player:Pain ()
    local GUID = self:GUID()
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID] if not UnitInfo then UnitInfo = {} Cache.UnitInfo[GUID] = UnitInfo end
      if not UnitInfo.PainMax then
        UnitInfo.PainMax = UnitPower(self.UnitID, Enum.PowerType.Pain);
      end
      return UnitInfo.PainMax;
    end
  end
  -- pain.pct
  function Player:PainPercentage ()
    return (self:Pain() / self:PainMax()) * 100;
  end
  -- pain.deficit
  function Player:PainDeficit ()
    return self:PainMax() - self:Pain();
  end
  -- "pain.deficit.pct"
  function Player:PainDeficitPercentage ()
    return (self:PainDeficit() / self:PainMax()) * 100;
  end

  -- Get if the player is stealthed or not
  local IsStealthedBuff = {
    -- Normal Stealth
    {
      -- Rogue
      Spell(1784),    -- Stealth
      Spell(115191),  -- Stealth w/ Subterfuge Talent
      -- Feral
      Spell(5215)     -- Prowl
    },
    -- Combat Stealth
    {
      -- Rogue
      Spell(11327),   -- Vanish
      Spell(115193),  -- Vanish w/ Subterfuge Talent
      Spell(115192),  -- Subterfuge Buff
      Spell(185422)   -- Stealth from Shadow Dance
    },
    -- Special Stealth
    {
      -- Night Elf
      Spell(58984)    -- Shadowmeld
    }
  };
  function Player:IterateStealthBuffs (Abilities, Special, Duration)
    -- TODO: Add Assassination Spells when it'll be done and improve code
    -- TODO: Add Feral if we do supports it some day
    if  Spell.Rogue.Outlaw.Vanish:TimeSinceLastCast() < 0.3 or
      Spell.Rogue.Subtlety.ShadowDance:TimeSinceLastCast() < 0.3 or
      Spell.Rogue.Subtlety.Vanish:TimeSinceLastCast() < 0.3 or
      (Special and (
        Spell.Rogue.Outlaw.Shadowmeld:TimeSinceLastCast() < 0.3 or
        Spell.Rogue.Subtlety.Shadowmeld:TimeSinceLastCast() < 0.3
      ))
    then
      return Duration and 1 or true;
    end
    -- Normal Stealth
    for i = 1, #IsStealthedBuff[1] do
      if self:Buff(IsStealthedBuff[1][i]) then
        return Duration and (self:BuffRemains(IsStealthedBuff[1][i]) >= 0 and self:BuffRemains(IsStealthedBuff[1][i]) or 60) or true;
      end
    end
    -- Combat Stealth
    if Abilities then
      for i = 1, #IsStealthedBuff[2] do
        if self:Buff(IsStealthedBuff[2][i]) then
          return Duration and (self:BuffRemains(IsStealthedBuff[2][i]) >= 0 and self:BuffRemains(IsStealthedBuff[2][i]) or 60) or true;
        end
      end
    end
    -- Special Stealth
    if Special then
      for i = 1, #IsStealthedBuff[3] do
        if self:Buff(IsStealthedBuff[3][i]) then
          return Duration and (self:BuffRemains(IsStealthedBuff[3][i]) >= 0 and self:BuffRemains(IsStealthedBuff[3][i]) or 60) or true;
        end
      end
    end
    return false;
  end
  local IsStealthedKey;
  function Player:IsStealthed (Abilities, Special, Duration)
    IsStealthedKey = tostring(Abilites).."-"..tostring(Special).."-"..tostring(Duration);
    if not Cache.MiscInfo then Cache.MiscInfo = {}; end
    if not Cache.MiscInfo.IsStealthed then Cache.MiscInfo.IsStealthed = {}; end
    if Cache.MiscInfo.IsStealthed[IsStealthedKey] == nil then
      Cache.MiscInfo.IsStealthed[IsStealthedKey] = self:IterateStealthBuffs(Abilities, Special, Duration);
    end
    return Cache.MiscInfo.IsStealthed[IsStealthedKey];
  end
  function Player:IsStealthedRemains (Abilities, Special)
    return self:IsStealthed(Abilities, Special, true);
  end

  -- buff.bloodlust.up
  local HeroismBuff = {
    Spell(90355),  -- Ancient Hysteria
    Spell(2825),   -- Bloodlust
    Spell(32182),  -- Heroism
    Spell(160452), -- Netherwinds
    Spell(80353)   -- Time Warp
  };
  function Player:HasHeroism (Duration)
     for i = 1, #HeroismBuff do
       if self:Buff(HeroismBuff[i], nil, true) then
         return Duration and self:BuffRemains(HeroismBuff[i], true) or true;
       end
     end
     return false;
  end

  -- Save the current player's equipment.
  AC.Equipment = {};
  function AC.GetEquipment ()
    local Item;
    for i = 1, 19 do
      Item = select(1, GetInventoryItemID("Player", i));
      -- If there is an item in that slot
      if Item ~= nil then
        AC.Equipment[i] = Item;
      end
    end
  end

  -- Check player set bonuses (call AC.GetEquipment before to refresh the current gear)
  HasTierSets = {
    ["T18"] = {
      [0]  = function (Count) return Count > 1, Count > 3; end,                                       -- Return Function
      [1]  = {[5] = 124319, [10] = 124329, [1] = 124334, [7] = 124340, [3] = 124346},                 -- Warrior:      Chest, Hands, Head, Legs, Shoulder
      [2]  = {[5] = 124318, [10] = 124328, [1] = 124333, [7] = 124339, [3] = 124345},                 -- Paladin:      Chest, Hands, Head, Legs, Shoulder
      [3]  = {[5] = 124284, [10] = 124292, [1] = 124296, [7] = 124301, [3] = 124307},                 -- Hunter:       Chest, Hands, Head, Legs, Shoulder
      [4]  = {[5] = 124248, [10] = 124257, [1] = 124263, [7] = 124269, [3] = 124274},                 -- Rogue:        Chest, Hands, Head, Legs, Shoulder
      [5]  = {[5] = 124172, [10] = 124155, [1] = 124161, [7] = 124166, [3] = 124178},                 -- Priest:       Chest, Hands, Head, Legs, Shoulder
      [6]  = {[5] = 124317, [10] = 124327, [1] = 124332, [7] = 124338, [3] = 124344},                 -- Death Knight: Chest, Hands, Head, Legs, Shoulder
      [7]  = {[5] = 124303, [10] = 124293, [1] = 124297, [7] = 124302, [3] = 124308},                 -- Shaman:       Chest, Hands, Head, Legs, Shoulder
      [8]  = {[5] = 124171, [10] = 124154, [1] = 124160, [7] = 124165, [3] = 124177},                 -- Mage:         Chest, Hands, Head, Legs, Shoulder
      [9]  = {[5] = 124173, [10] = 124156, [1] = 124162, [7] = 124167, [3] = 124179},                 -- Warlock:      Chest, Hands, Head, Legs, Shoulder
      [10] = {[5] = 124247, [10] = 124256, [1] = 124262, [7] = 124268, [3] = 124273},                 -- Monk:         Chest, Hands, Head, Legs, Shoulder
      [11] = {[5] = 124246, [10] = 124255, [1] = 124261, [7] = 124267, [3] = 124272},                 -- Druid:        Chest, Hands, Head, Legs, Shoulder
      [12] = nil                                                                                      -- Demon Hunter: Chest, Hands, Head, Legs, Shoulder
    },
    ["T18_ClassTrinket"] = {
      [0]  = function (Count) return Count > 0; end,                                                  -- Return Function
      [1]  = {[13] = 124523, [14] = 124523},                                                          -- Warrior:      Worldbreaker's Resolve
      [2]  = {[13] = 124518, [14] = 124518},                                                          -- Paladin:      Libram of Vindication
      [3]  = {[13] = 124515, [14] = 124515},                                                          -- Hunter:       Talisman of the Master Tracker
      [4]  = {[13] = 124520, [14] = 124520},                                                          -- Rogue:        Bleeding Hollow Toxin Vessel
      [5]  = {[13] = 124519, [14] = 124519},                                                          -- Priest:       Repudiation of War
      [6]  = {[13] = 124513, [14] = 124513},                                                          -- Death Knight: Reaper's Harvest
      [7]  = {[13] = 124521, [14] = 124521},                                                          -- Shaman:       Core of the Primal Elements
      [8]  = {[13] = 124516, [14] = 124516},                                                          -- Mage:         Tome of Shifting Words
      [9]  = {[13] = 124522, [14] = 124522},                                                          -- Warlock:      Fragment of the Dark Star
      [10] = {[13] = 124517, [14] = 124517},                                                          -- Monk:         Sacred Draenic Incense
      [11] = {[13] = 124514, [14] = 124514},                                                          -- Druid:        Seed of Creation
      [12] = {[13] = 139630, [14] = 139630}                                                           -- Demon Hunter: Etching of Sargeras
    },
    ["T19"] = {
      [0]  = function (Count) return Count > 1, Count > 3; end,                                       -- Return Function
      [1]  = {[5] = 138351, [15] = 138374, [10] = 138354, [1] = 138357, [7] = 138360, [3] = 138363},  -- Warrior:      Chest, Back, Hands, Head, Legs, Shoulder
      [2]  = {[5] = 138350, [15] = 138369, [10] = 138353, [1] = 138356, [7] = 138359, [3] = 138362},  -- Paladin:      Chest, Back, Hands, Head, Legs, Shoulder
      [3]  = {[5] = 138339, [15] = 138368, [10] = 138340, [1] = 138342, [7] = 138344, [3] = 138347},  -- Hunter:       Chest, Back, Hands, Head, Legs, Shoulder
      [4]  = {[5] = 138326, [15] = 138371, [10] = 138329, [1] = 138332, [7] = 138335, [3] = 138338},  -- Rogue:        Chest, Back, Hands, Head, Legs, Shoulder
      [5]  = {[5] = 138319, [15] = 138370, [10] = 138310, [1] = 138313, [7] = 138316, [3] = 138322},  -- Priest:       Chest, Back, Hands, Head, Legs, Shoulder
      [6]  = {[5] = 138349, [15] = 138364, [10] = 138352, [1] = 138355, [7] = 138358, [3] = 138361},  -- Death Knight: Chest, Back, Hands, Head, Legs, Shoulder
      [7]  = {[5] = 138346, [15] = 138372, [10] = 138341, [1] = 138343, [7] = 138345, [3] = 138348},  -- Shaman:       Chest, Back, Hands, Head, Legs, Shoulder
      [8]  = {[5] = 138318, [15] = 138365, [10] = 138309, [1] = 138312, [7] = 138315, [3] = 138321},  -- Mage:         Chest, Back, Hands, Head, Legs, Shoulder
      [9]  = {[5] = 138320, [15] = 138373, [10] = 138311, [1] = 138314, [7] = 138317, [3] = 138323},  -- Warlock:      Chest, Back, Hands, Head, Legs, Shoulder
      [10] = {[5] = 138325, [15] = 138367, [10] = 138328, [1] = 138331, [7] = 138334, [3] = 138337},  -- Monk:         Chest, Back, Hands, Head, Legs, Shoulder
      [11] = {[5] = 138324, [15] = 138366, [10] = 138327, [1] = 138330, [7] = 138333, [3] = 138336},  -- Druid:        Chest, Back, Hands, Head, Legs, Shoulder
      [12] = {[5] = 138376, [15] = 138375, [10] = 138377, [1] = 138378, [7] = 138379, [3] = 138380}   -- Demon Hunter: Chest, Back, Hands, Head, Legs, Shoulder
    },
    ["T20"] = {
      [0]  = function (Count) return Count > 1, Count > 3; end,                                       -- Return Function
      [1]  = {[5] = 147187, [15] = 147188, [10] = 147189, [1] = 147190, [7] = 147191, [3] = 147192},  -- Warrior:      Chest, Back, Hands, Head, Legs, Shoulder
      [2]  = {[5] = 147157, [15] = 147158, [10] = 147159, [1] = 147160, [7] = 147161, [3] = 147162},  -- Paladin:      Chest, Back, Hands, Head, Legs, Shoulder
      [3]  = {[5] = 147139, [15] = 147140, [10] = 147141, [1] = 147142, [7] = 147143, [3] = 147144},  -- Hunter:       Chest, Back, Hands, Head, Legs, Shoulder
      [4]  = {[5] = 147169, [15] = 147170, [10] = 147171, [1] = 147172, [7] = 147173, [3] = 147174},  -- Rogue:        Chest, Back, Hands, Head, Legs, Shoulder
      [5]  = {[5] = 147167, [15] = 147163, [10] = 147164, [1] = 147165, [7] = 147166, [3] = 147168},  -- Priest:       Chest, Back, Hands, Head, Legs, Shoulder
      [6]  = {[5] = 147121, [15] = 147122, [10] = 147123, [1] = 147124, [7] = 147125, [3] = 147126},  -- Death Knight: Chest, Back, Hands, Head, Legs, Shoulder
      [7]  = {[5] = 147175, [15] = 147176, [10] = 147177, [1] = 147178, [7] = 147179, [3] = 147180},  -- Shaman:       Chest, Back, Hands, Head, Legs, Shoulder
      [8]  = {[5] = 147149, [15] = 147145, [10] = 147146, [1] = 147147, [7] = 147148, [3] = 147150},  -- Mage:         Chest, Back, Hands, Head, Legs, Shoulder
      [9]  = {[5] = 147185, [15] = 147181, [10] = 147182, [1] = 147183, [7] = 147184, [3] = 147186},  -- Warlock:      Chest, Back, Hands, Head, Legs, Shoulder
      [10] = {[5] = 147151, [15] = 147152, [10] = 147153, [1] = 147154, [7] = 147155, [3] = 147156},  -- Monk:         Chest, Back, Hands, Head, Legs, Shoulder
      [11] = {[5] = 147133, [15] = 147134, [10] = 147135, [1] = 147136, [7] = 147137, [3] = 147138},  -- Druid:        Chest, Back, Hands, Head, Legs, Shoulder
      [12] = {[5] = 147127, [15] = 147128, [10] = 147129, [1] = 147130, [7] = 147131, [3] = 147132}   -- Demon Hunter: Chest, Back, Hands, Head, Legs, Shoulder
    }
  };
  function AC.HasTier (Tier)
    -- Set Bonuses are disabled in Challenge Mode (Diff = 8) and in Proving Grounds (Map = 1148).
    local DifficultyID, _, _, _, _, MapID = select(3, GetInstanceInfo());
    if DifficultyID == 8 or MapID == 1148 then return false; end
    -- Check gear
    if HasTierSets[Tier][Cache.Persistent.Player.Class[3]] then
      local Count = 0;
      local Item;
      for Slot, ItemID in pairs(HasTierSets[Tier][Cache.Persistent.Player.Class[3]]) do
        Item = AC.Equipment[Slot];
        if Item and Item == ItemID then
          Count = Count + 1;
        end
      end
      return HasTierSets[Tier][0](Count);
    else
      return false;
    end
  end

  -- Mythic Dungeon Abilites
  local MDA = {
    PlayerBuff = {
    },
    PlayerDebuff = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Vault of the Wardens
          -- Inquisitor Tormentorum
          {Spell(200904), "Sapped Soul"}
    },
    EnemiesBuff = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Black Rook Hold
          -- Trashes
          {Spell(200291), "Blade Dance Buff"} -- Risen Scout
    },
    EnemiesCast = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Black Rook Hold
          -- Trashes
          {Spell(200291), "Blade Dance Cast"} -- Risen Scout
    },
    EnemiesDebuff = {
    }
  }
  function AC.MythicDungeon ()
    -- TODO: Optimize
    for Key, Value in pairs(MDA) do
      if Key == "PlayerBuff" then
        for i = 1, #Value do
          if Player:Buff(Value[i][1], nil, true) then
            return Value[i][2];
          end
        end
      elseif Key == "PlayerDebuff" then
        for i = 1, #Value do
          if Player:Debuff(Value[i][1], nil, true) then
            return Value[i][2];
          end
        end
      elseif Key == "EnemiesBuff" then

      elseif Key == "EnemiesCast" then

      elseif Key == "EnemiesDebuff" then

      end
    end
    return "";
  end
