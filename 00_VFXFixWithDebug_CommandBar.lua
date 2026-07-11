-- ═══════════════════════════════════════════════════════════
-- 🔧 VFX FIX + DEBUG + CUSTOM VFX SUPPORT
-- ═══════════════════════════════════════════════════════════
-- HOW TO USE: View > Command Bar → paste ALL of this → Enter
--
-- This does 3 things:
--   1. Re-creates VFXData (CLEAN, with Template type for your own VFX!)
--   2. Re-creates VFXClient (CLEAN, with DEBUG prints to find bugs!)
--   3. Re-creates GameServer (CLEAN, fires equip events)
--   4. Creates CustomVFX folder in ReplicatedStorage (for your VFX!)
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function ensure(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName ~= className then inst:Destroy(); inst = nil end
	if not inst then inst = Instance.new(className); inst.Name = name; inst.Parent = parent end
	return inst
end

-- ═══ 1) Make sure EquippedChangedEvent remote exists ═══
local remotes = RS:FindFirstChild("Remotes") or ensure("Folder", "Remotes", RS)
ensure("RemoteEvent", "EquippedChangedEvent", remotes)

-- ═══ 2) Create CustomVFX folder (THIS IS WHERE YOUR OWN VFX GO!) ═══
-- How to use this folder:
--   1. Find a VFX you like in the Toolbox (smoke, fire, sparkle, etc.)
--   2. Insert it into Workspace
--   3. Find the ParticleEmitter (or Fire/Smoke) inside it
--   4. Drag that ParticleEmitter into THIS folder (ReplicatedStorage/CustomVFX)
--   5. Rename it something simple like "MyFire" or "PurpleSmoke"
--   6. In VFXData, use: { Type = "Template", TemplateName = "MyFire", Part = "HumanoidRootPart" }
ensure("Folder", "CustomVFX", RS)

-- ═══ 3) VFX DATA (CLEAN — with Template type!) ═══
ensure("ModuleScript", "VFXData", RS).Source = [==[
--[[
═══════════════════════════════════════════════════════════
✨ VFX DATA — The heart of the VFX system.

EFFECT TYPES YOU CAN USE:
  Type = "Particle"   → creates a new ParticleEmitter from settings
  Type = "Fire"       → creates a Fire instance
  Type = "Smoke"      → creates a Smoke instance
  Type = "Light"      → creates a PointLight
  Type = "Template"   → USES YOUR OWN VFX from the CustomVFX folder! ★

═══════════════════════════════════════════════════════════

★ HOW TO USE YOUR OWN VFX (Template type) ★

STEP 1: Get your VFX into the game
  • Open Toolbox (View > Toolbox)
  • Search for "fire", "smoke", "particles", etc.
  • Find one you like → right-click → Insert
  • It goes into Workspace

STEP 2: Find the ParticleEmitter
  • In Explorer, expand what you just inserted
  • Look for a "ParticleEmitter" (or "Fire" or "Smoke") object
  • Click it to see its properties

STEP 3: Move it to CustomVFX folder
  • Drag the ParticleEmitter from Workspace
  • Drop it into: ReplicatedStorage > CustomVFX
  • Rename it something simple (right-click > Rename)
    Example: "MyFire" or "PurpleSmoke" or "CoolSparkles"

STEP 4: Add it to a VFX in VFXData
  VFXData.VFX["My Custom Effect"] = {
    Name = "My Custom Effect",
    Effects = {
      {
        Type = "Template",             ← use Template type
        TemplateName = "MyFire",       ← the EXACT name from CustomVFX folder
        Part = "HumanoidRootPart",     ← which body part
      },
    },
  }

STEP 5: Connect it to an aura
  VFXData.AuraMap["Nine-Tails"] = "My Custom Effect"

DONE! When you equip Nine-Tails, your custom fire appears!

═══════════════════════════════════════════════════════════
]]
local VFXData = {}

--[[
────────────────────────────────────────────────────────────
📌 CUSTOMIZABLE: Aura → VFX Mapping
  Left side = aura name (from AuraData)
  Right side = VFX name (defined in VFX section below)

  If an aura isn't listed, it uses its Tier's VFX (see TierVFX below).

  TO CHANGE: just change the right side (the VFX name)
────────────────────────────────────────────────────────────
]]
VFXData.AuraMap = {
	["Flicker"]         = "Smoke Mist",
	["Spark"]           = "Smoke Mist",
	["Glow"]            = "Stardust",
	["Ember"]           = "Fire Burst",
	["Surge"]           = "Crystal Aura",
	["Bloom"]           = "Stardust",
	["Spirit Bomb"]     = "Fire Burst",
	["Tempest"]         = "Crystal Aura",
	["Nine-Tails"]      = "Fire Burst",
	["Eclipse"]         = "Shadow Flame",
	["Conqueror Haki"]  = "Holy Burst",
	["Cursed Energy"]   = "Shadow Flame",
	["Hollow Mask"]     = "Shadow Flame",
	["Genesis"]         = "Divine Wind",
}

--[[
────────────────────────────────────────────────────────────
📌 CUSTOMIZABLE: Tier → VFX Fallback
  If an aura isn't in AuraMap, its TIER's VFX is used instead.
────────────────────────────────────────────────────────────
]]
VFXData.TierVFX = {
	Common    = "Smoke Mist",
	Uncommon  = "Stardust",
	Rare      = "Fire Burst",
	Epic      = "Crystal Aura",
	Legendary = "Holy Burst",
	Mythic    = "Divine Wind",
}

-- ═══════════════════════════════════════════════════════════
-- 🎨 VFX DEFINITIONS
-- ═══════════════════════════════════════════════════════════
VFXData.VFX = {}

-- ────── SMOKE MIST (Common) ──────
VFXData.VFX["Smoke Mist"] = {
	Name = "Smoke Mist",
	Effects = {
		{ Type = "Smoke", Part = "HumanoidRootPart",
		  Color = Color3.fromRGB(150,150,150), Size = 1.2, Opacity = 0.4, RiseAcceleration = 1.5 },
		{ Type = "Particle", Part = "HumanoidRootPart",
		  Color = ColorSequence.new(Color3.fromRGB(160,160,160)),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,4)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,1)}),
		  Lifetime = NumberRange.new(3,5), Rate = 15, Speed = NumberRange.new(1,2),
		  SpreadAngle = Vector2.new(180,180), Acceleration = Vector3.new(0,1,0) },
	},
}

