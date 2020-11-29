--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroDBC
local DBC = HeroDBC.DBC
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
local SoulbindNodeState = Enum.SoulbindNodeState
local Soulbinds = _G.C_Soulbinds
local wipe = wipe
-- File Locals
local ActiveSoulbindAbilities = {} -- { [SoulbindAbilitySpellID] = true }
local ActiveSoulbindConduitsByID = {} -- { [ConduitID] = Rank }
local ActiveSoulbindConduitsBySpellID = {} -- { [ConduitSpellID] = Rank }


--- ============================ CONTENT ============================
function Player:UpdateSoulbinds()
  wipe(ActiveSoulbindAbilities)
  wipe(ActiveSoulbindConduitsByID)
  wipe(ActiveSoulbindConduitsBySpellID)

  local ActiveSoulbindID = Soulbinds.GetActiveSoulbindID()
  local SoulbindData = Soulbinds.GetSoulbindData(ActiveSoulbindID)
  local Nodes = SoulbindData.tree.nodes
  table.sort(Nodes, function (a, b) return a.column < b.column end) -- Sort each column
  table.sort(Nodes, function (a, b) return a.row < b.row end) -- Sort each row

  for _, Node in pairs(Nodes) do
    local State, SpellID, ConduitID, ConduitRank = Node.state, Node.spellID, Node.conduitID, Node.conduitRank
    if State == SoulbindNodeState.Selected then
      if SpellID ~= 0 then
        ActiveSoulbindAbilities[SpellID] = true
      elseif ConduitID ~= 0 then
        ActiveSoulbindConduitsByID[ConduitID] = ConduitRank
        ActiveSoulbindConduitsBySpellID[DBC.SpellConduits[ConduitID]] = ConduitRank
      end
    end
  end

end

-- soulbind.foo.enabled (or soulbind.foo)
function Spell:SoulbindEnabled()
  return ActiveSoulbindAbilities[self:ID()] or false
end

-- conduit.foo.rank
function Spell:ConduitRank()
  return ActiveSoulbindConduitsBySpellID[self:ID()] or 0
end

-- conduit.foo.enabled (or conduit.foo)
function Spell:ConduitEnabled()
  return self:ConduitRank() > 0
end
