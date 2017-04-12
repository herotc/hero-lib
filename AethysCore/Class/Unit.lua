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
  local mathfloor = math.floor;
  local mathmin = math.min;
  local pairs = pairs;
  local select = select;
  local tableinsert = table.insert;
  local tableremove = table.remove;
  local tonumber = tonumber;
  local tostring = tostring;
  local type = type;
  local unpack = unpack;
  local wipe = table.wipe;
  -- File Locals
  local _T = {                  -- Temporary Vars
    Parts,                        -- NPCID
    ThisUnit,                     -- TTDRefresh
    Infos,                        -- GetBuffs / GetDebuffs
    ExpirationTime                -- BuffRemains / DebuffRemains
  };
  local BossUnits = Unit["Boss"];
  local NameplateUnits = Unit["Nameplate"];


--- ============================ CONTENT ============================
  -- Get the unit ID.
  function Unit:ID ()
    return self.UnitID;
  end

  -- Get the unit GUID.
  function Unit:GUID ()
    return Cache.Get("GUIDInfo."..self.UnitID)
        or Cache.Set("GUIDInfo."..self.UnitID, UnitGUID(self.UnitID));
  end

  -- Get if the unit Exists and is visible.
  function Unit:Exists ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].Exists == nil then
        Cache.UnitInfo[self:GUID()].Exists = UnitExists(self.UnitID) and UnitIsVisible(self.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].Exists;
    end
    return nil;
  end

  -- Get the unit NPC ID.
  function Unit:NPCID ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].NPCID then
        _T.Parts = {};
        for Part in string.gmatch(self:GUID(), "([^-]+)") do
          tableinsert(_T.Parts, Part);
        end
        if _T.Parts[1] == "Creature" or _T.Parts[1] == "Pet" or _T.Parts[1] == "Vehicle" then
          Cache.UnitInfo[self:GUID()].NPCID = tonumber(_T.Parts[6]);
        else
          Cache.UnitInfo[self:GUID()].NPCID = -2;
        end
      end
      return Cache.UnitInfo[self:GUID()].NPCID;
    end
    return -1;
  end

  -- Get the level of the unit
  function Unit:Level()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].UnitLevel == nil then
        Cache.UnitInfo[self:GUID()].UnitLevel = UnitLevel(self.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].UnitLevel;
    end
    return nil;
  end

  -- Get if an unit with a given NPC ID is in the Boss list and has less HP than the given ones.
  function Unit:IsInBossList (NPCID, HP)
    local ThisUnit;
    for i = 1, #BossUnits do
      ThisUnit = BossUnits[i];
      if ThisUnit:NPCID() == NPCID and ThisUnit:HealthPercentage() <= HP then
        return true;
      end
    end
    return false;
  end

  -- Get if the unit CanAttack the other one.
  function Unit:CanAttack (Other)
    if self:GUID() and Other:GUID() then
      return Cache.Get("UnitInfo."..self:GUID()..".CanAttack."..Other:GUID())
        or Cache.Set("UnitInfo."..self:GUID()..".CanAttack."..Other:GUID(), UnitCanAttack(self.UnitID, Other.UnitID));
    end
    return nil;
  end

  local DummyUnits = {
    [31146] = true,
    -- WoD Alliance Garrison
    [87317] = true, -- Mage Tower Damage Training Dummy
    [87318] = true, -- Alliance & Mage Tower Damage Dungeoneer's Training Dummy
    [87320] = true, -- Mage Tower Damage Raider's Training Dummy
    [88314] = true, -- Alliance Tanking Dungeoneer's Training Dummy
    [88316] = true, -- Alliance Healing Training Dummy ----> FRIENDLY
    -- Rogue Class Order Hall
    [92164] = true, -- Training Dummy
    [92165] = true, -- Dungeoneer's Training Dummy
    [92166] = true,  -- Raider's Training Dummy
	-- Priest Class Order Hall
	[107555] = true, -- Bound void Wraith
    [107556] = true, -- Bound void Walker
	-- Druid Class Order Hall
    [113964] = true, -- Raider's Training Dummy
    [113966] = true, -- Dungeoneer's Training Dummy
  };
  function Unit:IsDummy ()
    return self:NPCID() >= 0 and DummyUnits[self:NPCID()] == true;
  end

  -- Get the unit Health.
  function Unit:Health ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].Health then
        Cache.UnitInfo[self:GUID()].Health = UnitHealth(self.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].Health;
    end
    return -1;
  end

  -- Get the unit MaxHealth.
  function Unit:MaxHealth ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].MaxHealth then
        Cache.UnitInfo[self:GUID()].MaxHealth = UnitHealthMax(self.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].MaxHealth;
    end
    return -1;
  end

  -- Get the unit Health Percentage
  function Unit:HealthPercentage ()
    return self:Health() ~= -1 and self:MaxHealth() ~= -1 and self:Health()/self:MaxHealth()*100;
  end

  -- Get if the unit Is Dead Or Ghost.
  function Unit:IsDeadOrGhost ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].IsDeadOrGhost == nil then
        Cache.UnitInfo[self:GUID()].IsDeadOrGhost = UnitIsDeadOrGhost(self.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].IsDeadOrGhost;
    end
    return nil;
  end

  -- Get if the unit Affecting Combat.
  function Unit:AffectingCombat ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].AffectingCombat == nil then
        Cache.UnitInfo[self:GUID()].AffectingCombat = UnitAffectingCombat(self.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].AffectingCombat;
    end
    return nil;
  end

  -- Get if two unit are the same.
  function Unit:IsUnit (Other)
    if self:GUID() and Other:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].IsUnit then Cache.UnitInfo[self:GUID()].IsUnit = {}; end
      if Cache.UnitInfo[self:GUID()].IsUnit[Other:GUID()] == nil then
        Cache.UnitInfo[self:GUID()].IsUnit[Other:GUID()] = UnitIsUnit(self.UnitID, Other.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].IsUnit[Other:GUID()];
    end
    return nil;
  end

  -- Get unit classification
  function Unit:Classification ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].Classification == nil then
        Cache.UnitInfo[self:GUID()].Classification = UnitClassification(self.UnitID);
      end
      return Cache.UnitInfo[self:GUID()].Classification;
    end
    return "";
  end

  -- Get if we are in range of the unit.
  AC.IsInRangeItemTable = {
    [5]   = 37727,   -- Ruby Acorn
    [6]   = 63427,   -- Worgsaw
    [8]   = 34368,   -- Attuned Crystal Cores
    [10]  = 32321,   -- Sparrowhawk Net
    [15]  = 33069,   -- Sturdy Rope
    [20]  = 10645,   -- Gnomish Death Ray
    [25]  = 41509,   -- Frostweave Net
    [30]  = 34191,   -- Handful of Snowflakes
    [35]  = 18904,   -- Zorbin's Ultra-Shrinker
    [40]  = 28767,   -- The Decapitator
    [45]  = 23836,   -- Goblin Rocket Launcher
    [50]  = 116139,  -- Haunting Memento
    [60]  = 32825,   -- Soul Cannon
    [70]  = 41265,   -- Eyesore Blaster
    [80]  = 35278,   -- Reinforced Net
    [100] = 33119    -- Malister's Frost Wand
  };
  -- Get if the unit is in range, you can use a number or a spell as argument.
  function Unit:IsInRange (Distance)
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].IsInRange then Cache.UnitInfo[self:GUID()].IsInRange = {}; end
      if Cache.UnitInfo[self:GUID()].IsInRange[Distance] == nil then
        if type(Distance) == "number" then
          Cache.UnitInfo[self:GUID()].IsInRange[Distance] = IsItemInRange(AC.IsInRangeItemTable[Distance], self.UnitID) or false;
        else
          Cache.UnitInfo[self:GUID()].IsInRange[Distance] = IsSpellInRange(Distance:Name(), self.UnitID) or false;
        end
      end
      return Cache.UnitInfo[self:GUID()].IsInRange[Distance];
    end
    return nil;
  end

  -- Get if we are Tanking or not the Unit.
  -- TODO: Use both GUID like CanAttack / IsUnit for better management.
  function Unit:IsTanking (Other)
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].Tanked == nil then
        Cache.UnitInfo[self:GUID()].Tanked = UnitThreatSituation(self.UnitID, Other.UnitID) and UnitThreatSituation(self.UnitID, Other.UnitID) >= 2 and true or false;
      end
      return Cache.UnitInfo[self:GUID()].Tanked;
    end
    return nil;
  end

  -- Get all the casting infos from an unit and put it into the Cache.
  function Unit:GetCastingInfo ()
    if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
    -- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID
    Cache.UnitInfo[self:GUID()].Casting = {UnitCastingInfo(self.UnitID)};
  end

  -- Get the Casting Infos from the Cache.
  function Unit:CastingInfo (Index)
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] or not Cache.UnitInfo[self:GUID()].Casting then
        self:GetCastingInfo();
      end
      if Index then
        return Cache.UnitInfo[self:GUID()].Casting[Index];
      else
        return unpack(Cache.UnitInfo[self:GUID()].Casting);
      end
    end
    return nil;
  end

  -- Get if the unit is casting or not.
  function Unit:IsCasting ()
    return self:CastingInfo(1) and true or false;
  end

  -- Get the unit cast's name if there is any.
  function Unit:CastName ()
    return self:IsCasting() and self:CastingInfo(1) or "";
  end

  -- Get the unit cast's id if there is any.
  function Unit:CastID ()
    return self:IsCasting() and self:CastingInfo(10) or -1;
  end

  --- Get all the Channeling Infos from an unit and put it into the Cache.
  function Unit:GetChannelingInfo ()
    if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
    Cache.UnitInfo[self:GUID()].Channeling = {UnitChannelInfo(self.UnitID)};
  end

  -- Get the Channeling Infos from the Cache.
  function Unit:ChannelingInfo (Index)
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] or not Cache.UnitInfo[self:GUID()].Channeling then
        self:GetChannelingInfo();
      end
      if Index then
        return Cache.UnitInfo[self:GUID()].Channeling[Index];
      else
        return unpack(Cache.UnitInfo[self:GUID()].Channeling);
      end
    end
    return nil;
  end

  -- Get if the unit is xhanneling or not.
  function Unit:IsChanneling ()
    return self:ChannelingInfo(1) and true or false;
  end

  -- Get the unit channel's name if there is any.
  function Unit:ChannelName ()
    return self:IsChanneling() and self:ChannelingInfo(1) or "";
  end

  -- Get if the unit cast is interruptible if there is any.
  function Unit:IsInterruptible ()
    return (self:CastingInfo(9) == false or self:ChannelingInfo(8) == false) and true or false;
  end

  -- Get when the cast, if there is any, started (in seconds).
  function Unit:CastStart ()
    if self:IsCasting() then return self:CastingInfo(5)/1000; end
    if self:IsChanneling() then return self:ChannelingInfo(5)/1000; end
    return 0;
  end

  -- Get when the cast, if there is any, will end (in seconds).
  function Unit:CastEnd ()
    if self:IsCasting() then return self:CastingInfo(6)/1000; end
    if self:IsChanneling() then return self:ChannelingInfo(6)/1000; end
    return 0;
  end

  -- Get the full duration, in seconds, of the current cast, if there is any.
  function Unit:CastDuration ()
      return self:CastEnd() - self:CastStart();
  end

  -- Get the remaining cast time, if there is any.
  function Unit:CastRemains ()
    if self:IsCasting() or self:IsChanneling() then
      return self:CastEnd() - AC.GetTime();
    end
    return 0;
  end

  -- Get the progression of the cast in percentage if there is any.
  -- By default for channeling, it returns total - progress, if ReverseChannel is true it'll return only progress.
  function Unit:CastPercentage (ReverseChannel)
    if self:IsCasting() then
      return (AC.GetTime() - self:CastStart())/(self:CastEnd() - self:CastStart())*100;
    end
    if self:IsChanneling() then
      return ReverseChannel and (AC.GetTime() - self:CastStart())/(self:CastEnd() - self:CastStart())*100 or 100-(AC.GetTime() - self:CastStart())/(self:CastEnd() - self:CastStart())*100;
    end
    return 0;
  end

  --- Get all the buffs from an unit and put it into the Cache.
  function Unit:GetBuffs ()
    if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
    Cache.UnitInfo[self:GUID()].Buffs = {};
    for i = 1, AC.MAXIMUM do
      --     1      2    3       4         5         6             7           8           9                   10              11         12            13             14               15           16       17      18      19
      -- buffName, rank, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
      _T.Infos = {UnitBuff(self.UnitID, i)};
      if not _T.Infos[11] then break; end
      tableinsert(Cache.UnitInfo[self:GUID()].Buffs, _T.Infos);
    end
  end

  -- buff.foo.up (does return the buff table and not only true/false)
  function Unit:Buff (Spell, Index, AnyCaster)
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] or not Cache.UnitInfo[self:GUID()].Buffs then
        self:GetBuffs();
      end
      for i = 1, #Cache.UnitInfo[self:GUID()].Buffs do
        if Spell:ID() == Cache.UnitInfo[self:GUID()].Buffs[i][11] then
          if AnyCaster or (Cache.UnitInfo[self:GUID()].Buffs[i][8] and Player:IsUnit(Unit(Cache.UnitInfo[self:GUID()].Buffs[i][8]))) then
            if Index then
              return Cache.UnitInfo[self:GUID()].Buffs[i][Index];
            else
              return unpack(Cache.UnitInfo[self:GUID()].Buffs[i]);
            end
          end
        end
      end
    end
    return nil;
  end

  -- buff.foo.remains
  function Unit:BuffRemains (Spell, AnyCaster)
    _T.ExpirationTime = self:Buff(Spell, 7, AnyCaster);
    return _T.ExpirationTime and _T.ExpirationTime - AC.GetTime() or 0;
  end

  -- buff.foo.duration
  function Unit:BuffDuration (Spell, AnyCaster)
    return self:Buff(Spell, 6, AnyCaster) or 0;
  end

  -- buff.foo.stack
  function Unit:BuffStack (Spell, AnyCaster)
    return self:Buff(Spell, 4, AnyCaster) or 0;
  end

  -- buff.foo.refreshable (doesn't exists on SimC atm tho)
  function Unit:BuffRefreshable (Spell, PandemicThreshold, AnyCaster)
    if not self:Buff(Spell, nil, AnyCaster) then return true; end
    return PandemicThreshold and self:BuffRemains(Spell, AnyCaster) <= PandemicThreshold;
  end

  --- Get all the debuffs from an unit and put it into the Cache.
  function Unit:GetDebuffs ()
    if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
    Cache.UnitInfo[self:GUID()].Debuffs = {};
    for i = 1, AC.MAXIMUM do
      _T.Infos = {UnitDebuff(self.UnitID, i)};
      if not _T.Infos[11] then break; end
      tableinsert(Cache.UnitInfo[self:GUID()].Debuffs, _T.Infos);
    end
  end

  -- debuff.foo.up or dot.foo.up (does return the debuff table and not only true/false)
  function Unit:Debuff (Spell, Index, AnyCaster)
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] or not Cache.UnitInfo[self:GUID()].Debuffs then
        self:GetDebuffs();
      end
      for i = 1, #Cache.UnitInfo[self:GUID()].Debuffs do
        if Spell:ID() == Cache.UnitInfo[self:GUID()].Debuffs[i][11] then
          if AnyCaster or (Cache.UnitInfo[self:GUID()].Debuffs[i][8] and Player:IsUnit(Unit(Cache.UnitInfo[self:GUID()].Debuffs[i][8]))) then
            if Index then
              return Cache.UnitInfo[self:GUID()].Debuffs[i][Index];
            else
              return unpack(Cache.UnitInfo[self:GUID()].Debuffs[i]);
            end
          end
        end
      end
    end
    return nil;
  end

  -- debuff.foo.remains or dot.foo.remains
  function Unit:DebuffRemains (Spell, AnyCaster)
    _T.ExpirationTime = self:Debuff(Spell, 7, AnyCaster);
    return _T.ExpirationTime and _T.ExpirationTime - AC.GetTime() or 0;
  end

  -- debuff.foo.duration or dot.foo.duration
  function Unit:DebuffDuration (Spell, AnyCaster)
    return self:Debuff(Spell, 6, AnyCaster) or 0;
  end

  -- debuff.foo.stack or dot.foo.stack
  function Unit:DebuffStack (Spell, AnyCaster)
    return self:Debuff(Spell, 4, AnyCaster) or 0;
  end

  -- debuff.foo.refreshable or dot.foo.refreshable
  function Unit:DebuffRefreshable (Spell, PandemicThreshold, AnyCaster)
    if not self:Debuff(Spell, nil, AnyCaster) then return true; end
    return PandemicThreshold and self:DebuffRemains(Spell, AnyCaster) <= PandemicThreshold;
  end

  -- Check if the unit is coded as blacklisted or not.
  local SpecialBlacklistDataSpells = {
    D_DHT_Submerged = Spell(220519)
  }
  local SpecialBlacklistData = {
    --- Legion
      ----- Dungeons (7.0 Patch) -----
      --- Darkheart Thicket
        -- Strangling roots can't be hit while this buff is present
        [100991] = function (self) return self:Buff(SpecialBlacklistDataSpells.D_DHT_Submerged, nil, true); end,
      --- Mythic+ Affixes
        -- Fel Explosives (7.2 Patch)
        [120651] = true,
      ----- Trial of Valor (T19 - 7.1 Patch) -----
      --- Helya
        -- Striking Tentacle cannot be hit.
        [114881] = true,
	  ----- Class Order Hall -----
	  --- Druid
	  -- Raider's Training Dummy 
		[113964] = true
  }
  function Unit:IsBlacklisted ()
    if SpecialBlacklistData[self:NPCID()] then
      if type(SpecialBlacklistData[self:NPCID()]) == "boolean" then
        return true;
      else
        return SpecialBlacklistData[self:NPCID()](self);
      end
    end
    return false;
  end

  -- Check if the unit is coded as blacklisted by the user or not.
  function Unit:IsUserBlacklisted ()
    if AC.GUISettings.General.Blacklist.UserDefined[self:NPCID()] then
      if type(AC.GUISettings.General.Blacklist.UserDefined[self:NPCID()]) == "boolean" then
        return true;
      else
        return AC.GUISettings.General.Blacklist.UserDefined[self:NPCID()](self);
      end
    end
    return false;
  end

  -- Check if the unit is coded as blacklisted for cycling by the user or not.
  function Unit:IsUserCycleBlacklisted ()
    if AC.GUISettings.General.Blacklist.CycleUserDefined[self:NPCID()] then
      if type(AC.GUISettings.General.Blacklist.CycleUserDefined[self:NPCID()]) == "boolean" then
        return true;
      else
        return AC.GUISettings.General.Blacklist.CycleUserDefined[self:NPCID()](self);
      end
    end
    return false;
  end

  --- Check if the unit is coded as blacklisted for Marked for Death (Rogue) or not.
  -- Most of the time if the unit doesn't really die and isn't the last unit of an instance.
  local SpecialMfdBlacklistData = {
    --- Legion
      ----- Dungeons (7.0 Patch) -----
      --- Halls of Valor
        -- Hymdall leaves the fight at 10%.
        [94960] = true,
        -- Solsten and Olmyr doesn't "really" die
        [102558] = true,
        [97202] = true,
        -- Fenryr leaves the fight at 60%. We take 50% as check value since it doesn't get immune at 60%.
        [95674] = function (self) return self:HealthPercentage() > 50 and true or false; end,

      ----- Trial of Valor (T19 - 7.1 Patch) -----
      --- Odyn
        -- Hyrja & Hymdall leaves the fight at 25% during first stage and 85%/90% during second stage (HM/MM)
        [114360] = true,
        [114361] = true,

    --- Warlord of Draenor (WoD)
      ----- HellFire Citadel (T18 - 6.2 Patch) -----
      --- Hellfire Assault
        -- Mar'Tak doesn't die and leave fight at 50% (blocked at 1hp anyway).
        [93023] = true,

      ----- Dungeons (6.0 Patch) -----
      --- Shadowmoon Burial Grounds
        -- Carrion Worm : They doesn't die but leave the area at 10%.
        [88769] = true,
        [76057] = true
  };
  function Unit:IsMfdBlacklisted ()
    if SpecialMfdBlacklistData[self:NPCID()] then
      if type(SpecialMfdBlacklistData[self:NPCID()]) == "boolean" then
        return true;
      else
        return SpecialMfdBlacklistData[self:NPCID()](self);
      end
    end
    return false;
  end

  function Unit:IsFacingBlacklisted ()
    if self:IsUnit(AC.UnitNotInFront) and AC.GetTime()-AC.UnitNotInFrontTime <= Player:GCD()*AC.GUISettings.General.Blacklist.NotFacingExpireMultiplier then
      return true;
    end
    return false;
  end

  -- Get if the unit is stunned or not
  local IsStunnedDebuff = {
    -- Demon Hunter
    -- Druid
      -- General
      Spell(5211), -- Mighty Bash
      -- Feral
      Spell(203123), -- Maim
      Spell(163505), -- Rake
    -- Paladin
      -- General
      Spell(853), -- Hammer of Justice
      -- Retribution
      Spell(205290), -- Wake of Ashes
    -- Rogue
      -- General
      Spell(199804), -- Between the Eyes
      Spell(1833), -- Cheap Shot
      Spell(408), -- Kidney Shot
      Spell(196958), -- Strike from the Shadows
    -- Warrior
      -- General
      Spell(132168), -- Shockwave
      Spell(132169) -- Storm Bolt
  };
  function Unit:IterateStunDebuffs ()
    for i = 1, #IsStunnedDebuff[1] do
      if self:Debuff(IsStunnedDebuff[1][i], nil, true) then
        return true;
      end
    end
    return false;
  end
  function Unit:IsStunned ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].IsStunned == nil then
        Cache.UnitInfo[self:GUID()].IsStunned = self:IterateStunDebuffs();
      end
      return Cache.UnitInfo[self:GUID()].IsStunned;
    end
    return nil;
  end

  -- Get if an unit is not immune to stuns
  local IsStunnableClassification = {
    ["trivial"] = true,
    ["minus"] = true,
    ["normal"] = true,
    ["rare"] = true,
    ["rareelite"] = false,
    ["elite"] = false,
    ["worldboss"] = false,
    [""] = false
  };
  function Unit:IsStunnable ()
    -- TODO: Add DR Check
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if Cache.UnitInfo[self:GUID()].IsStunnable == nil then
        Cache.UnitInfo[self:GUID()].IsStunnable = IsStunnableClassification[self:Classification()];
      end
      return Cache.UnitInfo[self:GUID()].IsStunnable;
    end
    return nil;
  end

  -- Get if an unit can be stunned or not
  function Unit:CanBeStunned (IgnoreClassification)
    return (IgnoreClassification or self:IsStunnable()) and not self:IsStunned() or false;
  end

  --- TimeToDie
    AC.TTD = {
      Settings = {
        -- Refresh time (seconds) : min=0.1,  max=2,    default = 0.2,  Aethys = 0.1
        Refresh = 0.1,
        -- History time (seconds) : min=5,    max=120,  default = 20,   Aethys = 10+0.4
        HistoryTime = 10+0.4,
        -- Max history count :      min=20,   max=500,  default = 120,  Aethys = 100
        HistoryCount = 100
      },
      Units = {},
      Throttle = 0
    };
    local TTD = AC.TTD;
    local TTDCache = {}; -- a cache of unused { time, value } tables
    local ExistingUnits = {}; -- used to track guids of existing units
    function AC.TTDRefresh ()
      wipe(ExistingUnits);

      -- this may not be needed if we don't have any units but caching them in case
      -- we do speeds it all up a little bit
      local CurrentTime = AC.GetTime();
      local HistoryCount = TTD.Settings.HistoryCount;
      local HistoryTime = TTD.Settings.HistoryTime;

      local ThisUnit;
      for i = 1, #NameplateUnits do
        ThisUnit = NameplateUnits[i];
        if ThisUnit:Exists() then
          local GUID = ThisUnit:GUID();
          ExistingUnits[GUID] = true;

          local Health = ThisUnit:Health();
          if Player:CanAttack(ThisUnit) and Health < ThisUnit:MaxHealth() then
            local UnitTable = TTD.Units[GUID];
            if not UnitTable or Health > UnitTable[1][1][2] then
              UnitTable = {{}, ThisUnit:MaxHealth(), CurrentTime, -1};
              TTD.Units[GUID] = UnitTable;
            end

            local Values = UnitTable[1];
            local Time = CurrentTime - UnitTable[3];
            if Health ~= UnitTable[4] then
              -- we can optimize it even more by using a ring buffer for the values
              -- table, this way most of the operations will be simple arithmetic
              local Value;
              if #TTDCache == 0 then
                Value = {Time, Health};
              else
                Value = TTDCache[#TTDCache];
                TTDCache[#TTDCache] = nil;
                Value[1] = Time;
                Value[2] = Health;
              end
              tableinsert(Values, 1, Value);
              local n = #Values;
              while (n > HistoryCount) or (Time - Values[n][1] > HistoryTime) do
                TTDCache[#TTDCache + 1] = Values[n];
                Values[n] = nil;
                n = n - 1;
              end
              UnitTable[4] = Health;
            end
          end
        end
      end

      -- not sure if it's even worth it to do this here
      -- ideally this should be event driven or done at least once a second if not less
      for Key in pairs(TTD.Units) do
        if not ExistingUnits[Key] then
          TTD.Units[Key] = nil;
        end
      end
    end

    -- Get the estimated time to reach a Percentage
    -- TODO : Cache the result, not done yet since we mostly use TimeToDie that cache for TimeToX 0%.
    -- Returns Codes :
      -- 11111 : No GUID
      --  9999 : Negative TTD
      --  8888 : Not Enough Samples or No Health Change
      --  7777 : No DPS
      --  6666 : Dummy
    function Unit:TimeToX (Percentage, MinSamples)
      if self:IsDummy() then return 6666; end
      local Seconds = 8888;
      local UnitTable = TTD.Units[self:GUID()];
      -- Simple linear regression
      -- ( E(x^2)  E(x) )  ( a )  ( E(xy) )
      -- ( E(x)     n  )  ( b ) = ( E(y)  )
      -- Format of the above: ( 2x2 Matrix ) * ( 2x1 Vector ) = ( 2x1 Vector )
      -- Solve to find a and b, satisfying y = a + bx
      -- Matrix arithmetic has been expanded and solved to make the following operation as fast as possible
      if UnitTable then
        local Values = UnitTable[1];
        local n = #Values;
        if n > MinSamples then
          local a, b = 0, 0;
          local Ex2, Ex, Exy, Ey = 0, 0, 0, 0;

          local Value, x, y;
          for i = 1, n do
            Value = Values[i];
            x, y = Value[1], Value[2];

            Ex2 = Ex2 + x * x;
            Ex = Ex + x;
            Exy = Exy + x * y;
            Ey = Ey + y;
          end
          -- Invariant to find matrix inverse
          local Invariant = 1 / ( Ex2*n - Ex*Ex );
          -- Solve for a and b
          a = (-Ex * Exy * Invariant) + (Ex2 * Ey * Invariant);
          b = (n * Exy * Invariant) - (Ex * Ey * Invariant);
          if b ~= 0 then
            -- Use best fit line to calculate estimated time to reach target health
            Seconds = (Percentage * 0.01 * UnitTable[2] - a) / b;
            -- Subtract current time to obtain "time remaining"
            Seconds = mathmin(7777, Seconds - (AC.GetTime() - UnitTable[3]));
            if Seconds < 0 then Seconds = 9999; end
          end
        end
      end
      return mathfloor(Seconds);
    end

    -- Get the unit TTD Percentage
    local SpecialTTDPercentageData = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Halls of Valor
          -- Hymdall leaves the fight at 10%.
          [94960] = 10,
          -- Fenryr leaves the fight at 60%. We take 50% as check value since it doesn't get immune at 60%.
          [95674] = function (self) return (self:HealthPercentage() > 50 and 60) or 0 end,
          -- Odyn leaves the fight at 80%.
          [95676] = 80,
        --- Maw of Souls
          -- Helya leaves the fight at 70%.
          [96759] = 70,

        ----- Trial of Valor (T19 - 7.1 Patch) -----
        --- Odyn
          -- Hyrja & Hymdall leaves the fight at 25% during first stage and 85%/90% during second stage (HM/MM).
          -- TODO : Put GetInstanceInfo into PersistentCache.
          [114360] = function (self) return (not self:IsInBossList(114263, 99) and 25) or (select(3, GetInstanceInfo()) == 16 and 85) or 90; end,
          [114361] = function (self) return (not self:IsInBossList(114263, 99) and 25) or (select(3, GetInstanceInfo()) == 16 and 85) or 90; end,
          -- Odyn leaves the fight at 10%.
          [114263] = 10,
        ----- Nighthold (T19 - 7.1.5 Patch) -----
        --- Elisande
          -- She leaves the fight two times at 10% then she normally dies.
          -- TODO: Add check for Stage 1 & 2 only.
          [106643] = 10,

      --- Warlord of Draenor (WoD)
        ----- HellFire Citadel (T18 - 6.2 Patch) -----
        --- Hellfire Assault
          -- Mar'Tak doesn't die and leave fight at 50% (blocked at 1hp anyway).
          [93023] = 50,

        ----- Dungeons (6.0 Patch) -----
        --- Shadowmoon Burial Grounds
          -- Carrion Worm : They doesn't die but leave the area at 10%.
          [88769] = 10,
          [76057] = 10
    };
    function Unit:SpecialTTDPercentage (NPCID)
      if SpecialTTDPercentageData[NPCID] then
        if type(SpecialTTDPercentageData[NPCID]) == "number" then
          return SpecialTTDPercentageData[NPCID];
        else
          return SpecialTTDPercentageData[NPCID](self);
        end
      end
      return 0;
    end

    -- Get the unit TimeToDie
    function Unit:TimeToDie (MinSamples)
      local GUID = self:GUID();
      if GUID then
        local MinSamples = MinSamples or 3;
        local UnitInfo = Cache.UnitInfo[GUID];
        if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
        if not UnitInfo.TTD then UnitInfo.TTD = {}; end
        if not UnitInfo.TTD[MinSamples] then
          UnitInfo.TTD[MinSamples] = self:TimeToX(self:SpecialTTDPercentage(self:NPCID()), MinSamples);
        end
        return UnitInfo.TTD[MinSamples];
      end
      return 11111;
    end

    -- Get if the unit meets the TimeToDie requirements.
    function Unit:FilteredTimeToDie (Operator, Value, Offset, ValueThreshold, MinSamples)
      local TTD = self:TimeToDie(MinSamples);
      return TTD < (ValueThreshold or 7777) and AC.CompareThis (Operator, TTD, Value+(Offset or 0)) or false;
    end
