-- ═══════════════════════════════════════════════════════════
-- 💥 ROLL UI: SHOCKWAVE & EXPANDING IMPACT
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- THE NEW IMPACT:
-- When an aura lands, a glowing "ring" (shockwave) explodes outward 
-- from the text, expanding across the entire screen and fading out.
-- Combined with the squash-and-stretch and expanding glow, this 
-- creates a massive, premium impact without hurting the eyes.
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

-- TIER INTENSITIES (Scales rings, glow, and shake)
local TIERS = {
	Common    = { intensity = 0.5, rings = 1, ringSize = 500,  shake = 0, particles = 0, sound = "reveal",     thickness = 4 },
	Uncommon  = { intensity = 0.7, rings = 1, ringSize = 700,  shake = 0, particles = 0, sound = "reveal",     thickness = 5 },
	Rare      = { intensity = 1.0, rings = 2, ringSize = 1200, shake = 2, particles = 10, sound = "rare",      thickness = 6 },
	Epic      = { intensity = 1.2, rings = 2, ringSize = 1500, shake = 3, particles = 15, sound = "rare",      thickness = 8 },
	Legendary = { intensity = 1.5, rings = 3, ringSize = 2000, shake = 4, particles = 25, sound = "legendary", thickness = 10 },
	Mythic    = { intensity = 2.0, rings = 4, ringSize = 2500, shake = 5, particles = 40, sound = "mythic",    thickness = 12 },
}

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

-- Build UI
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

-- Shaker Container
local shaker = Instance.new("Frame")
shaker.Size = UDim2.fromScale(1, 1); shaker.Position = UDim2.fromScale(0, 0)
shaker.BackgroundTransparency = 1; shaker.Parent = gui

-- Shockwave Holder (Contains the expanding rings)
local waveHolder = Instance.new("Frame")
waveHolder.Size = UDim2.fromScale(1, 1); waveHolder.Position = UDim2.fromScale(0, 0)
waveHolder.BackgroundTransparency = 1; waveHolder.ZIndex = 4; waveHolder.Parent = shaker

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

local outline = Instance.new("UIStroke")
outline.Thickness = 4; outline.Color = Color3.fromRGB(15, 15, 25)
outline.Transparency = 1; outline.Parent = resultText

-- Buttons
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
-- IMPACT EFFECTS LOGIC
-- ═══════════════════════════════════════════════════════════

-- Creates a single expanding shockwave ring
local function spawnShockwave(color, size, thickness, delay)
	task.delay(delay, function()
		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.4)
		ring.Size = UDim2.fromOffset(0, 0) -- Start tiny
		ring.BackgroundColor3 = color
		ring.BackgroundTransparency = 1 -- Make inside invisible
		ring.BorderSizePixel = 0
		ring.ZIndex = 4
		ring.Parent = waveHolder
		
		-- Use UIStroke for the ring outline so it expands smoothly
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = thickness
		stroke.Color = color
		stroke.Transparency = 0.1
		stroke.Parent = ring
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0) -- Make it a circle
		corner.Parent = ring
		
		-- Expand and fade out
		local tween = TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(size, size)
		})
		tween:Play()
		
		TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Transparency = 1,
			Thickness = 0.1
		}):Play()
		
		Debris:AddItem(ring, 1)
	end)
end

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
	
	resultText.TextTransparency = 0
	outline.Transparency = 0
	resultText.Rotation = 0
	
	-- 2. Anticipation (Start slightly below, squashed)
	resultText.Position = UDim2.fromScale(0.5, 0.42)
	resultText.Size = UDim2.fromOffset(BASE_WIDTH * 0.6, BASE_HEIGHT * 1.3)
	
	-- 3. The Slam (Snap upward, stretch out)
	local snapTime = 0.2
	TweenService:Create(resultText, TweenInfo.new(snapTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(BASE_WIDTH * 1.1 * cfg.intensity, BASE_HEIGHT * 0.9)
	}):Play()
	
	task.delay(snapTime, function()
		TweenService:Create(resultText, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
		}):Play()
	end)
	
	-- 4. Massive Glow Expansion (The "fade out screen from text" you described)
	glowFrame.BackgroundColor3 = color
	glowFrame.Size = UDim2.fromOffset(BASE_WIDTH * 0.5, BASE_HEIGHT * 0.5)
	glowFrame.BackgroundTransparency = 0.2 -- Flash brightly!
	
	TweenService:Create(glowFrame, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1 - (0.3 * cfg.intensity), -- Fade out based on rarity
		Size = UDim2.fromOffset(BASE_WIDTH * 3.0 * cfg.intensity, BASE_HEIGHT * 3.0 * cfg.intensity) -- Expands hugely
	}):Play()
	
	-- 5. Spawn Shockwaves!
	for i = 1, cfg.rings do
		spawnShockwave(color, cfg.ringSize * (1 + (i*0.2)), cfg.thickness, 0.1 * i)
	end
	
	-- Sound
	if SFX and cfg.sound then SFX.Play(gui, cfg.sound) end
	
	-- UI Shake
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
	
	-- Particle Burst
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
	
	-- 6. Breathing Loop
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

	-- Flicker Phase
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

print("RollUI loaded! (Shockwave Impact Edition)")
]==]

print("✅ SHOCKWAVE IMPACT ROLL UI APPLIED!")
print("💥 Expanding rings and massive glow wash added for impacts!")
