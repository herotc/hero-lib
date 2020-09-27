--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroDBC
local DBC = HeroDBC.DBC
-- HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Pet = Unit.Pet
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local pairs = pairs
local tableinsert = table.insert
local mathmax = math.max
local GetTime = GetTime
-- File Locals
local TriggerGCD = DBC.SpellGCD -- TriggerGCD table until it has been filtered.
local LastRecord = 15
local PrevGCDPredicted = 0
local PrevGCDCastTime = 0
local PrevOffGCDCastTime = 0
local Prev = {
  GCD = {},
  OffGCD = {},
  PetGCD = {},
  PetOffGCD = {},
}
local Custom = {
  Whitelist = {},
  Blacklist = {}
}
local PrevSuggested = {
  Spell = nil,
  Time = 0
}
local GCDSpell = Spell(61304)

--- ============================ CONTENT ============================

-- Init all the records at 0, so it saves one check on PrevGCD method.
for i = 1, LastRecord do
  for _, Table in pairs(Prev) do
    tableinsert(Table, 0)
  end
end

-- Clear Old Records
local function RemoveOldRecords()
  for _, Table in pairs(Prev) do
    local n = #Table
    while n > LastRecord do
      Table[n] = nil
      n = n - 1
    end
  end
end

-- Player On Cast Success Listener
HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    HL.Timer.LastCastSuccess = GetTime()
    if TriggerGCD[SpellID] ~= nil then
      if TriggerGCD[SpellID] then
        -- HL.Print(GetTime() .. " Self SPELL_CAST_SUCCESS " .. SpellID)
        tableinsert(Prev.GCD, 1, SpellID)
        PrevGCDCastTime = GetTime()
        Prev.OffGCD = {}
        PrevOffGCDCastTime = 0
        PrevGCDPredicted = 0
      else -- Prevents unwanted spells to be registered as OffGCD.
        tableinsert(Prev.OffGCD, 1, SpellID)
        PrevOffGCDCastTime = GetTime()
        PrevGCDCastTime = 0
      end
    end
    RemoveOldRecords()
  end,
  "SPELL_CAST_SUCCESS"
)

HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    if TriggerGCD[SpellID] then
      PrevGCDPredicted = SpellID
    end
  end,
  "SPELL_CAST_START"
)
HL:RegisterForSelfCombatEvent(
  function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    if PrevGCDPredicted == SpellID then
      PrevGCDPredicted = 0
    end
  end,
  "SPELL_CAST_FAILED"
)

-- Pet On Cast Success Listener
HL:RegisterForPetCombatEvent(
  function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    if TriggerGCD[SpellID] ~= nil then
      if TriggerGCD[SpellID] then
        tableinsert(Prev.PetGCD, 1, SpellID)
        Prev.PetOffGCD = {}
      else -- Prevents unwanted spells to be registered as OffGCD.
        tableinsert(Prev.PetOffGCD, 1, SpellID)
      end
    end
    RemoveOldRecords()
  end,
  "SPELL_CAST_SUCCESS"
)

-- Filter the Enum TriggerGCD table to keep only registered spells for a given class (based on SpecID).
function Player:FilterTriggerGCD(SpecID)
  local RegisteredSpells = {}
  local BaseTriggerGCD = DBC.SpellGCD -- In case FilterTriggerGCD is called multiple time, we take the Enum table as base.
  -- Fetch registered spells during the init
  for Spec, Spells in pairs(HL.Spell[HL.SpecID_ClassesSpecs[SpecID][1]]) do
    for _, Spell in pairs(Spells) do
      local SpellID = Spell:ID()
      local TriggerGCDInfo = BaseTriggerGCD[SpellID]
      if TriggerGCDInfo ~= nil then
        RegisteredSpells[SpellID] = (TriggerGCDInfo > 0)
      end
    end
  end
  -- Add Spells based on the Whitelist
  for SpellID, Value in pairs(Custom.Whitelist) do
    RegisteredSpells[SpellID] = Value
  end
  -- Remove Spells based on the Blacklist
  for i = 1, #Custom.Blacklist do
    local SpellID = Custom.Blacklist[i]
    if RegisteredSpells[SpellID] then
      RegisteredSpells[SpellID] = nil
    end
  end
  TriggerGCD = RegisteredSpells
end

-- Add spells in the Trigger GCD Whitelist
function Spell:AddToTriggerGCD(Value)
  if type(Value) ~= "boolean" then error("You must give a boolean as argument.") end
  Custom.Whitelist[self.SpellID] = Value
end

