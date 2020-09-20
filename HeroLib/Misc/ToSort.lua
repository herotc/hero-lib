--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local mathmax = math.max
local select = select
local GetTime = GetTime
local GetInstanceInfo = GetInstanceInfo
local GetNetStats = GetNetStats -- down, up, lagHome, lagWorld
local CreateFrame = CreateFrame
local UIParent = UIParent
-- File Locals



--- ============================ CONTENT ============================
-- Get the Instance Informations
-- TODO: Cache it in Persistent Cache and update it only when it changes
-- @returns name, type, difficulty, difficultyName, maxPlayers, playerDifficulty, isDynamicInstance, mapID, instanceGroupSize
-- name - Name of the instance or world area (string)
-- type - Type of the instance (string)
-- difficulty - Difficulty setting of the instance (number)
-- difficultyName - String representing the difficulty of the instance. E.g. "10 Player" (string)
-- maxPlayers - Maximum number of players allowed in the instance (number)
-- playerDifficulty - Unknown (number)
-- isDynamicInstance - True for raid instances that can support multiple maxPlayers values (10 and 25) - eg. ToC, DS, ICC, etc (boolean)
-- mapID - (number)
-- instanceGroupSize - maxPlayers for fixed size raids, holds the actual raid size for the new flexible raid (between (8?)10 and 25) (number)
function HL.GetInstanceInfo(Index)
  if Index then
    local Result = select(Index, GetInstanceInfo())
    return Result
  end
  return GetInstanceInfo()
end

-- Get the Instance Difficulty Infos
-- @returns difficulty - Difficulty setting of the instance (number)
-- 0 - None not in an Instance.
-- 1 - 5-player Instance.
-- 2 - 5-player Heroic Instance.
-- 3 - 10-player Raid Instance.
-- 4 - 25-player Raid Instance.
-- 5 - 10-player Heroic Raid Instance.
-- 6 - 25-player Heroic Raid Instance.
-- 7 - 25-player Raid Finder Instance.
-- 8 - Challenge Mode Instance.
-- 9 - 40-player Raid Instance.
-- 10 - Not used.
-- 11 - Heroic Scenario Instance.
-- 12 - Scenario Instance.
-- 13 - Not used.
-- 14 - 10-30-player Normal Raid Instance.
-- 15 - 10-30-player Heroic Raid Instance.
-- 16 - 20-player Mythic Raid Instance .
-- 17 - 10-30-player Raid Finder Instance.
-- 18 - 40-player Event raid (Used by the level 100 version of Molten Core for WoW's 10th anniversary).
-- 19 - 5-player Event instance (Used by the level 90 version of UBRS at WoD launch).
-- 20 - 25-player Event scenario (unknown usage).
-- 21 - Not used.
-- 22 - Not used.
-- 23 - Mythic 5-player Instance.
-- 24 - Timewalker 5-player Instance.
function HL.GetInstanceDifficulty()
  return HL.GetInstanceInfo(3)
end

-- Get the time since combat has started.
function HL.CombatTime()
  return HL.CombatStarted ~= 0 and GetTime() - HL.CombatStarted or 0
end

-- Get the time since combat has ended.
function HL.OutOfCombatTime()
  return HL.CombatEnded ~= 0 and GetTime() - HL.CombatEnded or 0
end

-- Get the Boss Mod Pull Timer.
function HL.BMPullTime()
  if not HL.BossModTime or HL.BossModTime == 0 or HL.BossModEndTime - GetTime() < 0 then
    return 60
  else
    return HL.BossModEndTime - GetTime()
  end
end

do
  -- Get the Latency in seconds (the game update it every 30s).
  local Latency = 0
  local LatencyFrame = CreateFrame("Frame", "HeroLib_LatencyFrame", UIParent)
  local LatencyFrameNextUpdate = 0
  local LatencyFrameUpdateFrequency = 30 -- 30 seconds
  LatencyFrame:SetScript(
    "OnUpdate",
    function ()
      if GetTime() <= LatencyFrameNextUpdate then return end
      LatencyFrameNextUpdate = GetTime() + LatencyFrameUpdateFrequency

      local _, _, _, lagWorld = GetNetStats()
      Latency = lagWorld / 1000
    end
  )
  function HL.Latency()
    return Latency
  end

  -- Get the recovery timer based the remaining time of the GCD or the current cast (whichever is higher) in order to improve prediction.
  function HL.RecoveryTimer()
    local CastRemains = Player:CastRemains()
    local GCDRemains = Player:GCDRemains()
    return mathmax(GCDRemains, CastRemains)
  end

  -- Compute the Recovery Offset with Lag Compensation.
  -- Bypass is there in case we want to ignore it (instead of handling this bypass condition in every method the offset is called)
  function HL.RecoveryOffset(Bypass)
    if (Bypass) then return 0 end

    return Latency + HL.RecoveryTimer()
  end
end

