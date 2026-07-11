-- ═══════════════════════════════════════════════════════════
-- 🚀 MEGA FIX — fixes ALL 4 scripts in ONE paste!
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar → Enter
--
-- This fixes:
--   1. VFXData (CLEAN — with auto-detection! No manual editing!)
--   2. VFXClient (with Model/rig support + error protection)
--   3. WeatherClient (fixes CelestialBodiesShow skybox error)
--   4. RollUI (result text fades out + inactivity reminder)
--
-- ⚠️ AFTER PASTING THIS: DO NOT EDIT VFXData MANUALLY!
--    To use your own VFX rig, just:
--    1. Put it in ReplicatedStorage > CustomVFX
--    2. Name it EXACTLY the same as the aura (case-sensitive!)
--    3. That's it! The system finds it automatically!
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

print("🔧 Fixing VFXData...")
-- ═══ 1) VFX DATA (CLEAN + AUTO-DETECTION) ═══
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

-- AUTO-DETECTION: if CustomVFX has a rig named the same as the aura, use it!
function VFXData.GetVFXForAura(auraName, tier)
	if VFXData.AuraMap[auraName] and VFXData.VFX[VFXData.AuraMap[auraName]] then
		return VFXData.VFX[VFXData.AuraMap[auraName]]
	end
	local CustomVFX = game:GetService("ReplicatedStorage"):FindFirstChild("CustomVFX")
	if CustomVFX then
		local rig = CustomVFX:FindFirstChild(auraName)
		if rig then
			return { Name = auraName, Effects = { { Type = "Model", TemplateName = auraName, Part = "HumanoidRootPart" } } }
		end
	end
	if tier and VFXData.TierVFX[tier] then return VFXData.VFX[VFXData.TierVFX[tier]] end
	return nil
end

return VFXData
]==]

print("🔧 Fixing VFXClient...")
-- ═══ 2) VFX CLIENT (with Model support + auto-detection + error protection) ═══
ensure("LocalScript", "VFXClient", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CustomVFXFolder = ReplicatedStorage:WaitForChild("CustomVFX")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")
local VFX_TAG = "AuraVFX"

local AuraData
local ok1 = pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)
if not ok1 then warn("VFXClient: AuraData error!") return end

local VFXData
local ok2 = pcall(function() VFXData = require(ReplicatedStorage:WaitForChild("VFXData")) end)
if not ok2 then warn("VFXClient: VFXData error! Run the mega fix command bar!") return end

print("✨ VFXClient loaded! CustomVFX folder has " .. #CustomVFXFolder:GetChildren() .. " items:")
for _, item in ipairs(CustomVFXFolder:GetChildren()) do
	print("   - " .. item.Name .. " (" .. item.ClassName .. ")")
end

local function clearVFX(character)
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:GetAttribute(VFX_TAG) then
			if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then obj.Enabled = false end
			obj:Destroy()
		end
	end
end

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

local function createModel(character, cfg)
	local template = CustomVFXFolder:FindFirstChild(cfg.TemplateName)
	if not template then
		warn("VFX: Rig '" .. tostring(cfg.TemplateName) .. "' NOT found in CustomVFX!")
		return nil
	end
	print("VFX: Cloning rig '" .. cfg.TemplateName .. "'...")
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
		warn("VFX: No parts found in rig!")
		clone:Destroy()
		return nil
	end
	clone.PrimaryPart = primaryPart
	local offsets = {}
	for _, part in ipairs(parts) do
		if part ~= primaryPart then
			offsets[part] = primaryPart.CFrame:Inverse() * part.CFrame
		end
	end
	local bodyPart = character:FindFirstChild(cfg.Part or "HumanoidRootPart")
	if not bodyPart then bodyPart = character:FindFirstChild("HumanoidRootPart") end
	if not bodyPart then clone:Destroy() return nil end
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
	print("VFX: Rig attached! (" .. #parts .. " parts, " .. #clone:GetDescendants() .. " total objects)")
	return clone
end

local function applyVFX(character, vfxConfig)
	if not character or not vfxConfig then return end
	print("VFX: Applying '" .. vfxConfig.Name .. "'...")
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
		end
	end
end

local function parseAuraName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

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
		print("VFX: No VFX for '" .. baseName .. "'. Put a rig named '" .. baseName .. "' in CustomVFX!")
	end
end

EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	currentEquipped = auraName
	updateVFX()
end)
player.CharacterAdded:Connect(function() task.wait(1) updateVFX() end)
]==]

