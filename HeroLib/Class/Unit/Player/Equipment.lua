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
local APIItem = Item
local Item = HL.Item
-- Lua
local GetInventoryItemID = GetInventoryItemID
local pairs = pairs
local select = select
local match = string.match
-- File Locals
local LegendaryLookupTable = {
  6823, -- Slick Ice
  6828, -- Cold Front
  6829, -- Freezing Winds
  6830, -- Glacial Fragments
  6831, -- Expanded Potential
  6832, -- Disciplinary Command
  6834, -- Temporal Warp
  6926, -- Arcane Infinity
  6927, -- Arcane Bombardment
  6928, -- Siphon Storm
  6931, -- Fevered Incantation
  6932, -- Firestorm
  6933, -- Molten Skyfall
  6934, -- Sun King's Blessing
  6936, -- Triune Ward
  6937, -- Grisly Icicle
  6940, -- Bryndaor's Might
  6941, -- Crimson Rune Weapon
  6942, -- Vampiric Aura
  6943, -- Gorefiend's Domination
  6944, -- Koltira's Favor
  6945, -- Biting Cold
  6946, -- Absolute Zero
  6947, -- Death's Embrace
  6948, -- Grip of the Everlasting
  6949, -- Reanimated Shambler
  6950, -- Frenzied Monstrosity
  6951, -- Death's Certainty
  6952, -- Deadliest Coil
  6953, -- Superstrain
  6954, -- Phearomones
  6955, -- Leaper
  6956, -- Thunderlord
  6957, -- The Wall
  6958, -- Misshapen Mirror
  6959, -- Signet of Tormented Kings
  6960, -- Battlelord
  6961, -- Exploiter
  6962, -- Enduring Blow
  6963, -- Cadence of Fujieda
  6964, -- Deathmaker
  6965, -- Reckless Defense
  6966, -- Will of the Berserker
  6967, -- Unbreakable Will
  6969, -- Reprisal
  6970, -- Unhinged
  6971, -- Seismic Reverberation
  6972, -- Vault of Heavens
  6973, -- Divine Image
  6974, -- Flash Concentration
  6975, -- Cauterizing Shadows
  6976, -- The Penitent One
  6977, -- Harmonious Apparatus
  6978, -- Crystalline Reflection
  6979, -- Kiss of Death
  6980, -- Clarity of Mind
  6981, -- Painbreaker Psalm
  6982, -- Shadowflame Prism
  6983, -- Eternal Call to the Void
  6984, -- X'anshi
  6985, -- Ancestral Reminder
  6986, -- Deeptremor Stone
  6987, -- Deeply Rooted Elements
  6988, -- Chains of Devastation
  6989, -- Skybreaker's Fiery Demise
  6990, -- Elemental Equilibrium
  6991, -- Echoes of Great Sundering
  6992, -- Windspeaker's Lava Resurgence
  6993, -- Doom Winds
  6994, -- Legacy of the Frost Witch
  6995, -- Witch Doctor's Wolf Bones
  6996, -- Primal Lava Actuators
  6997, -- Jonat's Natural Focus
  6998, -- Spiritwalker's Tidal Totem
  6999, -- Primal Tide Core
  7000, -- Earthen Harmony
  7002, -- Twins of the Sun Priestess
  7003, -- Call of the Wild
  7004, -- Nessingwary's Trapping Apparatus
  7005, -- Soulforge Embers
  7006, -- Craven Strategem
  7007, -- Dire Command
  7008, -- Flamewaker's Cobra Sting
  7009, -- Qa'pla
  7010, -- Rylakstalker's Piercing Fangs
  7011, -- Eagletalon's True Focus
  7012, -- Surging Shots
  7013, -- Serpentstalker's Trickery
  7014, -- Secrets of the Unblinking Vigil
  7015, -- Wildfire Cluster
  7016, -- Rylakstalker's Confounding Strikes
  7017, -- Latent Poison Injectors
  7018, -- Butcher's Bone Fragments
  7025, -- Wilfred's Sigil of Superior Summoning
  7026, -- Claw of Endereth
  7027, -- Relic of Demonic Synergy
  7028, -- Pillars of the Dark Portal
  7029, -- Perpetual Agony of Azj'Aqir
  7030, -- Sacrolash's Dark Strike
  7031, -- Malefic Wrath
  7032, -- Wrath of Consumption
  7033, -- Implosive Potential
  7034, -- Grim Inquisitor's Dread Calling
  7035, -- Forces of the Horned Nightmare
  7036, -- Balespider's Burning Core
  7037, -- Odr
  7038, -- Cinders of the Azj'Aqir
  7039, -- Madness of the Azj'Aqir
  7040, -- Embers of the Diabolic Raiment
  7041, -- Collective Anguish
  7043, -- Darkglare Medallion
  7044, -- Darkest Hour
  7045, -- Spirit of the Darkness Flame
  7046, -- Razelikh's Defilement
  7047, -- Fel Flame Fortification
  7048, -- Fiery Soul
  7050, -- Chaos Theory
  7051, -- Erratic Fel Core
  7052, -- Fel Bombardment
  7053, -- Uther's Devotion
  7054, -- The Mad Paragon
  7055, -- Of Dusk and Dawn
  7056, -- The Magistrate's Judgment
  7057, -- Shadowbreaker
  7058, -- Inflorescence of the Sunwell
  7059, -- Shock Barrier
  7060, -- Holy Avenger's Engraved Sigil
  7061, -- The Ardent Protector's Sanctum
  7062, -- Bulwark of Righteous Fury
  7063, -- Reign of Endless Kings
  7064, -- Final Verdict
  7065, -- Vanguard's Momentum
  7066, -- Relentless Inquisitor
  7067, -- Tempest of the Lightbringer
  7068, -- Keefer's Skyreach
  7069, -- Last Emperor's Capacitor
  7070, -- Xuen's Treasure
  7071, -- Jade Ignition
  7072, -- Tear of Morning
  7073, -- Yu'lon's Whisper
  7074, -- Clouded Focus
  7075, -- Ancient Teachings of the Monastery
  7076, -- Charred Passions
  7077, -- Stormstout's Last Keg
  7078, -- Celestial Infusion
  7079, -- Shaohao's Might
  7080, -- Swiftsure Wraps
  7081, -- Fatal Touch
  7082, -- Invoker's Delight
  7084, -- Oath of the Elder Druid
  7085, -- Circle of Life and Death
  7086, -- Draught of Deep Focus
  7087, -- Oneth's Clear Vision
  7088, -- Primordial Arcanic Pulsar
  7089, -- Cat-eye Curio
  7090, -- Eye of Fearful Symmetry
  7091, -- Apex Predator's Craving
  7092, -- Luffa-Infused Embrace
  7093, -- The Natural Order's Will
  7094, -- Ursoc's Fury Remembered
  7095, -- Legacy of the Sleeper
  7096, -- Memory of the Mother Tree
  7097, -- The Dark Titan's Lesson
  7098, -- Verdant Infusion
  7099, -- Vision of Unending Growth
  7100, -- Echo of Eonar
  7101, -- Judgment of the Arbiter
  7102, -- Norgannon's Sagacity
  7103, -- Sephuz's Proclamation
  7104, -- Stable Phantasma Lure
  7105, -- Third Eye of the Jailer
  7106, -- Vitality Sacrifice
  7107, -- Balance of All Things
  7108, -- Timeworn Dreambinder
  7109, -- Frenzyband
  7110, -- Lycara's Fleeting Glimpse
  7111, -- Mark of the Master Assassin
  7112, -- Tiny Toxic Blade
  7113, -- Essence of Bloodfang
  7114, -- Invigorating Shadowdust
  7115, -- Dashing Scoundrel
  7116, -- Doomblade
  7117, -- Zoldyck Insignia
  7118, -- Duskwalker's Patch
  7119, -- Greenskin's Wickers
  7120, -- Guile Charm
  7121, -- Celerity
  7122, -- Concealed Blunderbuss
  7123, -- Finality
  7124, -- Akaari's Soul Fragment
  7125, -- The Rotten
  7126, -- Deathly Shadows
  7128, -- Maraad's Dying Breath
  7159, -- Maw Rattle
  7160, -- Rage of the Frozen Champion
  7161, -- Measured Contemplation
  7162, -- Talbadar's Stratagem
  7184, -- Escape from Reality
  7218, -- Darker Nature
  7219, -- Burning Wound
}

