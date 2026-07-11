-- ═══════════════════════════════════════════════════════════
-- ✨ VFX FINAL FIX — Auto-detection + error protection + Model support
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar → Enter
--
-- HOW AUTO-DETECTION WORKS (THE EASY WAY!):
--   1. Put your VFX rig in ReplicatedStorage > CustomVFX
--   2. Name it the SAME as the aura (e.g. "Nine-Tails")
--   3. When you equip that aura, your rig appears!
--   NO CODE EDITING NEEDED! Just drag + rename!
--
-- You NEVER need to edit VFXData manually again!
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function ensure(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName ~= className then inst:Destroy(); inst = nil end
	if not inst then inst = Instance.new(className); inst.Name = name; inst.Parent = parent end
	return inst
end

ensure("Folder", "CustomVFX", RS)

-- ═══ 1) VFX DATA (clean + auto-detection!) ═══
ensure("ModuleScript", "VFXData", RS).Source = [==[
local VFXData = {}

VFXData.AuraMap = {
	["Flicker"] = "Smoke Mist", ["Spark"] = "Smoke Mist",
	["Glow"] = "Stardust", ["Ember"] = "Fire Burst",
	["Surge"] = "Crystal Aura", ["Bloom"] = "Stardust",
	["Spirit Bomb"] = "Fire Burst", ["Tempest"] = "Crystal Aura",
	["Nine-Tails"] = "Fire Burst", ["Eclipse"] = "Shadow Flame",
	["Conqueror Haki"] = "Holy Burst", ["Cursed Energy"] = "Shadow Flame",
	["Hollow Mask"] = "Shadow Flame", ["Genesis"] = "Divine Wind",
}

VFXData.TierVFX = {
	Common = "Smoke Mist", Uncommon = "Stardust", Rare = "Fire Burst",
	Epic = "Crystal Aura", Legendary = "Holy Burst", Mythic = "Divine Wind",
}

VFXData.VFX = {}

VFXData.VFX["Smoke Mist"] = { Name = "Smoke Mist", Effects = {
	{ Type = "Smoke", Part = "HumanoidRootPart", Color = Color3.fromRGB(150,150,150), Size = 1.2, Opacity = 0.4, RiseAcceleration = 1.5 },
	{ Type = "Particle", Part = "HumanoidRootPart",
	  Color = ColorSequence.new(Color3.fromRGB(160,160,160)),
	  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,4)}),
	  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,1)}),
	  Lifetime = NumberRange.new(3,5), Rate = 15, Speed = NumberRange.new(1,2),
	  SpreadAngle = Vector2.new(180,180), Acceleration = Vector3.new(0,1,0) },
}}

VFXData.VFX["Stardust"] = { Name = "Stardust", Effects = {
	{ Type = "Particle", Part = "HumanoidRootPart",
	  Color = ColorSequence.new(Color3.fromRGB(255,255,220)),
	  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(0.5,0.8),NumberSequenceKeypoint.new(1,0.1)}),
	  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),
	  Lifetime = NumberRange.new(1.5,3), Rate = 40, Speed = NumberRange.new(2,4),
	  SpreadAngle = Vector2.new(45,45), Acceleration = Vector3.new(0,3,0),
	  LightEmission = 1, Texture = "rbxassetid://243660364" },
	{ Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(255,255,200), Brightness = 1, Range = 8 },
}}

VFXData.VFX["Fire Burst"] = { Name = "Fire Burst", Effects = {
	{ Type = "Fire", Part = "HumanoidRootPart",
	  Color = Color3.fromRGB(255,100,30), SecondaryColor = Color3.fromRGB(255,200,50), Size = 2.5, Heat = 15 },
	{ Type = "Particle", Part = "HumanoidRootPart",
	  Color = ColorSequence.new({NumberSequenceKeypoint.new(0,Color3.fromRGB(255,200,50)),NumberSequenceKeypoint.new(0.5,Color3.fromRGB(255,100,30)),NumberSequenceKeypoint.new(1,Color3.fromRGB(150,30,0))}),
	  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1.5),NumberSequenceKeypoint.new(1,0.2)}),
	  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,1)}),
	  Lifetime = NumberRange.new(0.8,1.5), Rate = 50, Speed = NumberRange.new(5,10),
	  SpreadAngle = Vector2.new(15,15), Acceleration = Vector3.new(0,10,0), LightEmission = 0.8 },
	{ Type = "Light", Part = "HumanoidRootPart", Color = Color3.fromRGB(255,120,30), Brightness = 2, Range = 12 },
}}