-- ────── STARDUST (Uncommon) ──────
VFXData.VFX["Stardust"] = {
	Name = "Stardust",
	Effects = {
		{ Type = "Particle", Part = "HumanoidRootPart",
		  Color = ColorSequence.new(Color3.fromRGB(255,255,220)),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(0.5,0.8),NumberSequenceKeypoint.new(1,0.1)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),
		  Lifetime = NumberRange.new(1.5,3), Rate = 40, Speed = NumberRange.new(2,4),
		  SpreadAngle = Vector2.new(45,45), Acceleration = Vector3.new(0,3,0),
		  LightEmission = 1, Texture = "rbxassetid://243660364" },
		{ Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(255,255,200), Brightness = 1, Range = 8 },
	},
}

-- ────── FIRE BURST (Rare) ──────
VFXData.VFX["Fire Burst"] = {
	Name = "Fire Burst",
	Effects = {
		{ Type = "Fire", Part = "HumanoidRootPart",
		  Color = Color3.fromRGB(255,100,30), SecondaryColor = Color3.fromRGB(255,200,50), Size = 2.5, Heat = 15 },
		{ Type = "Particle", Part = "HumanoidRootPart",
		  Color = ColorSequence.new({NumberSequenceKeypoint.new(0,Color3.fromRGB(255,200,50)),NumberSequenceKeypoint.new(0.5,Color3.fromRGB(255,100,30)),NumberSequenceKeypoint.new(1,Color3.fromRGB(150,30,0))}),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1.5),NumberSequenceKeypoint.new(1,0.2)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,1)}),
		  Lifetime = NumberRange.new(0.8,1.5), Rate = 50, Speed = NumberRange.new(5,10),
		  SpreadAngle = Vector2.new(15,15), Acceleration = Vector3.new(0,10,0), LightEmission = 0.8 },
		{ Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(255,120,30), Brightness = 2, Range = 12 },
	},
}

