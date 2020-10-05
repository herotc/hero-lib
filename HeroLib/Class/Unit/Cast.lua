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
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo -- name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId
local UnitChannelInfo = UnitChannelInfo -- name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId
-- File Locals



--- ============================ CONTENT ============================
-- Get the CastingInfo (from UnitCastingInfo).
function Unit:CastingInfo()
  local UnitID = self:ID()
  if not UnitID then return end

  return UnitCastingInfo(UnitID)
end

-- Get the ChannelingInfo (from UnitChannelInfo).
function Unit:ChannelingInfo()
  local UnitID = self:ID()
  if not UnitID then return end

  return UnitChannelInfo(UnitID)
end

-- Get the unit cast's name if there is any.
function Unit:CastName()
  local CastName = self:CastingInfo()

  return CastName
end

-- Get the unit channel's name if there is any.
function Unit:ChannelName()
  local ChannelName = self:ChannelingInfo()

  return ChannelName
end

-- Get the unit cast's spell id if there is any.
function Unit:CastSpellID()
  local _, _, _, _, _, _, _, _, CastSpellID = self:CastingInfo()

  return CastSpellID
end

-- Get the unit channel's spell id if there is any.
function Unit:ChannelSpellID()
  local _, _, _, _, _, _, _, ChannelSpellID = self:ChannelingInfo()

  return ChannelSpellID
end

-- Get the cost of the current cast
function Unit:CastCost()
  local CastSpellID = self:CastSpellID()

  if CastSpellID then
    return Spell(CastSpellID):Cost(1, "cost")
  end

  return 0
end

-- Get if the unit is casting or not. Arg to check if the unit is casting a specific spell or not.
function Unit:IsCasting(ThisSpell)
  local CastName, _, _, _, _, _, _, _, CastSpellID = self:CastingInfo()

  if ThisSpell then
    return CastSpellID == ThisSpell:ID() and true or false
  end

  return CastName and true or false
end


-- Get if the unit is channeling or not.
function Unit:IsChanneling(ThisSpell)
  local ChannelName, _, _, _, _, _, _, ChannelSpellID = self:ChannelingInfo()

  if ThisSpell then
    return ChannelSpellID == ThisSpell:ID() and true or false
  end

  return ChannelName and true or false
end

-- Get if the unit cast is interruptible if there is any.
function Unit:IsInterruptible()
  local _, _, _, _, _, _, _, CastNotInterruptible = self:CastingInfo()
  local _, _, _, _, _, _, ChannelNotInterruptible = self:ChannelingInfo()

  return ((CastNotInterruptible == false or ChannelNotInterruptible == false) and true) or false
end

-- Get when the cast, if there is any, started (in seconds).
function Unit:CastStart()
  local _, _, _, CastStartTime = self:CastingInfo()
  local _, _, _, ChannelStartTime = self:ChannelingInfo()

  if CastStartTime then return CastStartTime / 1000 end
  if ChannelStartTime then return ChannelStartTime / 1000 end

  return 0
end

-- Alias of CastStart.
function Unit:ChannelStart()
  return self:CastStart()
end

-- Get when the cast, if there is any, will end (in seconds).
function Unit:CastEnd()
  local _, _, _, _, CastEndTime = self:CastingInfo()
  local _, _, _, _, ChannelEndTime = self:ChannelingInfo()

  if CastEndTime then return CastEndTime / 1000 end
  if ChannelEndTime then return ChannelEndTime / 1000 end

  return 0
end

-- Alias of CastEnd.
function Unit:ChannelEnd()
  return self:CastEnd()
end

-- Get the full duration, in seconds, of the current cast, if there is any.
function Unit:CastDuration()
  local _, _, _, CastStartTime, CastEndTime = self:CastingInfo()
  local _, _, _, ChannelStartTime, ChannelEndTime = self:ChannelingInfo()

  if CastStartTime then
    return (CastEndTime - CastStartTime) / 1000
  end
  if ChannelStartTime then
    return (ChannelEndTime - ChannelStartTime) / 1000
  end
end

-- Alias of CastDuration.
function Unit:ChannelDuration()
  return self:CastDuration()
end

-- Get the remaining cast time, if there is any.
function Unit:CastRemains()
  local CastEnd = self:CastEnd()

  return (CastEnd and (CastEnd - GetTime())) or 0
end

-- Alias of CastRemains.
function Unit:ChannelRemains()
  return self:CastRemains()
end

-- Get the progression of the cast in percentage if there is any.
-- By default for channeling, it returns total - progress, if ReverseChannel is true it'll return only progress.
function Unit:CastPercentage(ReverseChannel)
  local _, _, _, CastStartTime, CastEndTime = self:CastingInfo()
  local _, _, _, ChannelStartTime, ChannelEndTime = self:ChannelingInfo()

  if CastStartTime then
    return (GetTime() - CastStartTime) / (CastEndTime - CastStartTime) * 100
  end

  if ChannelStartTime then
    return ReverseChannel and (GetTime() - ChannelStartTime) / (ChannelEndTime - ChannelStartTime) * 100 or 100 - (GetTime() - ChannelStartTime) / (ChannelEndTime - ChannelStartTime) * 100
  end

  return 0
end

-- Alias of CastPercentage.
function Unit:ChannelPercentage(ReverseChannel)
  return self:CastPercentage(ReverseChannel)
end
