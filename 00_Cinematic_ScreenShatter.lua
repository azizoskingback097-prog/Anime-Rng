-- ═══════════════════════════════════════════════════════════
-- 💥 CINEMATIC SCREEN SHATTER V3 (Breaks the whole screen!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- WHAT'S NEW:
--   • FIXED THE FREEZE: No more spawning 20 physical fragments!
--   • SCREEN SHATTER: Huge cracks explode across the entire monitor.
--   • VOID Flicker: The screen goes black and flashes violently.
--   • THE HOOK: 1-in-7 rolls FAKE the shatter, but reveal a Common!
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

-- ⚙️ ANIMATION SETTINGS
local SHATTER_THRESHOLD = 1000   -- Real auras this rare+ trigger the TRUE shatter
local FAKEOUT_CHANCE = 7         -- 1 in X chance to FAKE a shatter on normal rolls
local FLICKER_SPEEDS = {0.03, 0.035, 0.04, 0.045, 0.05, 0.06, 0.07, 0.085, 0.10, 0.12}
local FAKE_HOLD_TIME = 0.4       
local BUILDUP_TIME = 0.5         
local RESULT_FADE_DELAY = 4
local RESULT_FADE_TIME = 1.5

local TEXT_COLOR = Color3.fromRGB(255,255,255)
local BANNER_DEFAULT_COLOR = Color3.fromRGB(255,215,0)
local THEME_COLOR = Color3.fromRGB(30,30,45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80,120,255)
local RESULT_HOME = UDim2.fromScale(0.5, 0.42)
local RESULT_HOME_SIZE = UDim2.fromScale(0.45, 0.16)

local auraNames, commonAuras = {}, {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		table.insert(auraNames, a.Name)
		if a.Rarity < 100 then table.insert(commonAuras, a) end
	end
end
if #auraNames == 0 then auraNames = {"..."} end
if #commonAuras == 0 then commonAuras = { {Name="Flicker", Color=Color3.fromRGB(200,200,200)} } end

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

-- Container (This gets shaken!)
local container = Instance.new("Frame")
container.Size = UDim2.fromScale(1, 1); container.Position = UDim2.fromScale(0, 0)
container.BackgroundTransparency = 1; container.Parent = gui

-- VOID (Covers the whole screen in darkness)
local voidFrame = Instance.new("Frame")
voidFrame.Size = UDim2.fromScale(1, 1); voidFrame.Position = UDim2.fromScale(0, 0)
voidFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
voidFrame.BackgroundTransparency = 1; voidFrame.ZIndex = 5; voidFrame.Parent = container

-- Speed Lines Holder
local speedHolder = Instance.new("Frame")
speedHolder.AnchorPoint = Vector2.new(0.5, 0.5); speedHolder.Size = UDim2.fromOffset(0, 0)
speedHolder.Position = RESULT_HOME; speedHolder.BackgroundTransparency = 1
speedHolder.ZIndex = 8; speedHolder.Parent = container

-- Glow behind text
local glow = Instance.new("Frame")
glow.AnchorPoint = Vector2.new(0.5, 0.5); glow.Size = UDim2.fromScale(0.6, 0.2)
glow.Position = RESULT_HOME; glow.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
glow.BackgroundTransparency = 1; glow.ZIndex = 9
local gCorner = Instance.new("UICorner"); gCorner.CornerRadius = UDim.new(1, 0); gCorner.Parent = glow
glow.Parent = container

-- Result Text
local result = Instance.new("TextLabel")
result.AnchorPoint = Vector2.new(0.5, 0.5); result.Size = RESULT_HOME_SIZE
result.Position = RESULT_HOME; result.Text = "Press ROLL to begin!"
result.Font = Enum.Font.Bangers; result.TextScaled = true
result.BackgroundTransparency = 1; result.TextColor3 = TEXT_COLOR
result.TextStrokeTransparency = 1; result.ZIndex = 10; result.Parent = container

-- Flash (Used for the violent flicker)
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1); flash.Position = UDim2.fromScale(0, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1; flash.ZIndex = 50; flash.Parent = container

-- Buttons (Outside container so they don't shake)
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5); button.Size = UDim2.fromScale(0.16, 0.09)
button.Position = UDim2.fromScale(0.5, 0.85); button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack; button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR; button.TextColor3 = TEXT_COLOR
button.ZIndex = 20
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12, 0); bCorner.Parent = button
button.Parent = gui

local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5); autoBtn.Size = UDim2.fromScale(0.10, 0.06)
autoBtn.Position = UDim2.fromScale(0.5, 0.78); autoBtn.Text = "AUTO: OFF"
autoBtn.Font = Enum.Font.GothamBold; autoBtn.TextScaled = true
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); autoBtn.TextColor3 = TEXT_COLOR
autoBtn.ZIndex = 20
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
local speedLinesActive = false
local breathingActive = false