-- ────── CRYSTAL AURA (Epic) ──────
VFXData.VFX["Crystal Aura"] = {
	Name = "Crystal Aura",
	Effects = {
		{ Type = "Particle", Part = "UpperTorso",
		  Color = ColorSequence.new(Color3.fromRGB(100,180,255)),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,2),NumberSequenceKeypoint.new(1,0.5)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0.8)}),
		  Lifetime = NumberRange.new(1.5,2.5), Rate = 35, Speed = NumberRange.new(3,6),
		  SpreadAngle = Vector2.new(360,360), Acceleration = Vector3.new(0,1,0),
		  LightEmission = 0.8, Rotation = NumberRange.new(0,360) },
		{ Type = "Light", Part = "UpperTorso", Color = Color3.fromRGB(100,180,255), Brightness = 1.5, Range = 10 },
	},
}

-- ────── SHADOW FLAME (Epic) ──────
VFXData.VFX["Shadow Flame"] = {
	Name = "Shadow Flame",
	Effects = {
		{ Type = "Fire", Part = "HumanoidRootPart",
		  Color = Color3.fromRGB(80,0,120), SecondaryColor = Color3.fromRGB(40,0,60), Size = 3, Heat = 10 },
		{ Type = "Smoke", Part = "HumanoidRootPart",
		  Color = Color3.fromRGB(40,0,60), Size = 2, Opacity = 0.5, RiseAcceleration = 2 },
		{ Type = "Particle", Part = "HumanoidRootPart",
		  Color = ColorSequence.new({NumberSequenceKeypoint.new(0,Color3.fromRGB(100,0,150)),NumberSequenceKeypoint.new(1,Color3.fromRGB(20,0,40))}),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,0.5)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)}),
		  Lifetime = NumberRange.new(1.5,3), Rate = 30, Speed = NumberRange.new(2,5),
		  SpreadAngle = Vector2.new(30,30), Acceleration = Vector3.new(0,5,0), LightEmission = 0.3 },
		{ Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(100,0,150), Brightness = 1, Range = 10 },
	},
}

-- ────── HOLY BURST (Legendary) ──────
VFXData.VFX["Holy Burst"] = {
	Name = "Holy Burst",
	Effects = {
		{ Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(255,255,220), Brightness = 3, Range = 18 },
		{ Type = "Particle", Part = "UpperTorso",
		  Color = ColorSequence.new(Color3.fromRGB(255,255,240)),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,3),NumberSequenceKeypoint.new(1,0.5)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.7,0.3),NumberSequenceKeypoint.new(1,1)}),
		  Lifetime = NumberRange.new(1,2), Rate = 60, Speed = NumberRange.new(8,15),
		  SpreadAngle = Vector2.new(180,180), Acceleration = Vector3.new(0,2,0),
		  LightEmission = 1, Texture = "rbxassetid://243660364" },
		{ Type = "Particle", Part = "Head",
		  Color = ColorSequence.new(Color3.fromRGB(255,255,200)),
		  Size = NumberSequence.new(0.5),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,1)}),
		  Lifetime = NumberRange.new(2,4), Rate = 20, Speed = NumberRange.new(0,1),
		  SpreadAngle = Vector2.new(45,45), LightEmission = 1, Texture = "rbxassetid://243660364" },
		{ Type = "Light", Part = "Head", Color = Color3.fromRGB(255,255,180), Brightness = 2, Range = 8 },
	},
}

