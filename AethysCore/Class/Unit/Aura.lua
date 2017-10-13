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
  --- Get all the buffs from an unit and put it into the Cache.
  function Unit:GetBuffs ()
    local GUID = self:GUID();
    local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
    local Buffs = UnitInfo.Buffs;
    if not Buffs then
      Buffs = {};
      UnitInfo.Buffs = Buffs;
      for i = 1, AC.MAXIMUM do
        --  1     2     3      4        5          6             7           8           9                   10              11         12            13           14               15           16       17      18      19
        -- name, rank, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
        local Infos = {UnitBuff(self.UnitID, i)};
        if not Infos[11] then break; end
        Buffs[i] = Infos;
      end
    end
    return Buffs;
  end

  -- buff.foo.up (does return the buff table and not only true/false)
  function Unit:Buff (Spell, Index, AnyCaster)
    local GUID = self:GUID();
    if GUID then
      local Buffs = self:GetBuffs();
      for i = 1, #Buffs do
        local Buff = Buffs[i];
        if Spell:ID() == Buff[11] then
          local Caster = Buff[8];
          if AnyCaster or Caster == "player" then
            if Index then
              return Buff[Index];
            else
              return unpack(Buff);
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

  --- Get all the debuffs from an unit and put it into the Cache.
  function Unit:GetDebuffs ()
    local GUID = self:GUID();
    local UnitInfo = Cache.UnitInfo[GUID]; if not UnitInfo then UnitInfo = {}; Cache.UnitInfo[GUID] = UnitInfo; end
    local Debuffs = UnitInfo.Debuffs;
    if not Debuffs then
      Debuffs = {};
      UnitInfo.Debuffs = Debuffs;
      for i = 1, AC.MAXIMUM do
        --  1     2     3      4         5          6             7          8           9                   10              11         12            13           14               15           16       17      18      19
        -- name, rank, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellID, canApplyAura, isBossAura, casterIsPlayer, nameplateShowAll, timeMod, value1, value2, value3
        local Infos = {UnitDebuff(self.UnitID, i)};
        if not Infos[11] then break; end
        Debuffs[i] = Infos;
      end
    end
    return Debuffs;
  end

  -- debuff.foo.up or dot.foo.up (does return the debuff table and not only true/false)
  function Unit:Debuff (Spell, Index, AnyCaster)
    local GUID = self:GUID();
    if GUID then
      local Debuffs = self:GetDebuffs();
      for i = 1, #Debuffs do
        local Debuff = Debuffs[i];
        if Spell:ID() == Debuff[11] then
          local Caster = Debuff[8];
          if AnyCaster or Caster == "player" or Caster == "pet" then
            if Index then
              return Debuff[Index];
            else
              return unpack(Debuff);
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
