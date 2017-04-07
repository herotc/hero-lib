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
  local pairs = pairs;
  local print = print;
  local select = select;
  local tableinsert = table.insert;
  local tostring = tostring;
  local unpack = unpack;
  local wipe = table.wipe;
  -- File Locals
  local _T = {                  -- Temporary Vars
    Charges, MaxCharges,          -- Cooldown / Recharge
    CDTime, CDValue, CD           -- Cooldown / Recharge
  };


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
    function Spell:IsAvailable ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if Cache.SpellInfo[self.SpellID].IsAvailable == nil then
        Cache.SpellInfo[self.SpellID].IsAvailable = IsPlayerSpell(self.SpellID);
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
    function Spell:BookScan ()
      local CurrentSpellID, CurrentSpell;
      -- Pet Book
      local NumPetSpells = HasPetSpells();
      if NumPetSpells then
        for i = 1, NumPetSpells do
          CurrentSpellID = select(7, GetSpellInfo(i, BOOKTYPE_PET))
          if CurrentSpellID then
            CurrentSpell = Spell(CurrentSpellID);
            if CurrentSpell:IsAvailable() and (CurrentSpell:IsKnown() or IsTalentSpell(i, BOOKTYPE_PET)) then
              Cache.Persistent.SpellLearned.Pet[CurrentSpell:ID()] = true;
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
              Cache.Persistent.SpellLearned.Player[CurrentSpellID] = true;
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

    -- Check if the spell Is Castable or not.
    function Spell:IsCastable ()
      return self:IsLearned() and not self:IsOnCooldown();
    end

    -- Get the CooldownInfo (from GetSpellCooldown) and cache it.
    function Spell:CooldownInfo ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].CooldownInfo then
        Cache.SpellInfo[self.SpellID].CooldownInfo = {GetSpellCooldown(self.SpellID)};
      end
      return unpack(Cache.SpellInfo[self.SpellID].CooldownInfo);
    end

    -- Get the CostInfo (from GetSpellPowerCost) and cache it.
    function Spell:CostInfo (Key)
      if not Key or type(Key) ~= "string" then error("Invalid Key."); end
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].CostInfo then
        Cache.SpellInfo[self.SpellID].CostInfo = GetSpellPowerCost(self.SpellID)[1];
      end
      return Cache.SpellInfo[self.SpellID].CostInfo[Key];
    end

    --- Artifact Traits Scan
    -- Fills the PowerTable with every traits informations.
    local ArtifactUI, HasArtifactEquipped  = _G.C_ArtifactUI, _G.HasArtifactEquipped;
    local ArtifactFrame = _G.ArtifactFrame;
    local PowerTable, Powers = {}, {};
    --- PowerTable Schema :
    --   1    2      3       4      5     6  7    8       9      10      11
    -- SpellID, Cost, CurrentRank, MaxRank, BonusRanks, x, y, PreReqsMet, IsStart, IsGoldMedal, IsFinal
    function Spell:ArtifactScan ()
      ArtifactFrame = _G.ArtifactFrame;
      -- Does the scan only if the Artifact is Equipped and the Frame not Opened.
      if HasArtifactEquipped() and not (ArtifactFrame and ArtifactFrame:IsShown()) then
        -- Unregister the events to prevent unwanted call.
        UIParent:UnregisterEvent("ARTIFACT_UPDATE");
        SocketInventoryItem(INVSLOT_MAINHAND);
        Powers = ArtifactUI.GetPowers();
        if Powers then
          wipe(PowerTable);
          for Index, Power in pairs(Powers) do
            tableinsert(PowerTable, {ArtifactUI.GetPowerInfo(Power)});
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

    -- action.foo.cost
    function Spell:Cost ()
      return self:CostInfo("cost");
    end

    -- TODO: Improve all cooldown functions (separate Charges and GetChargesInfo, then make the simc expression)

    -- action.foo.charges or cooldown.foo.charges
    function Spell:Charges ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].Charges then
        Cache.SpellInfo[self.SpellID].Charges = {GetSpellCharges(self.SpellID)};
      end
      return unpack(Cache.SpellInfo[self.SpellID].Charges);
    end

    -- action.foo.max_charges or cooldown.foo..max_charges
    function Spell:MaxCharges ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].MaxCharges then
        self:Charges(); -- Cache the charges infos to use the cache directly after. 
        Cache.SpellInfo[self.SpellID].MaxCharges = Cache.SpellInfo[self.SpellID].Charges[2];
      end
      return Cache.SpellInfo[self.SpellID].MaxCharges;
    end

    -- action.foo.recharge_time or cooldown.foo.recharge_time
    function Spell:Recharge ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].Recharge then
        -- Get Spell Recharge Infos
        _T.Charges, _T.MaxCharges, _T.CDTime, _T.CDValue = self:Charges();
        -- Return 0 if the Spell isn't in CD.
        if _T.Charges == _T.MaxCharges then
          return 0;
        end
        -- Compute the CD.
        _T.CD = _T.CDTime + _T.CDValue - AC.GetTime() - AC.RecoveryOffset();
        -- Return the Spell CD
        Cache.SpellInfo[self.SpellID].Recharge = _T.CD > 0 and _T.CD or 0;
      end
      return Cache.SpellInfo[self.SpellID].Recharge;
    end

    -- action.foo.charges_fractional or cooldown.foo.charges_fractional
    -- TODO : Changes function to avoid using the cache directly
    function Spell:ChargesFractional ()
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if not Cache.SpellInfo[self.SpellID].ChargesFractional then
        self:Charges(); -- Cache the charges infos to use the cache directly after. 
        if Cache.SpellInfo[self.SpellID].Charges[1] == Cache.SpellInfo[self.SpellID].Charges[2] then
          Cache.SpellInfo[self.SpellID].ChargesFractional = Cache.SpellInfo[self.SpellID].Charges[1];
        else
          Cache.SpellInfo[self.SpellID].ChargesFractional = Cache.SpellInfo[self.SpellID].Charges[1] + (Cache.SpellInfo[self.SpellID].Charges[4]-self:Recharge())/Cache.SpellInfo[self.SpellID].Charges[4];
        end
      end
      return Cache.SpellInfo[self.SpellID].ChargesFractional;
    end

    -- action.foo.full_recharge_time or cooldown.foo.charges_full_recharge_time
    function Spell:FullRechargeTime ()
      return self:MaxCharges()-self:ChargesFractional()*self:Recharge();
    end

    -- cooldown.foo.remains
    -- TODO: Swap Cooldown() to CooldownRemains() and then make a Cooldown() for cooldown.foo.up (and keep IsOnCooldown() for !cooldown.foo.up)
    function Spell:Cooldown (BypassRecovery)
      if not Cache.SpellInfo[self.SpellID] then Cache.SpellInfo[self.SpellID] = {}; end
      if (not BypassRecovery and not Cache.SpellInfo[self.SpellID].Cooldown) or (BypassRecovery and not Cache.SpellInfo[self.SpellID].CooldownNoRecovery) then
        -- Get Spell Cooldown Infos
        _T.CDTime, _T.CDValue = GetSpellCooldown(self.SpellID);
        -- Return 0 if the Spell isn't in CD.
        if _T.CDTime == 0 then
          return 0;
        end
        -- Compute the CD.
        _T.CD = _T.CDTime + _T.CDValue - AC.GetTime() - (BypassRecovery and 0 or AC.RecoveryOffset());
        if BypassRecovery then
          -- Return the Spell CD
          Cache.SpellInfo[self.SpellID].CooldownNoRecovery = _T.CD > 0 and _T.CD or 0;
        else
          -- Return the Spell CD
          Cache.SpellInfo[self.SpellID].Cooldown = _T.CD > 0 and _T.CD or 0;
        end
      end
      return BypassRecovery and Cache.SpellInfo[self.SpellID].CooldownNoRecovery or Cache.SpellInfo[self.SpellID].Cooldown;
    end

    -- !cooldown.foo.up
    function Spell:IsOnCooldown (BypassRecovery)
      return self:Cooldown(BypassRecovery) ~= 0;
    end

    -- artifact.foo.rank
    function Spell:ArtifactRank ()
      if #PowerTable > 0 then
        for Index, Table in pairs(PowerTable) do
          if self.SpellID == Table[1] and Table[3] > 0 then
            return Table[3];
          end
        end
      end
      return 0;
    end

    -- artifact.foo.enabled
    function Spell:ArtifactEnabled ()
      return self:ArtifactRank() > 0;
    end
