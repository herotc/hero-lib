--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache, Utils = HeroCache, HL.Utils
local Unit = HL.Unit
local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target
local Focus, MouseOver = Unit.Focus, Unit.MouseOver
local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate
local Party, Raid = Unit.Party, Unit.Raid
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local mathmax = math.max
local unpack = unpack
-- File Locals



--- ============================ CONTENT ============================
-- Get the ChargesInfo (from GetSpellCharges) and cache it.
do
  -- charges, maxCharges, chargeStart, chargeDuration, chargeModRate
  local GetSpellCharges = GetSpellCharges
  local SpellID
  local function _GetSpellCharges() return { GetSpellCharges(SpellID) } end

  function Spell:GetChargesInfo()
    SpellID = self.SpellID
    return Cache.Get("SpellInfo", SpellID, "Charges", _GetSpellCharges)
  end
end

-- Get the ChargesInfos from the Cache.
function Spell:ChargesInfo(Index)
  if Index then
    return self:GetChargesInfo()[Index]
  else
    return unpack(self:GetChargesInfo())
  end
end

-- Get the CooldownInfo (from GetSpellCooldown) and cache it.
function Spell:CooldownInfo()
  local SpellInfo = Cache.SpellInfo[self.SpellID]
  if not SpellInfo then
    SpellInfo = {}
    Cache.SpellInfo[self.SpellID] = SpellInfo
  end
  if not Cache.SpellInfo[self.SpellID].CooldownInfo then
    -- start, duration, enable, modRate
    Cache.SpellInfo[self.SpellID].CooldownInfo = { GetSpellCooldown(self.SpellID) }
  end
  return unpack(Cache.SpellInfo[self.SpellID].CooldownInfo)
end

-- Computes any spell cooldown.
function Spell:ComputeCooldown(BypassRecovery, Type)
  local Charges, MaxCharges, CDTime, CDValue
  if Type == "Charges" then
    -- Get spell recharge infos
    Charges, MaxCharges, CDTime, CDValue = self:ChargesInfo()
    -- Return 0 if the spell has already all its charges.
    if Charges == MaxCharges then return 0 end
  else
    -- Get spell cooldown infos
    CDTime, CDValue = self:CooldownInfo()
    -- Return 0 if the spell isn't in CD.
    if CDTime == 0 then return 0 end
  end
  -- Compute the CD.
  local CD = CDTime + CDValue - HL.GetTime() - (BypassRecovery and 0 or HL.RecoveryOffset())
  -- Return the Spell CD.
  return CD > 0 and CD or 0
end

function Spell:ComputeChargesCooldown(BypassRecovery)
  return self:ComputeCooldown(BypassRecovery, "Charges")
end

-- action.foo.cooldown
function Spell:Cooldown()
  return self:ChargesInfo(4)
end

-- action.foo.charges or cooldown.foo.charges
function Spell:Charges()
  return self:ChargesInfo(1)
end

