-- ═══════════════════════════════════════════════════════════
-- ✨ ROLL UI: CLEAN, COZY & IMPACTFUL (Squash & Stretch)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Features:
--   • Smooth RNG slot cycling
--   • Squash-and-Stretch bounce on reveal
--   • Slides upward and overshoots (Back/Elastic easing)
--   • Scales perfectly from Common to Mythic
--   • UI-only shake (Camera never moves, very clean)
--   • Soft glow and clean UIStroke outline
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
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

local SFX
pcall(function() SFX = require(ReplicatedStorage:WaitForChild("SFXConfig")) end)
local AuraData
pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)

local auraNames = {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do table.insert(auraNames, a.Name) end
end
if #auraNames == 0 then auraNames = {"..."} end

-- ⚙️ ANIMATION CONFIG
local FLICKER_SPEEDS = {0.03, 0.035, 0.04, 0.045, 0.05, 0.06, 0.07, 0.085, 0.10, 0.12}
local BASE_WIDTH = 450
local BASE_HEIGHT = 130

-- TIER INTENSITIES (Clean scaling)
local TIERS = {
	Common    = { intensity = 0.5, shake = 0, flash = false, particles = 0, sound = "reveal" },
	Uncommon  = { intensity = 0.7, shake = 0, flash = false, particles = 0, sound = "reveal" },
	Rare      = { intensity = 1.0, shake = 3, flash = true,  particles = 0, sound = "rare" },
	Epic      = { intensity = 1.2, shake = 4, flash = true,  particles = 10, sound = "rare" },
	Legendary = { intensity = 1.5, shake = 6, flash = true,  particles = 25, sound = "legendary" },
	Mythic    = { intensity = 2.0, shake = 8, flash = true,  particles = 40, sound = "mythic" },
}

-- Clean up old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

-- Build UI
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

-- Shaker Container (For UI only shake)
local shaker = Instance.new("Frame")
shaker.Size = UDim2.fromScale(1, 1); shaker.Position = UDim2.fromScale(0, 0)
shaker.BackgroundTransparency = 1; shaker.Parent = gui

-- Glow Frame (Behind Text)
local glowFrame = Instance.new("Frame")
glowFrame.AnchorPoint = Vector2.new(0.5, 0.5); glowFrame.Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
glowFrame.Position = UDim2.fromScale(0.5, 0.4)
glowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glowFrame.BackgroundTransparency = 1; glowFrame.ZIndex = 5
local gCorner = Instance.new("UICorner"); gCorner.CornerRadius = UDim.new(1, 0); gCorner.Parent = glowFrame
glowFrame.Parent = shaker

-- Result Text
local resultText = Instance.new("TextLabel")
resultText.AnchorPoint = Vector2.new(0.5, 0.5); resultText.Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
resultText.Position = UDim2.fromScale(0.5, 0.4)
resultText.Text = "Press ROLL to begin!"
resultText.Font = Enum.Font.GothamBlack; resultText.TextScaled = true
resultText.BackgroundTransparency = 1; resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
resultText.ZIndex = 6; resultText.Parent = shaker

-- Clean UIStroke Outline
local outline = Instance.new("UIStroke")
outline.Thickness = 4; outline.Color = Color3.fromRGB(15, 15, 25)
outline.Transparency = 1; outline.Parent = resultText

-- Flash Overlay
local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.fromScale(1, 1); flashFrame.Position = UDim2.fromScale(0, 0)
flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flashFrame.BackgroundTransparency = 1; flashFrame.ZIndex = 4; flashFrame.Parent = shaker

-- Buttons (Centered, outside shaker)
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5); button.Size = UDim2.fromScale(0.16, 0.09)
button.Position = UDim2.fromScale(0.5, 0.85); button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack; button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(80, 120, 255); button.TextColor3 = Color3.fromRGB(255,255,255)
button.ZIndex = 20
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12, 0); bCorner.Parent = button
button.Parent = gui

local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5); autoBtn.Size = UDim2.fromScale(0.10, 0.06)
autoBtn.Position = UDim2.fromScale(0.5, 0.78); autoBtn.Text = "AUTO: OFF"
autoBtn.Font = Enum.Font.GothamBold; autoBtn.TextScaled = true
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); autoBtn.TextColor3 = Color3.fromRGB(255,255,255)
autoBtn.ZIndex = 20
local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0.15, 0); abCorner.Parent = autoBtn
autoBtn.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.1); banner.Position = UDim2.fromScale(0.15, 0.12)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(30,30,45); banner.TextColor3 = Color3.fromRGB(255,215,0)
banner.BackgroundTransparency = 1; banner.Visible = false; banner.ZIndex = 30
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2, 0); bnCorner.Parent = banner
banner.Parent = gui

-- ═══════════════════════════════════════════════════════════
-- ANIMATION LOGIC
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local autoRollEnabled = false
local fadeTimer = nil
local breathingThread = nil

local function stopBreathing()
	if breathingThread then
		task.cancel(breathingThread)
		breathingThread = nil
	end
end

