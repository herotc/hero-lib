--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, HL = ...
-- HeroLib
local Cache, Utils = HeroCache, HL.Utils
local Unit = HL.Unit
local Player = Unit.Player
local Pet = Unit.Pet
local Target = Unit.Target
local Spell = HL.Spell
local Item = HL.Item
-- Lua
local CreateFrame = CreateFrame
local UIParent = UIParent
local GetTime = GetTime
local UnitGUID = UnitGUID
local pairs = pairs
local tableinsert = table.insert
local tablesort = table.sort
local tableremove = table.remove
local wipe = table.wipe
-- File Locals
local Splash = {}
local SPLASH_TRACKER_TIMEOUT = 3 -- 3000ms
local NucleusAbilities = {} -- Every abilities that are used in order to compute splash data. { [SpellID] = { Type, Radius } }
local FriendTargets = {} -- Track the targets of our friend (player, party, raid, pets, ...) in order to potentially assign the splash to their target (see NucleusAbility type). { [FriendGUID] = FriendTargetGUID }
local TrackerBuffer = {} -- Buffer of the tracker since splash is coming from multiple events. { [SpellID] = { [SourceGUID] = { FirstTime, FriendTargetGUID, FirstDestGUID, Enemies = { GUID, LastTime, LastSpellID } } } }
local Tracker = {} -- Track each enemies from where we splash from. { [PrimaryEnemyGUID] = { [Radius] = { [EnemyGUID] = { GUID, LastDamageTime, LastDamageSpellID } } } }

--- ======= GLOBALIZE =======
HL.SplashEnemies = Splash


--- ============================ CONTENT ============================
-- Update the targets of our friends.
do
  local StartsWith = Utils.StartsWith
  -- TODO: Add more available tracking like choosing between tanks, melees, ranged, etc...
  -- Who are the friend units we are tracking
  local FRIEND_TARGETS_TRACKING_ALL = 1 -- "All": Player + Party/Raid and their Pet
  local FRIEND_TARGETS_TRACKING_MINE = 2 -- "Mine Only": Player and his Pet
  local FriendTargetsTracking = FRIEND_TARGETS_TRACKING_ALL
  local function UpdateFriendTarget(UnitID)
    local FriendGUID = UnitGUID(UnitID)
    local TargetGUID = UnitGUID(UnitID .. "target")
    if FriendGUID then
      FriendTargets[FriendGUID] = TargetGUID
    end
  end
  local function UpdateGroupData()
    if Player:IsInRaid() then
      SPLASH_TRACKER_TIMEOUT = 3
    elseif Player:IsInDungeon() then
      SPLASH_TRACKER_TIMEOUT = 4
    else
      SPLASH_TRACKER_TIMEOUT = 5
    end

    -- Player update
    UpdateFriendTarget("player")
    UpdateFriendTarget("pet")
    -- Party/Raid update
    if FriendTargetsTracking == FRIEND_TARGETS_TRACKING_ALL then
      for _, PartyUnit in pairs(Unit.Party) do
        local UnitID = PartyUnit:ID()
        UpdateFriendTarget(UnitID)
        UpdateFriendTarget(UnitID .. "pet")
      end
      for _, RaidUnit in pairs(Unit.Raid) do
        local UnitID = RaidUnit:ID()
        UpdateFriendTarget(UnitID)
        UpdateFriendTarget(UnitID .. "pet")
      end
    end
  end

  -- OnInit
  UpdateGroupData()
  -- OnCombatEnter, OnGroupUpdate
  HL:RegisterForEvent(UpdateGroupData, "PLAYER_REGEN_DISABLED", "GROUP_ROSTER_UPDATE")
  -- OnTargetUpdate
  HL:RegisterForEvent(
    function(Event, UnitID)
      if FriendTargetsTracking == FRIEND_TARGETS_TRACKING_ALL and not StartsWith(UnitID, "player") and not StartsWith(UnitID, "pet") and not StartsWith(UnitID, "party") and not StartsWith(UnitID, "raid") then
        return
      end
      if FriendTargetsTracking == FRIEND_TARGETS_TRACKING_MINE and not StartsWith(UnitID, "player") and not StartsWith(UnitID, "pet") then
        return
      end

      UpdateFriendTarget(UnitID)
    end,
    "UNIT_TARGET"
  )
  HL:RegisterForEvent(
    function(Event, UnitID)
      if FriendTargetsTracking == FRIEND_TARGETS_TRACKING_ALL and not StartsWith(UnitID, "player") and not StartsWith(UnitID, "party") and not StartsWith(UnitID, "raid") then
        return
      end
      if FriendTargetsTracking == FRIEND_TARGETS_TRACKING_MINE and not StartsWith(UnitID, "player") then
        return
      end

      UpdateFriendTarget(UnitID .. "pet")
    end,
    "UNIT_PET"
  )

  function Splash.ChangeFriendTargetsTracking(NewTracking)
    assert(type(NewTracking) == "string" and (NewTracking == "All" or NewTracking == "Mine Only"), "Invalid Tracking.")

    if NewTracking == "All" then
      FriendTargetsTracking= FRIEND_TARGETS_TRACKING_ALL
    elseif NewTracking == "Mine Only" then
      FriendTargetsTracking = FRIEND_TARGETS_TRACKING_MINE
    end
  end
