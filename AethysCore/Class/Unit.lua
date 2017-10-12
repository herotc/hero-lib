--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Pet = Unit.Pet;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local mathfloor = math.floor;
  local mathmin = math.min;
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
  local Focus = Unit.Focus;
  local MouseOver = Unit.MouseOver;
  local BossUnits = Unit["Boss"];
  local NameplateUnits = Unit["Nameplate"];


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

  -- Get if we are in range of the unit.
  -- IsInRangeTable generated manually by FilterItemRange
  local IsInRangeTable = {
    Hostile = {
      RangeIndex = {"Melee", 5, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 100},
      ItemRange = {
        ['Melee'] = 37727,   -- Ruby Acorn
        [5]       = 37727,   -- Ruby Acorn
        [6]       = 63427,   -- Worgsaw
        [8]       = 34368,   -- Attuned Crystal Cores
        [10]      = 32321,   -- Sparrowhawk Net
        [15]      = 33069,   -- Sturdy Rope
        [20]      = 10645,   -- Gnomish Death Ray
        [25]      = 24268,   -- Netherweave Net
        [30]      = 34191,   -- Handful of Snowflakes
        [35]      = 18904,   -- Zorbin's Ultra-Shrinker
        [40]      = 28767,   -- The Decapitator
        [45]      = 23836,   -- Goblin Rocket Launcher
        [50]      = 116139,  -- Haunting Memento
        [60]      = 32825,   -- Soul Cannon
        [70]      = 41265,   -- Eyesore Blaster
        [80]      = 35278,   -- Reinforced Net
        [100]     = 33119    -- Malister's Frost Wand
      }
    },
    Friendly = {
      RangeIndex = {},
      ItemRange = {}
    }
  };
  -- Sort RangeIndex for FindRange
  tablesort(IsInRangeTable.Hostile.RangeIndex, AC.SortMixedASC);
  IsInRangeTable.Hostile.RangeIndex = AC.RevertTableIndex(IsInRangeTable.Hostile.RangeIndex);
  -- Run FilterItemRange() while standing at less than 1yds from an hostile target and the same for a friendly focus (easy with 2 players)
  function AC.ManuallyFilterItemRanges ()
    IsInRangeTable = {
      Hostile = {
        RangeIndex = {},
        ItemRange = {}
      },
      Friendly = {
        RangeIndex = {},
        ItemRange = {}
      }
    };
    -- Filter items that can only be casted on an unit. (i.e. blacklist ground targeted aoe items)
    local HostileTable, FriendlyTable = IsInRangeTable.Hostile, IsInRangeTable.Friendly;
    local TUnitID, FUnitID = Target.UnitID, Focus.UnitID;
    for Type, Ranges in pairs(AethysCore.Enum.ItemRangeUnfiltered) do
      for Range, Items in pairs(Ranges) do
        if Type == "Melee" and Range == 5 then
          Range = "Melee";
        end
        local ValidItems = {};
        for i = 1, #Items do
          local Item = Items[i];
          if IsItemInRange(Item, TUnitID) then
            if not HostileTable.ItemRange[Range] then
              HostileTable.ItemRange[Range] = {};
              tableinsert(HostileTable.RangeIndex, Range);
            end
            tableinsert(HostileTable.ItemRange[Range], Item);
          end
          if IsItemInRange(Item, FUnitID) then
            if not FriendlyTable.ItemRange[Range] then
              FriendlyTable.ItemRange[Range] = {};
              tableinsert(FriendlyTable.RangeIndex, Range);
            end
            tableinsert(FriendlyTable.ItemRange[Range], Item);
          end
        end
      end
    end
    AethysCoreDB = IsInRangeTable;
  end

  -- Get if the unit is in range, you can use a number or a spell as argument.
  function Unit:IsInRange (Distance, AoESpell)
    local GUID = self:GUID();
    if GUID then
      -- Regular ranged distance check through IsItemInRange & Special distance check (like melee)
      local DistanceType, Identifier, IsInRange = type(Distance), nil, nil;
      if DistanceType == "number" or (DistanceType == "string" and Distance == "Melee") then
        Identifier = Distance;
        local ItemRange = IsInRangeTable.Hostile.ItemRange;

        -- AoESpell Offset & Distance Fallback
        if DistanceType == "number" then
          -- AoESpell ignores Player CombatReach which is equals to 1.5yds
          if AoESpell then
            Distance = Distance - 1.5;
          end
          -- If the distance we wants to check doesn't exists, we look for a fallback.
          if not ItemRange[Distance] then
            local RangeIndex = IsInRangeTable.Hostile.RangeIndex;
            for i = 1, #RangeIndex do
              local Range = RangeIndex[i];
              if type(Range) == "number" and Range < Distance then
                Distance = Range;
                break;
              end
            end
            -- Test again in case we didn't found a new range
            if not ItemRange[Distance] then
              Distance = "Melee";
            end
          end
        end

        IsInRange = IsItemInRange(ItemRange[Distance], self.UnitID);
      -- Distance check through IsSpellInRange (works only for targeted spells only)
      elseif DistanceType == "table" then
        Identifier = tostring(Distance:ID());
        IsInRange = IsSpellInRange(Distance:Name(), self.UnitID) == 1;
      else
        error( "Invalid Distance." );
      end

      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      local UI_IsInRange = UnitInfo.IsInRange; if not UI_IsInRange then UI_IsInRange = {}; UnitInfo.IsInRange = UI_IsInRange; end
      if UI_IsInRange[Identifier] == nil then UI_IsInRange[Identifier] = IsInRange; end

      return IsInRange;
    end
    return nil;
  end

  --- Find Range mixin (used in xDistanceToPlayer)
  -- param Unit Object_Unit Unit to query on.
  -- param Max Boolean Min or Max range ?
  local function FindRange (Unit, Max)
    local RangeIndex = IsInRangeTable.Hostile.RangeIndex;
    for i = 1 + (Max and 1 or 0) , #RangeIndex do
      if not Unit:IsInRange(RangeIndex[i]) then
        return Max and RangeIndex[i-1] or RangeIndex[i];
      end
    end
    return 110;
  end

  -- Get the minimum distance to the player.
  function Unit:MinDistanceToPlayer ()
    return FindRange(self);
  end

  -- Get the maximum distance to the player.
  function Unit:MaxDistanceToPlayer ()
    return FindRange(self, true);
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

  -- Get all the casting infos from an unit and put it into the Cache.
  function Unit:GetCastingInfo ()
    local GUID = self:GUID();
    local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
    -- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID
    UnitInfo.Casting = {UnitCastingInfo(self.UnitID)};
  end

  -- Get the Casting Infos from the Cache.
  function Unit:CastingInfo (Index)
    local GUID = self:GUID();
    if GUID then
      if not Cache.UnitInfo[GUID] or not Cache.UnitInfo[GUID].Casting then
        self:GetCastingInfo();
      end
      local UnitInfo = Cache.UnitInfo[GUID]
      if Index then
        return UnitInfo.Casting[Index];
      else
        return unpack(UnitInfo.Casting);
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
    local GUID = self:GUID();
    local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
    UnitInfo.Channeling = {UnitChannelInfo(self.UnitID)};
  end

  -- Get the Channeling Infos from the Cache.
  function Unit:ChannelingInfo (Index)
    local GUID = self:GUID();
    if GUID then
      if not Cache.UnitInfo[GUID] or not Cache.UnitInfo[GUID].Channeling then
        self:GetChannelingInfo();
      end
      local UnitInfo = Cache.UnitInfo[GUID]
      if Index then
        return UnitInfo.Channeling[Index];
      else
        return unpack(UnitInfo.Channeling);
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
    local GUID = self:GUID();
    local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
    UnitInfo.Buffs = {};
    for i = 1, AC.MAXIMUM do
      --  1     2     3      4        5          6             7           8           9                   10              11         12            13           14               15           16       17      18      19
      -- name, rank, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
      local Infos = {UnitBuff(self.UnitID, i)};
      if not Infos[11] then break; end
      UnitInfo.Buffs[i] = Infos;
    end
  end

  -- buff.foo.up (does return the buff table and not only true/false)
  function Unit:Buff (Spell, Index, AnyCaster)
    local GUID = self:GUID();
    if GUID then
      if not Cache.UnitInfo[GUID] or not Cache.UnitInfo[GUID].Buffs then
        self:GetBuffs();
      end
      local UnitInfo = Cache.UnitInfo[GUID]
      for i = 1, #UnitInfo.Buffs do
        if Spell:ID() == UnitInfo.Buffs[i][11] then
          local Caster = UnitInfo.Buffs[i][8];
          if Caster == "player" then
            Caster = Unit[AC.UpperCaseFirst(Caster)];
          end
          if AnyCaster or (Caster and Player:IsUnit(Caster)) then
            if Index then
              return UnitInfo.Buffs[i][Index];
            else
              return unpack(UnitInfo.Buffs[i]);
            end
          end
        end
      end
    end
    return nil;
  end

  --[[*
    * @function Unit:BuffRemains
    * @desc Get the remaining time, if there is any, on a buff.
    * @simc buff.foo.remains
    *
    * @param {object} Spell - Spell to check.
    * @param {boolean} [AnyCaster] - Check from any caster ?
    * @param {string|number} [Offset] - The offset to apply, can be a string for a known method or directly the offset value in seconds.
    *
    * @returns {number}
    *]]
  function Unit:BuffRemains ( Spell, AnyCaster, Offset )
    local ExpirationTime = self:Buff( Spell, 7, AnyCaster );
    if ExpirationTime then
      if Offset then
        ExpirationTime = AC.OffsetRemains( ExpirationTime, Offset );
      end
      return ExpirationTime - AC.GetTime();
    else
      return 0;
    end
  end

  --[[*
    * @function Unit:BuffRemainsP
    * @override Unit:BuffRemains
    * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
    *
    * @param {string|number} [Offset="Auto"]
    *
    * @returns {number}
    *]]
  function Unit:BuffRemainsP ( Spell, AnyCaster, Offset )
    return self:BuffRemains( Spell, AnyCaster, Offset or "Auto" );
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
  function Unit:BuffRefreshable (Spell, PandemicThreshold, AnyCaster, Offset)
    if not self:Buff(Spell, nil, AnyCaster) then return true; end
    return PandemicThreshold and self:BuffRemains(Spell, AnyCaster, Offset) <= PandemicThreshold;
  end

  --[[*
    * @function Unit:BuffRefreshableP
    * @override Unit:BuffRefreshable
    * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
    *
    * @param {string|number} [Offset="Auto"]
    *
    * @returns {number}
    *]]
  function Unit:BuffRefreshableP ( Spell, PandemicThreshold, AnyCaster, Offset )
    return self:BuffRefreshable( Spell, PandemicThreshold, AnyCaster, Offset or "Auto" );
  end

  --- Get all the debuffs from an unit and put it into the Cache.
  function Unit:GetDebuffs ()
    local GUID = self:GUID();
    local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
    UnitInfo.Debuffs = {};
    for i = 1, AC.MAXIMUM do
      --  1     2     3      4         5          6             7          8           9                   10              11         12            13           14               15           16       17      18      19
      -- name, rank, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
      local Infos = {UnitDebuff(self.UnitID, i)};
      if not Infos[11] then break; end
      UnitInfo.Debuffs[i] = Infos;
    end
  end

  -- debuff.foo.up or dot.foo.up (does return the debuff table and not only true/false)
  function Unit:Debuff (Spell, Index, AnyCaster)
    local GUID = self:GUID();
    if GUID then
      if not Cache.UnitInfo[GUID] or not Cache.UnitInfo[GUID].Debuffs then
        self:GetDebuffs();
      end
      local UnitInfo = Cache.UnitInfo[GUID]
      for i = 1, #UnitInfo.Debuffs do
        if Spell:ID() == UnitInfo.Debuffs[i][11] then
          local Caster = UnitInfo.Debuffs[i][8];
          if Caster == "player" or Caster == "pet" then
            Caster = Unit[AC.UpperCaseFirst(Caster)];
          end
          if AnyCaster or (Caster and (Player:IsUnit(Caster) or Pet:IsUnit(Caster))) then
            if Index then
              return UnitInfo.Debuffs[i][Index];
            else
              return unpack(UnitInfo.Debuffs[i]);
            end
          end
        end
      end
    end
    return nil;
  end

  --[[*
    * @function Unit:DebuffRemains
    * @desc Get the remaining time, if there is any, on a debuff.
    * @simc debuff.foo.remains, dot.foo.remains
    *
    * @param {object} Spell - Spell to check.
    * @param {boolean} [AnyCaster] - Check from any caster ?
    * @param {string|number} [Offset] - The offset to apply, can be a string for a known method or directly the offset value in seconds.
    *
    * @returns {number}
    *]]
  function Unit:DebuffRemains ( Spell, AnyCaster, Offset )
    local ExpirationTime = self:Debuff( Spell, 7, AnyCaster );
    if ExpirationTime then
      if Offset then
        ExpirationTime = AC.OffsetRemains( ExpirationTime, Offset );
      end
      return ExpirationTime - AC.GetTime();
    else
      return 0;
    end
  end

  --[[*
    * @function Unit:DebuffRemainsP
    * @override Unit:DebuffRemains
    * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
    *
    * @param {string|number} [Offset="Auto"]
    *
    * @returns {number}
    *]]
  function Unit:DebuffRemainsP ( Spell, AnyCaster, Offset )
    return self:DebuffRemains( Spell, AnyCaster, Offset or "Auto" );
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
  function Unit:DebuffRefreshable (Spell, PandemicThreshold, AnyCaster, Offset)
    if not self:Debuff(Spell, nil, AnyCaster) then return true; end
    return PandemicThreshold and self:DebuffRemains(Spell, AnyCaster, Offset) <= PandemicThreshold;
  end

  --[[*
    * @function Unit:DebuffRefreshableP
    * @override Unit:DebuffRefreshable
    * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
    *
    * @param {string|number} [Offset="Auto"]
    *
    * @returns {number}
    *]]
  function Unit:DebuffRefreshableP ( Spell, PandemicThreshold, AnyCaster, Offset )
    return self:DebuffRefreshable( Spell, PandemicThreshold, AnyCaster, Offset or "Auto" );
  end

  -- Get the unit's power type
  function Unit:PowerType ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if not UnitInfo.PowerType then
        -- powerToken (ex: Enum.PowerType.Energy) when used for UnitPower function returns the powerType id (ex: 3), so we'll store the powerType id
        UnitInfo.PowerType = UnitPowerType(self.UnitID);
      end
      return UnitInfo.PowerType;
    end
  end

  -- power.max
  function Unit:PowerMax ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if not UnitInfo.PowerMax then
        UnitInfo.PowerMax = UnitPowerMax(self.UnitID, self:PowerType());
      end
      return UnitInfo.PowerMax;
    end
  end
  -- power
  function Unit:Power ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if not UnitInfo.Power then
        UnitInfo.Power = UnitPower(self.UnitID, self:PowerType());
      end
      return UnitInfo.Power;
    end
  end
  -- power.regen
  function Unit:PowerRegen ()
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if not UnitInfo.PowerRegen then
        UnitInfo.PowerRegen = select(2, GetPowerRegen(self.UnitID));
      end
      return UnitInfo.PowerRegen;
    end
  end
  -- power.pct
  function Unit:PowerPercentage ()
    return (self:Power() / self:PowerMax()) * 100;
  end
  -- power.deficit
  function Unit:PowerDeficit ()
    return self:PowerMax() - self:Power();
  end
  -- "power.deficit.pct"
  function Unit:PowerDeficitPercentage ()
    return (self:PowerDeficit() / self:PowerMax()) * 100;
  end
  -- "power.regen.pct"
  function Unit:PowerRegenPercentage ()
    return (self:PowerRegen() / self:PowerMax()) * 100;
  end
  -- power.time_to_max
  function Unit:PowerTimeToMax ()
    if self:PowerRegen() == 0 then return -1; end
    return self:PowerDeficit() / self:PowerRegen();
  end
  -- "power.time_to_x"
  function Unit:PowerTimeToX (Amount, Offset)
    if self:PowerRegen() == 0 then return -1; end
    return Amount > self:Power() and (Amount - self:Power()) / (self:PowerRegen() * (1 - (Offset or 0))) or 0;
  end
  -- "power.time_to_x.pct"
  function Unit:PowerTimeToXPercentage (Amount)
    if self:PowerRegen() == 0 then return -1; end
    return Amount > self:PowerPercentage() and (Amount - self:PowerPercentage()) / self:PowerRegenPercentage() or 0;
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
        [114881] = true
  }
  function Unit:IsBlacklisted ()
    local npcid = self:NPCID()
    if SpecialBlacklistData[npcid] then
      if type(SpecialBlacklistData[npcid]) == "boolean" then
        return true;
      else
        return SpecialBlacklistData[npcid](self);
      end
    end
    return false;
  end

  -- Check if the unit is coded as blacklisted by the user or not.
  function Unit:IsUserBlacklisted ()
    local npcid = self:NPCID()
    if AC.GUISettings.General.Blacklist.UserDefined[npcid] then
      if type(AC.GUISettings.General.Blacklist.UserDefined[npcid]) == "boolean" then
        return true;
      else
        return AC.GUISettings.General.Blacklist.UserDefined[npcid](self);
      end
    end
    return false;
  end

  -- Check if the unit is coded as blacklisted for cycling by the user or not.
  function Unit:IsUserCycleBlacklisted ()
    local npcid = self:NPCID()
    if AC.GUISettings.General.Blacklist.CycleUserDefined[npcid] then
      if type(AC.GUISettings.General.Blacklist.CycleUserDefined[npcid]) == "boolean" then
        return true;
      else
        return AC.GUISettings.General.Blacklist.CycleUserDefined[npcid](self);
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
    local npcid = self:NPCID()
    if SpecialMfdBlacklistData[npcid] then
      if type(SpecialMfdBlacklistData[npcid]) == "boolean" then
        return true;
      else
        return SpecialMfdBlacklistData[npcid](self);
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
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.IsStunned == nil then
        UnitInfo.IsStunned = self:IterateStunDebuffs();
      end
      return UnitInfo.IsStunned;
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
    local GUID = self:GUID();
    if GUID then
      local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
      if UnitInfo.IsStunnable == nil then
        UnitInfo.IsStunnable = IsStunnableClassification[self:Classification()];
      end
      return UnitInfo.IsStunnable;
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
      Cache = {}, -- A cache of unused { time, value } tables to reduce garbage due to table creation
      IterableUnits = {
        Target,
        Focus,
        MouseOver,
        unpack(AC.MergeTable(BossUnits, NameplateUnits))
      }; -- It's not possible to unpack multiple tables during the creation process, so we merge them before unpacking it (not efficient but done only 1 time)
      -- TODO: Improve IterableUnits creation
      Units = {}, -- Used to track units
      ExistingUnits = {}, -- Used to track GUIDs of currently existing units (to be compared with tracked units)
      Throttle = 0
    };
    local TTD = AC.TTD;
    function AC.TTDRefresh ()
      -- This may not be needed if we don't have any units but caching them in case
      -- We do speeds it all up a little bit
      local CurrentTime = AC.GetTime();
      local HistoryCount = TTD.Settings.HistoryCount;
      local HistoryTime = TTD.Settings.HistoryTime;
      local Cache = TTD.Cache;
      local IterableUnits = TTD.IterableUnits;
      local Units = TTD.Units;
      local ExistingUnits = TTD.ExistingUnits;

      wipe(ExistingUnits);

      local ThisUnit;
      for i = 1, #IterableUnits do
        ThisUnit = IterableUnits[i];
        if ThisUnit:Exists() then
          local GUID = ThisUnit:GUID();
          -- Check if we didn't already scanned this unit.
          if not ExistingUnits[GUID] then
            ExistingUnits[GUID] = true;
            local HealthPercentage = ThisUnit:HealthPercentage();
            -- Check if it's a valid unit
            if Player:CanAttack(ThisUnit) and HealthPercentage < 100 then
              local UnitTable = Units[GUID];
              -- Check if we have seen one time this unit, if we don't then initialize it.
              if not UnitTable or HealthPercentage > UnitTable[1][1][2] then
                UnitTable = {{}, CurrentTime};
                Units[GUID] = UnitTable;
              end
              local Values = UnitTable[1];
              local Time = CurrentTime - UnitTable[2];
              -- Check if the % HP changed since the last check (or if there were none)
              if not Values or HealthPercentage ~= Values[2] then
                local Value;
                local LastIndex = #Cache;
                -- Check if we can re-use a table from the cache
                if LastIndex == 0 then
                  Value = {Time, HealthPercentage};
                else
                  Value = Cache[LastIndex];
                  Cache[LastIndex] = nil;
                  Value[1] = Time;
                  Value[2] = HealthPercentage;
                end
                tableinsert(Values, 1, Value);
                local n = #Values;
                -- Delete values that are no longer valid
                while (n > HistoryCount) or (Time - Values[n][1] > HistoryTime) do
                  Cache[#Cache + 1] = Values[n];
                  Values[n] = nil;
                  n = n - 1;
                end
              end
            end
          end
        end
      end

      -- Not sure if it's even worth it to do this here
      -- Ideally this should be event driven or done at least once a second if not less
      for Key in pairs(Units) do
        if not ExistingUnits[Key] then
          Units[Key] = nil;
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
      --    25 : A Player
    function Unit:TimeToX (Percentage, MinSamples)
      if self:IsDummy() then return 6666; end
      if self:IsAPlayer() and Player:CanAttack(self) then return 25; end
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
            Seconds = (Percentage - a) / b;
            -- Subtract current time to obtain "time remaining"
            Seconds = mathmin(7777, Seconds - (AC.GetTime() - UnitTable[2]));
            if Seconds < 0 then Seconds = 9999; end
          end
        end
      end
      return Seconds;
    end

    -- Get the unit TTD Percentage
    local SpecialTTDPercentageData = {
      --- Legion
        ----- Open World  -----
        --- Stormheim Invasion (7.2 Patch)
          -- Lord Commander Alexius
          [118566] = 85,

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
          -- She looses 50% power per stage (100 -> 50 -> 0).
          [106643] = function (self) return (self:Power() > 0 and 10) or 0; end,

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
        local TTD = UnitInfo.TTD;
        if not TTD then TTD = {}; UnitInfo.TTD = TTD; end
        if not TTD[MinSamples] then
          TTD[MinSamples] = self:TimeToX(self:SpecialTTDPercentage(self:NPCID()), MinSamples);
        end
        return TTD[MinSamples];
      end
      return 11111;
    end

    -- Get if the unit meets the TimeToDie requirements.
    function Unit:FilteredTimeToDie (Operator, Value, Offset, ValueThreshold, MinSamples)
      local TTD = self:TimeToDie(MinSamples);
      return TTD < (ValueThreshold or 7777) and AC.CompareThis(Operator, TTD+(Offset or 0), Value) or false;
    end

    -- Get if the Time To Die is Valid for an Unit (i.e. not returning a warning code).
    function Unit:TimeToDieIsNotValid (MinSamples)
      return self:TimeToDie(MinSamples) >= 7777;
    end
