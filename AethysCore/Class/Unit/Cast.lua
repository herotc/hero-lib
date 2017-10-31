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

  -- Get if the unit is casting or not. Param to check if the unit is casting a specific spell or not
  function Unit:IsCasting (Spell)
    if Spell then
      return self:CastingInfo(10) == Spell:ID() and true or false;
    else
      return self:CastingInfo(1) and true or false;
    end
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
  
  -- Get the cost of the current cast
  function Unit:CastCost ()
    if self:CastID() and self:CastID() ~= -1 then
      if not Cache.SpellInfo[self:CastID()] then Cache.SpellInfo[self:CastID()] = {}; end
      if not Cache.SpellInfo[self:CastID()].CostInfo then
        -- hasRequiredAura, type, name, cost, minCost, requiredAuraID, costPercent, costPerSec
        Cache.SpellInfo[self:CastID()].CostInfo = GetSpellPowerCost(self:CastID());
      end
      if Cache.SpellInfo[self:CastID()].CostInfo[1] then
        return Cache.SpellInfo[self:CastID()].CostInfo[1]["cost"]
      end
    end
    return 0
  end
