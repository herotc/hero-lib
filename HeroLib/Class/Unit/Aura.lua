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
local unpack = unpack
-- WoW API
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
-- File Locals



--- ============================ CONTENT ============================
-- buff.foo.up (does return the buff table and not only true/false)
do
  --  1      2     3      4            5           6             7           8           9                      10          11          12            13                14            15       16     17      18
  -- name, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
  local UnitID
  local function _UnitBuff()
    local Buffs = {}
    for i = 1, HL.MAXIMUM do
      local Infos = { UnitBuff(UnitID, i) }
      if not Infos[10] then break end
      Buffs[i] = Infos
    end
    return Buffs
  end

  function Unit:Buff(ThisSpell, Index, AnyCaster)
    local GUID = self:GUID()
    if not GUID then return false end

    UnitID = self.UnitID
    local SpellID = ThisSpell:ID()
    local Buffs = Cache.Get("UnitInfo", GUID, "Buffs", _UnitBuff)
    for i = 1, #Buffs do
      local Buff = Buffs[i]
      if SpellID == Buff[10] then
        local Caster = Buff[7]
        if AnyCaster or Caster == "player" then
          if not Index then return true end
          if type(Index) == "number" then return Buff[Index] end
          return unpack(Buff)
        end
      end
    end
  end
end

--[[*
  * @function Unit:BuffDown
  * @desc Get if the buff is down.
  * @simc buff.foo.down
  *
  * @param {object} ThisSpell - Spell to check.
  * @param {number|array} [Index] - The index of the attribute to retrieve when calling the spell info.
  * @param {boolean} [AnyCaster] - Check from any caster ?
  *
  * @returns {boolean}
  *]]
function Unit:BuffDown(ThisSpell, Index, AnyCaster)
  return (not self:Buff(ThisSpell, Index, AnyCaster))
end

--[[*
  * @function Unit:BuffRemains
  * @desc Get the remaining time, if there is any, on a buff.
  * @simc buff.foo.remains
  *
  * @param {object} ThisSpell - Spell to check.
  * @param {boolean} [AnyCaster] - Check from any caster ?
  * @param {string|number} [Offset] - The offset to apply, can be a string for a known method or directly the offset value in seconds.
  *
  * @returns {number}
  *]]
function Unit:BuffRemains(ThisSpell, AnyCaster, Offset)
  local ExpirationTime = self:Buff(ThisSpell, 6, AnyCaster)
  if ExpirationTime then
    if ExpirationTime == 0 then
      return 9999
    end

    if Offset then
      ExpirationTime = HL.OffsetRemains(ExpirationTime, Offset)
    end

    -- Stealth-like buffs (Subterfurge and Master Assassin) are delayed but within aura latency
    local SpellID = ThisSpell:ID()
    if SpellID == 115192 or SpellID == 256735 then
      ExpirationTime = ExpirationTime - 0.3
    end
    local Remains = ExpirationTime - GetTime()
    return Remains >= 0 and Remains or 0
  else
    return 0
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
function Unit:BuffRemainsP(ThisSpell, AnyCaster, Offset)
  return self:BuffRemains(ThisSpell, AnyCaster, Offset or "Auto")
end

function Unit:BuffP(ThisSpell, AnyCaster, Offset)
  return self:BuffRemains(ThisSpell, AnyCaster, Offset or "Auto") > 0
end

function Unit:BuffDownP(ThisSpell, AnyCaster, Offset)
  return self:BuffRemains(ThisSpell, AnyCaster, Offset or "Auto") == 0
end

-- buff.foo.duration
function Unit:BuffDuration(ThisSpell, AnyCaster)
  return self:Buff(ThisSpell, 5, AnyCaster) or 0
end

-- buff.foo.stack
function Unit:BuffStack(ThisSpell, AnyCaster)
  return self:Buff(ThisSpell, 3, AnyCaster) or 0
end