local function scheduleFadeOut()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end) end
	fadeTimer = task.delay(4, function()
		fadeTimer = nil
		if not isRolling and not autoRollEnabled then
			stopBreathing()
			TweenService:Create(resultText, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
			TweenService:Create(outline, TweenInfo.new(1.5), {Transparency = 1}):Play()
			TweenService:Create(glowFrame, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()
		end
	end)
end

local function doReveal(res)
	stopBreathing()
	
	local tier = res.Tier or "Common"
	local cfg = TIERS[tier] or TIERS.Common
	local color = res.Color or Color3.fromRGB(255, 255, 255)
	
	-- 1. Setup Text
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "✨ " .. displayText end
	resultText.Text = displayText .. "\n1 in " .. res.Rarity
	resultText.TextColor3 = color
	outline.Color = Color3.fromRGB(15, 15, 25)
	
	-- Reset visual state
	resultText.TextTransparency = 0
	outline.Transparency = 0
	resultText.Rotation = 0
	
	-- 2. Anticipation (Start slightly below, small size, squashed vertically)
	resultText.Position = UDim2.fromScale(0.5, 0.42) -- 0.02 lower
	resultText.Size = UDim2.fromOffset(BASE_WIDTH * 0.6, BASE_HEIGHT * 1.3) -- Squashed!
	
	-- 3. The Slam (Snap upward, stretch out to 110%, then bounce)
	-- Tween 1: Overshoot (Back Out)
	local snapTime = 0.2
	TweenService:Create(resultText, TweenInfo.new(snapTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(BASE_WIDTH * 1.1 * cfg.intensity, BASE_HEIGHT * 0.9) -- Stretch horizontal!
	}):Play()
	
	-- Tween 2: Settle (Sine Out)
	task.delay(snapTime, function()
		TweenService:Create(resultText, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT) -- 100% size
		}):Play()
	end)
	
	-- 4. Glow Effect
	glowFrame.BackgroundColor3 = color
	glowFrame.Size = UDim2.fromOffset(BASE_WIDTH * 0.5, BASE_HEIGHT * 0.5)
	glowFrame.BackgroundTransparency = 0.8 - (0.3 * cfg.intensity)
	TweenService:Create(glowFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1 - (0.3 * cfg.intensity),
		Size = UDim2.fromOffset(BASE_WIDTH * 1.5 * cfg.intensity, BASE_HEIGHT * 1.5 * cfg.intensity)
	}):Play()
	
	-- 5. Add Effects based on Rarity
	if SFX and cfg.sound then SFX.Play(gui, cfg.sound) end
	
	-- UI Shake (Clean, tiny offsets)
	if cfg.shake > 0 then
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 0.3 do
				local ox = (math.random() - 0.5) * cfg.shake * 2
				local oy = (math.random() - 0.5) * cfg.shake * 2
				shaker.Position = UDim2.fromOffset(ox, oy)
				task.wait()
			end
			shaker.Position = UDim2.fromScale(0, 0)
		end)
	end
	
	-- Flash (Behind text)
	if cfg.flash then
		flashFrame.BackgroundColor3 = color
		flashFrame.BackgroundTransparency = 0.8
		TweenService:Create(flashFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	end
	
	-- Particle Burst (From center of text)
	if cfg.particles > 0 then
		for i = 1, cfg.particles do
			local p = Instance.new("Frame")
			p.AnchorPoint = Vector2.new(0.5, 0.5)
			p.Size = UDim2.fromOffset(math.random(6, 12), math.random(6, 12))
			p.Position = UDim2.fromScale(0.5, 0.4)
			p.BackgroundColor3 = color
			p.BorderSizePixel = 0; p.ZIndex = 5
			p.Parent = shaker
			
			local angle = (i / cfg.particles) * math.pi * 2
			local dist = math.random(100, 300)
			local endX = 0.5 + math.cos(angle) * (dist / 1000)
			local endY = 0.4 + math.sin(angle) * (dist / 1000)
			
			TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(endX, endY),
				BackgroundTransparency = 1,
				Rotation = math.random(-360, 360)
			}):Play()
			
			Debris:AddItem(p, 1)
		end
	end
	
	-- 6. Breathing Loop (Make it feel alive)
	if cfg.intensity >= 1.0 then
		breathingThread = task.spawn(function()
			while true do
				task.wait(1.5)
				TweenService:Create(glowFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 0.9, Size = UDim2.fromOffset(BASE_WIDTH * 1.6, BASE_HEIGHT * 1.6)
				}):Play()
				task.wait(1.5)
				TweenService:Create(glowFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 0.7, Size = UDim2.fromOffset(BASE_WIDTH * 1.4, BASE_HEIGHT * 1.4)
				}):Play()
			end
		end)
	end
	
	scheduleFadeOut()
end

-- ═══════════════════════════════════════════════════════════
-- MAIN ROLL FUNCTION
-- ═══════════════════════════════════════════════════════════
local function doRoll()
	if isRolling then return end
	isRolling = true

	stopBreathing()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
	resultText.TextTransparency = 0
	outline.Transparency = 0

	if SFX then SFX.Play(gui, "roll") end
	button.Text = "..."
	
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)

	-- Flicker Phase (Normal size, cycling)
	for _, speed in ipairs(FLICKER_SPEEDS) do
		resultText.Text = auraNames[math.random(1, #auraNames)]
		resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
		resultText.Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
		resultText.Position = UDim2.fromScale(0.5, 0.4)
		if SFX and math.random() < 0.3 then SFX.Play(gui, "tick", 0.2) end
		task.wait(speed)
	end
	
	while not gotResult do task.wait(0.02) end
	button.Text = "ROLL"

	if not res then
		resultText.Text = "Too fast!"; resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
		isRolling = false; return
	end

	-- Trigger the Reveal
	doReveal(res)
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
	banner.TextColor3 = info.Color or Color3.fromRGB(255, 215, 0)
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.12)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)

print("RollUI loaded! (Clean & Cozy Impact Edition)")
]==]

print("✅ CLEAN & COZY ROLL UI APPLIED!")
print("✨ Features real Squash-and-Stretch physics!")
print("🎯 Perfectly scales from Common to Mythic.")
print("👁️ Camera never moves, UI is clean and readable.")
