-- ═══════════════════════════════════════════════════════════
-- 🌪️ FIX WEATHER CLIENT (Nuke & Rebuild)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- This removes the broken/old WeatherClient and installs a clean one.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local old = SPS:FindFirstChild("WeatherClient")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "WeatherClient"
s.Parent = SPS
s.Source = [==[
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

local WeatherData
pcall(function() WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData")) end)

local VH = 50
local TT = 3
local BD = 5

for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "WeatherGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "WeatherGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15; gui.Parent = playerGui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.08); banner.Position = UDim2.fromScale(0.15, 0.04)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(20,20,35); banner.TextColor3 = Color3.fromRGB(255,255,255)
banner.BackgroundTransparency = 1; banner.Visible = false
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0.15,0); bc.Parent = banner; banner.Parent = gui

local cv = nil
local wo = false

local function clearVFX() if cv then cv:Destroy() cv = nil end end

local function applyVFX(particles)
	clearVFX()
	if not particles or #particles == 0 then return end
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	cv = Instance.new("Part")
	cv.Name = "WeatherVFX"; cv.Size = Vector3.new(1,1,1); cv.Transparency = 1
	cv.CanCollide = false; cv.CanQuery = false; cv.Anchored = false; cv.Massless = true
	
	local w = Instance.new("Weld")
	w.Part0 = root; w.Part1 = cv; w.C0 = CFrame.new(0, VH, 0); w.Parent = cv
	cv.Parent = char
	
	for _, c in ipairs(particles) do
		local e = Instance.new("ParticleEmitter")
		e.Color = ColorSequence.new(c.Color or Color3.fromRGB(255,255,255))
		e.Size = c.Size or NumberSequence.new(2)
		e.Transparency = c.Transparency or NumberSequence.new(0)
		e.Lifetime = c.Lifetime or NumberRange.new(5,10)
		e.Rate = c.Rate or 100; e.Speed = c.Speed or NumberRange.new(5,10)
		e.SpreadAngle = c.SpreadAngle or Vector2.new(45,45)
		e.Acceleration = c.Acceleration or Vector3.new(0,0,0)
		if c.Texture and c.Texture ~= "" then e.Texture = c.Texture end
		e.Parent = cv
	end
end

local function applySkybox(skybox)
	if not skybox or #skybox ~= 6 then return end
	local s = Lighting:FindFirstChildOfClass("Sky")
	if not s then s = Instance.new("Sky"); s.Parent = Lighting end
	pcall(function()
		s.SkyboxBk = skybox[1]; s.SkyboxDn = skybox[2]; s.SkyboxFt = skybox[3]
		s.SkyboxLf = skybox[4]; s.SkyboxRt = skybox[5]; s.SkyboxUp = skybox[6]
	end)
end

local function applyLighting(lc)
	if not lc then return end
	TweenService:Create(Lighting, TweenInfo.new(TT, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		ClockTime = lc.ClockTime or 14,
		FogColor = lc.FogColor or Color3.fromRGB(199,217,240),
		FogEnd = lc.FogEnd or 100000,
		Ambient = lc.Ambient or Color3.fromRGB(128,128,128),
		OutdoorAmbient = lc.OutdoorAmbient or Color3.fromRGB(128,128,128),
		Brightness = lc.Brightness or 2,
		ColorShift_Top = lc.ColorShift_Top or Color3.fromRGB(0,0,0),
		ColorShift_Bottom = lc.ColorShift_Bottom or Color3.fromRGB(0,0,0),
	}):Play()
end

local function showBanner(txt, col)
	if not txt or txt == "" then return end
	banner.Text = txt; banner.TextColor3 = col or Color3.fromRGB(255,255,255)
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.TextTransparency = 0
	banner.Position = UDim2.fromScale(0.15, -0.1)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15, 0.04)}):Play()
	task.delay(BD, function()
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		task.wait(0.5); banner.Visible = false
	end)
end

WeatherChangedEvent.OnClientEvent:Connect(function(info)
	wo = (info.Name ~= "Clear")
	applyLighting(info.Lighting)
	applyVFX(info.Particles)
	applySkybox(info.Skybox)
	showBanner(info.BannerText, info.BannerColor)
end)

local tc = WeatherData.TimeCycle
if tc.Enabled then
	Lighting.ClockTime = tc.StartTime or 6
	local hps = 24 / ((tc.DayDurationMinutes or 10) * 60)
	task.spawn(function()
		while true do
			if not wo then
				Lighting.ClockTime = (Lighting.ClockTime + hps * 0.1) % 24
			end
			task.wait(0.1)
		end
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(1)
	local v = ReplicatedStorage:FindFirstChild("CurrentWeather")
	if v and v.Value ~= "Clear" then
		local w = WeatherData.GetByName(v.Value)
		if w then applyVFX(w.Particles) end
	end
end)

ChatTipEvent.OnClientEvent:Connect(function(msg)
	pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", {Text=msg, Color=Color3.fromRGB(255,215,0), Font=Enum.Font.SourceSansBold, TextSize=18}) end)
end)

ChatAnnounceEvent.OnClientEvent:Connect(function(info)
	pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", {Text="⭐ "..info.Player.." has obtained "..info.Name.."! ("..info.Tier..")", Color=info.Color or Color3.fromRGB(255,215,0), Font=Enum.Font.SourceSansBold, TextSize=18}) end)
end)

print("WeatherClient loaded successfully!")
]==]

print("✅ WeatherClient NUKED AND REBUILT! Weather is fixed.")
