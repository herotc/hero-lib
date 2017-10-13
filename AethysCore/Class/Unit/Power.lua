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



--- ============================ CONTENT ============================
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
