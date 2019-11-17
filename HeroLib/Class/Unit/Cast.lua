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
-- File Locals



--- ============================ CONTENT ============================
-- Get all the casting infos from an unit and put it into the Cache.
function Unit:GetCastingInfo(GUID)
  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end
  -- name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID
  UnitInfo.Casting = { UnitCastingInfo(self.UnitID) }
end

-- Get the Casting Infos from the Cache.
function Unit:CastingInfo(Index)
  local GUID = self:GUID()
  if GUID then
    local UnitInfo = Cache.UnitInfo[GUID]
    if not UnitInfo or not UnitInfo.Casting then
      self:GetCastingInfo(GUID)
      UnitInfo = Cache.UnitInfo[GUID]
    end
    if Index then
      return UnitInfo.Casting[Index]
    else
      return unpack(UnitInfo.Casting)
    end
  end
  return nil
end

-- Get if the unit is casting or not. Param to check if the unit is casting a specific spell or not
function Unit:IsCasting(Spell)
  if Spell then
    return self:CastingInfo(9) == Spell:ID() and true or false
  else
    return self:CastingInfo(1) and true or false
  end
end

-- Get the unit cast's name if there is any.
function Unit:CastName()
  return self:IsCasting() and self:CastingInfo(1) or ""
end

-- Get the unit cast's id if there is any.
function Unit:CastID()
  return self:IsCasting() and self:CastingInfo(10) or -1
end

--- Get all the Channeling Infos from an unit and put it into the Cache.
function Unit:GetChannelingInfo(GUID)
  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end
  UnitInfo.Channeling = { UnitChannelInfo(self.UnitID) }
end

-- Get the Channeling Infos from the Cache.
function Unit:ChannelingInfo(Index)
  local GUID = self:GUID()
  if GUID then
    local UnitInfo = Cache.UnitInfo[GUID]
    if not UnitInfo or not UnitInfo.Channeling then
      self:GetChannelingInfo(GUID)
      UnitInfo = Cache.UnitInfo[GUID]
    end
    if Index then
      return UnitInfo.Channeling[Index]
    else
      return unpack(UnitInfo.Channeling)
    end
  end
  return nil
end

-- Get if the unit is channeling or not.
function Unit:IsChanneling(Spell)
  if Spell then
    return self:ChannelName() == Spell:Name() and true or false
  else
    return self:ChannelingInfo(1) and true or false
  end
end

-- Get the unit channel's name if there is any.
function Unit:ChannelName()
  return self:IsChanneling() and self:ChannelingInfo(1) or ""
end

-- Get if the unit cast is interruptible if there is any.
function Unit:IsInterruptible()
  return (self:CastingInfo(8) == false or self:ChannelingInfo(7) == false) and true or false
end

-- Get when the cast, if there is any, started (in seconds).
function Unit:CastStart()
  if self:IsCasting() then return self:CastingInfo(4) / 1000 end
  if self:IsChanneling() then return self:ChannelingInfo(4) / 1000 end
  return 0
end

-- Get when the cast, if there is any, will end (in seconds).
function Unit:CastEnd()
  if self:IsCasting() then return self:CastingInfo(5) / 1000 end
  if self:IsChanneling() then return self:ChannelingInfo(5) / 1000 end
  return 0
end

-- Get the full duration, in seconds, of the current cast, if there is any.
function Unit:CastDuration()
  return self:CastEnd() - self:CastStart()
end

-- Get the remaining cast time, if there is any.
function Unit:CastRemains()
  if self:IsCasting() or self:IsChanneling() then
    return self:CastEnd() - GetTime()
  end
  return 0
end

-- Get the progression of the cast in percentage if there is any.
-- By default for channeling, it returns total - progress, if ReverseChannel is true it'll return only progress.
function Unit:CastPercentage(ReverseChannel)
  if self:IsCasting() then
    local CastStart = self:CastStart()
    return (GetTime() - CastStart) / (self:CastEnd() - CastStart) * 100
  end
  if self:IsChanneling() then
    local CastStart = self:CastStart()
    return ReverseChannel and (GetTime() - CastStart) / (self:CastEnd() - CastStart) * 100 or 100 - (GetTime() - CastStart) / (self:CastEnd() - CastStart) * 100
  end
  return 0
end

-- Get the cost of the current cast
function Unit:CastCost()
  local CastID = self:CastID()
  if CastID and CastID ~= -1 then
    return Spell(CastID):CostInfo(1, "cost")
  end
  return 0
end
