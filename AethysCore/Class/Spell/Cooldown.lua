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