--- ============================ CONTENT ============================
-- Save the current player's equipment.
HL.Equipment = {}
HL.OnUseTrinkets = {}
function HL.GetEquipment()
  local ItemID
  HL.Equipment = {}
  HL.OnUseTrinkets = {}

  for i = 1, 19 do
    ItemID = select(1, GetInventoryItemID("player", i))
    -- If there is an item in that slot
    if ItemID ~= nil then
      HL.Equipment[i] = ItemID
      if (i == 13 or i == 14) then
        local TrinketItem = HL.Item(ItemID, {i})
        if TrinketItem:IsUsable() then
          table.insert(HL.OnUseTrinkets, TrinketItem)
        end
      end
    end
  end
end

function HL.GetLegendaries()
  HL.LegendaryEffects = {}
  local LegendaryItems = {}
  for i = 1, 12, 1 do
    local ItemObject = APIItem:CreateFromEquipmentSlot(i)
    if ItemObject:GetItemQuality() == 5 then
      table.insert(LegendaryItems, ItemObject)
    end
  end

  for _, item in pairs(LegendaryItems) do
    local itemLink = item:GetItemLink()
    for _, legEffect in pairs(LegendaryLookupTable) do
      if itemLink and match(itemLink, legEffect) then
        HL.LegendaryEffects[legEffect] = true
      end
    end
  end
end

function HL.LegendaryEnabled(effect)
  return HL.LegendaryEffects[effect] ~= nil
end

-- Check if the trinket is coded as blacklisted by the user or not.
local function IsUserTrinketBlacklisted(TrinketItem)
  if not TrinketItem then return false end
  if HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItem:ID()] then
    if type(HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItem:ID()]) == "boolean" then
      return true
    else
      return HL.GUISettings.General.Blacklist.TrinketUserDefined[TrinketItem:ID()](TrinketItem)
    end
  end
  return false
end

-- Function to be called against SimC's use_items
function HL.UseTrinkets(ExcludedTrinkets)
  for _, TrinketItem in ipairs(HL.OnUseTrinkets) do
  local isExcluded = false
    -- Check if the trinket is ready, unless it's blacklisted
    if TrinketItem:IsReady() and not IsUserTrinketBlacklisted(TrinketItem) then
      for i=1,#ExcludedTrinkets do
        if (ExcludedTrinkets[i] == TrinketItem:ID()) then
          isExcluded = true
          break
        end
      end
      if (not isExcluded) then
        return TrinketItem
      end
    end
  end
  return nil
end