end

-- Update the tracker using damage from the combatlog.
do
  local function UpdateSplashes(_, Event, _, SourceGUID, _, _, _, DestGUID, _, _, _, SpellID)
    -- Check if the ability used to damage the unit is valid.
    local NucleusAbility = NucleusAbilities[SpellID]
    if not NucleusAbility then return end

    -- Stop processing if the event is not corresponding to the type of the NucleusAbility.
    if Event ~= "SPELL_DAMAGE" and (NucleusAbility.Type == "TargetDirectDamage" or NucleusAbility.Type == "SourceDirectDamage") then return end

    -- Check if the SourceGUID is valid.
    local FriendTargetGUID = FriendTargets[SourceGUID]
    if not FriendTargetGUID then return end

    -- Retrieve the buffer or create it.
    local Buffer = TrackerBuffer[SpellID][SourceGUID]
    if not Buffer then
      -- Buffer are created only on SPELL_DAMAGE event, it should always be the case though.
      if Event ~= "SPELL_DAMAGE" then return end

      -- HL.Print("[SplashEnemies] Creating buffer for SpellID '" .. SpellID .. "' from SourceGUID '" .. SourceGUID .. "'.")
      Buffer = { FirstTime = GetTime(), FriendTargetGUID = FriendTargetGUID, FirstDestGUID = DestGUID, Enemies = { { GUID = DestGUID, LastTime = GetTime(), LastSpellID = SpellID } } }
      TrackerBuffer[SpellID][SourceGUID] = Buffer

      -- Stop here since we already process the enemy on buffer creation
      return
    end

    -- Find the enemy if it exists in order to update it, otherwise insert it.
    local DestEnemy
    local BufferEnemies = Buffer.Enemies
    for i = 1, #BufferEnemies do
      local BufferEnemy = BufferEnemies[i]
      if BufferEnemy.GUID == DestGUID then
        DestEnemy = BufferEnemy
        break
      end
    end
    if DestEnemy then
      -- HL.Print("[SplashEnemies] Updating enemy with GUID '" .. DestGUID .. "' in buffer with SpellID '" .. SpellID .. "' from SourceGUID '" .. SourceGUID .. "'.")
      DestEnemy.LastTime = GetTime()
      DestEnemy.LastSpellID = SpellID
    else
      -- HL.Print("[SplashEnemies] Adding enemy with GUID '" .. DestGUID .. "' in buffer with SpellID '" .. SpellID .. "' from SourceGUID '" .. SourceGUID .. "'.")
      DestEnemy = { GUID = DestGUID, LastTime = GetTime(), LastSpellID = SpellID }
      tableinsert(BufferEnemies, DestEnemy)
    end
  end

  HL:RegisterForCombatEvent(UpdateSplashes, "SPELL_DAMAGE", "SPELL_AURA_APPLIED", "SPELL_AURA_REFRESH", "SPELL_AURA_APPLIED_DOSE")