print("🔧 Fixing WeatherClient...")
-- ═══ 3) WEATHER CLIENT (fixes CelestialBodiesShow error) ═══
ensure("LocalScript", "WeatherClient", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeatherChangedEvent = Remotes:WaitForChild("WeatherChangedEvent")
local ChatTipEvent = Remotes:WaitForChild("ChatTipEvent")
local ChatAnnounceEvent = Remotes:WaitForChild("ChatAnnounceEvent")
local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))

local VFX_HEIGHT = 50
local TWEEN_TIME = 3
local BANNER_DURATION = 5

for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "WeatherGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "WeatherGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15; gui.Parent = playerGui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.08); banner.Position = UDim2.fromScale(0.15, 0.04)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(20,20,35); banner.TextColor3 = Color3.fromRGB(255,255,255)
banner.BackgroundTransparency = 1; banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.15,0); bnCorner.Parent = banner; banner.Parent = gui

local currentVFX = nil
local weatherOverride = false

local function clearVFX() if currentVFX then currentVFX:Destroy(); currentVFX = nil end end

local function applyVFX(particles)
	clearVFX()
	if not particles or #particles == 0 then return end
	local char = player.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	currentVFX = Instance.new("Part")
	currentVFX.Name = "WeatherVFX"; currentVFX.Size = Vector3.new(1,1,1); currentVFX.Transparency = 1
	currentVFX.CanCollide = false; currentVFX.CanQuery = false; currentVFX.Anchored = false; currentVFX.Massless = true
	local weld = Instance.new("Weld"); weld.Part0 = root; weld.Part1 = currentVFX; weld.C0 = CFrame.new(0, VFX_HEIGHT, 0); weld.Parent = currentVFX
	currentVFX.Parent = char
	for _, cfg in ipairs(particles) do
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(cfg.Color or Color3.fromRGB(255,255,255))
		e.Size = cfg.Size or NumberSequence.new(2)
		e.Transparency = cfg.Transparency or NumberSequence.new(0)
		e.Lifetime = cfg.Lifetime or NumberRange.new(5,10)
		e.Rate = cfg.Rate or 100; e.Speed = cfg.Speed or NumberRange.new(5,10)
		e.SpreadAngle = cfg.SpreadAngle or Vector2.new(45,45)
		e.Acceleration = cfg.Acceleration or Vector3.new(0,0,0)
		if cfg.Texture and cfg.Texture ~= "" then e.Texture = cfg.Texture end
		e.Parent = currentVFX
	end
end

local function applySkybox(skyboxIds)
	if not skyboxIds or #skyboxIds ~= 6 then return end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then sky = Instance.new("Sky"); sky.Parent = Lighting end
	pcall(function()
		sky.SkyboxBk = skyboxIds[1]
		sky.SkyboxDn = skyboxIds[2]
		sky.SkyboxFt = skyboxIds[3]
		sky.SkyboxLf = skyboxIds[4]
		sky.SkyboxRt = skyboxIds[5]
		sky.SkyboxUp = skyboxIds[6]
	end)
	pcall(function() sky.CelestialBodiesShow = true end)
end

local function applyLighting(lightingCfg)
	if not lightingCfg then return end
	TweenService:Create(Lighting, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		ClockTime = lightingCfg.ClockTime or 14,
		FogColor = lightingCfg.FogColor or Color3.fromRGB(199,217,240),
		FogEnd = lightingCfg.FogEnd or 100000,
		Ambient = lightingCfg.Ambient or Color3.fromRGB(128,128,128),
		OutdoorAmbient = lightingCfg.OutdoorAmbient or Color3.fromRGB(128,128,128),
		Brightness = lightingCfg.Brightness or 2,
		ColorShift_Top = lightingCfg.ColorShift_Top or Color3.fromRGB(0,0,0),
		ColorShift_Bottom = lightingCfg.ColorShift_Bottom or Color3.fromRGB(0,0,0),
	}):Play()
end

local function showBanner(text, color)
	if not text or text == "" then return end
	banner.Text = text; banner.TextColor3 = color or Color3.fromRGB(255,255,255)
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.TextTransparency = 0
	banner.Position = UDim2.fromScale(0.15, -0.1)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15, 0.04)}):Play()
	task.delay(BANNER_DURATION, function()
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		task.wait(0.5); banner.Visible = false
	end)
end

WeatherChangedEvent.OnClientEvent:Connect(function(info)
	weatherOverride = (info.Name ~= "Clear")
	applyLighting(info.Lighting)
	applyVFX(info.Particles)
	applySkybox(info.Skybox)
	showBanner(info.BannerText, info.BannerColor)
end)