--[[*
  * @function Unit:BuffStackP
  * @override Unit:BuffStack
  * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Unit:BuffStackP(ThisSpell, AnyCaster, Offset)
  if self:BuffRemainsP(ThisSpell, AnyCaster, Offset) then
    return self:BuffStack(ThisSpell, AnyCaster)
  else
    return 0
  end
end

-- buff.foo.refreshable (doesn't exists on SimC atm tho)
function Unit:BuffRefreshable(ThisSpell, PandemicThreshold, AnyCaster, Offset)
  return self:BuffRemains(ThisSpell, AnyCaster, Offset) <= PandemicThreshold
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
function Unit:BuffRefreshableP(ThisSpell, PandemicThreshold, AnyCaster, Offset)
  return self:BuffRefreshable(ThisSpell, PandemicThreshold, AnyCaster, Offset or "Auto")
end

--[[*
  * @function Unit:BuffRefreshableC
  * @override Unit:BuffRefreshable
  * @desc Automaticaly calculates the pandemicThreshold from enum table.
  *
  * @param
  *
  * @returns {number}
  *]]
function Unit:BuffRefreshableC(ThisSpell, AnyCaster, Offset)
  return self:BuffRefreshable(ThisSpell, ThisSpell:PandemicThreshold(), AnyCaster, Offset)
end

--[[*
  * @function Unit:BuffRefreshableCP
  * @override Unit:BuffRefreshableP
  * @desc Automaticaly calculates the pandemicThreshold from enum table with prediction.
  *
  * @param
  *
  * @returns {number}
  *]]
function Unit:BuffRefreshableCP(ThisSpell, AnyCaster, Offset)
  return self:BuffRefreshableP(ThisSpell, ThisSpell:PandemicThreshold(), AnyCaster, Offset)
end

-- hot.foo.ticks_remain
function Unit:BuffTicksRemainP(ThisSpell)
  local Remains = self:BuffRemainsP(ThisSpell)
  if Remains == 0 then
    return 0
  else
    return math.ceil(Remains / ThisSpell:TickTime())
  end
end

-- debuff.foo.up or dot.foo.up (does return the debuff table and not only true/false)
do
  --  1     2      3         4          5           6           7           8                   9              10         11            12           13               14            15       16      17      18
  -- name, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
  local UnitID
  local function _UnitDebuff()
    local Debuffs = {}
    for i = 1, HL.MAXIMUM do
      local Infos = { UnitDebuff(UnitID, i) }
      if not Infos[10] then break end
      Debuffs[i] = Infos
    end
    return Debuffs
  end

  function Unit:Debuff(ThisSpell, Index, AnyCaster)
    local GUID = self:GUID()
    if GUID then
      UnitID = self.UnitID
      local Debuffs = Cache.Get("UnitInfo", GUID, "Debuffs", _UnitDebuff)
      for i = 1, #Debuffs do
        local Debuff = Debuffs[i]
        if ThisSpell:ID() == Debuff[10] then
          local Caster = Debuff[7]
          if AnyCaster or Caster == "player" or Caster == "pet" then
            if not Index then return true end
            if type(Index) == "number" then return Debuff[Index] end
            return unpack(Debuff)
          end
        end
      end
    end
    return false
  end
end

--[[*
  * @function Unit:DebuffDown
  * @desc Get if the debuff is down.
  * @simc debuff.foo.down
  *
  * @param {object} ThisSpell - Spell to check.
  * @param {number|array} [Index] - The index of the attribute to retrieve when calling the spell info.
  * @param {boolean} [AnyCaster] - Check from any caster ?
  *
  * @returns {boolean}
  *]]
function Unit:DebuffDown(ThisSpell, Index, AnyCaster)
  return (not self:Debuff(ThisSpell, Index, AnyCaster))
end

--[[*
  * @function Unit:DebuffRemains
  * @desc Get the remaining time, if there is any, on a debuff.
  * @simc debuff.foo.remains, dot.foo.remains
  *
  * @param {object} ThisSpell - Spell to check.
  * @param {boolean} [AnyCaster] - Check from any caster ?
  * @param {string|number} [Offset] - The offset to apply, can be a string for a known method or directly the offset value in seconds.
  *
  * @returns {number}
  *]]
function Unit:DebuffRemains(ThisSpell, AnyCaster, Offset)
  local ExpirationTime = self:Debuff(ThisSpell, 6, AnyCaster)
  if ExpirationTime then
    if Offset then
      ExpirationTime = HL.OffsetRemains(ExpirationTime, Offset)
    end
    local Remains = ExpirationTime - GetTime()
    return Remains >= 0 and Remains or 0
  else
    return 0
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
function Unit:DebuffRemainsP(ThisSpell, AnyCaster, Offset)
  return self:DebuffRemains(ThisSpell, AnyCaster, Offset or "Auto")
end

function Unit:DebuffP(ThisSpell, AnyCaster, Offset)
  return self:DebuffRemains(ThisSpell, AnyCaster, Offset or "Auto") > 0
end

function Unit:DebuffDownP(ThisSpell, AnyCaster, Offset)
  return self:DebuffRemains(ThisSpell, AnyCaster, Offset or "Auto") == 0
end

-- debuff.foo.duration or dot.foo.duration
function Unit:DebuffDuration(ThisSpell, AnyCaster)
  return self:Debuff(ThisSpell, 5, AnyCaster) or 0
end

-- debuff.foo.stack or dot.foo.stack
function Unit:DebuffStack(ThisSpell, AnyCaster)
  return self:Debuff(ThisSpell, 3, AnyCaster) or 0
end

--[[*
  * @function Unit:DebuffStackP
  * @override Unit:DebuffStack
  * @desc Offset defaulted to "Auto" which is ideal in most cases to improve the prediction.
  *
  * @param {string|number} [Offset="Auto"]
  *
  * @returns {number}
  *]]
function Unit:DebuffStackP(ThisSpell, AnyCaster, Offset)
  if self:DebuffP(ThisSpell, AnyCaster, Offset) then
    return self:DebuffStack(ThisSpell, AnyCaster)
  else
    return 0
  end
end

-- debuff.foo.refreshable or dot.foo.refreshable
function Unit:DebuffRefreshable(ThisSpell, PandemicThreshold, AnyCaster, Offset)
  return self:DebuffRemains(ThisSpell, AnyCaster, Offset) <= PandemicThreshold
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
function Unit:DebuffRefreshableP(ThisSpell, PandemicThreshold, AnyCaster, Offset)
  return self:DebuffRefreshable(ThisSpell, PandemicThreshold, AnyCaster, Offset or "Auto")
end

--[[*
  * @function Unit:DebuffRefreshableC
  * @override Unit:DebuffRefreshable
  * @desc Automaticaly calculates the pandemicThreshold from enum table.
  *
  * @param
  *
  * @returns {number}
  *]]
function Unit:DebuffRefreshableC(ThisSpell, AnyCaster, Offset)
  return self:DebuffRefreshable(ThisSpell, ThisSpell:PandemicThreshold(), AnyCaster, Offset)
end

--[[*
  * @function Unit:DebuffRefreshableCP
  * @override Unit:DebuffRefreshableP
  * @desc Automaticaly calculates the pandemicThreshold from enum table with prediction.
  *
  * @param
  *
  * @returns {number}
  *]]
function Unit:DebuffRefreshableCP(ThisSpell, AnyCaster, Offset)
  return self:DebuffRefreshableP(ThisSpell, ThisSpell:PandemicThreshold(), AnyCaster, Offset)
end

-- dot.foo.ticks_remain
function Unit:DebuffTicksRemainP(ThisSpell)
  local Remains = self:DebuffRemainsP(ThisSpell)
  if Remains == 0 then
    return 0
  else
    return math.ceil(Remains / ThisSpell:TickTime())
  end
end

-- buff.bloodlust.up
do
  local HeroismBuff = {
    Spell(90355), -- Ancient Hysteria
    Spell(2825), -- Bloodlust
    Spell(32182), -- Heroism
    Spell(160452), -- Netherwinds
    Spell(80353), -- Time Warp
    Spell(178207), -- Drums of Fury
    Spell(35475), -- Drums of War
    Spell(230935), -- Drums of Montain
    Spell(256740) -- Drums of Maelstrom
  }
  local ThisUnit, _Remains
  local function _HasHeroism()
    for i = 1, #HeroismBuff do
      local Buff = HeroismBuff[i]
      if ThisUnit:Buff(Buff, nil, true) then
        return _Remains and ThisUnit:BuffRemains(Buff, true) or true
      end
    end
    return false
  end

  local function _HasHeroismP(Offset)
    for i = 1, #HeroismBuff do
      local Buff = HeroismBuff[i]
      if ThisUnit:Buff(Buff, nil, true) then
        return _Remains and ThisUnit:BuffRemainsP(Buff, true, Offset or "Auto") or true
      end
    end
    return false
  end

  function Unit:HasHeroism(Remains)
    local GUID = self:GUID()
    if GUID then
      local Key = Remains and "Remains" or "Up"
      ThisUnit, _Remains = self, Remains
      return Cache.Get("UnitInfo", GUID, "HasHeroism", Key, _HasHeroism)
    end
    return Remains and 0 or false
  end

  function Unit:HasHeroismP(Remains)
    local GUID = self:GUID()
    if GUID then
      local Key = Remains and "Remains" or "Up"
      ThisUnit, _Remains = self, Remains
      return Cache.Get("UnitInfo", GUID, "HasHeroismP", Key, _HasHeroismP)
    end
    return Remains and 0 or false
  end
end
function Unit:HasHeroismRemains()
  return self:HasHeroism(true)
end

function Unit:HasHeroismRemainsP()
  return self:HasHeroismP(true)
end

function Unit:HasNotHeroism()
  return (not self:HasHeroism())
end
