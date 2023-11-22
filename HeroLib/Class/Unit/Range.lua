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
local mathrandom = math.random
local pairs = pairs
local tablesort = table.sort
local type = type
local unpack = unpack
-- WoW API
local IsActionInRange = IsActionInRange
local IsSpellInRange = IsSpellInRange
-- File Locals



--- ============================ CONTENT ============================
-- IsInRangeTable generated manually by FilterItemRange
local RangeTableByType = {
  Melee = {
    Hostile = {
      RangeIndex = {},
      ItemRange = {}
    },
    Friendly = {
      RangeIndex = {},
      ItemRange = {}
    }
  },
  Ranged = {
    Hostile = {
      RangeIndex = {},
      ItemRange = {}
    },
    Friendly = {
      RangeIndex = {},
      ItemRange = {}
    }
  }
}

-- Spell table for range checking
local RangeTableBySpell = {}
RangeTableBySpell = {
  WARRIOR = {
    Hostile = {
      RangeIndex = {
        5, 8, 20, 25, 30
      },
      SpellRange = {
         [5] = {
          1464,            -- Slam
        },
         [8] = {
          5246,            -- Intimidating Shout
        },
        [20] = {
          107570,          -- Storm Bolt
        },
        [25] = {
          100,             -- Charge
        },
        [30] = {
          355,             -- Taunt
          2764,            -- Throw
          57755,           -- Heroic Throw
          384090,          -- Titanic Throw
        },
      },
    },
    Friendly = {}
  },
  PALADIN = {
    Hostile = {
      RangeIndex = {
        5, 8, 10, 20, 30, 40
      },
      SpellRange = {
         [5] = {
          35395,           -- Crusader Strike
          53600,           -- Shield of the Righteous
        },
         [8] = {
          53395,           -- Hammer of the Righteous
          96231,           -- Rebuke
        },
        [10] = {
          853,             -- Hammer of Justice
        },
        [20] = {
          10326,           -- Turn Undead
          184575,          -- Blade of Justice
        },
        [30] = {
          20271,           -- Judgment
          24275,           -- Hammer of Wrath
          31935,           -- Avenger's Shield
          62124,           -- Hand of Reckoning
          183218,          -- Hand of Hinderance
          275779,          -- Judgment
          375576,          -- Divine Toll
        },
        [40] = {
          20473,           -- Holy Shock
        },
      },
    },
    Friendly = {}
  },
  HUNTER = {
    Hostile = {
      RangeIndex = {
        5, 8, 15, 20, 30, 40, 50
      },
      SpellRange = {
         [5] = {
          186270,          -- Raptor Strike
          259387,          -- Mongoose Bite
        },
         [8] = {
          187707,          -- Muzzle
          195645,          -- Wing Clip
        },
        [15] = {
          269751,          -- Flanking Strike
        },
        [20] = {
          213691,          -- Scatter Shot
        },
        [30] = {
          109248,          -- Binding Shot
          190925,          -- Harpoon
        },
        [40] = {
          75,              -- Auto Shot
        },
        [50] = {
          34026,           -- Kill Command
          321530,          -- Bloodshed
          360966,          -- Spearhead
        },
      },
    },
    Friendly = {}
  },
  ROGUE = {
    Hostile = {
    RangeIndex = {
        5, 10, 15, 20, 25, 30
      },
      SpellRange = {
         [5] = {
          8676,            -- Ambush
          196819,          -- Eviscerate
        },
        [10] = {
          921,             -- Pick Pocket
        },
        [15] = {
          2094,            -- Blind
        },
        [20] = {
          271877,          -- Blade Rush
        },
        [25] = {
          36554,           -- Shadowstep
        },
        [30] = {
          114014,          -- Shuriken Toss
          185565,          -- Poisoned Knife
          185763,          -- Pistol Shot
        },
      },
    },
    Friendly = {}
  },
  PRIEST = {
    Hostile = {
      RangeIndex = {
        40
      },
      SpellRange = {
        [40] = {
          589,             -- Shadow Word: Pain
          8092,            -- Mind Blast
        },
      },
    },
    Friendly = {}
  },
  DEATHKNIGHT = {
    Hostile = {
      RangeIndex = {
        5, 8, 15, 30, 40
      },
      SpellRange = {
         [5] = {
          49020,           -- Obliterate
          85948,           -- Festering Strike
          195182,          -- Marrowrend
        },
         [8] = {
          207230,          -- Frostscythe
        },
        [15] = {
          47528,           -- Mind Freeze
        },
        [30] = {
          49576,           -- Death Grip
        },
        [40] = {
          305392,          -- Chill Streak
        },
      },
    },
    Friendly = {}
  },
  SHAMAN = {
    Hostile = {
      RangeIndex = {
        5, 20, 30, 40
      },
      SpellRange = {
         [5] = {
          17364            -- Stormstrike
        },
        [20] = {
          305483,          -- Lightning Lasso
        },
        [30] = {
          57994,           -- Wind Shear
        },
        [40] = {
          188196,          -- Lightning Bolt
        },
      },
    },
    Friendly = {}
  },
  MAGE = {
    Hostile = {
      RangeIndex = {
        30, 35, 40
      },
      SpellRange = {
        [30] = {
          118,             -- Polymorph
        },
        [35] = {
          31589,           -- Slow
        },
        [40] = {
          2139,            -- Counterspell
        },
      },
    },
    Friendly = {}
  },
  WARLOCK = {
    Hostile = {
      RangeIndex = {
        20, 30, 40
      },
      SpellRange = {
        [20] = {
          6789,            -- Mortal Coil
        },
        [30] = {
          710,             -- Banish
        },
        [40] = {
          686,             -- Shadow Bolt
          980,             -- Agony
          29722,           -- Incinerate
        },
      },
    },
    Friendly = {}
  },
  MONK = {
    Hostile = {
      RangeIndex = {
        5, 8, 9, 15, 20, 30, 40
      },
      SpellRange = {
         [5] = {
          100780,          -- Tiger Palm
          205523,          -- Blackout Kick (Brewmaster - PTA replaces Tiger Palm)
        },
         [8] = {
          113656,          -- Fists of Fury
        },
         [9] = {
          392983,          -- Strike of the Windlord
        },
        [15] = {
          121253,          -- Keg Smash
        },
        [20] = {
          115078,          -- Paralysis
          122470,          -- Touch of Karma
        },
        [30] = {
          115546,          -- Provoke
        },
        [40] = {
          117952,          -- Crackling Jade Lightning
        },
      },
    },
    Friendly = {}
  },
  DRUID = {
    Hostile = {
      RangeIndex = {
        5, 13, 20, 25, 40
      },
      SpellRange = {
         [5] = {
          5221,            -- Shred
          6807,            -- Maul
        },
        [13] = {
          106839,          -- Skull Bash
        },
        [20] = {
          33786,           -- Cyclone
        },
        [25] = {
          16979,           -- Feral Charge (bear)
          49376,           -- Feral Charge (cat)
          102383,          -- Feral Charge (moonkin)
          102401,          -- Feral Charge (no form)
        },
        [40] = {
          2908,            -- Soothe
          8921,            -- Moonfire
          197628,          -- Starfire
        },
      },
    },
    Friendly = {}
  },
  DEMONHUNTER = {
    Hostile = {
      RangeIndex = {
        5, 10, 15, 30, 40, 50
      },
      SpellRange = {
         [5] = {
          162794,          -- Chaos Strike
          201427,          -- Annihilation
          228477,          -- Soul Cleave
        },
        [10] = {
          183752,          -- Disrupt
        },
        [15] = {
          232893,          -- Felblade
        },
        [30] = {
          185245,          -- Torment
        },
        [40] = {
          204157,          -- Throw Glaive
        },
        [50] = {
          370965,          -- The Hunt
        },
      },
    },
    Friendly = {}
  },
  EVOKER = {
    Hostile = {
      RangeIndex = {
        25
      },
      SpellRange = {
        [25] = {
          361469,                                   -- Living Flame
          369819,                                   -- Disintegrate
        },
      }
    },
    Friendly = {
      RangeIndex = {
        25
      },
      SpellRange = {
        [25] = {
          361469,                                   -- Living Flame
        },
      },
    },
  },
}