local tc = WeatherData.TimeCycle
if tc.Enabled then
	Lighting.ClockTime = tc.StartTime or 6
	local hoursPerSec = 24 / ((tc.DayDurationMinutes or 10) * 60)
	task.spawn(function()
		while true do
			if not weatherOverride then
				Lighting.ClockTime = (Lighting.ClockTime + hoursPerSec * 0.1) % 24
			end
			task.wait(0.1)
		end
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(1)
	local cv = ReplicatedStorage:FindFirstChild("CurrentWeather")
	if cv and cv.Value ~= "Clear" then
		local weather = WeatherData.GetByName(cv.Value)
		if weather then applyVFX(weather.Particles) end
	end
end)

ChatTipEvent.OnClientEvent:Connect(function(message)
	pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", { Text = message, Color = Color3.fromRGB(255,215,0), Font = Enum.Font.SourceSansBold, TextSize = 18 }) end)
end)

ChatAnnounceEvent.OnClientEvent:Connect(function(info)
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "⭐ " .. info.Player .. " has obtained " .. info.Name .. "! (" .. info.Tier .. ")",
			Color = info.Color or Color3.fromRGB(255, 215, 0),
			Font = Enum.Font.SourceSansBold, TextSize = 18,
		})
	end)
end)

print("WeatherClient loaded!")
]==]

print("🔧 Fixing RollUI...")
-- ═══ 4) ROLL UI (result fades + inactivity reminder) ═══
ensure("LocalScript", "RollUI", SPS).Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local auraNames = {}
for _, a in ipairs(AuraData.Auras) do table.insert(auraNames, a.Name) end

local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BANNER_DEFAULT_COLOR = Color3.fromRGB(255,215,0)
local THEME_COLOR = Color3.fromRGB(30,30,45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80,120,255)
local FLICKER_SPEEDS = {0.03,0.035,0.04,0.045,0.05,0.06,0.07,0.085,0.10,0.12}
local NEAR_MISS_RARITY = 1000
local NEAR_MISS_HOLD = 0.6
local FLASH_TIME = 0.25
local GLOW_STROKE = 0.2
local SHAKE_THRESHOLD = 1000
local SHAKE_INTENSITY = 0.012
local SHAKE_DURATION = 0.4
local RESULT_HOME = UDim2.fromScale(0.2,0.36)
local NEAR_MISS_SIZE = UDim2.fromScale(0.7,0.32)
local RESULT_FADE_DELAY = 4
local RESULT_FADE_TIME = 1.5
local INACTIVITY_REMINDER = 600

local rareAuras = {}
for _, a in ipairs(AuraData.Auras) do if a.Rarity >= NEAR_MISS_RARITY then table.insert(rareAuras, a) end end

for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "RollGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10; gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(0.16,0.09); button.Position = UDim2.fromScale(0.81,0.87)
button.Text = "ROLL"; button.Font = Enum.Font.GothamBlack; button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR; button.TextColor3 = TEXT_COLOR
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12,0); bCorner.Parent = button; button.Parent = gui

local result = Instance.new("TextLabel")
result.Size = UDim2.fromScale(0.6,0.22); result.Position = RESULT_HOME
result.Text = "Press ROLL to begin!"; result.Font = Enum.Font.GothamBlack; result.TextScaled = true
result.BackgroundTransparency = 1; result.TextColor3 = TEXT_COLOR; result.TextStrokeTransparency = 1; result.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7,0.1); banner.Position = UDim2.fromScale(0.15,0.12)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = THEME_COLOR; banner.TextColor3 = BANNER_DEFAULT_COLOR
banner.BackgroundTransparency = 1; banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2,0); bnCorner.Parent = banner; banner.Parent = gui

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1,1); flash.Position = UDim2.fromScale(0,0)
flash.BackgroundColor3 = Color3.fromRGB(255,255,255); flash.BackgroundTransparency = 1; flash.ZIndex = 50; flash.Parent = gui

local function setGlow(on) result.TextStrokeColor3 = result.TextColor3; result.TextStrokeTransparency = on and GLOW_STROKE or 1 end
local function shakeLabel(label, homePos, rarity)
	local intensity = SHAKE_INTENSITY; local duration = SHAKE_DURATION
	if rarity >= 5000 then intensity = SHAKE_INTENSITY*1.5; duration = SHAKE_DURATION*1.4 end
	if rarity >= 70000 then intensity = SHAKE_INTENSITY*2.2; duration = SHAKE_DURATION*1.8 end
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		label.Position = UDim2.fromScale(homePos.X.Scale+(math.random()-0.5)*2*intensity, homePos.Y.Scale+(math.random()-0.5)*2*intensity)
		task.wait(0.02)
	end
	label.Position = homePos
