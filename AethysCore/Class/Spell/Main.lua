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
  function Spell:IsReady ( Range, AoESpell, ThisUnit )
    return self:IsCastable( Range, AoESpell, ThisUnit ) and self:IsUsable();
  end

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

  -- action.foo.cost
  function Spell:Cost (Index)
    local Index = Index or 1;
    local Cost = self:CostInfo(Index, "cost")
    return Cost and Cost or 0;
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
    if Hasted then return BaseTickTime / Player:SpellHaste(); end
    return BaseTickTime;
  end
