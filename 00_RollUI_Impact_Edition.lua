-- ═══════════════════════════════════════════════════════════
-- 💥 ROLL UI: IMPACT EDITION (Stable + Heavy Impacts!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- WHAT THIS DOES:
--   • Fixes the crash (removed AbsoluteSize bug).
--   • Normal pulls: Quick, clean slot-machine reveal.
--   • Rare/Epic/Legendary/Mythic pulls: HEAVY IMPACTS!
--     (Screen shakes violently, colored flashes, particle bursts).
--   • The "Fakeout Hook" is included (1-in-7 chance to fake a rare).
--   • Has empty slots for YOU to add custom cutscenes later!
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("RollUI")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "RollUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

local SFX
pcall(function() SFX = require(ReplicatedStorage:WaitForChild("SFXConfig")) end)
local AuraData
pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)

-- ⚙️ SETTINGS
local FAKEOUT_CHANCE = 7         -- 1 in X chance to FAKE an impact on normal rolls
local FLICKER_SPEEDS = {0.03, 0.035, 0.04, 0.045, 0.05, 0.06, 0.07, 0.085, 0.10, 0.12}
local RESULT_FADE_DELAY = 4
local INACTIVITY_REMINDER = 600

local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BANNER_DEFAULT_COLOR = Color3.fromRGB(255,215,0)
local THEME_COLOR = Color3.fromRGB(30,30,45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80,120,255)
local RESULT_HOME = UDim2.fromScale(0.5, 0.42)
local RESULT_HOME_SIZE = UDim2.fromScale(0.45, 0.16)

-- Tier Thresholds for Impacts
local RARE_THRESHOLD = 100
local EPIC_THRESHOLD = 1000
local LEGENDARY_THRESHOLD = 5000
local MYTHIC_THRESHOLD = 50000

local auraNames, commonAuras = {}, {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		table.insert(auraNames, a.Name)
		if a.Rarity < RARE_THRESHOLD then table.insert(commonAuras, a) end
	end
end
if #auraNames == 0 then auraNames = {"..."} end
if #commonAuras == 0 then commonAuras = { {Name="Flicker", Color=Color3.fromRGB(200,200,200)} } end

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

-- Build GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

-- Container (gets shaken)
local container = Instance.new("Frame")
container.Size = UDim2.fromScale(1, 1); container.Position = UDim2.fromScale(0, 0)
container.BackgroundTransparency = 1; container.Parent = gui

-- Result Text
local result = Instance.new("TextLabel")
result.AnchorPoint = Vector2.new(0.5, 0.5); result.Size = RESULT_HOME_SIZE
result.Position = RESULT_HOME; result.Text = "Press ROLL to begin!"
result.Font = Enum.Font.Bangers; result.TextScaled = true
result.BackgroundTransparency = 1; result.TextColor3 = TEXT_COLOR
result.TextStrokeTransparency = 1; result.ZIndex = 10; result.Parent = container

-- Glow behind text
local glow = Instance.new("Frame")
glow.AnchorPoint = Vector2.new(0.5, 0.5); glow.Size = UDim2.fromScale(0.6, 0.2)
glow.Position = RESULT_HOME; glow.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
glow.BackgroundTransparency = 1; glow.ZIndex = 9
local gCorner = Instance.new("UICorner"); gCorner.CornerRadius = UDim.new(1, 0); gCorner.Parent = glow
glow.Parent = container

-- Flash overlay
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1); flash.Position = UDim2.fromScale(0, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1; flash.ZIndex = 50; flash.Parent = container

-- Buttons
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5); button.Size = UDim2.fromScale(0.16, 0.09)
button.Position = UDim2.fromScale(0.5, 0.85); button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack; button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR; button.TextColor3 = TEXT_COLOR; button.ZIndex = 20
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12, 0); bCorner.Parent = button
button.Parent = gui

local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5); autoBtn.Size = UDim2.fromScale(0.10, 0.06)
autoBtn.Position = UDim2.fromScale(0.5, 0.78); autoBtn.Text = "AUTO: OFF"
autoBtn.Font = Enum.Font.GothamBold; autoBtn.TextScaled = true
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); autoBtn.TextColor3 = TEXT_COLOR; autoBtn.ZIndex = 20
local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0.15, 0); abCorner.Parent = autoBtn
autoBtn.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.1); banner.Position = UDim2.fromScale(0.15, 0.12)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = THEME_COLOR; banner.TextColor3 = BANNER_DEFAULT_COLOR
banner.BackgroundTransparency = 1; banner.Visible = false; banner.ZIndex = 30
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2, 0); bnCorner.Parent = banner
banner.Parent = gui

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local breathingActive = false