end

-- Process the tracker buffer every 50ms.
do
  local SplashBufferFrame = CreateFrame("Frame", "HeroLib_SplashBufferFrame", UIParent)
  local SplashBufferFrameNextUpdate = 0
  local SplashBufferFrameUpdateFrequency = 0.05 -- 50ms
  SplashBufferFrame:SetScript(
    "OnUpdate",
    function ()
      if GetTime() <= SplashBufferFrameNextUpdate then return end
      SplashBufferFrameNextUpdate = GetTime() + SplashBufferFrameUpdateFrequency

      local BufferThresholdTime = GetTime() - SplashBufferFrameUpdateFrequency
      for SpellID, BufferBySourceGUID in pairs(TrackerBuffer) do
        local NucleusAbility = NucleusAbilities[SpellID]

        for SourceGUID, Buffer in pairs(BufferBySourceGUID) do
          -- Do process only the buffer that are old enough.
          if Buffer.FirstTime <= BufferThresholdTime then
            local BufferEnemies = Buffer.Enemies

            -- Assign the correct PrimaryTargetGUID (see Type explanation).
            local PrimaryEnemyGUID = BufferEnemies[1].GUID -- Takes the first enemy we hit, either for "SourceDirectDamage" or "TargetDirectDamage".
            if NucleusAbility.Type == "TargetDirectDamage" then
              local FriendTargetGUID = Buffer.FriendTargetGUID
              for i = 1, #BufferEnemies do
                local Enemy = BufferEnemies[i]
                if Enemy.GUID == FriendTargetGUID then
                  PrimaryEnemyGUID = Enemy.GUID
                  break
                end
              end
            elseif NucleusAbility.Type == "TargetPeriodicDamage" then
              PrimaryEnemyGUID = Buffer.FirstDestGUID
            end

            -- Retrieve the tracker entry or create it.
            local EnemiesByRadius = Tracker[PrimaryEnemyGUID]
            if not EnemiesByRadius then
              -- HL.Print("[SplashEnemies] Creating enemies by radius table for PrimaryEnemyGUID '" .. PrimaryEnemyGUID .. "'.")
              EnemiesByRadius = {}
              Tracker[PrimaryEnemyGUID] = EnemiesByRadius
            end

            -- Retrieve the enemies table in order to update it or create it from the buffer.
            local Enemies = EnemiesByRadius[NucleusAbility.Radius]
            if not Enemies then
              -- HL.Print("[SplashEnemies] Creating enemies table within '" .. NucleusAbility.Radius .. "y' radius of enemy with GUID '" .. PrimaryEnemyGUID .. ".")
              Enemies = {}
              EnemiesByRadius[NucleusAbility.Radius] = Enemies
            end

            -- Iterate to find the enemy if it exists in order to update it, otherwise add it.
            for i = 1, #BufferEnemies do
              local BufferEnemy = BufferEnemies[i]
              local Enemy = Enemies[BufferEnemy.GUID]
              if Enemy then
                if (BufferEnemy.LastTime > Enemy.LastTime) then
                  -- HL.Print("[SplashEnemies] Updating enemy with GUID '" .. BufferEnemy.GUID .. "' in enemies table within '" .. NucleusAbility.Radius .. "y' radius of enemy with GUID '" .. PrimaryEnemyGUID .. ".")
                  Enemy.LastTime = BufferEnemy.LastTime
                  Enemy.LastSpellID = BufferEnemy.LastSpellID
                end
              else
                -- HL.Print("[SplashEnemies] Adding enemy with GUID '" .. BufferEnemy.GUID .. "' in enemies table within '" .. NucleusAbility.Radius .. "y' radius of enemy with GUID '" .. PrimaryEnemyGUID .. ".")
                Enemies[BufferEnemy.GUID] = BufferEnemy
                --Enemies[BufferEnemy.GUID] = { GUID = BufferEnemy.GUID, LastTime = BufferEnemy.LastTime, LastSpellID = BufferEnemy.LastSpellID }
              end
            end

            -- Remove the buffer
            BufferBySourceGUID[SourceGUID] = nil
          end
        end
      end
    end
  )
