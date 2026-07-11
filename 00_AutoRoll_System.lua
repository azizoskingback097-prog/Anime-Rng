-- ═══════════════════════════════════════════════════════════
-- 🤖 AUTO ROLL SYSTEM + ROLL UI FIX
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- Adds a small AUTO button behind the Roll button.
-- Keeps the centered position, text fading, and SFX!
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

local auraNames = {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do table.insert(auraNames, a.Name) end
end

-- Settings
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

local RARE_SOUND_THRESHOLD = 1000
local LEGENDARY_SOUND_THRESHOLD = 5000
local MYTHIC_SOUND_THRESHOLD = 50000

local rareAuras = {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		if a.Rarity >= NEAR_MISS_RARITY then table.insert(rareAuras, a) end
	end
end

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

-- Main ROLL Button (Centered)
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Size = UDim2.fromScale(0.16,0.09); button.Position = UDim2.fromScale(0.5, 0.85)
button.Text = "ROLL"; button.Font = Enum.Font.GothamBlack; button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR; button.TextColor3 = TEXT_COLOR
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12,0); bCorner.Parent = button
button.Parent = gui

-- 🤖 AUTO Button (Behind Roll Button)
local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5)
autoBtn.Size = UDim2.fromScale(0.10, 0.06)
autoBtn.Position = UDim2.fromScale(0.5, 0.78) -- Centered, slightly above Roll
autoBtn.Text = "AUTO: OFF"
autoBtn.Font = Enum.Font.GothamBold; autoBtn.TextScaled = true
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); autoBtn.TextColor3 = TEXT_COLOR
local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0.15,0); abCorner.Parent = autoBtn
autoBtn.Parent = gui

local result = Instance.new("TextLabel")
result.Size = UDim2.fromScale(0.6,0.22); result.Position = RESULT_HOME
result.Text = "Press ROLL to begin!"; result.Font = Enum.Font.GothamBlack; result.TextScaled = true
result.BackgroundTransparency = 1; result.TextColor3 = TEXT_COLOR; result.TextStrokeTransparency = 1
result.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7,0.1); banner.Position = UDim2.fromScale(0.15,0.12)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = THEME_COLOR; banner.TextColor3 = BANNER_DEFAULT_COLOR
banner.BackgroundTransparency = 1; banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2,0); bnCorner.Parent = banner
banner.Parent = gui

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1,1); flash.Position = UDim2.fromScale(0,0)
flash.BackgroundColor3 = Color3.fromRGB(255,255,255); flash.BackgroundTransparency = 1; flash.ZIndex = 50
flash.Parent = gui

local function setGlow(on)
	result.TextStrokeColor3 = result.TextColor3
	result.TextStrokeTransparency = on and GLOW_STROKE or 1
end

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

local function playRevealSound(rarity)
	if not SFX then return end
	if rarity >= MYTHIC_SOUND_THRESHOLD then SFX.Play(gui, "mythic")
	elseif rarity >= LEGENDARY_SOUND_THRESHOLD then SFX.Play(gui, "legendary")
	elseif rarity >= RARE_SOUND_THRESHOLD then SFX.Play(gui, "rare")
	else SFX.Play(gui, "reveal") end
end

local isRolling = false
local hasRolled = false
local lastRollTime = os.clock()
local fadeTimer = nil
local autoRollEnabled = false

local function scheduleFadeOut()
	if fadeTimer then pcall(function() task.cancel(fadeTimer) end) end
	fadeTimer = task.delay(RESULT_FADE_DELAY, function()
		fadeTimer = nil
		if not isRolling and not autoRollEnabled then
			TweenService:Create(result, TweenInfo.new(RESULT_FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(30)
		if hasRolled and not isRolling and not autoRollEnabled and (os.clock() - lastRollTime) > INACTIVITY_REMINDER then
			if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
			result.TextTransparency = 0
			result.TextStrokeTransparency = 1
			result.Text = "Still there? Press ROLL!"
			result.TextColor3 = TEXT_COLOR
			result.Position = RESULT_HOME
			result.Size = UDim2.fromScale(0.6,0.22)
			setGlow(false)
		end
	end
end)

local function doRoll()
	if isRolling then return end
	isRolling = true; hasRolled = true; lastRollTime = os.clock()

	if fadeTimer then pcall(function() task.cancel(fadeTimer) end); fadeTimer = nil end
	result.TextTransparency = 0

	if SFX then SFX.Play(gui, "roll") end

	button.Text = "..."
	result.Text = ""; result.TextColor3 = TEXT_COLOR
	result.Position = RESULT_HOME; result.Size = UDim2.fromScale(0.6,0.22); setGlow(false)

	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)

	for _, speed in ipairs(FLICKER_SPEEDS) do
		result.Text = auraNames[math.random(1,#auraNames)]
		if SFX and math.random() < 0.3 then SFX.Play(gui, "tick", 0.2) end
		task.wait(speed)
	end

	if #rareAuras > 0 then
		local fake = rareAuras[math.random(1,#rareAuras)]
		result.TextColor3 = fake.Color; setGlow(true)
		result.Text = fake.Name .. "\n1 in " .. fake.Rarity .. "  -  " .. fake.Tier
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
		result.Text = "Too fast!"; result.TextColor3 = TEXT_COLOR
		TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
		isRolling = false; return
	end

	local displayText = res.DisplayName or res.Name
	if res.Mutated then displayText = "MUTATED\n" .. displayText end
	result.Text = displayText .. "\n1 in " .. res.Rarity .. "  -  " .. res.Tier
	result.TextColor3 = res.Color or TEXT_COLOR
	result.Position = UDim2.fromScale(0.2,-0.3)

	TweenService:Create(flash, TweenInfo.new(FLASH_TIME), {BackgroundTransparency = 1}):Play()
	playRevealSound(res.Rarity)

	local reveal = TweenService:Create(result, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = RESULT_HOME})
	reveal:Play(); reveal.Completed:Wait()

	if res.Rarity >= SHAKE_THRESHOLD or res.Mutated then
		setGlow(true); shakeLabel(result, RESULT_HOME, res.Rarity)
	end

	if not autoRollEnabled then
		scheduleFadeOut()
	end

	isRolling = false
end

button.MouseButton1Click:Connect(doRoll)

-- 🤖 AUTO ROLL LOGIC
autoBtn.MouseButton1Click:Connect(function()
	autoRollEnabled = not autoRollEnabled
	
	if autoRollEnabled then
		autoBtn.Text = "AUTO: ON"
		autoBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- Green
		if SFX then SFX.Play(gui, "click") end
	else
		autoBtn.Text = "AUTO: OFF"
		autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Grey
		if SFX then SFX.Play(gui, "click") end
		scheduleFadeOut()
	end
end)

-- Auto Roll Loop
task.spawn(function()
	while true do
		task.wait(0.1)
		if autoRollEnabled and not isRolling then
			doRoll()
		end
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

print("RollUI loaded! (With Auto Roll)")
]==]

print("✅ AUTO ROLL SYSTEM APPLIED!")
print("🤖 A small 'AUTO: OFF' button has been added behind the Roll button.")
print("🎮 Click it to toggle automatic rolling!")