-- Get if the unit is in range, distance check through IsSpellInRange.
-- Do keep in mind that if you're checking the range for a distance from the player (player-centered AoE like Fan of Knives),
-- you should use the radius - 1.5yds as distance (ex: instead of 10 you should use 8.5) because the player CombatReach is ignored (the distance is computed from the center to the edge, instead of edge to edge).
function Unit:IsInRange(Distance)
  assert(type(Distance) == "number", "Distance must be a number.")
  assert(Distance >= 5 and Distance <= 100, "Distance must be between 5 and 100.")

  local GUID = self:GUID()
  if not GUID then return false end

  local UnitInfo = Cache.UnitInfo[GUID]
  if not UnitInfo then
    UnitInfo = {}
    Cache.UnitInfo[GUID] = UnitInfo
  end
  local UnitInfoIsInRange = UnitInfo.IsInRange
  if not UnitInfoIsInRange then
    UnitInfoIsInRange = {}
    UnitInfo.IsInRange = UnitInfoIsInRange
  end

  local Identifier = Distance -- Considering the Distance can change if it doesn't exist we use the one passed as argument for the cache
  local IsInRange = UnitInfoIsInRange[Identifier]
  if IsInRange == nil then
    -- Select the hostile or friendly range table
    local Class = Cache.Persistent.Player.Class[2]
    local RangeTable = Player:CanAttack(self) and RangeTableBySpell[Class].Hostile or RangeTableBySpell[Class].Friendly
    if not RangeTable.RangeIndex then return false end
    local SpellRange = RangeTable.SpellRange

    -- Determine what spell to use to check range
    local CheckSpell = nil
    local RangeIndex = RangeTable.RangeIndex
    for i = #RangeIndex, 1, -1 do
      local Range = RangeIndex[i]
      if Range <= Distance then
        for _, SpellID in pairs(SpellRange[Range]) do
          if Spell(SpellID):IsLearned() then
            CheckSpell = Spell(SpellID)
            break
          end
        end
        Distance = Range - 1
      end
      if CheckSpell then break end
    end

    -- Check the range
    if not CheckSpell then return false end
    IsInRange = self:IsSpellInRange(CheckSpell)
    UnitInfoIsInRange[Identifier] = IsInRange
  end

  return IsInRange