-- ────── DIVINE WIND (Mythic) ──────
VFXData.VFX["Divine Wind"] = {
	Name = "Divine Wind",
	Effects = {
		{ Type = "Particle", Part = "HumanoidRootPart",
		  Color = ColorSequence.new({NumberSequenceKeypoint.new(0,Color3.fromRGB(0,255,200)),NumberSequenceKeypoint.new(0.5,Color3.fromRGB(0,200,255)),NumberSequenceKeypoint.new(1,Color3.fromRGB(100,255,255))}),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(0.5,4),NumberSequenceKeypoint.new(1,1)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0.9)}),
		  Lifetime = NumberRange.new(1,2), Rate = 80, Speed = NumberRange.new(10,20),
		  SpreadAngle = Vector2.new(180,180), Acceleration = Vector3.new(0,15,0),
		  LightEmission = 1, Rotation = NumberRange.new(0,360) },
		{ Type = "Particle", Part = "HumanoidRootPart",
		  Color = ColorSequence.new(Color3.fromRGB(0,255,220)),
		  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,2)}),
		  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),
		  Lifetime = NumberRange.new(0.5,1), Rate = 40, Speed = NumberRange.new(15,25),
		  SpreadAngle = Vector2.new(45,45), Acceleration = Vector3.new(0,5,0), LightEmission = 1 },
		{ Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(0,255,200), Brightness = 3, Range = 20 },
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 EXAMPLE: Using YOUR OWN VFX (from the CustomVFX folder)

  VFXData.VFX["My Custom Effect"] = {
    Name = "My Custom Effect",
    Effects = {
      {
        Type = "Template",             ← tells the system to use YOUR VFX
        TemplateName = "MyFire",       ← name of your VFX in CustomVFX folder
        Part = "HumanoidRootPart",     ← which body part
      },
    },
  }

  Then connect it:  VFXData.AuraMap["Nine-Tails"] = "My Custom Effect"
═══════════════════════════════════════════════════════════
]]

function VFXData.GetVFXForAura(auraName, tier)
	if VFXData.AuraMap[auraName] then
		return VFXData.VFX[VFXData.AuraMap[auraName]]
	end
	if tier and VFXData.TierVFX[tier] then
		return VFXData.VFX[VFXData.TierVFX[tier]]
	end
	return nil
end

return VFXData
]==]