end

-- Clear the enemies that timed out from the tracker every 250ms.
do
  local SplashCleanerFrame = CreateFrame("Frame", "HeroLib_SplashCleanerFrame", UIParent)
  local SplashCleanerFrameNextUpdate = 0
  local SplashCleanerFrameUpdateFrequency = 0.25 -- 250ms
  SplashCleanerFrame:SetScript(
    "OnUpdate",
    function ()
      if GetTime() <= SplashCleanerFrameNextUpdate then return end
      SplashCleanerFrameNextUpdate = GetTime() + SplashCleanerFrameUpdateFrequency

      local TimeoutTime = GetTime() - SPLASH_TRACKER_TIMEOUT
      for PrimaryEnemyGUID, EnemiesByRadius in pairs(Tracker) do
        for Radius, Enemies in pairs(EnemiesByRadius) do
          local EnemiesCount = 0
          -- Remove expired enemies
          for EnemyGUID, Enemy in pairs(Enemies) do
            if Enemy.LastTime <= TimeoutTime then
              -- HL.Print("[SplashEnemies] Removing enemy with GUID '" .. EnemyGUID .. "' from enemies table within '" .. Radius .. "y' radius of enemy with GUID '" .. PrimaryEnemyGUID .. "' due to timeout.")
              Enemies[EnemyGUID] = nil
            else
              EnemiesCount = EnemiesCount + 1
            end
          end
          -- Remove the entry if it does not contain any enemy
          if EnemiesCount == 0 then
            -- HL.Print("[SplashEnemies] Removing enemies table within '" .. Radius .. "y' radius of enemy with GUID '" .. PrimaryEnemyGUID .. "' due to timeout.")
            EnemiesByRadius[Radius] = nil
          end
        end
      end
    end
  )
end

-- Clear the enemies that dies from the tracker.
HL:RegisterForCombatEvent(
  function (_, _, _, _, _, _, _, DestGUID)
    if Tracker[DestGUID] then
      -- HL.Print("[SplashEnemies] Removing enemy with GUID '" .. DestGUID .. "' from the tracker.")
      Tracker[DestGUID] = nil
    end

    for PrimaryEnemyGUID, EnemiesByRadius in pairs(Tracker) do
      for Radius, Enemies in pairs(EnemiesByRadius) do
        local EnemiesCount = 0
        -- Find the enemy and if it exists remove it.
        for EnemyGUID, Enemy in pairs(Enemies) do
          if DestGUID == Enemy.GUID then
            -- HL.Print("[SplashEnemies] Removing enemy with GUID '" .. EnemyGUID .. "' from enemies table within '" .. Radius .. "y' radius of enemy with GUID '" .. PrimaryEnemyGUID .. "' due to death event.")
            Enemies[EnemyGUID] = nil
          else
            EnemiesCount = EnemiesCount + 1
          end
        end
        -- Remove the entry if it does not contain any enemy.
        if EnemiesCount == 0 then
          -- HL.Print("[SplashEnemies] Removing enemies table within '" .. Radius .. "y' radius of enemy with GUID '" .. PrimaryEnemyGUID .. "' due to death event.")
          EnemiesByRadius[Radius] = nil
        end
      end
    end
  end,
  "UNIT_DIED", "UNIT_DESTROYED"
)

-- Clear the tracker once the player leaves combat, technically it's not needed but not doing so keep undefinetely the GUID as index with a nil value.
HL:RegisterForEvent(
  function()
    -- HL.Print("[SplashEnemies] Clearing the tracker and the buffers.")
    wipe(Tracker)
    for _, BufferBySourceGUID in pairs(TrackerBuffer) do
      wipe(BufferBySourceGUID)
    end
  end,
  "PLAYER_REGEN_ENABLED"
)