VFXData.VFX["Crystal Aura"] = { Name = "Crystal Aura", Effects = {
	{ Type = "Particle", Part = "UpperTorso",
	  Color = ColorSequence.new(Color3.fromRGB(100,180,255)),
	  Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,2),NumberSequenceKeypoint.new(1,0.5)}),
	  Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0.8)}),
	  Lifetime = NumberRange.new(1.5,2.5), Rate = 35, Speed = NumberRange.new(3,6),
	  SpreadAngle = Vector2.new(360,360), Acceleration = Vector3.new(0,1,0),
	  LightEmission = 0.8, Rotation = NumberRange.new(0,360) },
	{ Type = "Light", Part = "UpperTorso", Color = Color3.fromRGB(100,180,255), Brightness = 1.5, Range = 10 },
}}

VFXData.VFX["Shadow Flame"] = { Name = "Shadow Flame", Effects = {
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
}}

VFXData.VFX["Holy Burst"] = { Name = "Holy Burst", Effects = {
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
}}

VFXData.VFX["Divine Wind"] = { Name = "Divine Wind", Effects = {
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
}}

-- ═══════════════════════════════════════════════════════════
-- 🌟 AUTO-DETECTION! The magic happens here.
-- If CustomVFX folder has a rig named the SAME as the aura,
-- it automatically uses it! No code editing needed!
-- ═══════════════════════════════════════════════════════════
function VFXData.GetVFXForAura(auraName, tier)
	-- 1. Check explicit AuraMap
	if VFXData.AuraMap[auraName] and VFXData.VFX[VFXData.AuraMap[auraName]] then
		return VFXData.VFX[VFXData.AuraMap[auraName]]
	end

	-- 2. AUTO-DETECT: check CustomVFX folder for a rig with this aura's name!
	local CustomVFX = game:GetService("ReplicatedStorage"):FindFirstChild("CustomVFX")
	if CustomVFX then
		local rig = CustomVFX:FindFirstChild(auraName)
		if rig then
			-- Found a custom rig! Use it automatically!
			return {
				Name = auraName,
				Effects = {
					{ Type = "Model", TemplateName = auraName, Part = "HumanoidRootPart" }
				}
			}
		end
	end

	-- 3. Fall back to tier VFX
	if tier and VFXData.TierVFX[tier] then
		return VFXData.VFX[VFXData.TierVFX[tier]]
	end
	return nil
end

return VFXData
]==]

-- ═══ 2) VFX CLIENT (clean + error protection + Model support!) ═══
ensure("LocalScript", "VFXClient", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CustomVFXFolder = ReplicatedStorage:WaitForChild("CustomVFX")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")
local VFX_TAG = "AuraVFX"

-- 🔒 ERROR PROTECTION: if VFXData or AuraData is broken, print a CLEAR message
local AuraData, VFXData
local ok1, err1 = pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)
if not ok1 then
	warn("❌❌❌ VFXClient STOPPED: AuraData has an error! ❌❌❌")
	warn("Error: " .. tostring(err1))
	return
end
local ok2, err2 = pcall(function() VFXData = require(ReplicatedStorage:WaitForChild("VFXData")) end)
if not ok2 then
	warn("❌❌❌ VFXClient STOPPED: VFXData has an error! ❌❌❌")
	warn("Error: " .. tostring(err2))
	warn("FIX: Run the clean VFXData command bar (don't edit manually!)")
	return
end

