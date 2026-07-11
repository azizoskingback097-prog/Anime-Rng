-- ═══════════════════════════════════════════════════════════
-- 🎬 SOL'S RNG STYLE CUTSCENE SYSTEM
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- HOW IT WORKS:
--   • Common/Uncommon: Quick reveal (no cutscene)
--   • Rare (100+): Small dramatic reveal
--   • Epic (1000+): Full cutscene with background
--   • Legendary (5000+): Epic cutscene, heavy shake
--   • Mythic (50000+): MAXIMUM cutscene, everything explodes
--
-- CUTSCENE STRUCTURE:
--   1. Screen darkens, colored gradient appears
--   2. Flash + impact shake
--   3. Aura name SLAMS in from above (overshoot)
--   4. Rarity text fades in below
--   5. Particles burst outward
--   6. Glows and breathes for 3-5 seconds
--   7. Fades out smoothly
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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

local SFX
pcall(function() SFX = require(ReplicatedStorage:WaitForChild("SFXConfig")) end)
local AuraData
pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)

-- ═══════════════════════════════════════════════════════════
-- ⚙️ SETTINGS
-- ═══════════════════════════════════════════════════════════
local CUTSCENE_THRESHOLD = 100   -- 100+ = Rare gets a cutscene
local FLICKER_SPEEDS = {0.03, 0.035, 0.04, 0.045, 0.05, 0.06, 0.07, 0.085, 0.10, 0.12}
local RESULT_FADE_DELAY = 4
local INACTIVITY_REMINDER = 600

-- Tier colors for cutscenes
local TIER_COLORS = {
	Common    = { primary = Color3.fromRGB(180,180,180), secondary = Color3.fromRGB(100,100,100) },
	Uncommon  = { primary = Color3.fromRGB(120,255,150), secondary = Color3.fromRGB(60,180,80) },
	Rare      = { primary = Color3.fromRGB(80,140,255),  secondary = Color3.fromRGB(40,80,180) },
	Epic      = { primary = Color3.fromRGB(180,80,255),  secondary = Color3.fromRGB(100,40,160) },
	Legendary = { primary = Color3.fromRGB(255,200,0),   secondary = Color3.fromRGB(200,140,0) },
	Mythic    = { primary = Color3.fromRGB(255,60,60),   secondary = Color3.fromRGB(180,20,20) },
}

local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BANNER_DEFAULT_COLOR = Color3.fromRGB(255,215,0)
local THEME_COLOR = Color3.fromRGB(30,30,45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80,120,255)

-- Gather auras
local auraNames = {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do table.insert(auraNames, a.Name) end
end
if #auraNames == 0 then auraNames = {"..."} end

-- Self-clean
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

-- ═══════════════════════════════════════════════════════════
-- BUILD MAIN UI
-- ═══════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

-- Shaker container
local container = Instance.new("Frame")
container.Size = UDim2.fromScale(1, 1); container.Position = UDim2.fromScale(0, 0)
container.BackgroundTransparency = 1; container.Parent = gui

-- Normal result text (for common pulls)
local result = Instance.new("TextLabel")
result.AnchorPoint = Vector2.new(0.5, 0.5); result.Size = UDim2.fromScale(0.45, 0.16)
result.Position = UDim2.fromScale(0.5, 0.42); result.Text = "Press ROLL to begin!"
result.Font = Enum.Font.Bangers; result.TextScaled = true
result.BackgroundTransparency = 1; result.TextColor3 = TEXT_COLOR
result.TextStrokeTransparency = 1; result.ZIndex = 10; result.Parent = container

-- ═══════════════════════════════════════════════════════════
-- BUILD CUTSCENE UI (Hidden until triggered)
-- ═══════════════════════════════════════════════════════════
local cutsceneGui = Instance.new("ScreenGui")
cutsceneGui.Name = "CutsceneGui"; cutsceneGui.ResetOnSpawn = false
cutsceneGui.IgnoreGuiInset = true; cutsceneGui.DisplayOrder = 100
cutsceneGui.Enabled = false; cutsceneGui.Parent = playerGui

-- Background overlay (dark with gradient)
local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.fromScale(1, 1); bgFrame.Position = UDim2.fromScale(0, 0)
bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bgFrame.BackgroundTransparency = 1; bgFrame.ZIndex = 50; bgFrame.Parent = cutsceneGui

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 10, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
})
bgGradient.Rotation = 90; bgGradient.Parent = bgFrame

