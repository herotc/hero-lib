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
  local unpack = unpack;
  -- File Locals
  


--- ============================ CONTENT ============================
  -- buff.foo.up (does return the buff table and not only true/false)
  do
    --  1     2     3      4        5          6             7           8           9                   10              11         12            13           14               15           16       17      18      19
    -- name, rank, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
    local UnitBuff = UnitBuff;
    local UnitID;
    local function _UnitBuff ()
      local Buffs = {};
      for i = 1, AC.MAXIMUM do
        local Infos = {UnitBuff(UnitID, i)};
        if not Infos[11] then break; end
        Buffs[i] = Infos;
      end
      return Buffs;
    end
    function Unit:Buff (Spell, Index, AnyCaster)
      local GUID = self:GUID();
      if GUID then
        UnitID = self.UnitID;
        local Buffs = Cache.Get("UnitInfo", GUID, "Buffs", _UnitBuff);
        for i = 1, #Buffs do
          local Buff = Buffs[i];
          if Spell:ID() == Buff[11] then
            local Caster = Buff[8];
            if AnyCaster or Caster == "player" then
              if Index then
                if type(Index) == "number" then
                  return Buff[Index];
                else
                  return unpack(Buff);
                end
              else
                return true;
              end
            end
          end
        end
      end
      return false;
    end
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
    return self:BuffRemains(Spell, AnyCaster, Offset) <= PandemicThreshold;
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
  
  --[[*
    * @function Unit:BuffRefreshableC
    * @override Unit:BuffRefreshable
    * @desc Automaticaly calculates the pandemicThreshold from enum table.
    *
    * @param 
    *
    * @returns {number}
    *]]
  function Unit:BuffRefreshableC ( Spell, AnyCaster, Offset )
    return self:BuffRefreshable( Spell, Spell:PandemicThreshold(), AnyCaster, Offset);
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
  function Unit:BuffRefreshableCP ( Spell, AnyCaster, Offset )
    return self:BuffRefreshableP( Spell, Spell:PandemicThreshold(), AnyCaster, Offset);
  end

  -- debuff.foo.up or dot.foo.up (does return the debuff table and not only true/false)
  do
    --  1     2     3      4         5          6             7          8           9                   10              11         12            13           14               15           16       17      18      19
    -- name, rank, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
    local UnitDebuff = UnitDebuff;
    local UnitID;
    local function _UnitDebuff ()
      local Debuffs = {};
      for i = 1, AC.MAXIMUM do
        local Infos = {UnitDebuff(UnitID, i)};
        if not Infos[11] then break; end
        Debuffs[i] = Infos;
      end
      return Debuffs;
    end
    function Unit:Debuff (Spell, Index, AnyCaster)
      local GUID = self:GUID();
      if GUID then
        UnitID = self.UnitID;
        local Debuffs = Cache.Get("UnitInfo", GUID, "Debuffs", _UnitDebuff);
        for i = 1, #Debuffs do
          local Debuff = Debuffs[i];
          if Spell:ID() == Debuff[11] then
            local Caster = Debuff[8];
            if AnyCaster or Caster == "player" or Caster == "pet" then
              if Index then
                if type(Index) == "number" then
                  return Debuff[Index];
                else
                  return unpack(Debuff);
                end
              else
                return true;
              end
            end
          end
        end
      end
      return false;
    end
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
    return self:DebuffRemains(Spell, AnyCaster, Offset) <= PandemicThreshold;
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

  --[[*
    * @function Unit:DebuffRefreshableC
    * @override Unit:DebuffRefreshable
    * @desc Automaticaly calculates the pandemicThreshold from enum table.
    *
    * @param 
    *
    * @returns {number}
    *]]
  function Unit:DebuffRefreshableC ( Spell, AnyCaster, Offset )
    return self:DebuffRefreshable( Spell, Spell:PandemicThreshold(), AnyCaster, Offset);
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
  function Unit:DebuffRefreshableCP ( Spell, AnyCaster, Offset )
    return self:DebuffRefreshableP( Spell, Spell:PandemicThreshold(), AnyCaster, Offset);
  end
  
  -- buff.bloodlust.up
  do
    local HeroismBuff = {
      Spell(90355),  -- Ancient Hysteria
      Spell(2825),   -- Bloodlust
      Spell(32182),  -- Heroism
      Spell(160452), -- Netherwinds
      Spell(80353)   -- Time Warp
    };
    local ThisUnit, _Remains;
    local function _HasHeroism ()
      for i = 1, #HeroismBuff do
        local Buff = HeroismBuff[i];
        if ThisUnit:Buff(Buff, nil, true) then
          return _Remains and ThisUnit:BuffRemains(Buff, true) or true;
        end
      end
      return false;
    end
    function Unit:HasHeroism (Remains)
      local GUID = self:GUID();
      if GUID then
        local Key = Remains and "Remains" or "Up";
        ThisUnit, _Remains = self, Remains;
        return Cache.Get("UnitInfo", GUID, "HasHeroism", Key, _HasHeroism);
      end
      return Remains and 0 or false;
    end
  end
  function Unit:HasHeroismRemains ()
    return self:HasHeroism(true);
  end