-- Register a NucleusAbility.
-- Type: TargetDirectDamage = Ability like Multi-Shot or Eye Beam where the area of effect is near an unit and deals direct damage.
--                            We listen only on the SPELL_DAMAGE event.
--                            The main target is considered to be the current target of the source on the first event trigger if it has been hit, otherwise the first unit hit.
-- Type: TargetPeriodicDamage = Ability like Sunfire where the area of effect is near an unit and deals direct damage then periodic damage.
--                              We listen on SPELL_DAMAGE, SPELL_AURA_APPLIED, SPELL_AURA_REFRESH, SPELL_AURA_APPLIED_DOSE events.
--                              The main target is the unit hit by the SPELL_DAMAGE event.
-- Type : SourceDirectDamage = Ability like Fan of Knives where the area of effect is near the player (or the pet) and deals direct damage. Technically it can be used for GTAoE abilities but the Radius should be the Diameter instead.
--                             We listen only on the SPELL_DAMAGE event.
--                             The main target is considered to be the first unit hit since events are ordered from min distance to max distance.
function Splash.RegisterNucleusAbility(Type, SpellID, Radius)
  assert(type(Type) == "string" and (Type == "TargetDirectDamage" or Type == "TargetPeriodicDamage" or Type == "SourceDirectDamage"), "Invalid Type.")
  assert(type(SpellID) == "number", "Invalid SpellID.")
  assert(type(Radius) == "number" and Radius >= 1 and Radius < 100, "Radius must be between 1 and 100.")

  HL.Debug("RegisterNucleusAbility - Adding ability " .. SpellID .. " with " .. Radius .. "y radius.")
  NucleusAbilities[SpellID] = { Type = Type, Radius = Radius }
  TrackerBuffer[SpellID] = {}
end