-- ═══ 4) VFX CLIENT (CLEAN — with DEBUG prints!) ═══
ensure("LocalScript", "VFXClient", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local VFXData = require(ReplicatedStorage:WaitForChild("VFXData"))
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")

local VFX_TAG = "AuraVFX"
local CustomVFXFolder = ReplicatedStorage:WaitForChild("CustomVFX")

print("✨ VFXClient loaded — waiting for equip changes...")

-- 🧹 CLEAN UP old VFX
local function clearVFX(character)
	if not character then return end
	local count = 0
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:GetAttribute(VFX_TAG) then
			if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
				obj.Enabled = false
			end
			obj:Destroy()
			count = count + 1
		end
	end
	if count > 0 then print("🧹 VFX cleaned up " .. count .. " old effects") end
end

-- 🏗️ CREATE EFFECTS
local function createParticle(part, cfg)
	local e = Instance.new("ParticleEmitter")
	if cfg.Color then e.Color = cfg.Color end
	if cfg.Size then e.Size = cfg.Size end
	if cfg.Transparency then e.Transparency = cfg.Transparency end
	if cfg.Lifetime then e.Lifetime = cfg.Lifetime end
	if cfg.Rate then e.Rate = cfg.Rate end
	if cfg.Speed then e.Speed = cfg.Speed end
	if cfg.SpreadAngle then e.SpreadAngle = cfg.SpreadAngle end
	if cfg.Acceleration then e.Acceleration = cfg.Acceleration end
	if cfg.Rotation then e.Rotation = cfg.Rotation end
	if cfg.RotSpeed then e.Rotation = cfg.RotSpeed end
	if cfg.LightEmission then e.LightEmission = cfg.LightEmission end
	if cfg.Texture and cfg.Texture ~= "" then e.Texture = cfg.Texture end
	e.Enabled = true
	e:SetAttribute(VFX_TAG, true)
	e.Parent = part
	return e
end

local function createFire(part, cfg)
	local f = Instance.new("Fire")
	f.Color = cfg.Color or Color3.fromRGB(255,100,30)
	f.SecondaryColor = cfg.SecondaryColor or Color3.fromRGB(255,200,50)
	f.Size = cfg.Size or 2
	f.Heat = cfg.Heat or 15
	f.Enabled = true
	f:SetAttribute(VFX_TAG, true)
	f.Parent = part
	return f
end

local function createSmoke(part, cfg)
	local s = Instance.new("Smoke")
	s.Color = cfg.Color or Color3.fromRGB(150,150,150)
	s.Size = cfg.Size or 1.2
	s.Opacity = cfg.Opacity or 0.4
	s.RiseVelocity = cfg.RiseAcceleration or 1.5
	s.Enabled = true
	s:SetAttribute(VFX_TAG, true)
	s.Parent = part
	return s
end

local function createLight(part, cfg)
	local l = Instance.new("PointLight")
	l.Color = cfg.Color or Color3.fromRGB(255,255,255)
	l.Brightness = cfg.Brightness or 1
	l.Range = cfg.Range or 10
	l:SetAttribute(VFX_TAG, true)
	l.Parent = part
	return l
end

-- ★ TEMPLATE: clones YOUR OWN VFX from CustomVFX folder!
local function createTemplate(part, cfg)
	local template = CustomVFXFolder:FindFirstChild(cfg.TemplateName)
	if not template then
		warn("⚠️ VFX Template '" .. tostring(cfg.TemplateName) .. "' not found in CustomVFX folder!")
		return nil
	end
	local clone = template:Clone()
	-- enable it (in case the original was disabled)
	if clone:IsA("ParticleEmitter") or clone:IsA("Fire") or clone:IsA("Smoke") then
		clone.Enabled = true
	end
	clone:SetAttribute(VFX_TAG, true)
	clone.Parent = part
	return clone
end

-- 🎬 APPLY VFX
local function applyVFX(character, vfxConfig)
	if not character or not vfxConfig then return end
	print("🎬 Applying VFX: " .. vfxConfig.Name .. " (" .. #vfxConfig.Effects .. " effects)")
	local created = {}
	for _, effect in ipairs(vfxConfig.Effects) do
		local part = character:FindFirstChild(effect.Part)
		if not part then
			part = character:FindFirstChild("HumanoidRootPart")
			if part then print("  ⚠️ Part '" .. effect.Part .. "' not found, using HumanoidRootPart") end
		end
		if not part then
			print("  ❌ No body part found for effect: " .. effect.Type)
			continue
		end
		local inst
		if effect.Type == "Particle" then inst = createParticle(part, effect)
		elseif effect.Type == "Fire" then inst = createFire(part, effect)
		elseif effect.Type == "Smoke" then inst = createSmoke(part, effect)
		elseif effect.Type == "Light" then inst = createLight(part, effect)
		elseif effect.Type == "Template" then inst = createTemplate(part, effect) end
		if inst then
			table.insert(created, inst)
			print("  ✅ Created " .. effect.Type .. " on " .. part.Name)
		else
			print("  ❌ Failed to create " .. effect.Type)
		end
	end
	print("🎬 VFX applied: " .. #created .. " effects created")
end

-- 🔍 PARSE mutated aura name
local function parseAuraName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

-- 🎮 MAIN UPDATE
local currentEquipped = nil
local function updateVFX()
	print("🔄 updateVFX called, equipped = " .. tostring(currentEquipped))
	local character = player.Character
	if not character then
		print("  ❌ No character found!")
		return
	end
	clearVFX(character)
	if not currentEquipped or currentEquipped == "" then
		print("  ℹ️ Nothing equipped, VFX removed")
		return
	end
	local baseName = parseAuraName(currentEquipped)
	print("  🔍 Looking up aura: " .. baseName)
	local aura = AuraData.GetByName(baseName)
	local tier = aura and aura.Tier or nil
	print("  📊 Tier: " .. tostring(tier))
	local vfxConfig = VFXData.GetVFXForAura(baseName, tier)
	if vfxConfig then
		applyVFX(character, vfxConfig)
	else
		print("  ❌ No VFX found for aura '" .. baseName .. "' (tier: " .. tostring(tier) .. ")")
	end
end

EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	print("📡 Received equip event: " .. tostring(auraName))
	currentEquipped = auraName
	updateVFX()
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	print("🔄 Character respawned, updating VFX...")
	updateVFX()
end)
]==]

-- ═══ 5) GAME SERVER (CLEAN — fires equip events) ═══
ensure("Script", "GameServer", SSS).Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

