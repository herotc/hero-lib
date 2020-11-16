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
local GetTotemInfo = GetTotemInfo --haveTotem, totemName, startTime, duration
local GetTime = GetTime
-- File Locals



--- ============================ CONTENT ============================
-- Get infos for player totems

  function Player:GetTotemInfo(totemNumber)
    local haveTotem, totemName, startTime, duration = GetTotemInfo(totemNumber)

    return haveTotem, totemName, startTime, duration
  end

  function Player:TotemRemains(totemNumber)
    local _, _, ExpirationTime, DurationTime = self:GetTotemInfo(totemNumber)
    local Remains = ExpirationTime + DurationTime - GetTime()

    return Remains >= 0 and Remains or 0
  end

function Player:TotemName(totemNumber)
  local _, totemName, _, _ = self:GetTotemInfo(totemNumber)

  return totemName or 0
end