local function shakeContainer(duration, intensity)
	local t0 = os.clock()
	while os.clock() - t0 < duration do
		local ox = (math.random() - 0.5) * 2 * intensity
		local oy = (math.random() - 0.5) * 2 * intensity
		container.Position = UDim2.fromOffset(ox, oy)
		task.wait(0.02)
	end
	container.Position = UDim2.fromScale(0, 0)
end

local function clearAnimation()
	speedLinesActive = false
	breathingActive = false
	
	-- Destroy any dynamic elements
	for _, child in ipairs(container:GetChildren()) do
		if child.Name == "CrackLayer" or child.Name == "Ambient" then
			child:Destroy()
		end
	end
	for _, child in ipairs(speedHolder:GetChildren()) do
		child:Destroy()
	end
	
	voidFrame.BackgroundTransparency = 1
	flash.BackgroundTransparency = 1
	glow.BackgroundTransparency = 1
	result.Rotation = 0
	result.Size = RESULT_HOME_SIZE
end

local function startSpeedLines()
	speedLinesActive = true
	task.spawn(function()
		local lines = {}
		for i = 1, 20 do
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 1); f.Size = UDim2.fromOffset(math.random(2, 4), math.random(100, 300))
			f.Position = UDim2.new(0.5, 0, 0.5, 0); f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			f.BackgroundTransparency = math.random(60, 90) / 100; f.Rotation = (i * 18) + math.random(-5, 5)
			f.BorderSizePixel = 0; f.ZIndex = 8; f.Parent = speedHolder
			table.insert(lines, f)
		end
		while speedLinesActive do
			for _, l in ipairs(lines) do
				l.BackgroundTransparency = math.random(50, 95) / 100
			end
			task.wait(0.05)
		end
		for _, l in ipairs(lines) do
			TweenService:Create(l, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		end
		task.wait(0.3)
		for _, l in ipairs(lines) do l:Destroy() end
	end)
end