local ADMIN_IDS = { 12345678, 87654321 }
local ADMIN_USERNAMES = { "Twix79i" }
local ROLL_COOLDOWN = 0.5
local LUCK = 1
local ANNOUNCE_RARITY = 1000
local AUTO_EQUIP_FIRST = true
local AUTOSAVE_INTERVAL = 60
local DATASTORE_KEY = "AnimeRNG_v1"

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")
local ChatAnnounceEvent = Remotes:WaitForChild("ChatAnnounceEvent")
local GetInventoryFunction = Remotes:WaitForChild("GetInventoryFunction")
local EquipFunction = Remotes:WaitForChild("EquipFunction")
local AdminFunction = Remotes:WaitForChild("AdminFunction")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")
local AdminStatusEvent = Remotes:WaitForChild("AdminStatusEvent")
local WeatherChangedEvent = Remotes:WaitForChild("WeatherChangedEvent")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")
local currentWeatherValue = ReplicatedStorage:WaitForChild("CurrentWeather")

local playerStore
pcall(function() playerStore = DataStoreService:GetDataStore(DATASTORE_KEY) end)
local PlayerData = {}
local lastRoll = {}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do if player.UserId == id then return true end end
	local pn = string.lower(player.Name); local dn = string.lower(player.DisplayName)
	for _, name in ipairs(ADMIN_USERNAMES) do
		if pn == string.lower(name) or dn == string.lower(name) then return true end
	end
	return false
end
local function newData() return { Inventory = {}, Equipped = nil, Rolls = 0, Luck = LUCK, RarestAura = "None", RarestRarity = 0 } end
local function ensureFields(d)
	d.Inventory = d.Inventory or {}; d.Equipped = d.Equipped or nil; d.Rolls = d.Rolls or 0
	d.Luck = d.Luck or LUCK; d.RarestAura = d.RarestAura or "None"; d.RarestRarity = d.RarestRarity or 0
	return d