-- Colored glow behind text
local csGlow = Instance.new("Frame")
csGlow.AnchorPoint = Vector2.new(0.5, 0.5); csGlow.Size = UDim2.fromScale(0.8, 0.3)
csGlow.Position = UDim2.fromScale(0.5, 0.45)
csGlow.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
csGlow.BackgroundTransparency = 1; csGlow.ZIndex = 51
local csGlowCorner = Instance.new("UICorner"); csGlowCorner.CornerRadius = UDim.new(1, 0); csGlowCorner.Parent = csGlow
csGlow.Parent = cutsceneGui

-- Main aura name (HUGE)
local csName = Instance.new("TextLabel")
csName.AnchorPoint = Vector2.new(0.5, 0.5); csName.Size = UDim2.fromScale(0.8, 0.25)
csName.Position = UDim2.fromScale(0.5, 0.4)
csName.Text = ""; csName.Font = Enum.Font.Bangers; csName.TextScaled = true
csName.BackgroundTransparency = 1; csName.TextColor3 = TEXT_COLOR
csName.TextStrokeTransparency = 1; csName.ZIndex = 53; csName.Parent = cutsceneGui

-- Rarity text (below name)
local csRarity = Instance.new("TextLabel")
csRarity.AnchorPoint = Vector2.new(0.5, 0.5); csRarity.Size = UDim2.fromScale(0.4, 0.1)
csRarity.Position = UDim2.fromScale(0.5, 0.58)
csRarity.Text = ""; csRarity.Font = Enum.Font.GothamBold; csRarity.TextScaled = true
csRarity.BackgroundTransparency = 1; csRarity.TextColor3 = TEXT_COLOR
csRarity.TextStrokeTransparency = 1; csRarity.TextTransparency = 1; csRarity.ZIndex = 53
csRarity.Parent = cutsceneGui

-- Tier label (above name)
local csTier = Instance.new("TextLabel")
csTier.AnchorPoint = Vector2.new(0.5, 0.5); csTier.Size = UDim2.fromScale(0.3, 0.08)
csTier.Position = UDim2.fromScale(0.5, 0.25)
csTier.Text = ""; csTier.Font = Enum.Font.GothamBlack; csTier.TextScaled = true
csTier.BackgroundTransparency = 1; csTier.TextColor3 = TEXT_COLOR
csTier.TextStrokeTransparency = 1; csTier.TextTransparency = 1; csTier.ZIndex = 53
csTier.Parent = cutsceneGui

-- Flash overlay
local csFlash = Instance.new("Frame")
csFlash.Size = UDim2.fromScale(1, 1); csFlash.Position = UDim2.fromScale(0, 0)
csFlash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
csFlash.BackgroundTransparency = 1; csFlash.ZIndex = 60; csFlash.Parent = cutsceneGui

-- Particle holder (for UI particles)
local csParticles = Instance.new("Frame")
csParticles.Size = UDim2.fromScale(1, 1); csParticles.Position = UDim2.fromScale(0, 0)
csParticles.BackgroundTransparency = 1; csParticles.ZIndex = 52; csParticles.Parent = cutsceneGui

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

local function clearParticles()
	for _, child in ipairs(csParticles:GetChildren()) do
		child:Destroy()
	end
end

-- Spawn UI particles that burst outward
local function burstParticles(color, count)
	for i = 1, count do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Size = UDim2.fromOffset(math.random(4, 10), math.random(4, 10))
		p.Position = UDim2.fromScale(0.5, 0.45)
		p.BackgroundColor3 = color
		p.BackgroundTransparency = 0.1
		p.BorderSizePixel = 0
		p.ZIndex = 52
		p.Parent = csParticles
		
		local angle = (i / count) * math.pi * 2 + math.random(-0.3, 0.3)
		local dist = math.random(200, 500)
		local endX = 0.5 + math.cos(angle) * (dist / playerGui.AbsoluteSize.X)
		local endY = 0.45 + math.sin(angle) * (dist / playerGui.AbsoluteSize.Y)
		
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