-- Register every default NucleusAbilities.
function Splash.RegisterNucleusAbilities()
  HL.Debug("RegisterNucleusAbilities")
  local RegisterNucleusAbility = Splash.RegisterNucleusAbility

  -- Commons
  -- Azerite Traits
  RegisterNucleusAbility("TargetDirectDamage", 271686, 3)      -- Head My Call
  -- Essences
  RegisterNucleusAbility("TargetDirectDamage", 295305, 8)      -- Purification Protocol (Minor)
  RegisterNucleusAbility("SourceDirectDamage", 297108, 12)     -- Blood of the Enemy (Major)
  -- Trinkets
  RegisterNucleusAbility("SourceDirectDamage", 313088, 8)     -- Torment in Jar (Buff)
  RegisterNucleusAbility("SourceDirectDamage", 313089, 8)     -- Torment in Jar (Explosion)

  -- Death Knight
  -- Commons
  RegisterNucleusAbility("SourceDirectDamage", 43265, 8 * 2)   -- Death and Decay
  -- Blood
  RegisterNucleusAbility("SourceDirectDamage", 50842, 10)      -- Blood Boil
  RegisterNucleusAbility("SourceDirectDamage", 194844, 8)      -- Bonestorm
  -- Frost
  RegisterNucleusAbility("SourceDirectDamage", 196770, 8)      -- Remorseless Winter
  RegisterNucleusAbility("SourceDirectDamage", 207230, 8)      -- Frostscythe
  RegisterNucleusAbility("TargetDirectDamage", 49184, 10)      -- Howling Blast
  -- Unholy
  RegisterNucleusAbility("SourceDirectDamage", 152280, 8 * 2)  -- Defile
  -- RegisterNucleusAbility("TO_INVESTIGATE", 115989, 8)          -- Unholy Blight

  -- Demon Hunter
  -- Havoc
  RegisterNucleusAbility("SourceDirectDamage", 191427, 8 * 2)  -- Metamorphosis
  RegisterNucleusAbility("SourceDirectDamage", 198013, 20)     -- Eye Beam
  RegisterNucleusAbility("SourceDirectDamage", 188499, 8)      -- Blade Dance
  RegisterNucleusAbility("SourceDirectDamage", 210152, 8)      -- Death Sweep
  RegisterNucleusAbility("SourceDirectDamage", 258920, 8)      -- Immolation Aura
  RegisterNucleusAbility("SourceDirectDamage", 179057, 8)      -- Chaos Nova
  -- Vengeance
  RegisterNucleusAbility("SourceDirectDamage", 247455, 8)      -- Spirit Bomb
  RegisterNucleusAbility("SourceDirectDamage", 189112, 6 * 2)  -- Infernal Strike
  RegisterNucleusAbility("SourceDirectDamage", 258921, 8)      -- Immolation Aura 1
  RegisterNucleusAbility("SourceDirectDamage", 258922, 8)      -- Immolation Aura 2
  RegisterNucleusAbility("SourceDirectDamage", 228478, 5)      -- Soul Cleave
  RegisterNucleusAbility("TargetDirectDamage", 204157, 10 * 2) -- Throw Glaive
  RegisterNucleusAbility("SourceDirectDamage", 204598, 8 * 2)  -- Sigil of Flame
  RegisterNucleusAbility("SourceDirectDamage", 212105, 8)      -- Fel Devastation
  RegisterNucleusAbility("SourceDirectDamage", 320341, 8)      -- Bulk Extraction

  -- Druid
  -- Commons
  RegisterNucleusAbility("TargetPeriodicDamage", 164815, 8)    -- Sunfire
  RegisterNucleusAbility("SourceDirectDamage", 194153, 8)      -- Lunar Strike
  -- Balance
  -- RegisterNucleusAbility("TO_INVESTIGATE", 191037, 40)         -- Starfall
  -- Feral
  RegisterNucleusAbility("SourceDirectDamage", 285381, 8)      -- Primal Wrath
  RegisterNucleusAbility("SourceDirectDamage", 202028, 8)      -- Brutal Slash
  RegisterNucleusAbility("SourceDirectDamage", 106830, 8)      -- Thrash (Cat)
  RegisterNucleusAbility("SourceDirectDamage", 106785, 8)      -- Swipe (Cat)
  -- Guardian
  RegisterNucleusAbility("SourceDirectDamage", 77758, 8)       -- Thrash (Bear)
  RegisterNucleusAbility("SourceDirectDamage", 213771, 8)      -- Swipe (Bear)
  -- Restoration

  -- Hunter
  -- Commons
  RegisterNucleusAbility("SourceDirectDamage", 120361, 40)     -- Barrage
  RegisterNucleusAbility("TargetDirectDamage", 171454, 8)      -- Chimaera Shot 1
  RegisterNucleusAbility("TargetDirectDamage", 171457, 8)      -- Chimaera Shot 2
  -- Beast Mastery
  RegisterNucleusAbility("TargetDirectDamage", 118459, 10)     -- Beast Cleave
  RegisterNucleusAbility("TargetDirectDamage", 2643, 8)        -- Multi-Shot
  RegisterNucleusAbility("TargetDirectDamage", 201754, 8)      -- Stomp
  -- Marksmanship
  RegisterNucleusAbility("TargetDirectDamage", 257620, 10)     -- Multi-Shot
  -- Survival
  RegisterNucleusAbility("SourceDirectDamage", 212436, 8)      -- Butchery
  RegisterNucleusAbility("SourceDirectDamage", 187708, 8)      -- Carve
  RegisterNucleusAbility("SourceDirectDamage", 259391, 40)     -- Chakrams
  RegisterNucleusAbility("TargetDirectDamage", 259495, 8)      -- Bombs 1
  RegisterNucleusAbility("TargetDirectDamage", 270335, 8)      -- Bombs 2
  RegisterNucleusAbility("TargetDirectDamage", 270323, 8)      -- Bombs 3
  RegisterNucleusAbility("TargetDirectDamage", 271045, 8)      -- Bombs 4

  -- Mage
  -- Arcane
  RegisterNucleusAbility("SourceDirectDamage", 1449, 10)       -- Arcane Explosion
  RegisterNucleusAbility("TargetDirectDamage", 44425, 10)      -- Arcane Barrage
  -- Fire
  RegisterNucleusAbility("SourceDirectDamage", 157981, 8)      -- Blast Wave
  RegisterNucleusAbility("TargetDirectDamage", 153561, 8 * 2)  -- Meteor
  RegisterNucleusAbility("SourceDirectDamage", 31661, 8)       -- Dragon's Breath
  RegisterNucleusAbility("TargetDirectDamage", 44457, 10)      -- Living Bomb
  RegisterNucleusAbility("TargetDirectDamage", 2120, 8 * 2)    -- Flamestrike
  RegisterNucleusAbility("TargetDirectDamage", 257541, 8)      -- Phoenix Flames
  -- RegisterNucleusAbility("TO_INVESTIGATE", 12654, 8)           -- AoE Ignite
  -- Frost
  RegisterNucleusAbility("TargetDirectDamage", 84721, 8 * 2)   -- Frozen Orb
  RegisterNucleusAbility("TargetDirectDamage", 190357, 8 * 2)  -- Blizzard
  RegisterNucleusAbility("TargetDirectDamage", 153596, 6)      -- Comet Storm
  RegisterNucleusAbility("SourceDirectDamage", 120, 12)        -- Cone of Cold
  RegisterNucleusAbility("TargetDirectDamage", 228600, 8)      -- Glacial Spike
  RegisterNucleusAbility("TargetDirectDamage", 148022, 8)      -- Icicle
  RegisterNucleusAbility("TargetDirectDamage", 228598, 8)      -- Ice Lance
  RegisterNucleusAbility("SourceDirectDamage", 122, 12)        -- Frost Nova
  RegisterNucleusAbility("TargetDirectDamage", 157997, 8)      -- Ice Nova

  -- Monk
  -- Brewmaster
  -- Windwalker
  RegisterNucleusAbility("SourceDirectDamage", 113656, 8)      -- Fists of Fury
  RegisterNucleusAbility("SourceDirectDamage", 101546, 8)      -- Spinning Crane Kick
  RegisterNucleusAbility("SourceDirectDamage", 261715, 8)      -- Rushing Jade Wind
  RegisterNucleusAbility("SourceDirectDamage", 152175, 8)      -- Whirling Dragon Punch

  -- Paladin
  -- Holy
  -- Protection
  -- Retribution

  -- Priest
  -- Discipline
  -- Holy
  -- Shadow
  RegisterNucleusAbility("TargetDirectDamage", 228360, 10)     -- Void Eruption 1
  RegisterNucleusAbility("TargetDirectDamage", 228361, 10)     -- Void Eruption 2
  RegisterNucleusAbility("TargetDirectDamage", 48045, 10)      -- Mind Sear 1
  RegisterNucleusAbility("TargetDirectDamage", 49821, 10)      -- Mind Sear 2
  RegisterNucleusAbility("TargetDirectDamage", 342835, 8)      -- Shadow Crash
  RegisterNucleusAbility("SourceDirectDamage", 325203, 15)     -- Covenant Ability: Unholy Nova DoT
  RegisterNucleusAbility("SourceDirectDamage", 325020, 8)      -- Covenant Ability: Ascended Nova
  RegisterNucleusAbility("SourceDirectDamage", 325326, 15)     -- Covenant Ability: Ascended Explosion

  -- Rogue
  -- Assassination
  RegisterNucleusAbility("SourceDirectDamage", 51723, 10)     -- Fan of Knives
  RegisterNucleusAbility("SourceDirectDamage", 121411, 10)     -- Crimson Tempest
  RegisterNucleusAbility("TargetDirectDamage", 255546, 6)     -- Poison Bomb
  -- Outlaw
  -- RegisterNucleusAbility("TO_INVESTIGATE", 22482, 6)         -- Blade Flurry
  RegisterNucleusAbility("TargetDirectDamage", 271881, 8)     -- Blade Rush
  -- Subtlety
  RegisterNucleusAbility("SourceDirectDamage", 197835, 10)     -- Shuriken Storm
  RegisterNucleusAbility("SourceDirectDamage", 280720, 10)     -- Secret Technique
  RegisterNucleusAbility("SourceDirectDamage", 319175, 10)     -- Shadow Vault

  -- Shaman
  -- Elemental
  RegisterNucleusAbility("TargetDirectDamage", 188443, 10 * 2) -- Chain Lightning
  RegisterNucleusAbility("SourceDirectDamage", 61882, 8 * 2)   -- Earthquake
  RegisterNucleusAbility("SourceDirectDamage", 192222, 8 * 2)  -- Liquid Magma Totem
  -- Enhancement
  RegisterNucleusAbility("SourceDirectDamage", 187874, 8)      -- Bladestorm
  RegisterNucleusAbility("SourceDirectDamage", 197214, 11)     -- Sundering
  RegisterNucleusAbility("SourceDirectDamage", 197211, 8)      -- Fury of Air
  -- Restoration

  -- Warlock
  -- Afflication
  RegisterNucleusAbility("TargetDirectDamage", 27285, 10)      -- Seed Explosion
  -- Demonology
  RegisterNucleusAbility("SourceDirectDamage", 89753, 8)       -- Felstorm (Felguard)
  RegisterNucleusAbility("TargetDirectDamage", 105174, 8)      -- Hand of Gul'dan
  RegisterNucleusAbility("TargetDirectDamage", 196277, 8)      -- Implosion
  -- Destruction
  RegisterNucleusAbility("SourceDirectDamage", 42223, 8 * 2)   -- Rain of Fire
  RegisterNucleusAbility("SourceDirectDamage", 152108, 8 * 2)  -- Cataclysm
  RegisterNucleusAbility("SourceDirectDamage", 22703, 10 * 2)  -- Summon Infernal

  -- Warrior
  -- Arms
  RegisterNucleusAbility("SourceDirectDamage", 152277, 8 * 2)  -- Ravager
  RegisterNucleusAbility("SourceDirectDamage", 227847, 8)      -- Bladestorm
  RegisterNucleusAbility("SourceDirectDamage", 845, 8)         -- Cleave
  RegisterNucleusAbility("SourceDirectDamage", 1680, 8)        -- Whirlwind
  -- Fury
  RegisterNucleusAbility("SourceDirectDamage", 46924, 8)       -- Bladestorm
  RegisterNucleusAbility("SourceDirectDamage", 118000, 12)     -- Dragon Roar
  RegisterNucleusAbility("SourceDirectDamage", 190411, 8)      -- Whirlwind
  -- Protection
  RegisterNucleusAbility("SourceDirectDamage", 6343, 8)        -- Thunder Clap
  RegisterNucleusAbility("SourceDirectDamage", 118000, 12)     -- Dragon Roar
  RegisterNucleusAbility("SourceDirectDamage", 6572, 8)        -- Revenge
  RegisterNucleusAbility("SourceDirectDamage", 228920, 8 * 2)  -- Ravager