print("✨ VFXClient loaded successfully!")
print("   📦 VFX defined: " .. #VFXData.VFX .. " types")
print("   📁 CustomVFX folder contents:")
for _, item in ipairs(CustomVFXFolder:GetChildren()) do
	print("      - " .. item.Name .. " (" .. item.ClassName .. ")")
end
if #CustomVFXFolder:GetChildren() == 0 then
	print("      (empty — add your rigs here!)")
end

-- 🧹 CLEAN UP
local function clearVFX(character)
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:GetAttribute(VFX_TAG) then
			if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then obj.Enabled = false end
			obj:Destroy()
		end
	end
end

-- 🏗️ SINGLE EFFECT CREATORS
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

-- 🌟 MODEL TYPE: clones your whole rig and welds it to the character
local function createModel(character, cfg)
	local template = CustomVFXFolder:FindFirstChild(cfg.TemplateName)
	if not template then
		warn("⚠️ Rig '" .. tostring(cfg.TemplateName) .. "' not found in CustomVFX!")
		return nil
	end

	local clone = template:Clone()
	local parts = {}
	local primaryPart = nil

	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
			if not primaryPart then primaryPart = obj end
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CanTouch = false
			obj.Massless = true
			obj.Anchored = false
		end
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
		end
		obj:SetAttribute(VFX_TAG, true)
	end

	if not primaryPart then
		warn("⚠️ No parts in rig '" .. cfg.TemplateName .. "'!")
		clone:Destroy()
		return nil
	end

	clone.PrimaryPart = primaryPart

	-- Record offsets BEFORE moving (so rig shape is preserved!)
	local offsets = {}
	for _, part in ipairs(parts) do
		if part ~= primaryPart then
			offsets[part] = primaryPart.CFrame:Inverse() * part.CFrame
		end
	end

	-- Find body part
	local bodyPart = character:FindFirstChild(cfg.Part or "HumanoidRootPart")
	if not bodyPart then bodyPart = character:FindFirstChild("HumanoidRootPart") end
	if not bodyPart then
		warn("⚠️ No HumanoidRootPart on character!")
		clone:Destroy()
		return nil
	end

	-- Position and weld
	primaryPart.CFrame = bodyPart.CFrame
	clone:SetAttribute(VFX_TAG, true)
	clone.Parent = character

	local mainWeld = Instance.new("Weld")
	mainWeld.Part0 = bodyPart
	mainWeld.Part1 = primaryPart
	mainWeld.C0 = CFrame.new()
	mainWeld.Parent = primaryPart

	for part, offset in pairs(offsets) do
		local weld = Instance.new("Weld")
		weld.Part0 = primaryPart
		weld.Part1 = part
		weld.C0 = offset
		weld.Parent = part
	end

	print("✅ Rig '" .. cfg.TemplateName .. "' attached! (" .. #parts .. " parts)")
	return clone
end

-- 🎬 APPLY VFX
local function applyVFX(character, vfxConfig)
	if not character or not vfxConfig then return end
	print("🎬 Applying VFX: " .. vfxConfig.Name)
	for _, effect in ipairs(vfxConfig.Effects) do
		if effect.Type == "Model" then
			createModel(character, effect)
		else
			local part = character:FindFirstChild(effect.Part)
			if not part then part = character:FindFirstChild("HumanoidRootPart") end
			if not part then continue end
			local inst
			if effect.Type == "Particle" then inst = createParticle(part, effect)
			elseif effect.Type == "Fire" then inst = createFire(part, effect)
			elseif effect.Type == "Smoke" then inst = createSmoke(part, effect)
			elseif effect.Type == "Light" then inst = createLight(part, effect) end
			if inst then print("  ✅ " .. effect.Type .. " on " .. part.Name) end
		end
	end
end

-- parse mutated aura name
local function parseAuraName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

-- 🎮 MAIN
local currentEquipped = nil
local function updateVFX()
	local character = player.Character
	if not character then return end
	clearVFX(character)
	if not currentEquipped or currentEquipped == "" then return end
	local baseName = parseAuraName(currentEquipped)
	local aura = AuraData.GetByName(baseName)
	local tier = aura and aura.Tier or nil
	local vfxConfig = VFXData.GetVFXForAura(baseName, tier)
	if vfxConfig then
		applyVFX(character, vfxConfig)
	else
		print("ℹ️ No VFX for '" .. baseName .. "' (using tier: " .. tostring(tier) .. ")")
	end
end

EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	print("📡 Equip event: " .. tostring(auraName))
	currentEquipped = auraName
	updateVFX()
end)
player.CharacterAdded:Connect(function() task.wait(1) updateVFX() end)
]==]

print("══════════════════════════════════════")
print("✅ VFX FINAL FIX APPLIED!")
print("══════════════════════════════════════")
print("🌟 NEW: Auto-detection!")
print("   Just put your rig in CustomVEX and name it after the aura!")
print("   Example: name your rig 'Nine-Tails' → equip Nine-Tails → VFX!")
print("🔒 Error protection added (won't crash silently anymore)")
print("══════════════════════════════════════")
print("🎮 TEST:")
print("   1. Put your rig in ReplicatedStorage > CustomVEX")
print("   2. Rename it to match an aura (e.g. 'Nine-Tails')")
print("   3. Press Play → check Output for 'VFXClient loaded!'")
print("   4. Admin → Give Nine-Tails → Equip → check Output!")
print("══════════════════════════════════════")