-- Spawn floating ambient particles
local function spawnFloatingParticle(color)
	local p = Instance.new("Frame")
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Size = UDim2.fromOffset(math.random(3, 7), math.random(3, 7))
	p.Position = UDim2.new(math.random(20, 80) / 100, 0, math.random(40, 80) / 100, 0)
	p.BackgroundColor3 = color
	p.BackgroundTransparency = math.random(30, 60) / 100
	p.BorderSizePixel = 0
	p.ZIndex = 52
	p.Parent = csParticles
	
	TweenService:Create(p, TweenInfo.new(math.random(2, 4)), {
		Position = UDim2.new(p.Position.X.Scale, p.Position.X.Offset, p.Position.Y.Scale - 0.3, p.Position.Y.Offset),
		BackgroundTransparency = 1,
		Rotation = math.random(-180, 180),
	}):Play()
	
	task.delay(4, function()
		if p.Parent then p:Destroy() end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- CUTSCENE SYSTEM
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local autoRollEnabled = false
local fadeTimer = nil
local floatParticleConnection = nil

local function stopCutscene()
	cutsceneGui.Enabled = false
	clearParticles()
	if floatParticleConnection then
		floatParticleConnection:Disconnect()
		floatParticleConnection = nil
	end
	csName.TextTransparency = 1
	csName.TextStrokeTransparency = 1
	csRarity.TextTransparency = 1
	csRarity.TextStrokeTransparency = 1
	csTier.TextTransparency = 1
	csTier.TextStrokeTransparency = 1
	csGlow.BackgroundTransparency = 1
	bgFrame.BackgroundTransparency = 1
	csFlash.BackgroundTransparency = 1
end

local function playCutscene(res)
	local tier = res.Tier or "Common"
	local colors = TIER_COLORS[tier] or TIER_COLORS.Common
	local primary = res.Color or colors.primary
	local secondary = colors.secondary
	
	-- Duration scales with rarity
	local duration = 3
	if res.Rarity >= 1000 then duration = 4 end
	if res.Rarity >= 5000 then duration = 5 end
	if res.Rarity >= 50000 then duration = 6 end
	
	-- Particles scale with rarity
	local particleCount = 15
	if res.Rarity >= 1000 then particleCount = 25 end
	if res.Rarity >= 5000 then particleCount = 40 end
	if res.Rarity >= 50000 then particleCount = 60 end
	
	stopCutscene()
	cutsceneGui.Enabled = true
	
	-- ══ PHASE 1: DARKEN SCREEN ══
	bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TweenService:Create(bgFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.1
	}):Play()
	
	task.wait(0.2)
	
	-- ══ PHASE 2: FLASH + IMPACT ══
	csFlash.BackgroundColor3 = primary
	csFlash.BackgroundTransparency = 0
	TweenService:Create(csFlash, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
	
	shakeScreen(0.3, 15)
	if SFX then SFX.Play(gui, "legendary") end
	
	-- Set up text
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "✨ " .. displayText end
	
	csName.Text = displayText
	csName.TextColor3 = primary
	csName.TextStrokeColor3 = secondary
	csName.TextStrokeTransparency = 0.1
	
	csRarity.Text = "1 in " .. res.Rarity
	csRarity.TextColor3 = primary
	csRarity.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	
	csTier.Text = string.upper(tier)
	csTier.TextColor3 = secondary
	
	-- Glow color
	csGlow.BackgroundColor3 = primary
	
	-- ══ PHASE 3: NAME SLAMS IN ══
	-- Start small (far away)
	csName.Size = UDim2.fromScale(0.01, 0.01)
	csName.TextTransparency = 0
	csName.TextStrokeTransparency = 0.1
	
	-- Slam with overshoot
	TweenService:Create(csName, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.7, 0.22)
	}):Play()
	
	-- Glow appears
	task.delay(0.2, function()
		TweenService:Create(csGlow, TweenInfo.new(0.4), {BackgroundTransparency = 0.5}):Play()
	end)
	
	task.wait(0.4)
	
	-- ══ PHASE 4: TIER + RARITY FADE IN ══
	csTier.TextTransparency = 0
	csTier.TextStrokeTransparency = 0.2
	TweenService:Create(csTier, TweenInfo.new(0.4), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.2
	}):Play()
	
	csRarity.TextTransparency = 0
	csRarity.TextStrokeTransparency = 0.3
	TweenService:Create(csRarity, TweenInfo.new(0.4), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.3
	}):Play()
	
	-- Small impact shake
	shakeScreen(0.2, 6)
	
	-- ══ PHASE 5: PARTICLE BURST ══
	burstParticles(primary, particleCount)
	if SFX then SFX.Play(gui, "rare", 0.5) end
	
	task.wait(0.3)
	
	-- ══ PHASE 6: HOLD + FLOATING PARTICLES + BREATHE ══
	floatParticleConnection = task.spawn(function()
		while cutsceneGui.Enabled do
			spawnFloatingParticle(primary)
			task.wait(math.random(15, 40) / 100)
		end
	end)
	
	-- Breathing glow
	task.spawn(function()
		while cutsceneGui.Enabled do
			TweenService:Create(csGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0.3,
				Size = UDim2.fromScale(0.9, 0.35)
			}):Play()
			task.wait(1.5)
			TweenService:Create(csGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0.6,
				Size = UDim2.fromScale(0.7, 0.25)
			}):Play()
			task.wait(1.5)
		end
	end)
	
	-- Name breathing
	task.spawn(function()
		while cutsceneGui.Enabled do
			TweenService:Create(csName, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromScale(0.72, 0.23)
			}):Play()
			task.wait(1.5)
			TweenService:Create(csName, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.fromScale(0.68, 0.21)
			}):Play()
			task.wait(1.5)
		end
	end)
	
	-- Hold for duration
	task.wait(duration - 1.5)
	
	-- ══ PHASE 7: FADE OUT ══
	local fadeGroup = { bgFrame, csGlow, csName, csRarity, csTier }
	for _, el in ipairs(fadeGroup) do
		local isText = el:IsA("TextLabel")
		TweenService:Create(el, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			TextTransparency = isText and 1 or nil,
			TextStrokeTransparency = isText and 1 or nil,
		}):Play()
	end
	
	task.wait(0.9)
	stopCutscene()
