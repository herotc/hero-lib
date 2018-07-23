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
local pairs = pairs
-- File Locals



--- ============================ CONTENT ============================
-- action.foo.travel_time
local ProjectileSpeed = HL.Enum.ProjectileSpeed
function Spell:FilterProjectileSpeed(SpecID)
  local RegisteredSpells = {}
  local BaseProjectileSpeed = HL.Enum.ProjectileSpeed -- In case FilterTravelTime is called multiple time, we take the Enum table as base.
  -- Fetch registered spells during the init
  for Spec, Spells in pairs(HL.Spell[HL.SpecID_ClassesSpecs[SpecID][1]]) do
    for _, Spell in pairs(Spells) do
      local SpellID = Spell:ID()
      local ProjectileSpeedInfo = BaseProjectileSpeed[SpellID]
      if ProjectileSpeedInfo ~= nil then
        RegisteredSpells[SpellID] = ProjectileSpeedInfo
      end
    end
  end
  ProjectileSpeed = RegisteredSpells
end

function Spell:TravelTime()
  local Speed = ProjectileSpeed[self.SpellID]
  if not Speed or Speed == 0 then return 0 end
  return Target:MaxDistanceToPlayer(true) / (ProjectileSpeed[self.SpellID] or 22)
end

-- action.foo.in_flight
function Spell:IsInFlight()
  return HL.GetTime() < self.LastHitTime
end