-- Add spells in the Trigger GCD Blacklist
function Spell:RemoveFromTriggerGCD()
  tableinsert(Custom.Blacklist, self.SpellID)
end

-- Time of the last on-GCD SPELL_CAST_SUCCESS
function Player:PrevGCDTime()
  return PrevGCDCastTime
end

-- Time of the last off-GCD SPELL_CAST_SUCCESS
function Player:PrevOffGCDTime()
  return PrevOffGCDCastTime
end

-- Time of the last SPELL_CAST_SUCCESS of any type
function Player:PrevCastTime()
  return mathmax(PrevGCDCastTime, PrevOffGCDCastTime)
end

-- Returns if a GCD has been started but we don't yet know what the spell is
function Player:IsPrevCastPending()
  -- If we recieved a SPELL_CAST_START event, we know about the cast
  if PrevGCDPredicted > 0 then
    return false
  end

  -- Otherwise, check to see if the GCD was started after the last known SPELL_CAST_SUCCESS
  local GCDStartTime, GCDDuration = GCDSpell:CooldownInfo()
  if GCDDuration > 0 and GCDStartTime > PrevGCDCastTime then
    return true
  end

  return false
end

-- Sets the last known tracked suggestion before the start of the next GCD
function Player:SetPrevSuggestedSpell(SuggestedSpell)
  if SuggestedSpell == nil or SuggestedSpell.SpellID ~= nil then
    -- Don't update the previous suggested spell if we are currently on the GCD
    local GCDStartTime, GCDDuration = GCDSpell:CooldownInfo()
    if GCDDuration > 0 and GCDStartTime > PrevGCDCastTime then
      return
    end
    PrevSuggested.Spell = SuggestedSpell
    PrevSuggested.Time = GetTime()
  end
end

-- prev_gcd.x.foo
function Player:PrevGCD(Index, Spell)
  if Index > LastRecord then error("Only the last " .. LastRecord .. " GCDs can be checked.") end
  if Spell then
    return Prev.GCD[Index] == Spell:ID()
  else
    return Prev.GCD[Index]
  end
end

-- Player:PrevGCD with cast start prediction
function Player:PrevGCDP(Index, Spell, ForcePred)
  if Index > LastRecord then error("Only the last " .. (LastRecord) .. " GCDs can be checked.") end

  -- If we don't have a PrevGCDPredicted from SPELL_CAST_START, attempt to use the last suggested spell instead
  -- This is only used when the local GCD has begun but a SPELL_CAST_SUCCESS has not yet fired to determine what the spell is
  local PredictedGCD = PrevGCDPredicted
  if PredictedGCD == 0 and PrevSuggested.Spell and PrevSuggested.Time > PrevGCDCastTime then
    local SpellId = PrevSuggested.Spell:ID()
    local GCDStartTime, GCDDuration = GCDSpell:CooldownInfo()
    if GCDDuration > 0 and GCDStartTime > PrevGCDCastTime and TriggerGCD[SpellId] then
      PredictedGCD = SpellId
    end
  end

  if PredictedGCD > 0 and Index == 1 or ForcePred then
    return PredictedGCD == Spell:ID()
  elseif PredictedGCD > 0 then
    return Player:PrevGCD(Index - 1, Spell)
  else
    return Player:PrevGCD(Index, Spell)
  end
end

-- prev_off_gcd.x.foo
function Player:PrevOffGCD(Index, Spell)
  if Index > LastRecord then error("Only the last " .. LastRecord .. " OffGCDs can be checked.") end
  return Prev.OffGCD[Index] == Spell:ID()
end

-- Player:PrevOffGCD with cast start prediction
function Player:PrevOffGCDP(Index, Spell)
  if Index > LastRecord then error("Only the last " .. (LastRecord) .. " GCDs can be checked.") end
  if PrevGCDPredicted > 0 and Index == 1 then
    return false
  elseif PrevGCDPredicted > 0 then
    return Player:PrevOffGCD(Index - 1, Spell)
  else
    return Player:PrevOffGCD(Index, Spell)
  end
end

-- "pet.prev_gcd.x.foo"
function Pet:PrevGCD(Index, Spell)
  if Index > LastRecord then error("Only the last " .. LastRecord .. " GCDs can be checked.") end
  return Prev.PetGCD[Index] == Spell:ID()
end

-- "pet.prev_off_gcd.x.foo"
function Pet:PrevOffGCD(Index, Spell)
  if Index > LastRecord then error("Only the last " .. LastRecord .. " OffGCDs can be checked.") end
  return Prev.PetOffGCD[Index] == Spell:ID()
end