end

-- ═══════════════════════════════════════════════════════════
-- NORMAL REVEAL (Common pulls)
-- ═══════════════════════════════════════════════════════════
local function doNormalReveal(res)
	if SFX then SFX.Play(gui, "reveal") end
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "MUTATED\n" .. displayText end
	result.Text = displayText .. "\n1 in " .. res.Rarity
	result.TextColor3 = res.Color or TEXT_COLOR
	
	result.Size = UDim2.fromScale(0.8, 0.3)
	result.TextTransparency = 0
	result.TextStrokeTransparency = 1
	TweenService:Create(result, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.45, 0.16)
	}):Play()
	shakeScreen(0.2, 3)
end

local function scheduleFadeOut()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end) end
	fadeTimer = task.delay(RESULT_FADE_DELAY, function()
		fadeTimer = nil
		if not isRolling and not autoRollEnabled then
			TweenService:Create(result, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				TextTransparency = 1, TextStrokeTransparency = 1
			}):Play()
		end
	end)
end

-- Inactivity reminder
task.spawn(function()
	while true do
		task.wait(30)
		if not isRolling and not autoRollEnabled and (os.clock() - (lastRollTime or 0)) > INACTIVITY_REMINDER then
			result.TextTransparency = 0
			result.Text = "Still there? Press ROLL!"
			result.TextColor3 = TEXT_COLOR
			result.TextStrokeTransparency = 1
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- MAIN ROLL
-- ═══════════════════════════════════════════════════════════
local function doRoll()
	if isRolling then return end
	isRolling = true
	local lastRollTime = os.clock()

	stopCutscene()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
	result.TextTransparency = 0

	if SFX then SFX.Play(gui, "roll") end
	button.Text = "..."
	
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)

	-- Flicker phase
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

	-- DECIDE: Cutscene or Normal
	if res.Rarity >= CUTSCENE_THRESHOLD then
		-- Hide normal text
		result.TextTransparency = 1
		-- Play cutscene!
		playCutscene(res)
	else
		doNormalReveal(res)
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

print("RollUI loaded! (Sol's RNG Style Cutscene System)")
]==]

print("══════════════════════════════════════")
print("🎬 SOL'S RNG STYLE CUTSCENE SYSTEM!")
print("══════════════════════════════════════")
print("✨ Features:")
print("   • Common pulls: Quick, snappy reveal")
print("   • Rare+ pulls: FULL CINEMATIC CUTSCENE!")
print("   • Screen darkens, name slams in")
print("   • Tier label + Rarity text")
print("   • Particle bursts scale with rarity")
print("   • Breathing glow + floating particles")
print("   • Duration increases with rarity")
print("   • Smooth fade out")
print("══════════════════════════════════════")
print("⚙️ Change CUTSCENE_THRESHOLD to adjust when cutscenes trigger!")
print("══════════════════════════════════════")