local function shakeScreen(duration, intensity)
	local t0 = os.clock()
	while os.clock() - t0 < duration do
		local ox = (math.random() - 0.5) * 2 * intensity
		local oy = (math.random() - 0.5) * 2 * intensity
		container.Position = UDim2.fromOffset(ox, oy)
		task.wait(0.02)
	end
	container.Position = UDim2.fromScale(0, 0)
end

local function burstParticles(color, count)
	local viewportSize = Camera.ViewportSize
	for i = 1, count do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Size = UDim2.fromOffset(math.random(4, 10), math.random(4, 10))
		p.Position = UDim2.fromScale(0.5, 0.45)
		p.BackgroundColor3 = color
		p.BackgroundTransparency = 0.1
		p.BorderSizePixel = 0
		p.ZIndex = 8
		p.Parent = container
		
		local angle = (i / count) * math.pi * 2 + math.random(-0.3, 0.3)
		local dist = math.random(200, 500)
		local endX = 0.5 + math.cos(angle) * (dist / viewportSize.X)
		local endY = 0.45 + math.sin(angle) * (dist / viewportSize.Y)
		
		local tween = TweenService:Create(p, TweenInfo.new(math.random(8, 15) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(endX, endY),
			BackgroundTransparency = 1,
			Rotation = math.random(-360, 360),
		})
		tween:Play()
		
		tween.Completed:Connect(function()
			if p.Parent then p:Destroy() end
		end)
	end
end

local function startAmbientParticles(color)
	breathingActive = true
	task.spawn(function()
		while breathingActive do
			local p = Instance.new("Frame")
			p.AnchorPoint = Vector2.new(0.5, 0.5); p.Size = UDim2.fromOffset(math.random(4, 8), math.random(4, 8))
			p.Position = UDim2.new(RESULT_HOME.X.Scale + (math.random()-0.5)*0.3, RESULT_HOME.Y.Scale + (math.random()-0.5)*0.1)
			p.BackgroundColor3 = color; p.BackgroundTransparency = 0.2
			p.BorderSizePixel = 0; p.ZIndex = 9; p.Parent = container
			TweenService:Create(p, TweenInfo.new(math.random(1, 2)), {
				Position = UDim2.new(p.Position.X.Scale, p.Position.X.Offset, p.Position.Y.Scale - 0.15, p.Position.Y.Offset),
				BackgroundTransparency = 1
			}):Play()
			task.wait(math.random(10, 30) / 100)
		end
	end)
	task.spawn(function()
		while breathingActive do
			TweenService:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.5}):Play()
			task.wait(1)
			TweenService:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.8}):Play()
			task.wait(1)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- IMPACT LOGIC
-- ═══════════════════════════════════════════════════════════
local function playImpact(res, isFake)
	breathingActive = false
	local color = res.Color or Color3.fromRGB(150, 0, 255)
	
	-- Customize impact based on REAL rarity
	local shakeIntensity = 5
	local particleCount = 15
	local soundName = "rare"
	
	if isFake then
		shakeIntensity = 4
		particleCount = 10
		soundName = "reveal" -- Deflated sound for fakeouts
	elseif res.Rarity >= MYTHIC_THRESHOLD then
		shakeIntensity = 25; particleCount = 60; soundName = "mythic"
		-- ➕ ADD YOUR MYTHIC CUTSCENE HERE LATER!
	elseif res.Rarity >= LEGENDARY_THRESHOLD then
		shakeIntensity = 20; particleCount = 40; soundName = "legendary"
		-- ➕ ADD YOUR LEGENDARY CUTSCENE HERE LATER!
	elseif res.Rarity >= EPIC_THRESHOLD then
		shakeIntensity = 15; particleCount = 25; soundName = "rare"
	end
	
	-- Flash
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0
	TweenService:Create(flash, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
	
	-- Shake
	shakeScreen(0.4, shakeIntensity)
	
	-- Particles
	burstParticles(color, particleCount)
	
	-- Sound
	if SFX then SFX.Play(gui, soundName) end
	
	-- Setup Text
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "MUTATED\n" .. displayText end
	result.Text = displayText .. "\n1 in " .. res.Rarity
	result.TextColor3 = color
	result.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	result.TextStrokeTransparency = 0.1
	
	-- Glow
	glow.BackgroundColor3 = color
	glow.BackgroundTransparency = 0.5
	glow.Size = UDim2.fromScale(2, 0.5)
	TweenService:Create(glow, TweenInfo.new(0.5), {BackgroundTransparency = 0.4, Size = UDim2.fromScale(0.6, 0.2)}):Play()
	
	-- Slam In
	result.Size = UDim2.fromScale(0.05, 0.02)
	result.TextTransparency = 0
	TweenService:Create(result, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = RESULT_HOME_SIZE}):Play()
	
	-- Ambient particles only if it's a REAL rare
	if not isFake then
		startAmbientParticles(color)
	end