--[[*
  * @function Spell:ChargesP
  * @override Spell:Charges
  * @desc Charges with recharge prediction
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Spell:ChargesP(BypassRecovery, Offset)
  local Charges = self:Charges()
  if Charges < self:MaxCharges() and self:RechargeP(BypassRecovery, Offset) == 0 then
    Charges = Charges + 1
  end
  return Charges
end

-- action.foo.max_charges or cooldown.foo..max_charges
function Spell:MaxCharges()
  return self:ChargesInfo(2)
end

-- action.foo.usable_in
function Spell:UsableIn()
  if self:Charges() > 0 then return 0 end
  return self:Recharge()
end

--[[*
  * @function Spell:UsableInP
  * @override Spell:UsableIn
  * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Spell:UsableInP(BypassRecovery, Offset)
  if self:ChargesP(BypassRecovery, Offset) > 0 then return 0 end
  return self:RechargeP(BypassRecovery, Offset)
end

-- action.foo.recharge_time or cooldown.foo.recharge_time
function Spell:Recharge(BypassRecovery, Offset)
  local SpellInfo = Cache.SpellInfo[self.SpellID]
  if not SpellInfo then
    SpellInfo = {}
    Cache.SpellInfo[self.SpellID] = SpellInfo
  end
  local Recharge = Cache.SpellInfo[self.SpellID].Recharge
  local RechargeNoRecovery = Cache.SpellInfo[self.SpellID].RechargeNoRecovery
  if (not BypassRecovery and not Cache.SpellInfo[self.SpellID].Recharge)
    or (BypassRecovery and not Cache.SpellInfo[self.SpellID].RechargeNoRecovery) then
    if BypassRecovery then
      RechargeNoRecovery = self:ComputeChargesCooldown(BypassRecovery)
    else
      Recharge = self:ComputeChargesCooldown()
    end
  end
  if Offset then
    return BypassRecovery and mathmax(HL.OffsetRemains(RechargeNoRecovery, Offset), 0) or mathmax(HL.OffsetRemains(Recharge, Offset), 0)
  else
    return BypassRecovery and RechargeNoRecovery or Recharge
  end
end

--[[*
  * @function Spell:RechargeP
  * @override Spell:Recharge
  * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Spell:RechargeP(BypassRecovery, Offset)
  return self:Recharge(BypassRecovery, Offset or "Auto")
end

-- action.foo.charges_fractional or cooldown.foo.charges_fractional
-- TODO : Changes function to avoid using the cache directly
function Spell:ChargesFractional(BypassRecovery, Offset)
  local SpellInfo = Cache.SpellInfo[self.SpellID]
  if not SpellInfo then
    SpellInfo = {}
    Cache.SpellInfo[self.SpellID] = SpellInfo
  end
  local ChargesFractional = Cache.SpellInfo[self.SpellID].ChargesFractional
  local ChargesFractionalNoRecovery = Cache.SpellInfo[self.SpellID].ChargesFractionalNoRecovery
  if (not BypassRecovery and not Cache.SpellInfo[self.SpellID].ChargesFractional)
    or (BypassRecovery and not Cache.SpellInfo[self.SpellID].ChargesFractionalNoRecovery) then
    if self:Charges() == self:MaxCharges() then
      if BypassRecovery then
        ChargesFractionalNoRecovery = self:Charges()
      else
        ChargesFractional = self:Charges()
      end
    else
      -- charges + (chargeDuration - recharge) / chargeDuration
      if BypassRecovery then
        ChargesFractionalNoRecovery = self:Charges() + (self:ChargesInfo(4) - self:Recharge(BypassRecovery)) / self:ChargesInfo(4)
      else
        ChargesFractional = self:Charges() + (self:ChargesInfo(4) - self:Recharge()) / self:ChargesInfo(4)
      end
    end
  end
  if Offset then
    return BypassRecovery and mathmax(HL.OffsetRemains(ChargesFractionalNoRecovery, Offset), 0) or mathmax(HL.OffsetRemains(ChargesFractional, Offset), 0)
  else
    return BypassRecovery and ChargesFractionalNoRecovery or ChargesFractional
  end
end

--[[*
  * @function Spell:ChargesFractionalP
  * @override Spell:ChargesFractional
  * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Spell:ChargesFractionalP(BypassRecovery, Offset)
  return self:ChargesFractional(BypassRecovery, Offset or "Auto")
end

-- action.foo.full_recharge_time or cooldown.foo.charges_full_recharge_time
function Spell:FullRechargeTime(BypassRecovery, Offset)
  local SpellInfo = Cache.SpellInfo[self.SpellID]
  if not SpellInfo then
    SpellInfo = {}
    Cache.SpellInfo[self.SpellID] = SpellInfo
  end
  local FullRechargeTime = Cache.SpellInfo[self.SpellID].FullRechargeTime
  local FullRechargeTimeNoRecovery = Cache.SpellInfo[self.SpellID].FullRechargeTimeNoRecovery
  if (not BypassRecovery and not Cache.SpellInfo[self.SpellID].FullRechargeTime)
    or (BypassRecovery and not Cache.SpellInfo[self.SpellID].FullRechargeTimeNoRecovery) then
    if self:Charges() == self:MaxCharges() then
      if BypassRecovery then
        FullRechargeTimeNoRecovery = 0
      else
        FullRechargeTime = 0
      end
    else
      if BypassRecovery then
        FullRechargeTimeNoRecovery = (self:MaxCharges() - self:ChargesFractional(BypassRecovery)) * self:ChargesInfo(4)
      else
        FullRechargeTime = (self:MaxCharges() - self:ChargesFractional()) * self:ChargesInfo(4)
      end
    end
  end
  if Offset then
    return BypassRecovery and mathmax(HL.OffsetRemains(FullRechargeTimeNoRecovery, Offset), 0) or mathmax(HL.OffsetRemains(FullRechargeTime, Offset), 0)
  else
    return BypassRecovery and FullRechargeTimeNoRecovery or FullRechargeTime
  end
end

--[[*
  * @function Spell:FullRechargeTimeP
  * @override Spell:FullRechargeTime
  * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Spell:FullRechargeTimeP(BypassRecovery, Offset)
  return self:FullRechargeTime(BypassRecovery, Offset or "Auto")
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
function Spell:CooldownRemains(BypassRecovery, Offset)
  local SpellInfo = Cache.SpellInfo[self.SpellID]
  if not SpellInfo then
    SpellInfo = {}
    Cache.SpellInfo[self.SpellID] = SpellInfo
  end
  local Cooldown = Cache.SpellInfo[self.SpellID].Cooldown
  local CooldownNoRecovery = Cache.SpellInfo[self.SpellID].CooldownNoRecovery
  if (not BypassRecovery and not Cooldown) or (BypassRecovery and not CooldownNoRecovery) then
    if BypassRecovery then
      CooldownNoRecovery = self:ComputeCooldown(BypassRecovery)
    else
      Cooldown = self:ComputeCooldown()
    end
  end
  if Offset then
    return BypassRecovery and mathmax(HL.OffsetRemains(CooldownNoRecovery, Offset), 0) or mathmax(HL.OffsetRemains(Cooldown, Offset), 0)
  else
    return BypassRecovery and CooldownNoRecovery or Cooldown
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
function Spell:CooldownRemainsP(BypassRecovery, Offset)
  return self:CooldownRemains(BypassRecovery or true, Offset or "Auto")
end

-- cooldown.foo.up
function Spell:CooldownUp(BypassRecovery)
  return self:CooldownRemains(BypassRecovery) == 0
end

function Spell:CooldownUpP(BypassRecovery)
  return self:CooldownRemainsP(BypassRecovery) == 0
end

-- "cooldown.foo.down"
-- Since it doesn't exists in SimC, I think it's better to use 'not Spell:CooldownUp' for consistency with APLs.
function Spell:CooldownDown(BypassRecovery)
  return self:CooldownRemains(BypassRecovery) ~= 0
end

function Spell:CooldownDownP(BypassRecovery)
  return self:CooldownRemainsP(BypassRecovery) ~= 0
end
