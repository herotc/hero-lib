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
  local error = error;
  local mathmax = math.max;
  local pairs = pairs;
  local print = print;
  local select = select;
  local tableinsert = table.insert;
  local tostring = tostring;
  local unpack = unpack;
  local wipe = table.wipe;
  -- File Locals


--- ============================ CONTENT ============================
  -- Get the spell ID.
  function Spell:ID ()
    return self.SpellID;
  end

  -- Get the spell Type.
  function Spell:Type ()
    return self.SpellType;
  end

  -- Get the Time since Last spell Cast.
  function Spell:TimeSinceLastCast ()
    return AC.GetTime() - self.LastCastTime;
  end

  -- Get the Time since Last spell Display.
  function Spell:TimeSinceLastDisplay ()
    return AC.GetTime() - self.LastDisplayTime;
  end
  
  -- Get the Time since Last Buff applied.
  function Spell:TimeSinceLastBuff ()
    return AC.GetTime() - self.LastBuffTime;
  end

  -- Register the spell damage formula.
  function Spell:RegisterDamage (Function)
    self.DamageFormula = Function;
  end

  -- Get the spell damage formula if it exists.
  function Spell:Damage ()
    return self.DamageFormula and self.DamageFormula() or 0;
  end

  --- WoW Specific Function
    -- Get the spell Info.
    function Spell:Info (Type, Index)
      local Identifier;
      if Type == "ID" then
        Identifier = self:ID();
      elseif Type == "Name" then
        Identifier = self:Name();
      else
        error("Spell Info Type Missing.");
      end
      if Identifier then
        if not Cache.SpellInfo[Identifier] then Cache.SpellInfo[Identifier] = {}; end
        if not Cache.SpellInfo[Identifier].Info then
          Cache.SpellInfo[Identifier].Info = {GetSpellInfo(Identifier)};
        end
        if Index then
          return Cache.SpellInfo[Identifier].Info[Index];
        else
          return unpack(Cache.SpellInfo[Identifier].Info);
        end
      else
        error("Identifier Not Found.");
      end
    end

    -- Get the spell Info from the spell ID.
    function Spell:InfoID (Index)
      return self:Info("ID", Index);
    end

    -- Get the spell Info from the spell Name.
    function Spell:InfoName (Index)
      return self:Info("Name", Index);
    end

    -- Get the spell Name.
    function Spell:Name ()
      return self:Info("ID", 1);
    end

    -- Get the spell BookIndex along with BookType.
    function Spell:BookIndex ()
      local CurrentSpellID;
      -- Pet Book
      local NumPetSpells = HasPetSpells();
      if NumPetSpells then
        for i = 1, NumPetSpells do
          CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET));
          if CurrentSpellID and CurrentSpellID == self:ID() then
            return i, BOOKTYPE_PET;
          end
        end
      end
      -- Player Book
      local Offset, NumSpells, OffSpec;
      for i = 1, GetNumSpellTabs() do
        Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i));
        -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
        -- If the OffSpec ID is set to 0, then it's the Main Spec.
        if OffSpec == 0 then
          for j = 1, (Offset + NumSpells) do
            CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL));
            if CurrentSpellID and CurrentSpellID == self:ID() then
              return j, BOOKTYPE_SPELL;
            end
          end
        end
      end
    end

    -- Check if the spell Is Available or not.
    function Spell:IsAvailable (CheckPet)
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if Cache.SpellInfo[self.SpellID].IsAvailable == nil then
		if CheckPet == true then
			Cache.SpellInfo[self.SpellID].IsAvailable = IsSpellKnown(self.SpellID, true );
		else
			Cache.SpellInfo[self.SpellID].IsAvailable = IsPlayerSpell(self.SpellID);
		end
      end
      return Cache.SpellInfo[self.SpellID].IsAvailable;
    end

    -- Check if the spell Is Known or not.
    function Spell:IsKnown (CheckPet)
      return IsSpellKnown(self.SpellID, CheckPet and CheckPet or false); 
    end

    -- Check if the spell Is Known (including Pet) or not.
    function Spell:IsPetKnown ()
      return self:IsKnown(true);
    end

    -- Check if the spell Is Usable or not.
    function Spell:IsUsable ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if Cache.SpellInfo[self.SpellID].IsUsable == nil then
        Cache.SpellInfo[self.SpellID].IsUsable = IsUsableSpell(self.SpellID);
      end
      return Cache.SpellInfo[self.SpellID].IsUsable;
    end

    -- Get the spell Minimum Range.
    function Spell:MinimumRange ()
      return self:InfoID(5);
    end

    -- Get the spell Maximum Range.
    function Spell:MaximumRange ()
      return self:InfoID(6);
    end

    -- Check if the spell Is Melee or not.
    function Spell:IsMelee ()
      return self:MinimumRange() == 0 and self:MaximumRange() == 0;
    end

    -- Scan the Book to cache every Spell Learned.
    function Spell:BookScan (BlankScan)
      local CurrentSpellID, CurrentSpell;
      -- Pet Book
      local NumPetSpells = HasPetSpells();
      if NumPetSpells then
        for i = 1, NumPetSpells do
          CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET))
          if CurrentSpellID then
            CurrentSpell = Spell(CurrentSpellID, "Pet");
            if CurrentSpell:IsAvailable(true) and (CurrentSpell:IsKnown( true ) or IsTalentSpell(i, BOOKTYPE_PET)) then
              if not BlankScan then
                Cache.Persistent.SpellLearned.Pet[CurrentSpell:ID()] = true;
              end
            end
          end
        end
      end
      -- Player Book (except Flyout Spells)
      local Offset, NumSpells, OffSpec;
      for i = 1, GetNumSpellTabs() do
        Offset, NumSpells, _, OffSpec = select(3, GetSpellTabInfo(i));
        -- GetSpellTabInfo has been updated, it now returns the OffSpec ID.
        -- If the OffSpec ID is set to 0, then it's the Main Spec.
        if OffSpec == 0 then
          for j = 1, (Offset + NumSpells) do
            CurrentSpellID = select(7, GetSpellInfo(j, BOOKTYPE_SPELL))
            if CurrentSpellID and GetSpellBookItemInfo(j, BOOKTYPE_SPELL) == "SPELL" then
              --[[ Debug Code
              CurrentSpell = Spell(CurrentSpellID);
              print(
                tostring(CurrentSpell:ID()) .. " | " .. 
                tostring(CurrentSpell:Name()) .. " | " .. 
                tostring(CurrentSpell:IsAvailable()) .. " | " .. 
                tostring(CurrentSpell:IsKnown()) .. " | " .. 
                tostring(IsTalentSpell(j, BOOKTYPE_SPELL)) .. " | " .. 
                tostring(GetSpellBookItemInfo(j, BOOKTYPE_SPELL)) .. " | " .. 
                tostring(GetSpellLevelLearned(CurrentSpell:ID()))
              );
              ]]
              if not BlankScan then
                Cache.Persistent.SpellLearned.Player[CurrentSpellID] = true;
              end
            end
          end
        end
      end
      -- Flyout Spells
      local FlyoutID, NumSlots, IsKnown, IsKnownSpell;
      for i = 1, GetNumFlyouts() do
        FlyoutID = GetFlyoutID(i);
        NumSlots, IsKnown = select(3, GetFlyoutInfo(FlyoutID));
        if IsKnown and NumSlots > 0 then
          for j = 1, NumSlots do
            CurrentSpellID, _, IsKnownSpell = GetFlyoutSlotInfo(FlyoutID, j);
            if CurrentSpellID and IsKnownSpell then
              Cache.Persistent.SpellLearned.Player[CurrentSpellID] = true;
            end
          end
        end
      end
    end

    -- Check if the spell is in the Spell Learned Cache.
    function Spell:IsLearned ()
      return Cache.Persistent.SpellLearned[self:Type()][self:ID()] or false;
    end

    --[[*
      * @function Spell:IsCastable
      * @desc Check if the spell Is Castable or not.
      *
      * @param {number} [Range] - Range to check.
      * @param {boolean} [AoESpell] - Is it an AoE Spell ?
      * @param {object} [ThisUnit=Target] - Unit to check the range for.
      *
      * @returns {boolean}
      *]]
    function Spell:IsCastable ( Range, AoESpell, ThisUnit )
      if Range then
        local RangeUnit = ThisUnit or Target;
        return self:IsLearned() and self:CooldownUp() and RangeUnit:IsInRange( Range, AoESpell );
      else
        return self:IsLearned() and self:CooldownUp();
      end
    end

    -- Check if the spell Is Castable and Usable or not.
    function Spell:IsReady ()
      return self:IsLearned() and self:CooldownUp() and self:IsUsable();
    end

    -- Get the ChargesInfo (from GetSpellCharges) and cache it.
    function Spell:GetChargesInfo ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      -- charges, maxCharges, chargeStart, chargeDuration, chargeModRate
      Cache.SpellInfo[self.SpellID].Charges = {GetSpellCharges(self.SpellID)};
    end

    -- Get the ChargesInfos from the Cache.
    function Spell:ChargesInfo (Index)
      if not Cache.SpellInfo[self.SpellID] or not Cache.SpellInfo[self.SpellID].Charges then
        self:GetChargesInfo();
      end
      if Index then
        return Cache.SpellInfo[self.SpellID].Charges[Index];
      else
        return unpack(Cache.SpellInfo[self.SpellID].Charges);
      end
    end

    -- Get the CooldownInfo (from GetSpellCooldown) and cache it.
    function Spell:CooldownInfo ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].CooldownInfo then
        -- start, duration, enable, modRate
        Cache.SpellInfo[self.SpellID].CooldownInfo = {GetSpellCooldown(self.SpellID)};
      end
      return unpack(Cache.SpellInfo[self.SpellID].CooldownInfo);
    end

    -- Computes any spell cooldown.
    function Spell:ComputeCooldown (BypassRecovery, Type)
      local Charges, MaxCharges, CDTime, CDValue;
      if Type == "Charges" then
        -- Get spell recharge infos
        Charges, MaxCharges, CDTime, CDValue = self:ChargesInfo();
        -- Return 0 if the spell has already all its charges.
        if Charges == MaxCharges then return 0; end
      else
        -- Get spell cooldown infos
        CDTime, CDValue = self:CooldownInfo();
        -- Return 0 if the spell isn't in CD.
        if CDTime == 0 then return 0; end
      end
      -- Compute the CD.
      local CD = CDTime + CDValue - AC.GetTime() - (BypassRecovery and 0 or AC.RecoveryOffset());
      -- Return the Spell CD.
      return CD > 0 and CD or 0;
    end
    function Spell:ComputeChargesCooldown (BypassRecovery)
      return self:ComputeCooldown(BypassRecovery, "Charges");
    end

    -- Get the CostInfo (from GetSpellPowerCost) and cache it.
    function Spell:CostInfo (Index, Key)
      if not Key or type(Key) ~= "string" then error("Invalid Key."); end
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].CostInfo then
        -- hasRequiredAura, type, name, cost, minCost, requiredAuraID, costPercent, costPerSec
        Cache.SpellInfo[self.SpellID].CostInfo = GetSpellPowerCost(self.SpellID);
      end
      return Cache.SpellInfo[self.SpellID].CostInfo[Index] and Cache.SpellInfo[self.SpellID].CostInfo[Index][Key] and Cache.SpellInfo[self.SpellID].CostInfo[Index][Key] or nil;
    end

    --- Artifact Traits Scan
    -- Get every traits informations and stores them.
    local ArtifactUI = _G.C_ArtifactUI;
    local HasArtifactEquipped, SocketInventoryItem = _G.HasArtifactEquipped, _G.SocketInventoryItem;
    local ArtifactFrame = _G.ArtifactFrame;
    local Powers, PowerTableByPowerID, PowerTableBySpellID = {}, {}, {};
    --local PowerTable = {}; -- Uncomment for debug purpose in case they changes the Artifact API
    function Spell:ArtifactScan ()
      ArtifactFrame = _G.ArtifactFrame;
      -- Does the scan only if the artifact is equipped and the artifact frame not opened.
      if HasArtifactEquipped() and not (ArtifactFrame and ArtifactFrame:IsShown()) then
        -- Unregister the event to prevent unwanted call(s).
        UIParent:UnregisterEvent("ARTIFACT_UPDATE");
        SocketInventoryItem(INVSLOT_MAINHAND);
        Powers = ArtifactUI.GetPowers();
        if Powers then
          --wipe(PowerTable);
          wipe(PowerTableByPowerID);
          wipe(PowerTableBySpellID);
          local PowerInfo;
          for Index, Power in pairs(Powers) do
            -- GetPowerInfo() returns a table and not multiple values unlike most WoW API.
            -- offset, prereqsMet, cost, bonusRanks, maxRanks, linearIndex, position, isFinal, numMaxRankBonusFromTier, tier, isGoldMedal, isStart, currentRank, spellID
            PowerInfo = ArtifactUI.GetPowerInfo(Power);
            --tableinsert(PowerTable, PowerInfo);
            PowerTableByPowerID[Power] = PowerInfo;
            PowerTableBySpellID[PowerInfo.spellID] = PowerInfo;
          end
        end
        ArtifactUI.Clear();
        -- Register back the event.
        UIParent:RegisterEvent("ARTIFACT_UPDATE");
      end
    end

  --- Simulationcraft Aliases
    -- action.foo.cast_time
    function Spell:CastTime ()
      if not self:InfoID(4) then 
        return 0;
      else
        return self:InfoID(4)/1000;
      end
    end
    
    -- action.foo.execute_time
    function Spell:ExecuteTime ()
      if self:CastTime() > Player:GCD() then
        return self:CastTime()
      else
        return Player:GCD()
      end
    end

    -- action.foo.cost
    function Spell:Cost (Index)
      local Index = Index or 1;
      local Cost = self:CostInfo(Index, "cost")
      return Cost and Cost or 0;
    end

    -- action.foo.charges or cooldown.foo.charges
    function Spell:Charges ()
      return self:ChargesInfo(1);
    end

    -- action.foo.max_charges or cooldown.foo..max_charges
    function Spell:MaxCharges ()
      return self:ChargesInfo(2);
    end

    -- action.foo.recharge_time or cooldown.foo.recharge_time
    function Spell:Recharge (BypassRecovery)
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if (not BypassRecovery and not Cache.SpellInfo[self.SpellID].Recharge)
        or (BypassRecovery and not Cache.SpellInfo[self.SpellID].RechargeNoRecovery) then
        if BypassRecovery then
          Cache.SpellInfo[self.SpellID].RechargeNoRecovery = self:ComputeChargesCooldown(BypassRecovery);
        else
          Cache.SpellInfo[self.SpellID].Recharge = self:ComputeChargesCooldown();
        end
      end
      return Cache.SpellInfo[self.SpellID].Recharge;
    end

    -- action.foo.charges_fractional or cooldown.foo.charges_fractional
    -- TODO : Changes function to avoid using the cache directly
    function Spell:ChargesFractional (BypassRecovery)
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if (not BypassRecovery and not Cache.SpellInfo[self.SpellID].ChargesFractional)
        or (BypassRecovery and not Cache.SpellInfo[self.SpellID].ChargesFractionalNoRecovery) then
        if self:Charges() == self:MaxCharges() then
          if BypassRecovery then
            Cache.SpellInfo[self.SpellID].ChargesFractionalNoRecovery = self:Charges();
          else
            Cache.SpellInfo[self.SpellID].ChargesFractional = self:Charges();
          end
        else
          -- charges + (chargeDuration - recharge) / chargeDuration
          if BypassRecovery then
            Cache.SpellInfo[self.SpellID].ChargesFractionalNoRecovery = self:Charges() + (self:ChargesInfo(4)-self:Recharge(BypassRecovery))/self:ChargesInfo(4);
          else
            Cache.SpellInfo[self.SpellID].ChargesFractional = self:Charges() + (self:ChargesInfo(4)-self:Recharge())/self:ChargesInfo(4);
          end
        end
      end
      return Cache.SpellInfo[self.SpellID].ChargesFractional;
    end

    -- action.foo.full_recharge_time or cooldown.foo.charges_full_recharge_time
    function Spell:FullRechargeTime ()
      return self:MaxCharges() - self:ChargesFractional() * self:Recharge();
    end

    --[[*
      * @function Spell:CooldownRemains
      * @desc Get the remaining time, if there is any, on a cooldown.
      * @simc cooldown.foo.remains
      *
      * @param {boolean} [BypassRecovery] - Do you want to take in account Recovery offset ?
      * @param {string|number} [Offset] - The offset to apply, can be a string for a known method or directly the offset value in seconds.
      *
      * @returns {number}
      *]]
    function Spell:CooldownRemains ( BypassRecovery, Offset )
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      local Cooldown = Cache.SpellInfo[self.SpellID].Cooldown;
      local CooldownNoRecovery = Cache.SpellInfo[self.SpellID].CooldownNoRecovery;
      if ( not BypassRecovery and not Cooldown ) or ( BypassRecovery and not CooldownNoRecovery ) then
        if BypassRecovery then
          CooldownNoRecovery = self:ComputeCooldown(BypassRecovery);
        else
          Cooldown = self:ComputeCooldown();
        end
      end
      if Offset then
        return BypassRecovery and mathmax( AC.OffsetRemains( CooldownNoRecovery, Offset ), 0 ) or mathmax(AC.OffsetRemains( Cooldown, Offset ), 0 );
      else
        return BypassRecovery and CooldownNoRecovery or Cooldown;
      end
    end

    --[[*
      * @function Spell:CooldownRemainsP
      * @override Spell:CooldownRemains
      * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
      *
      * @param {string|number} [Offset="Auto"]
      *
      * @returns {number}
      *]]
    function Spell:CooldownRemainsP ( BypassRecovery, Offset )
      return self:CooldownRemains( BypassRecovery, Offset or "Auto" );
    end

    -- cooldown.foo.up
    function Spell:CooldownUp (BypassRecovery)
      return self:CooldownRemains(BypassRecovery) == 0;
    end
    function Spell:CooldownUpP (BypassRecovery)
      return self:CooldownRemainsP(BypassRecovery) == 0;
    end

    -- "cooldown.foo.down"
    -- Since it doesn't exists in SimC, I think it's better to use 'not Spell:CooldownUp' for consistency with APLs.
    function Spell:CooldownDown (BypassRecovery)
      return self:CooldownRemains(BypassRecovery) ~= 0;
    end
    function Spell:CooldownDownP (BypassRecovery)
      return self:CooldownRemainsP(BypassRecovery) ~= 0;
    end

    -- artifact.foo.rank
    function Spell:ArtifactRank ()
      return PowerTableBySpellID[self.SpellID] and PowerTableBySpellID[self.SpellID].currentRank or 0;
    end
    function Spell:ArtifactRankPowerID ()
      return PowerTableByPowerID[self.SpellID] and PowerTableByPowerID[self.SpellID].currentRank or 0;
    end

    -- artifact.foo.enabled
    function Spell:ArtifactEnabled ()
      return self:ArtifactRank() > 0;
    end
    function Spell:ArtifactEnabledPowerID ()
      return self:ArtifactRankPowerID() > 0;
    end

    -- action.foo.travel_time
    local ProjectileSpeed = AC.Enum.ProjectileSpeed;
    function Spell:FilterProjectileSpeed (SpecID)
      local RegisteredSpells = {};
      local BaseProjectileSpeed = AC.Enum.ProjectileSpeed; -- In case FilterTravelTime is called multiple time, we take the Enum table as base.
      -- Fetch registered spells during the init
      for Spec, Spells in pairs(AC.Spell[AC.SpecID_ClassesSpecs[SpecID][1]]) do
        for _, Spell in pairs(Spells) do
          local SpellID = Spell:ID();
          local ProjectileSpeedInfo = BaseProjectileSpeed[SpellID];
          if ProjectileSpeedInfo ~= nil then
            RegisteredSpells[SpellID] = ProjectileSpeedInfo;
          end
        end
      end
      ProjectileSpeed = RegisteredSpells;
    end
    function Spell:TravelTime ()
      local Speed = ProjectileSpeed[self.SpellID];
      if not Speed or Speed == 0 then return 0; end
      return Target:MaxDistanceToPlayer() / (ProjectileSpeed[self.SpellID] or 22);
    end
    
    -- action.foo.tick_time
    local TickTime = AC.Enum.TickTime;
    function Spell:FilterTickTime (SpecID)
      local RegisteredSpells = {};
      local BaseTickTime = AC.Enum.TickTime; 
      -- Fetch registered spells during the init
      for Spec, Spells in pairs(AC.Spell[AC.SpecID_ClassesSpecs[SpecID][1]]) do
        for _, Spell in pairs(Spells) do
          local SpellID = Spell:ID();
          local TickTimeInfo = BaseTickTime[SpellID][1];
          if TickTimeInfo ~= nil then
            RegisteredSpells[SpellID] = TickTimeInfo;
          end
        end
      end
      TickTime = RegisteredSpells;
    end
    function Spell:BaseTickTime ()
      local Tick = TickTime[self.SpellID]
      if not Tick or Tick == 0 then return 0; end
      local TickTime = Tick[1];
      return TickTime / 1000;
    end
    function Spell:TickTime ()
      local BaseTickTime = self:BaseTickTime();
      if not BaseTickTime or BaseTickTime == 0 then return 0; end
      local Hasted = TickTime[self.SpellID][2];
      if Hasted then return BaseTickTime / (1 + (Player:HastePct() / 100)); end
      return BaseTickTime;
    end

    -- action.foo.in_flight
    function Spell:IsInFlight ()
      return AC.GetTime() < self.LastHitTime;
    end