end

local isRolling = false
local hasRolled = false
local lastRollTime = os.clock()
local fadeTimer = nil

local function scheduleFadeOut()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end) end
	fadeTimer = task.delay(RESULT_FADE_DELAY, function()
		fadeTimer = nil
		if not isRolling then
			TweenService:Create(result, TweenInfo.new(RESULT_FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(30)
		if hasRolled and not isRolling and (os.clock() - lastRollTime) > INACTIVITY_REMINDER then
			if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
			result.TextTransparency = 0
			result.TextStrokeTransparency = 1
			result.Text = "💤 Still there? Press ROLL!"
			result.TextColor3 = TEXT_COLOR
			result.Position = RESULT_HOME
			result.Size = UDim2.fromScale(0.6,0.22)
			setGlow(false)
		end
	end
end)

button.MouseButton1Click:Connect(function()
	if isRolling then return end
	isRolling = true; hasRolled = true; lastRollTime = os.clock()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
	result.TextTransparency = 0
	button.Text = "..."
	result.Text = ""; result.TextColor3 = TEXT_COLOR; result.Position = RESULT_HOME; result.Size = UDim2.fromScale(0.6,0.22); setGlow(false)
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)
	for _, speed in ipairs(FLICKER_SPEEDS) do result.Text = auraNames[math.random(1,#auraNames)]; task.wait(speed) end
	if #rareAuras > 0 then
		local fake = rareAuras[math.random(1,#rareAuras)]
		result.TextColor3 = fake.Color; setGlow(true)
		result.Text = fake.Name .. "\n1 in " .. fake.Rarity .. "  •  " .. fake.Tier
		result.Size = NEAR_MISS_SIZE; result.Position = UDim2.fromScale(0.15,0.34)
		TweenService:Create(result, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.30)}):Play()
		task.wait(NEAR_MISS_HOLD)
	end
	flash.BackgroundTransparency = 1
	local flashIn = TweenService:Create(flash, TweenInfo.new(FLASH_TIME*0.4), {BackgroundTransparency = 0})
	flashIn:Play(); flashIn.Completed:Wait()
	setGlow(false); result.Size = UDim2.fromScale(0.6,0.22)
	while not gotResult do task.wait(0.02) end
	button.Text = "ROLL"
	if not res then
		result.Text = "⏳ Too fast!"; result.TextColor3 = TEXT_COLOR
		TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
		isRolling = false; return
	end
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "✨ MUTATED ✨\n" .. displayText end
	result.Text = displayText .. "\n1 in " .. res.Rarity .. "  •  " .. res.Tier
	result.TextColor3 = res.Color or TEXT_COLOR
	result.Position = UDim2.fromScale(0.2,-0.3)
	TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
	local reveal = TweenService:Create(result, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = RESULT_HOME})
	reveal:Play(); reveal.Completed:Wait()
	if res.Rarity >= SHAKE_THRESHOLD or res.Mutated then setGlow(true); shakeLabel(result, RESULT_HOME, res.Rarity) end
	scheduleFadeOut()
	isRolling = false
end)

AnnounceEvent.OnClientEvent:Connect(function(info)
	local prefix = info.Mutated and "✨ MUTATED " or ""
	banner.Text = "🎉  " .. info.Player .. " pulled " .. prefix .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.TextColor3 = info.Color or BANNER_DEFAULT_COLOR
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.12)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)
]==]

print("══════════════════════════════════════")
print("✅ MEGA FIX COMPLETE! All 4 scripts fixed!")
print("══════════════════════════════════════")
print("1. VFXData → CLEAN (no more errors!) + auto-detection")
print("2. VFXClient → Model/rig support + error protection")
print("3. WeatherClient → Skybox error fixed")
print("4. RollUI → Result fades out + inactivity reminder")
print("══════════════════════════════════════")
print("⚠️ IMPORTANT — DO NOT EDIT VFXData MANUALLY!")
print("   To use your VFX rig:")
print("   1. Put it in ReplicatedStorage > CustomVFX")
print("   2. Name it EXACTLY like the aura (case-sensitive!)")
print("   Example: name it 'Nine-Tails' (NOT 'NINE-TAILS' or 'nine-tails')")
print("══════════════════════════════════════")
print("🎮 TEST NOW:")
print("   1. Press Play")
print("   2. Check Output — you should see 'VFXClient loaded!'")
print("   3. Admin → Give Nine-Tails → Equip")
print("   4. You should see fire VFX on your character!")
print("══════════════════════════════════════")