end
local function getData(p) if not PlayerData[p] then PlayerData[p] = newData() end return PlayerData[p] end
local function buildStats(d)
	local u = {}; for _, n in ipairs(d.Inventory) do u[n] = true end
	local f = 0; for _ in pairs(u) do f = f + 1 end
	return { Rolls=d.Rolls, RarestAura=d.RarestAura, RarestRarity=d.RarestRarity, Luck=d.Luck, Found=f, Total=#AuraData.Auras }
end
local function loadData(p)
	if playerStore then
		local k = "Player_" .. p.UserId
		local s, r = pcall(function() return playerStore:GetAsync(k) end)
		if s and r then PlayerData[p] = ensureFields(r) else PlayerData[p] = newData() end
	else PlayerData[p] = newData() end
	task.wait(0.5)
	if PlayerData[p] then
		StatsUpdatedEvent:FireClient(p, buildStats(PlayerData[p]))
		if PlayerData[p].Equipped then
			print("📡 Firing initial equip event for " .. p.Name .. ": " .. PlayerData[p].Equipped)
			EquippedChangedEvent:FireClient(p, PlayerData[p].Equipped)
		end
	end
end
local function saveData(p)
	local d = PlayerData[p]; if not d or not playerStore then return end
	pcall(function() playerStore:SetAsync("Player_" .. p.UserId, d) end)
end

RollFunction.OnServerInvoke = function(player)
	local now = os.clock()
	if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then return nil end
	lastRoll[player] = now
	local data = getData(player)
	data.Rolls = data.Rolls + 1
	local aura = AuraData.GetWeightedRandom(data.Luck)
	local storedName = aura.Name
	local displayName = aura.Name
	local displayColor = aura.Color
	local mutated = false
	local wn = currentWeatherValue.Value
	if wn and wn ~= "Clear" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(wn)
		if weather and weather.Mutation and weather.Mutation.Chance > 0 then
			if math.random() <= weather.Mutation.Chance then
				storedName = weather.Mutation.Name .. "|" .. aura.Name
				displayName = weather.Mutation.Name .. " " .. aura.Name
				displayColor = weather.Mutation.Color or aura.Color
				mutated = true
			end
		end
	end
	table.insert(data.Inventory, storedName)
	if aura.Rarity > data.RarestRarity then data.RarestRarity = aura.Rarity; data.RarestAura = displayName end
	if AUTO_EQUIP_FIRST and data.Equipped == nil then
		data.Equipped = storedName
		EquippedChangedEvent:FireClient(player, storedName)
	end
	if aura.Rarity >= ANNOUNCE_RARITY then
		local ad = { Player = player.Name, Name = displayName, Rarity = aura.Rarity, Tier = aura.Tier, Color = displayColor, Mutated = mutated }
		AnnounceEvent:FireAllClients(ad)
		ChatAnnounceEvent:FireAllClients(ad)
	end
	StatsUpdatedEvent:FireClient(player, buildStats(data))
	return { Name = storedName, DisplayName = displayName, Rarity = aura.Rarity, Tier = aura.Tier, TotalRolls = data.Rolls, Color = displayColor, Mutated = mutated }
end

GetInventoryFunction.OnServerInvoke = function(player)
	local data = getData(player); local counts = {}
	for _, name in ipairs(data.Inventory) do counts[name] = (counts[name] or 0) + 1 end
	return { Counts = counts, Equipped = data.Equipped }
end

EquipFunction.OnServerInvoke = function(player, auraName)
	local data = getData(player)
	for _, name in ipairs(data.Inventory) do
		if name == auraName then
			data.Equipped = auraName
			print("📡 Firing equip event for " .. player.Name .. ": " .. auraName)
			EquippedChangedEvent:FireClient(player, auraName)
			return true
		end
	end
	return false
end

AdminFunction.OnServerInvoke = function(player, action, value)
	if not isAdmin(player) then return nil end
	local data = getData(player)
	if action == "IsAdmin" then return true
	elseif action == "GiveAura" then
		local aura = AuraData.GetByName(value)
		if not aura then return false end
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "GiveMutated" then
		table.insert(data.Inventory, value)
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "ForceWeather" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(value)
		if not weather then return false end
		currentWeatherValue.Value = weather.Name
		WeatherChangedEvent:FireAllClients({ Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles, Skybox = weather.Skybox, BannerText = weather.BannerText, BannerColor = weather.BannerColor })
		return true
	elseif action == "SetLuck" then
		data.Luck = math.max(1, math.floor(tonumber(value) or 1))
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return data.Luck
	elseif action == "GiveRare" then
		local aura = AuraData.GetWeightedRandom(5000)
		table.insert(data.Inventory, aura.Name)
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return aura.Name
	elseif action == "ClearInventory" then
		data.Inventory = {}; data.Equipped = nil
		EquippedChangedEvent:FireClient(player, nil)
		StatsUpdatedEvent:FireClient(player, buildStats(data)); return true
	elseif action == "ResetData" then
		PlayerData[player] = newData()
		EquippedChangedEvent:FireClient(player, nil)
		StatsUpdatedEvent:FireClient(player, buildStats(PlayerData[player])); return true
	end
	return nil
end

GetStatsFunction.OnServerInvoke = function(player) return buildStats(getData(player)) end
Players.PlayerAdded:Connect(function(player)
	loadData(player); task.wait(1.5)
	if isAdmin(player) then AdminStatusEvent:FireClient(player, true) end
end)
Players.PlayerRemoving:Connect(function(player) saveData(player); PlayerData[player] = nil; lastRoll[player] = nil end)
task.spawn(function() while true do task.wait(AUTOSAVE_INTERVAL) for p in pairs(PlayerData) do saveData(p) end end end)
game:BindToClose(function() for p in pairs(PlayerData) do saveData(p) end task.wait(2) end)
print("✅ GameServer running with VFX equip events!")
]==]

print("══════════════════════════════════════")
print("✅ VFX FIX + DEBUG + CUSTOM VFX READY!")
print("══════════════════════════════════════")
print("🔧 Clean reinstall of VFXData + VFXClient + GameServer")
print("🐛 DEBUG MODE ON — check Output when equipping!")
print("📁 CustomVFX folder created in ReplicatedStorage")
print("══════════════════════════════════════")
print("🎮 TEST NOW:")
print("   1. Press Play")
print("   2. Admin → Give Aura: Nine-Tails")
print("   3. Inventory → Equip Nine-Tails")
print("   4. CHECK THE OUTPUT for debug messages!")
print("══════════════════════════════════════")
print("📂 To use YOUR OWN VFX:")
print("   1. Drag your ParticleEmitter into ReplicatedStorage/CustomVFX")
print("   2. Rename it (e.g. 'MyFire')")
print("   3. Add to VFXData: { Type='Template', TemplateName='MyFire', Part='HumanoidRootPart' }")
print("══════════════════════════════════════")