-- 🌟 SCREEN SHATTER EFFECT (Replaces the old fragment logic)
local function shatterScreen()
	local crackLayer = Instance.new("Frame")
	crackLayer.Name = "CrackLayer"
	crackLayer.Size = UDim2.fromScale(1, 1)
	crackLayer.BackgroundTransparency = 1
	crackLayer.ZIndex = 40 -- Covers the screen!
	crackLayer.Parent = container
	
	-- Spawn massive glass cracks across the whole screen
	for i = 1, 12 do
		local c = Instance.new("Frame")
		c.AnchorPoint = Vector2.new(0.5, 1)
		-- Make them massive so they cross the whole screen
		c.Size = UDim2.fromOffset(math.random(5, 10), math.random(800, 1500))
		c.Position = UDim2.new(0.5, 0, 0.5, 0)
		c.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		c.BackgroundTransparency = 1
		c.Rotation = (i * 30) + math.random(-15, 15)
		c.BorderSizePixel = 0
		c.Parent = crackLayer
		
		-- Make them flash into view violently
		TweenService:Create(c, TweenInfo.new(0.1), {BackgroundTransparency = 0.1}):Play()
	end
	
	-- Violent Black/White screen flicker
	task.spawn(function()
		for i = 1, 4 do
			flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			flash.BackgroundTransparency = 0
			task.wait(0.05)
			flash.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			task.wait(0.05)
		end
		flash.BackgroundTransparency = 1
	end)
	
	-- Open the dark void
	TweenService:Create(voidFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	
	-- Keep cracks on screen for a moment, then fade them out
	task.delay(0.5, function()
		if crackLayer.Parent then
			TweenService:Create(crackLayer, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			for _, c in ipairs(crackLayer:GetChildren()) do
				TweenService:Create(c, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			end
			task.wait(0.6)
			crackLayer:Destroy()
		end
	end)
end

local function startAmbientParticles(color)
	breathingActive = true
	task.spawn(function()
		while breathingActive do
			local pHolder = container:FindFirstChild("Ambient")
			if not pHolder then
				pHolder = Instance.new("Folder")
				pHolder.Name = "Ambient"
				pHolder.Parent = container
			end
			
			local p = Instance.new("Frame")
			p.AnchorPoint = Vector2.new(0.5, 0.5); p.Size = UDim2.fromOffset(math.random(4, 8), math.random(4, 8))
			p.Position = UDim2.new(RESULT_HOME.X.Scale + (math.random()-0.5)*0.3, RESULT_HOME.Y.Scale + (math.random()-0.5)*0.1)
			p.BackgroundColor3 = color; p.BackgroundTransparency = 0.2
			p.BorderSizePixel = 0; p.ZIndex = 9; p.Parent = pHolder
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
-- THE REVEAL SEQUENCES
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local hasRolled = false
local lastRollTime = os.clock()
local autoRollEnabled = false
local fadeTimer = nil

local function scheduleFadeOut()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end) end
	fadeTimer = task.delay(RESULT_FADE_DELAY, function()
		fadeTimer = nil
		if not isRolling and not autoRollEnabled then
			breathingActive = false
			TweenService:Create(result, TweenInfo.new(RESULT_FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			TweenService:Create(glow, TweenInfo.new(RESULT_FADE_TIME), {BackgroundTransparency = 1}):Play()
		end
	end)
end

local function doNormalReveal(res)
	speedLinesActive = false
	if SFX then SFX.Play(gui, "reveal") end
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "MUTATED\n" .. displayText end
	result.Text = displayText .. "\n1 in " .. res.Rarity
	result.TextColor3 = res.Color or TEXT_COLOR
	
	result.Size = UDim2.fromScale(0.8, 0.3)
	result.TextTransparency = 0
	TweenService:Create(result, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = RESULT_HOME_SIZE}):Play()
	shakeContainer(0.2, 2)
	
	if res.Rarity >= 1000 then
		result.TextStrokeColor3 = res.Color
		result.TextStrokeTransparency = 0.2
		glow.BackgroundColor3 = res.Color or Color3.fromRGB(150,0,255)
		glow.BackgroundTransparency = 0.5
		startAmbientParticles(res.Color or Color3.fromRGB(150,0,255))
	end
	scheduleFadeOut()
end

local function doShatteredReveal(res, isFake)
	local fake = commonAuras[math.random(1, #commonAuras)]
	result.Text = (fake.Name or "Flicker") .. "\n1 in " .. (fake.Rarity or 1)
	result.TextColor3 = fake.Color or TEXT_COLOR
	result.Size = RESULT_HOME_SIZE
	result.TextTransparency = 0
	result.TextStrokeTransparency = 1
	TweenService:Create(result, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = RESULT_HOME_SIZE}):Play()
	
	task.wait(FAKE_HOLD_TIME)
	if not isRolling then return end
	
	-- BUILDUP
	speedLinesActive = true
	startSpeedLines()
	task.spawn(function() shakeContainer(BUILDUP_TIME, 4) end)
	if SFX then 
		SFX.Play(gui, "tick")
		task.wait(0.2)
		SFX.Play(gui, "tick")
	end
	
	-- Violent text flicker
	local t0 = os.clock()
	while os.clock() - t0 < BUILDUP_TIME do
		result.Rotation = math.random(-2, 2)
		result.TextColor3 = Color3.fromRGB(255, 50, 50)
		task.wait(0.05)
		result.TextColor3 = fake.Color or TEXT_COLOR
		task.wait(0.05)
	end
	result.Rotation = 0
	result.TextTransparency = 1 -- Hide text for the screen shatter
	if not isRolling then return end
	
	-- 💥 SCREEN SHATTER!
	speedLinesActive = false
	shatterScreen()
	shakeContainer(0.3, 10) -- Huge screen shake
	
	task.wait(0.4)
	if not isRolling then return end
	
	-- TRUE REVEAL SLAM
	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "MUTATED\n" .. displayText end
	result.Text = displayText .. "\n1 in " .. res.Rarity
	result.TextColor3 = res.Color or TEXT_COLOR
	
	glow.BackgroundColor3 = res.Color or Color3.fromRGB(150, 0, 255)
	glow.BackgroundTransparency = 0.6
	glow.Size = UDim2.fromScale(2, 0.5)
	TweenService:Create(glow, TweenInfo.new(0.5), {BackgroundTransparency = 0.4, Size = UDim2.fromScale(0.6, 0.2)}):Play()
	
	result.Size = UDim2.fromScale(0.05, 0.02)
	result.TextTransparency = 0
	result.TextStrokeColor3 = res.Color or Color3.fromRGB(255,255,255)
	result.TextStrokeTransparency = 0.1
	
	if SFX then
		if isFake then 
			SFX.Play(gui, "reveal") 
		else 
			SFX.Play(gui, "legendary") 
		end
	end
	
	TweenService:Create(result, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = RESULT_HOME_SIZE}):Play()
	shakeContainer(0.4, 8)
	
	-- Fade the void out so the game is visible again
	TweenService:Create(voidFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	
	if not isFake then
		startAmbientParticles(res.Color or Color3.fromRGB(150,0,255))
	end
	
	task.wait(1)
	scheduleFadeOut()
end

-- MAIN ROLL
local function doRoll()
	if isRolling then return end
	isRolling = true; hasRolled = true; lastRollTime = os.clock()

	clearAnimation()
	breathingActive = false
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
	result.TextTransparency = 0

	if SFX then SFX.Play(gui, "roll") end
	button.Text = "..."
	
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)

	startSpeedLines()
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
		speedLinesActive = false
		result.Text = "Too fast!"; result.TextColor3 = TEXT_COLOR
		isRolling = false; return
	end

	-- DECIDE PATH
	if res.Rarity >= SHATTER_THRESHOLD then
		doShatteredReveal(res, false)
	else
		if math.random(1, FAKEOUT_CHANCE) == 1 then
			doShatteredReveal(res, true)
		else
			doNormalReveal(res)
		end
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

print("RollUI loaded! (Cinematic Screen Shatter V3)")
]==]

print("✅ CINEMATIC SCREEN SHATTER V3 APPLIED!")
print("💥 Shatters the ENTIRE screen (massive cracks + void).")
print("🚫 Fixed the freeze bug completely (no more fragments).")
