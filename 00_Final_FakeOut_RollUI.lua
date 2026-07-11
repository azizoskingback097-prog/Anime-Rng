-- ═══════════════════════════════════════════════════════════
-- 💥 ROLL UI: EXACT 4-SECOND TROLL FAKE-OUT
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- TIMELINE:
--   0.0s - 1.8s: Rapid slot spin (scales 0.9 to 1.0).
--   1.8s - 2.8s: Slows down, lands on Mythic (Elastic scale up).
--   2.8s - 3.2s: Text turns gray, tilts, breaks (Glitch effect).
--   3.2s - 4.0s: Real aura spawns at 3.0 scale, slams to 1.0 (Bounce).
--                Triggers Screen Flash + Heavy UI Shake + Particles!
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

local auraNames, commonAuras, mythicAuras = {}, {}, {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		table.insert(auraNames, a.Name)
		if a.Rarity < 100 then table.insert(commonAuras, a) end
		if a.Rarity >= 50000 then table.insert(mythicAuras, a) end
	end
end
if #auraNames == 0 then auraNames = {"..."} end
if #commonAuras == 0 then commonAuras = { {Name="Flicker", Color=Color3.fromRGB(200,200,200)} } end
if #mythicAuras == 0 then mythicAuras = { {Name="GENESIS", Color=Color3.fromRGB(255,255,200), Rarity=99999} } end

local BASE_WIDTH = 500
local BASE_HEIGHT = 150

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

-- Build UI
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

-- Shaker Frame
local shaker = Instance.new("Frame")
shaker.Size = UDim2.fromScale(1, 1); shaker.Position = UDim2.fromScale(0, 0)
shaker.BackgroundTransparency = 1; shaker.Parent = gui

-- Cutscene Overlay (For Mythics)
local csOverlay = Instance.new("Frame")
csOverlay.Size = UDim2.fromScale(1, 1); csOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
csOverlay.BackgroundTransparency = 1; csOverlay.ZIndex = 4; csOverlay.Parent = shaker

-- Full Screen Flash
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1); flash.Position = UDim2.fromScale(0, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1; flash.ZIndex = 50; flash.Parent = shaker

-- Result Text
local resultText = Instance.new("TextLabel")
resultText.AnchorPoint = Vector2.new(0.5, 0.5); resultText.Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
resultText.Position = UDim2.fromScale(0.5, 0.4)
resultText.Text = "Press ROLL to begin!"
resultText.Font = Enum.Font.FredokaOne; resultText.TextScaled = true
resultText.BackgroundTransparency = 1; resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
resultText.ZIndex = 6; resultText.Parent = shaker

-- Glowing Outline
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
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function uiShake(duration, intensity)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration do
			local ox = (math.random() - 0.5) * intensity * 2
			local oy = (math.random() - 0.5) * intensity * 2
			shaker.Position = UDim2.fromOffset(ox, oy)
			task.wait()
		end
		shaker.Position = UDim2.fromScale(0, 0)
	end)
end

local function burstParticles(color, count)
	for i = 1, count do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Size = UDim2.fromOffset(math.random(8, 15), math.random(8, 15))
		p.Position = UDim2.fromScale(0.5, 0.4)
		p.BackgroundColor3 = color; p.BorderSizePixel = 0; p.ZIndex = 5
		p.Parent = shaker
		local angle = (i / count) * math.pi * 2
		local dist = math.random(150, 350)
		TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5 + math.cos(angle) * (dist/1000), 0.4 + math.sin(angle) * (dist/1000)),
			BackgroundTransparency = 1, Rotation = math.random(-360, 360)
		}):Play()
		Debris:AddItem(p, 1)
	end
end