end

-- Normal Reveal (Common auras)
local function doNormalReveal(res)
	breathingActive = false
	if SFX then SFX.Play(gui, "reveal") end
	local displayText = res.DisplayName or res.Name
	result.Text = displayText .. "\n1 in " .. res.Rarity
	result.TextColor3 = res.Color or TEXT_COLOR
	
	result.Size = UDim2.fromScale(0.8, 0.3)
	result.TextTransparency = 0
	result.TextStrokeTransparency = 1
	TweenService:Create(result, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = RESULT_HOME_SIZE}):Play()
	shakeScreen(0.2, 2)
end

-- ═══════════════════════════════════════════════════════════
-- MAIN ROLL LOGIC
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local autoRollEnabled = false
local fadeTimer = nil
local lastRollTime = os.clock()

local function scheduleFadeOut()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end) end
	fadeTimer = task.delay(RESULT_FADE_DELAY, function()
		fadeTimer = nil
		if not isRolling and not autoRollEnabled then
			breathingActive = false
			TweenService:Create(result, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				TextTransparency = 1, TextStrokeTransparency = 1
			}):Play()
			TweenService:Create(glow, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(30)
		if not isRolling and not autoRollEnabled and (os.clock() - lastRollTime) > INACTIVITY_REMINDER then
			result.TextTransparency = 0
			result.Text = "Still there? Press ROLL!"
			result.TextColor3 = TEXT_COLOR
			result.TextStrokeTransparency = 1
		end
	end
end)

local function doRoll()
	if isRolling then return end
	isRolling = true; lastRollTime = os.clock()

	breathingActive = false
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
	result.TextTransparency = 0

	if SFX then SFX.Play(gui, "roll") end
	button.Text = "..."
	
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)

	-- Flicker
	for _, speed in ipairs(FLICKER_SPEEDS) do
		result.Text = auraNames[math.random(1, #auraNames)]
		result.TextColor3 = TEXT_COLOR
		result.TextStrokeTransparency = 1
		container.Position = UDim2.fromOffset((math.random()-0.5)*2, (math.random()-0.5)*2)
		if SFX and math.random() < 0.3 then SFX.Play(gui, "tick", 0.2) end
		task.wait(speed)
	end
	container.Position = UDim2.fromScale(0,0)
	
	while not gotResult do task.wait(0.02) end
	button.Text = "ROLL"

	if not res then
		result.Text = "Too fast!"; result.TextColor3 = TEXT_COLOR
		isRolling = false; return
	end

	-- DECIDE PATH
	if res.Rarity >= RARE_THRESHOLD then
		playImpact(res, false) -- Real Impact!
	else
		if math.random(1, FAKEOUT_CHANCE) == 1 then
			playImpact(res, true) -- Fake Impact!
		else
			doNormalReveal(res) -- Normal Quick Reveal
		end
	end

	scheduleFadeOut()
	isRolling = false
end

button.MouseButton1Click:Connect(doRoll)

autoBtn.MouseButton1Click:Connect(function()
	autoRollEnabled = not autoRollEnabled
	if autoRollEnabled then
		autoBtn.Text = "AUTO: ON"; autoBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	else
		autoBtn.Text = "AUTO: OFF"; autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
	if SFX then SFX.Play(gui, "click") end
	if not autoRollEnabled then scheduleFadeOut() end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if autoRollEnabled and not isRolling then doRoll() end
	end
end)

AnnounceEvent.OnClientEvent:Connect(function(info)
	local prefix = info.Mutated and "MUTATED " or ""
	banner.Text = "🎉  " .. info.Player .. " pulled " .. prefix .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.TextColor3 = info.Color or BANNER_DEFAULT_COLOR
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.12)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)

print("RollUI loaded! (Impact Edition - Stable)")
]==]

print("✅ ROLL UI IMPACT EDITION APPLIED!")
print("💥 Heavy impacts restored for Epic/Legendary/Mythic.")
print("🚫 Full cutscene removed (stable rolling restored).")
print("📝 Left empty slots in the code for your custom cutscenes!")
