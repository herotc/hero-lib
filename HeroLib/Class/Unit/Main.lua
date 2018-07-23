--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, HL = ...;
  -- HeroLib
  local Cache, Utils = HeroCache, HL.Utils;
  local Unit = HL.Unit;
  local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target;
  local Focus, MouseOver = Unit.Focus, Unit.MouseOver;
  local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate;
  local Party, Raid = Unit.Party, Unit.Raid;
  local Spell = HL.Spell;
  local Item = HL.Item;
  -- Lua
  local tonumber = tonumber;
  -- File Locals



--- ============================ CONTENT ============================
  -- Get the unit ID.
  function Unit:ID ()
    return self.UnitID;
  end

  -- Get the unit GUID.
  do
    -- guid
    local UnitGUID = UnitGUID;
    function Unit:GUID ()
      return UnitGUID(self.UnitID);
    end
  end

  -- Get the unit Name.
  do
    -- name
    local UnitName = UnitName;
    function Unit:Name ()
      return UnitName(self.UnitID);
    end
  end

  -- Get if the unit Exists and is visible.
  function Unit:Exists ()
    return UnitExists(self.UnitID) and UnitIsVisible(self.UnitID);
  end

  -- Get the unit NPC ID.
  function Unit:NPCID ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID];
      if not UnitInfo then
        UnitInfo = {};
        Cache.UnitInfo[GUID] = UnitInfo;
      end
      if not UnitInfo.NPCID then
        local type, _, _, _, _, npcid = strsplit('-', GUID);
        if type == "Creature" or type == "Pet" or type == "Vehicle" then
          UnitInfo.NPCID = tonumber(npcid);
        else
          UnitInfo.NPCID = -2;
        end
      end
      return UnitInfo.NPCID;
    end
    return -1;
  end

  -- Get the level of the unit
  function Unit:Level()
    return UnitLevel(self.UnitID);
  end

  -- Get if an unit with a given NPC ID is in the Boss list and has less HP than the given ones.
  function Unit:IsInBossList (NPCID, HP)
    local NPCID = NPCID or self:NPCID();
    local HP = HP or 100;
    local ThisUnit;
    for i = 1, #Boss do
      ThisUnit = Boss[i];
      if ThisUnit:NPCID() == NPCID and ThisUnit:HealthPercentage() <= HP then
        return true;
      end
    end
    return false;
  end

  -- Get if the unit CanAttack the other one.
  do
    -- canAttack
    local UnitCanAttack = UnitCanAttack;
    function Unit:CanAttack (Other)
      return UnitCanAttack(self.UnitID, Other.UnitID);
    end
  end

  local DummyUnits = {
    -- City (SW, Orgri, ...)
    [31146] = true, -- Raider's Training Dummy
    [46647] = true, -- Training Dummy
    -- WoD Alliance Garrison
    [87317] = true, -- Mage Tower Damage Training Dummy
    [87318] = true, -- Mage Tower Damage Dungeoneer's Training Dummy (& Garrison)
    [87320] = true, -- Mage Tower Damage Raider's Training Dummy
    [88314] = true, -- Tanking Dungeoneer's Training Dummy
    [88316] = true, -- Healing Training Dummy ----> FRIENDLY
    -- WoD Horde Garrison
    [87760] = true, -- Mage Tower Damage Training Dummy
    [87761] = true, -- Mage Tower Damage Dungeoneer's Training Dummy (& Garrison)
    [87762] = true, -- Mage Tower Damage Raider's Training Dummy
    [88288] = true, -- Tanking Dungeoneer's Training Dummy
    [88289] = true, -- Healing Training Dummy ----> FRIENDLY
    -- Rogue Class Order Hall
    [92164] = true, -- Training Dummy
    [92165] = true, -- Dungeoneer's Training Dummy
    [92166] = true, -- Raider's Training Dummy
    -- Priest Class Order Hall
    [107555] = true, -- Bound void Wraith
    [107556] = true, -- Bound void Walker
    -- Druid Class Order Hall
    [113964] = true, -- Raider's Training Dummy
    [113966] = true, -- Dungeoneer's Training Dummy
    -- Warlock Class Order Hall
    [102052] = true, -- Rebellious imp
    [102048] = true, -- Rebellious Felguard
    [102045] = true, -- Rebellious WrathGuard
    [101956] = true, -- Rebellious Fel Lord
    -- Mage Class Order Hall
    [103397] = true, -- Greater Bullwark Construct
    [103404] = true, -- Bullwark Construct
    [103402] = true -- Lesser Bullwark Construct
  };
  function Unit:IsDummy ()
    local NPCID = self:NPCID()
    return NPCID >= 0 and DummyUnits[NPCID] == true;
  end

  -- Get if the unit is a Player or not.
  do
    -- isPlayer
    local UnitIsPlayer = UnitIsPlayer;
    function Unit:IsAPlayer ()
      return UnitIsPlayer(self.UnitID);
    end
  end

  -- Get the unit Health.
  function Unit:Health ()
    return UnitHealth(self.UnitID) or -1;
  end

  -- Get the unit MaxHealth.
  function Unit:MaxHealth ()
    return UnitHealthMax(self.UnitID) or -1;
  end

  -- Get the unit Health Percentage
  function Unit:HealthPercentage ()
    return self:Health() ~= -1 and self:MaxHealth() ~= -1 and self:Health()/self:MaxHealth()*100;
  end

  -- Get if the unit Is Dead Or Ghost.
  function Unit:IsDeadOrGhost ()
    return UnitIsDeadOrGhost(self.UnitID);
  end

  -- Get if the unit Affecting Combat.
  function Unit:AffectingCombat ()
    return UnitAffectingCombat(self.UnitID);
  end

  -- Get if two unit are the same.
  function Unit:IsUnit (Other)
    return UnitIsUnit(self.UnitID, Other.UnitID);
  end

  -- Get unit classification
  function Unit:Classification ()
    return UnitClassification(self.UnitID) or "";
  end

  -- Get if we are Tanking or not the Unit.
  function Unit:IsTanking (Other, ThreatThreshold)
    local ThreatThreshold = ThreatThreshold or 2;
    local ThreatSituation = UnitThreatSituation(self.UnitID, Other.UnitID);
    return ThreatSituation and ThreatSituation >= ThreatThreshold or false;
  end

  function Unit:IsTankingAoE (Radius, ThreatSituation)
    local Radius = Radius or 8;
    HL.GetEnemies(Radius, true);
    local IsTankingAOE = false;
    for _, Unit in pairs(Cache.Enemies[Radius]) do
      if self:IsTanking(Unit, ThreatSituation) then
        IsTankingAOE = true;
      end
    end
    return IsTankingAOE;
  end

  -- Get if the unit is moving or not.
  do
    -- speed, groundSpeed, flightSpeed, swimSpeed
    local GetUnitSpeed = GetUnitSpeed;
    function Unit:IsMoving ()
      return GetUnitSpeed(self.UnitID) ~= 0;
    end
  end