end

-- Get if the unit is in range, distance check through IsItemInRange.
-- Melee ranges are different than Ranged one, we can only check the 5y Melee range through items at this moment.
-- If you have a spell that increase your melee range you should instead use Unit:IsInSpellRange().
-- Supported hostile ranges: 5
-- Supported friendly ranges: 5
function Unit:IsInMeleeRange(Distance)
  assert(type(Distance) == "number", "Distance must be a number.")
  assert(Distance >= 5 and Distance <= 100, "Distance must be between 5 and 100.")

  -- At this moment we cannot check multiple melee range (5, 8, 10), only the 5yds one from the item.
  -- So we use the ranged item while substracting 1.5y, which is the player hitbox radius.
  if (Distance ~= 5) then
    return self:IsInRange(Distance - 1.5)
  end

  local GUID = self:GUID()
  if not GUID then return false end

  local Class = Cache.Persistent.Player.Class[2]
  local RangeTable = Player:CanAttack(self) and RangeTableBySpell[Class].Hostile or RangeTableBySpell[Class].Friendly
  if not RangeTable.RangeIndex then return false end
  local SpellRange = RangeTable.SpellRange[Distance]

  local CheckSpell = nil
  for _, SpellID in pairs(SpellRange) do
    if Spell(SpellID):IsLearned() then
      CheckSpell = Spell(SpellID)
      return self:IsSpellInRange(CheckSpell)
    end
  end
  return false
end

-- Get if the unit is in range, distance check through IsSpellInRange (works only for targeted spells only)
function Unit:IsSpellInRange(ThisSpell)
  local GUID = self:GUID()
  if not GUID then return false end
  if ThisSpell:BookIndex() == nil then return false end
  
  return IsSpellInRange(ThisSpell:BookIndex(), ThisSpell:BookType(), self:ID()) == 1
end

-- Get if the unit is in range, distance check through IsActionInRange (works only for targeted actions only)
function Unit:IsActionInRange(ActionSlot)
  return IsActionInRange(ActionSlot, self:ID())
end

-- Find Range mixin, used by Unit:MinDistance() and Unit:MaxDistance()
local function FindRange(ThisUnit, Max)
  local RangeTableByReaction = RangeTableByType.Ranged
  local RangeTable = Player:CanAttack(ThisUnit) and RangeTableByReaction.Hostile or RangeTableByReaction.Friendly
  local RangeIndex = RangeTable.RangeIndex

  for i = #RangeIndex - (Max and 1 or 0), 1, -1 do
    if not ThisUnit:IsInRange(RangeIndex[i]) then
      return Max and RangeIndex[i + 1] or RangeIndex[i]
    end
  end
end

-- Get the minimum distance to the player, using Unit:IsInRange().
function Unit:MinDistance()
  return FindRange(self)
end

-- Get the maximum distance to the player, using Unit:IsInRange().
function Unit:MaxDistance()
  return FindRange(self, true)
end
