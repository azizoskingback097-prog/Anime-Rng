-- ═══════════════════════════════════════════════════════════
-- 🔧 WEATHER CLIENT FIX — fixes CelestialBodiesShow error
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar → Enter
-- This updates WeatherClient to handle the skybox error gracefully.
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local function ensure(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName ~= className then inst:Destroy(); inst = nil end
	if not inst then inst = Instance.new(className); inst.Name = name; inst.Parent = parent end
	return inst
end

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

-- 🔧 FIXED: handles skybox errors gracefully
local function applySkybox(skyboxIds)
	if not skyboxIds or #skyboxIds ~= 6 then return end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then sky = Instance.new("Sky"); sky.Parent = Lighting end
	-- use pcall to safely set each property (in case the Sky is different)
	pcall(function()
		sky.SkyboxBk = skyboxIds[1]
		sky.SkyboxDn = skyboxIds[2]
		sky.SkyboxFt = skyboxIds[3]
		sky.SkyboxLf = skyboxIds[4]
		sky.SkyboxRt = skyboxIds[5]
		sky.SkyboxUp = skyboxIds[6]
	end)
	-- CelestialBodiesShow might not exist on all Sky objects
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
			Font = Enum.Font.SourceSansBold,
			TextSize = 18,
		})
	end)
end)

print("WeatherClient loaded! (Skybox fix applied)")
]==]

print("══════════════════════════════════════")
print("✅ WEATHER CLIENT SKYBOX FIX APPLIED!")
print("🔧 Fixed: CelestialBodiesShow error (now wrapped in pcall)")
print("══════════════════════════════════════")