local function fadeOutUI()
	TweenService:Create(resultText, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
	TweenService:Create(outline, TweenInfo.new(1.5), {Transparency = 1}):Play()
end

-- ═══════════════════════════════════════════════════════════
-- THE ANIMATIONS
-- ═══════════════════════════════════════════════════════════

-- 1. THE TROLL FAKE-OUT (EXACT 4s TIMELINE)
local function playFakeOutSequence(res)
	if SFX then SFX.Play(gui, "roll") end
	button.Text = "..."
	
	-- PHASE 1: The Rapid Spin (0.0s - 1.8s)
	-- 36 ticks at 0.05s each = 1.8s
	for i = 1, 36 do
		resultText.Text = commonAuras[math.random(1, #commonAuras)].Name
		resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
		outline.Color = Color3.fromRGB(15, 15, 25)
		outline.Thickness = 4
		
		-- Pulse from 0.9 to 1.0
		resultText.Size = UDim2.fromOffset(BASE_WIDTH * 0.9, BASE_HEIGHT * 0.9)
		TweenService:Create(resultText, TweenInfo.new(0.05), {Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)}):Play()
		
		if SFX and i % 2 == 0 then SFX.Play(gui, "tick", 0.4) end
		task.wait(0.05)
	end
	
	-- PHASE 2: The Mythic Tease (1.8s - 2.8s)
	-- Slows down, 3 slow clicks
	for i = 1, 3 do
		resultText.Text = commonAuras[math.random(1, #commonAuras)].Name
		if SFX then SFX.Play(gui, "tick", 0.6) end
		task.wait(0.25)
	end
	
	-- Freezes on MYTHIC
	local fakeMythic = mythicAuras[math.random(1, #mythicAuras)]
	resultText.Text = fakeMythic.Name .. "\n1 in " .. fakeMythic.Rarity
	resultText.TextColor3 = fakeMythic.Color
	resultText.Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
	
	-- Elastic Scale up & Glow Outline
	outline.Color = fakeMythic.Color
	outline.Thickness = 8
	outline.Transparency = 0
	
	TweenService:Create(resultText, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(BASE_WIDTH * 1.5, BASE_HEIGHT * 1.5)
	}):Play()
	
	if SFX then SFX.Play(gui, "legendary") end -- Bass thud / Choir
	
	task.wait(0.7) -- Wait until 2.8s
	
	-- PHASE 3: The "Break" (2.8s - 3.2s)
	resultText.TextColor3 = Color3.fromRGB(50, 50, 50) -- Dark Gray
	resultText.TextTransparency = 0.5
	outline.Color = Color3.fromRGB(20, 20, 20)
	outline.Thickness = 4
	
	-- Shrink to 0.8 scale & Tilt randomly
	resultText.Size = UDim2.fromOffset(BASE_WIDTH * 0.8, BASE_HEIGHT * 0.8)
	resultText.Rotation = math.random(-10, 10)
	
	if SFX then SFX.Play(gui, "shatter") end -- Record scratch
	
	task.wait(0.4) -- Wait until 3.2s
	
	-- PHASE 4: The True Impact Reveal (3.2s - 4.0s)
	-- Reset rotation and transparency
	resultText.Rotation = 0
	resultText.TextTransparency = 0
	
	local displayText = res.DisplayName or res.Name
	resultText.Text = displayText .. "\n1 in " .. res.Rarity
	resultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
	outline.Color = Color3.fromRGB(15, 15, 25)
	
	-- Spawn at massive scale (3.0)
	resultText.Size = UDim2.fromOffset(BASE_WIDTH * 3.0, BASE_HEIGHT * 3.0)
	
	if SFX then SFX.Play(gui, "mythic") end -- Boom sound
	
	-- Slam down to 1.0 in 0.15s using Bounce
	local slamTween = TweenService:Create(resultText, TweenInfo.new(0.15, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
	})
	slamTween:Play()
	
	-- THE IMPACT EVENT (The exact millisecond it hits 1.0)
	slamTween.Completed:Connect(function()
		-- 1. Screen Flash (0.5 transparency -> 1.0 in 0.3s)
		flash.BackgroundTransparency = 0.5
		TweenService:Create(flash, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		
		-- 2. UI Shake (Vibrates heavily for 0.4s)
		uiShake(0.4, 15)
		
		-- 3. Particles Burst outward
		burstParticles(res.Color or Color3.fromRGB(255, 255, 255), 40)
	end)
	
	button.Text = "ROLL"
	task.wait(1) -- Let the impact settle
	
	task.delay(3, function()
		if not isRolling and not autoRollEnabled then fadeOutUI() end
	end)
end

-- 2. THE NORMAL IMPACT (For regular rolls)
local function playNormalImpact(res)
	if SFX then SFX.Play(gui, "reveal") end
	local displayText = res.DisplayName or res.Name
	resultText.Text = displayText .. "\n1 in " .. res.Rarity
	resultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
	
	resultText.Position = UDim2.fromScale(0.5, 0.42)
	resultText.Size = UDim2.fromOffset(BASE_WIDTH * 0.6, BASE_HEIGHT * 1.3)
	resultText.TextTransparency = 0; outline.Transparency = 0
	
	TweenService:Create(resultText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(BASE_WIDTH * 1.1, BASE_HEIGHT * 0.9)
	}):Play()
	
	task.delay(0.2, function()
		TweenService:Create(resultText, TweenInfo.new(0.15), {Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)}):Play()
	end)
	
	task.delay(4, function()
		if not isRolling and not autoRollEnabled then fadeOutUI() end
	end)
end

-- 3. THE MYTHIC CUTSCENE SLOT (Ready for editing!)
local function playMythicCutscene(res)
	TweenService:Create(csOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
	if SFX then SFX.Play(gui, "legendary") end
	
	task.wait(1)
	
	local displayText = res.DisplayName or res.Name
	resultText.Text = displayText .. "\n1 in " .. res.Rarity
	resultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
	
	resultText.Size = UDim2.fromOffset(0, 0)
	resultText.Position = UDim2.fromScale(0.5, 0.4)
	resultText.TextTransparency = 0; outline.Transparency = 0
	
	TweenService:Create(resultText, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(BASE_WIDTH * 1.5, BASE_HEIGHT * 1.5)
	}):Play()
	
	burstParticles(res.Color or Color3.fromRGB(150,0,255), 50)
	uiShake(0.5, 10)
	
	task.wait(4)
	TweenService:Create(csOverlay, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(resultText, TweenInfo.new(1), {Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)}):Play()
	
	task.delay(3, function()
		if not isRolling and not autoRollEnabled then fadeOutUI() end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- MAIN ROLL LOGIC
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local autoRollEnabled = false

local function doRoll()
	if isRolling then return end
	isRolling = true
	button.Text = "..."
	
	-- Reset UI
	resultText.TextTransparency = 0
	outline.Transparency = 0
	csOverlay.BackgroundTransparency = 1
	
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)
	
	-- Wait for server result
	while not gotResult do task.wait(0.02) end
	
	if not res then
		resultText.Text = "Too fast!"; resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
		isRolling = false; button.Text = "ROLL"; return
	end

	-- DECIDE PATH:
	-- 1. Mythic+ -> Cutscene!
	if res.Rarity >= 50000 then
		playMythicCutscene(res)
		
	-- 2. 1-in-4 Chance -> Fakeout Sequence!
	elseif math.random(1, 4) == 1 then
		playFakeOutSequence(res)
		
	-- 3. Otherwise -> Normal Impact
	else
		playNormalImpact(res)
	end
	
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

print("RollUI loaded! (Exact 4-Second Fake-Out Timeline)")
]==]

print("✅ EXACT 4-SECOND FAKE-OUT APPLIED!")
print("⏱️ Implements your EXACT timeline and easing styles!")
