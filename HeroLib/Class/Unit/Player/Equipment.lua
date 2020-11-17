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
local GetRuneforgeLegendaryComponentInfo = C_LegendaryCrafting.GetRuneforgeLegendaryComponentInfo
local IsRuneforgeLegendary = C_LegendaryCrafting.IsRuneforgeLegendary
local GetInventoryItemID = GetInventoryItemID
local ItemLocation = ItemLocation
local pairs = pairs
local select = select
local match = string.match
-- File Locals

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

-- Create a table of active Shadowlands legendaries
function HL.GetLegendaries()
  HL.LegendaryEffects = HL.LegendaryEffects and wipe(HL.LegendaryEffects) or {}

  for i = 1, 15, 1 do
    if (i ~= 13 and i ~= 14) then -- No trinket legendaries currently
      local Item = ItemLocation:CreateFromEquipmentSlot(i)
      if Item:IsValid() and IsRuneforgeLegendary(Item) then
        local LegendaryInfo = GetRuneforgeLegendaryComponentInfo(Item)
        HL.LegendaryEffects[LegendaryInfo.powerID] = true
      end
    end
  end
end

-- Check if a specific legendary is active, using the effect's ID
-- legendaryID, bonusID, legendaryName
-- 2, 6823, Slick Ice
-- 3, 6828, Cold Front
-- 4, 6829, Freezing Winds
-- 5, 6830, Glacial Fragments
-- 6, 6831, Expanded Potential
-- 7, 6832, Disciplinary Command
-- 8, 6937, Grisly Icicle
-- 9, 6834, Temporal Warp
-- 10, 6931, Fevered Incantation
-- 11, 6932, Firestorm
-- 12, 6933, Molten Skyfall
-- 13, 6934, Sun King's Blessing
-- 14, 6926, Arcane Infinity
-- 15, 6927, Arcane Bombardment
-- 16, 6928, Siphon Storm
-- 17, 6936, Triune Ward
-- 18, 7041, Collective Anguish
-- 19, 7052, Fel Bombardment
-- 20, 7043, Darkglare Medallion
-- 21, 7044, Darkest Hour
-- 22, 7218, Darker Nature
-- 23, 7050, Chaos Theory
-- 24, 7051, Erratic Fel Core
-- 25, 7219, Burning Wound
-- 26, 7045, Spirit of the Darkness Flame
-- 27, 7046, Razelikh's Defilement
-- 28, 7047, Fel Flame Fortification
-- 29, 7048, Fiery Soul
-- 30, 6953, Superstrain
-- 31, 6954, Phearomones
-- 32, 6947, Death's Embrace
-- 33, 6948, Grip of the Everlasting
-- 34, 6940, Bryndaor's Might
-- 35, 6941, Crimson Rune Weapon
-- 36, 6943, Gorefiend's Domination
-- 37, 6942, Vampiric Aura
-- 38, 6944, Koltira's Favor
-- 39, 6945, Biting Cold
-- 40, 6946, Absolute Zero
-- 41, 7160, Rage of the Frozen Champion
-- 42, 6949, Reanimated Shambler
-- 43, 6950, Frenzied Monstrosity
-- 44, 6951, Death's Certainty
-- 45, 6952, Deadliest Coil
-- 46, 7086, Draught of Deep Focus
-- 47, 7085, Circle of Life and Death
-- 48, 7110, Lycara's Fleeting Glimpse
-- 49, 7084, Oath of the Elder Druid
-- 50, 7087, Oneth's Clear Vision
-- 51, 7088, Primordial Arcanic Pulsar
-- 52, 7107, Balance of All Things
-- 53, 7108, Timeworn Dreambinder
-- 54, 7109, Frenzyband
-- 55, 7091, Apex Predator's Craving
-- 56, 7090, Eye of Fearful Symmetry
-- 57, 7089, Cat-eye Curio
-- 58, 7092, Luffa-Infused Embrace
-- 59, 7093, The Natural Order's Will
-- 60, 7094, Ursoc's Fury Remembered
-- 61, 7095, Legacy of the Sleeper
-- 62, 7096, Memory of the Mother Tree
-- 63, 7097, The Dark Titan's Lesson
-- 64, 7098, Verdant Infusion
-- 65, 7099, Vision of Unending Growth
-- 66, 7003, Call of the Wild
-- 67, 7004, Nessingwary's Trapping Apparatus
-- 68, 7005, Soulforge Embers
-- 69, 7006, Craven Strategem
-- 70, 7007, Dire Command
-- 71, 7008, Flamewaker's Cobra Sting
-- 72, 7009, Qa'pla, Eredun War Order
-- 73, 7010, Rylakstalker's Piercing Fangs
-- 74, 7011, Eagletalon's True Focus
-- 75, 7012, Surging Shots
-- 76, 7013, Serpentstalker's Trickery
-- 77, 7014, Secrets of the Unblinking Vigil
-- 78, 7015, Wildfire Cluster
-- 79, 7016, Rylakstalker's Confounding Strikes
-- 80, 7017, Latent Poison Injectors
-- 81, 7018, Butcher's Bone Fragments
-- 82, 7184, Escape from Reality
-- 83, 7082, Invoker's Delight
-- 84, 7080, Swiftsure Wraps
-- 85, 7081, Fatal Touch
-- 86, 7076, Charred Passions
-- 87, 7077, Stormstout's Last Keg
-- 88, 7078, Celestial Infusion
-- 89, 7079, Shaohao's Might
-- 90, 7075, Ancient Teachings of the Monastery
-- 91, 7073, Yu'lon's Whisper
-- 92, 7074, Clouded Focus
-- 93, 7072, Tear of Morning
-- 94, 7070, Xuen's Treasure
-- 95, 7068, Keefer's Skyreach
-- 96, 7071, Jade Ignition
-- 97, 7069, Last Emperor's Capacitor
-- 98, 7053, Uther's Devotion
-- 100, 7055, Of Dusk and Dawn
-- 101, 7056, The Magistrate's Judgment
-- 102, 7128, Maraad's Dying Breath
-- 103, 7059, Shock Barrier
-- 104, 7057, Shadowbreaker, Dawn of the Sun
-- 105, 7058, Inflorescence of the Sunwell
-- 106, 7060, Holy Avenger's Engraved Sigil
-- 107, 7061, The Ardent Protector's Sanctum
-- 108, 7062, Bulwark of Righteous Fury
-- 109, 7063, Reign of Endless Kings
-- 110, 7067, Tempest of the Lightbringer
-- 111, 7066, Relentless Inquisitor
-- 112, 7065, Vanguard's Momentum
-- 113, 7064, Final Verdict
-- 114, 7114, Invigorating Shadowdust
-- 115, 7113, Essence of Bloodfang
-- 116, 7112, Tiny Toxic Blade
-- 117, 7111, Mark of the Master Assassin
-- 118, 7115, Dashing Scoundrel
-- 119, 7116, Doomblade
-- 120, 7117, Zoldyck Insignia
-- 121, 7118, Duskwalker's Patch
-- 122, 7122, Concealed Blunderbuss
-- 123, 7121, Celerity
-- 124, 7120, Guile Charm
-- 125, 7119, Greenskin's Wickers
-- 126, 7123, Finality
-- 127, 7124, Akaari's Soul Fragment
-- 128, 7125, The Rotten
-- 129, 7126, Deathly Shadows
-- 130, 6985, Ancestral Reminder
-- 131, 6986, Deeptremor Stone
-- 132, 6987, Deeply Rooted Elements
-- 133, 6988, Chains of Devastation
-- 134, 6989, Skybreaker's Fiery Demise
-- 135, 6990, Elemental Equilibrium
-- 136, 6991, Echoes of Great Sundering
-- 137, 6992, Windspeaker's Lava Resurgence
-- 138, 6993, Doom Winds
-- 139, 6994, Legacy of the Frost Witch
-- 140, 6995, Witch Doctor's Wolf Bones
-- 141, 6996, Primal Lava Actuators
-- 142, 6997, Jonat's Natural Focus
-- 143, 6998, Spiritwalker's Tidal Totem
-- 144, 6999, Primal Tide Core
-- 145, 7000, Earthen Harmony
-- 146, 7161, Measured Contemplation
-- 147, 7002, Twins of the Sun Priestess
-- 148, 6975, Cauterizing Shadows
-- 149, 6972, Vault of Heavens
-- 150, 6976, The Penitent One
-- 151, 6978, Crystalline Reflection
-- 152, 6979, Kiss of Death
-- 153, 6980, Clarity of Mind
-- 154, 6984, X'anshi, Return of Archbishop Benedictus
-- 155, 6977, Harmonious Apparatus
-- 156, 6974, Flash Concentration
-- 157, 6973, Divine Image
-- 158, 6981, Painbreaker Psalm
-- 159, 6982, Shadowflame Prism
-- 160, 6983, Eternal Call to the Void
-- 161, 7162, Talbadar's Stratagem
-- 162, 7025, Wilfred's Sigil of Superior Summoning
-- 163, 7026, Claw of Endereth
-- 164, 7027, Relic of Demonic Synergy
-- 165, 7028, Pillars of the Dark Portal
-- 166, 7029, Perpetual Agony of Azj'Aqir
-- 167, 7030, Sacrolash's Dark Strike
-- 168, 7031, Malefic Wrath
-- 169, 7032, Wrath of Consumption
-- 170, 7033, Implosive Potential
-- 171, 7034, Grim Inquisitor's Dread Calling
-- 172, 7035, Forces of the Horned Nightmare
-- 173, 7036, Balespider's Burning Core
-- 174, 7037, Odr, Shawl of the Ymirjar
-- 175, 7038, Cinders of the Azj'Aqir
-- 176, 7039, Madness of the Azj'Aqir
-- 177, 7040, Embers of the Diabolic Raiment
-- 178, 6955, Leaper
-- 179, 6971, Seismic Reverberation
-- 180, 6958, Misshapen Mirror
-- 181, 6959, Signet of Tormented Kings
-- 182, 6962, Enduring Blow
-- 183, 6960, Battlelord
-- 184, 6961, Exploiter
-- 185, 6970, Unhinged
-- 186, 6963, Cadence of Fujieda
-- 187, 6964, Deathmaker
-- 188, 6965, Reckless Defense
-- 189, 6966, Will of the Berserker
-- 190, 6956, Thunderlord
-- 191, 6957, The Wall
-- 192, 6967, Unbreakable Will
-- 193, 6969, Reprisal
-- 196, 7054, The Mad Paragon
-- 199, 7100, Echo of Eonar
-- 200, 7101, Judgment of the Arbiter
-- 201, 7102, Norgannon's Sagacity
-- 202, 7103, Sephuz's Proclamation
-- 203, 7104, Stable Phantasma Lure
-- 204, 7105, Third Eye of the Jailer
-- 205, 7106, Vitality Sacrifice
-- 206, 7159, Maw Rattle
function HL.LegendaryEnabled(legendaryID)
  return HL.LegendaryEffects[legendaryID] ~= nil
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