end

-- Unregister every NucleusAbilities.
function Splash.UnregisterNucleusAbilities()
  HL.Debug("UnregisterNucleusAbilities")
  wipe(NucleusAbilities)
  wipe(TrackerBuffer)
end

-- Get the enemies in given range of the unit using splash data.
function Unit:GetEnemiesInSplashRangeCount(Radius)
  if not self:Exists() then return 0 end

  local GUID = self:GUID()
  local EnemiesByRadius = Tracker[GUID]
  if not EnemiesByRadius then return 1 end

  -- Look for an entry with the given radius.
  local Enemies = EnemiesByRadius[Radius]
  if Enemies then
    local EnemiesCount = 0
    for _, _ in pairs(Enemies) do
      EnemiesCount = EnemiesCount + 1
    end

    return EnemiesCount
  else
    -- If we did not find, look for lower radiuses (since they are inside the circle from the unit to the edge).
    -- Always took the entry that have the highest count of enemies.
    local HighestEnemiesCount = 1
    for TrackerRadius, TrackerEnemies in pairs(EnemiesByRadius) do
      local EnemiesCount = 0
      for _, _ in pairs(TrackerEnemies) do
        EnemiesCount = EnemiesCount + 1
      end
      if TrackerRadius < Radius and EnemiesCount > HighestEnemiesCount then
        HighestEnemiesCount = EnemiesCount
      end
    end

    return HighestEnemiesCount
  end
end

-- OnInit
Splash.RegisterNucleusAbilities()
