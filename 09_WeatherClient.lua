-- ═══════════════════════════════════════════════════════════
-- 🌪️  WEATHER CLIENT  —  LocalScript   |   PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
--   1. VISUALS → when weather changes, smoothly tweens Lighting
--      (fog, brightness, time of day, colors) and spawns a VFX Part
--      with particle emitters that follow your character
--   2. BANNER → shows a weather banner ("🌪️ SANDSTORM!")
--   3. CHAT TIPS → shows tips from the server in the chat
--
-- 🎨 HOW TO CUSTOMIZE:
--   • VFX height        → VFX_HEIGHT (how far above you particles spawn)
--   • Tween speed       → TWEEN_TIME (how fast lighting transitions)
--   • Banner duration   → BANNER_DURATION
--   • Tip color         → TIP_COLOR
--   • Particle settings → edit in WeatherData (not here!)
--
-- 🔗 RELATED SCRIPTS:
--   • WeatherServer → fires WeatherChangedEvent + ChatTipEvent
--   • WeatherData   → reads particle configs + mutation colors
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Add a sound effect when weather changes (wind howl for Sandstorm,
--   eerie tone for Blood Moon). Play it here when receiving the event.
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local StarterGui        = game:GetService("StarterGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes             = ReplicatedStorage:WaitForChild("Remotes")
local WeatherChangedEvent = Remotes:WaitForChild("WeatherChangedEvent")
local ChatTipEvent        = Remotes:WaitForChild("ChatTipEvent")

-- ⚙️ ─────────────────── CUSTOMIZE: SETTINGS ───────────────────
local VFX_HEIGHT      = 50      -- studs above the player particles spawn
local TWEEN_TIME      = 3       -- seconds for lighting to transition
local BANNER_DURATION = 5       -- seconds the weather banner stays
local TIP_COLOR       = Color3.fromRGB(255, 215, 0)
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

-- ────────────── build the weather banner UI ──────────────
local gui = Instance.new("ScreenGui")
gui.Name = "WeatherGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 15
gui.Parent = playerGui

-- 🧹 SELF-CLEAN
for _, child in ipairs(playerGui:GetChildren()) do
	if child.Name == "WeatherGui" and child ~= gui then child:Destroy() end
end

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.08)
banner.Position = UDim2.fromScale(0.15, 0.04)
banner.Text = ""
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
banner.TextColor3 = Color3.fromRGB(255, 255, 255)
banner.BackgroundTransparency = 1
banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.15, 0); bnCorner.Parent = banner
banner.Parent = gui

-- ────────────── VFX part management ──────────────
local currentVFX = nil  -- holds the current VFX Part

local function clearVFX()
	if currentVFX then
		currentVFX:Destroy()
		currentVFX = nil
	end
end

local function applyVFX(particles)
	clearVFX()
	if not particles or #particles == 0 then return end

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- create the transparent VFX part
	currentVFX = Instance.new("Part")
	currentVFX.Name = "WeatherVFX"
	currentVFX.Size = Vector3.new(1, 1, 1)
	currentVFX.Transparency = 1
	currentVFX.CanCollide = false
	currentVFX.CanQuery = false
	currentVFX.Anchored = false
	currentVFX.Massless = true

	-- weld it above the player so particles follow you
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = currentVFX
	weld.C0 = CFrame.new(0, VFX_HEIGHT, 0)
	weld.Parent = currentVFX
	currentVFX.Parent = character

	-- add a ParticleEmitter for each particle config
	for _, cfg in ipairs(particles) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(cfg.Color or Color3.fromRGB(255, 255, 255))
		emitter.Size = cfg.Size or NumberSequence.new(2)
		emitter.Transparency = cfg.Transparency or NumberSequence.new(0)
		emitter.Lifetime = cfg.Lifetime or NumberRange.new(5, 10)
		emitter.Rate = cfg.Rate or 100
		emitter.Speed = cfg.Speed or NumberRange.new(5, 10)
		emitter.SpreadAngle = cfg.SpreadAngle or Vector2.new(45, 45)
		emitter.Acceleration = cfg.Acceleration or Vector3.new(0, 0, 0)
		if cfg.Texture and cfg.Texture ~= "" then
			emitter.Texture = cfg.Texture
		end
		emitter.Parent = currentVFX
	end
end

-- ────────────── apply lighting changes (smooth tween) ──────────────
local function applyLighting(lightingCfg)
	if not lightingCfg then return end
	local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	-- tween all lighting properties at once
	TweenService:Create(Lighting, tweenInfo, {
		ClockTime        = lightingCfg.ClockTime or 14,
		FogColor         = lightingCfg.FogColor or Color3.fromRGB(199, 217, 240),
		FogEnd           = lightingCfg.FogEnd or 100000,
		Ambient          = lightingCfg.Ambient or Color3.fromRGB(128, 128, 128),
		OutdoorAmbient   = lightingCfg.OutdoorAmbient or Color3.fromRGB(128, 128, 128),
		Brightness       = lightingCfg.Brightness or 2,
		ColorShift_Top    = lightingCfg.ColorShift_Top or Color3.fromRGB(0, 0, 0),
		ColorShift_Bottom = lightingCfg.ColorShift_Bottom or Color3.fromRGB(0, 0, 0),
	}):Play()
end

-- ────────────── show weather banner ──────────────
local function showBanner(text, color)
	if not text or text == "" then return end
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	banner.Visible = true
	banner.BackgroundTransparency = 0.3

	banner.Position = UDim2.fromScale(0.15, -0.1)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.15, 0.04) }):Play()

	task.delay(BANNER_DURATION, function()
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.5)
		banner.Visible = false
		banner.TextTransparency = 0
	end)
end

-- ────────────── listen for weather changes ──────────────
WeatherChangedEvent.OnClientEvent:Connect(function(info)
	applyLighting(info.Lighting)
	applyVFX(info.Particles)
	showBanner(info.BannerText, info.BannerColor)
end)

-- ────────────── handle character respawn (re-attach VFX) ──────────────
player.CharacterAdded:Connect(function()
	task.wait(1)
	-- re-apply current weather's particles if a weather is active
	local currentWeatherValue = ReplicatedStorage:FindFirstChild("CurrentWeather")
	if currentWeatherValue and currentWeatherValue.Value ~= "Clear" then
		local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))
		local weather = WeatherData.GetByName(currentWeatherValue.Value)
		if weather then applyVFX(weather.Particles) end
	end
end)

-- ────────────── chat tips ──────────────
ChatTipEvent.OnClientEvent:Connect(function(message)
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message,
			Color = TIP_COLOR,
			Font = Enum.Font.SourceSansBold,
			TextSize = 18,
		})
	end)
end)

print("🌪️ WeatherClient loaded!")
