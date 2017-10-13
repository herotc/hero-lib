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
  local mathfloor = math.floor;
  local mathmin = math.min;
  local mathrandom = math.random;
  local pairs = pairs;
  local select = select;
  local tableinsert = table.insert;
  local tableremove = table.remove;
  local tablesort = table.sort;
  local tonumber = tonumber;
  local tostring = tostring;
  local type = type;
  local unpack = unpack;
  local wipe = table.wipe;
  -- File Locals
  local BossUnits = Unit.Boss;


--- ============================ CONTENT ============================
  -- Get the unit ID.
  function Unit:ID ()
    return self.UnitID;
  end

  -- Get the unit GUID.
  function Unit:GUID ()
    return Cache.Get("GUIDInfo", self.UnitID,
                    function() return UnitGUID(self.UnitID); end);
  end

  -- Get the unit Name.
  function Unit:Name ()
    local GUID = self:GUID();
    if GUID then
      return Cache.Get("UnitInfo", GUID, "Name",
                      function() return UnitName(self.UnitID); end);
    end
    return nil;
  end

  -- Get if the unit Exists and is visible.
  function Unit:Exists ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.Exists == nil then
        UnitInfo.Exists = UnitExists(self.UnitID) and UnitIsVisible(self.UnitID);
      end
      return UnitInfo.Exists;
    end
    return nil;
  end

  -- Get the unit NPC ID.
  function Unit:NPCID ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
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
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.UnitLevel == nil then
        UnitInfo.UnitLevel = UnitLevel(self.UnitID);
      end
      return UnitInfo.UnitLevel;
    end
    return nil;
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
  function Unit:CanAttack (Other)
    if self:GUID() and Other:GUID() then
      return Cache.Get("UnitInfo", self:GUID(), "CanAttack", Other:GUID(),
                      function() return UnitCanAttack(self.UnitID, Other.UnitID) end);
    end
    return nil;
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
    [101956] = true -- Rebellious Fel Lord
  };
  function Unit:IsDummy ()
    local npcid = self:NPCID()
    return npcid >= 0 and DummyUnits[npcid] == true;
  end

  -- Get if the unit is a Player or not.
  function Unit:IsAPlayer ()
    if self:GUID() then
      return Cache.Get("UnitInfo", self:GUID(), "IsAPlayer",
                      function() return UnitIsPlayer(self.UnitID) end);
    end
    return nil;
  end

  -- Get the unit Health.
  function Unit:Health ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if not UnitInfo.Health then
        UnitInfo.Health = UnitHealth(self.UnitID);
      end
      return UnitInfo.Health;
    end
    return -1;
  end

  -- Get the unit MaxHealth.
  function Unit:MaxHealth ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if not UnitInfo.MaxHealth then
        UnitInfo.MaxHealth = UnitHealthMax(self.UnitID);
      end
      return UnitInfo.MaxHealth;
    end
    return -1;
  end

  -- Get the unit Health Percentage
  function Unit:HealthPercentage ()
    return self:Health() ~= -1 and self:MaxHealth() ~= -1 and self:Health()/self:MaxHealth()*100;
  end

  -- Get if the unit Is Dead Or Ghost.
  function Unit:IsDeadOrGhost ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.IsDeadOrGhost == nil then
        UnitInfo.IsDeadOrGhost = UnitIsDeadOrGhost(self.UnitID);
      end
      return UnitInfo.IsDeadOrGhost;
    end
    return nil;
  end

  -- Get if the unit Affecting Combat.
  function Unit:AffectingCombat ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.AffectingCombat == nil then
        UnitInfo.AffectingCombat = UnitAffectingCombat(self.UnitID);
      end
      return UnitInfo.AffectingCombat;
    end
    return nil;
  end

  -- Get if two unit are the same.
  function Unit:IsUnit (Other)
    local GUID = self:GUID();
    local OtherGUID = Other:GUID();
    if GUID and OtherGUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if not UnitInfo.IsUnit then UnitInfo.IsUnit = {}; end
      if UnitInfo.IsUnit[OtherGUID] == nil then
        UnitInfo.IsUnit[OtherGUID] = UnitIsUnit(self.UnitID, Other.UnitID);
      end
      return UnitInfo.IsUnit[OtherGUID];
    end
    return nil;
  end

  -- Get unit classification
  function Unit:Classification ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.Classification == nil then
        UnitInfo.Classification = UnitClassification(self.UnitID);
      end
      return UnitInfo.Classification;
    end
    return "";
  end

  -- Get if we are Tanking or not the Unit.
  -- TODO: Use both GUID like CanAttack / IsUnit for better management.
  function Unit:IsTanking (Other)
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.Tanked == nil then
        local Situation = UnitThreatSituation(self.UnitID, Other.UnitID);
        UnitInfo.Tanked = Situation and Situation >= 2 and true or false;
      end
      return UnitInfo.Tanked;
    end
    return nil;
  end

  -- Get if the unit is moving or not.
  function Unit:IsMoving()
    return Cache.Get("UnitInfo", self:GUID(), "IsMoving",
                       function() return GetUnitSpeed(self.UnitID) ~= 0; end)
  end
