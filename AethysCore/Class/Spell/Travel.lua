--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache, Utils = HeroCache, AC.Utils;
  local Unit = AC.Unit;
  local Player, Pet, Target = Unit.Player, Unit.Pet, Unit.Target;
  local Focus, MouseOver = Unit.Focus, Unit.MouseOver;
  local Arena, Boss, Nameplate = Unit.Arena, Unit.Boss, Unit.Nameplate;
  local Party, Raid = Unit.Party, Unit.Raid;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local pairs = pairs;
  -- File Locals
  


--- ============================ CONTENT ============================
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
    return Target:MaxDistanceToPlayer(true) / (ProjectileSpeed[self.SpellID] or 22);
  end

  -- action.foo.in_flight
  function Spell:IsInFlight ()
    return AC.GetTime() < self.LastHitTime;
  end
