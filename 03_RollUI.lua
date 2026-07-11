-- ═══════════════════════════════════════════════════════════
-- 🖥️  ROLL UI  —  LocalScript   |   PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- The roll screen with a CINEMATIC animation:
--   Phase 1: names flicker fast → slow (building suspense)
--   Phase 2: a rare aura ZOOMS IN big & glowing (the "oh wow!" moment)
--   Phase 3: a WHITE FLASH hides the swap (smooth, not jarring!)
--   Phase 4: the REAL result slides in → shake on good pulls
-- Plus a rolls counter + global rare-pull banner.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Animation pacing   → FLICKER_SPEEDS, NEAR_MISS_HOLD
--   • Flash strength     → FLASH_TIME (longer = more dramatic)
--   • Glow intensity     → GLOW_STROKE (lower = thicker glow)
--   • Shake              → SHAKE_THRESHOLD / SHAKE_INTENSITY
--   • Colors / theme     → ⚙️ UI THEME block
--
-- 🔗 RELATED SCRIPTS:
--   • GameServer   → answers RollFunction
--   • AuraData → names + colors for the animation
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Color the flash to match the pulled tier (gold for Legendary,
--   purple for Mythic) instead of white.
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction  = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

local auraNames = {}
for _, a in ipairs(AuraData.Auras) do
	table.insert(auraNames, a.Name)
end

-- ⚙️ ─────────────────── CUSTOMIZE: UI THEME ───────────────────
local THEME_COLOR       = Color3.fromRGB(30, 30, 45)
local ROLL_BUTTON_COLOR = Color3.fromRGB(80, 120, 255)
local TEXT_COLOR        = Color3.fromRGB(255, 255, 255)
local BANNER_COLOR      = Color3.fromRGB(255, 215, 0)
-- ⚙️ ─────────────────── CUSTOMIZE: ANIMATION ──────────────────
local FLICKER_SPEEDS = { 0.03, 0.035, 0.04, 0.045, 0.05, 0.06, 0.07, 0.085, 0.10, 0.12 }
local NEAR_MISS_RARITY = 1000
local NEAR_MISS_HOLD   = 0.6
local FLASH_TIME       = 0.25
local GLOW_STROKE      = 0.2
local SHAKE_THRESHOLD  = 1000
local SHAKE_INTENSITY  = 0.012
local SHAKE_DURATION   = 0.4
local RESULT_HOME = UDim2.fromScale(0.2, 0.36)
local NEAR_MISS_SIZE = UDim2.fromScale(0.7, 0.32)
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

local rareAuras = {}
for _, a in ipairs(AuraData.Auras) do
	if a.Rarity >= NEAR_MISS_RARITY then
		table.insert(rareAuras, a)
	end
end

-- ────────────── build the UI ──────────────
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "RollButton"
button.Size = UDim2.fromScale(0.16, 0.09)
button.Position = UDim2.fromScale(0.81, 0.87)
button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.BackgroundColor3 = ROLL_BUTTON_COLOR
button.TextColor3 = TEXT_COLOR
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12, 0); bCorner.Parent = button
button.Parent = gui

local result = Instance.new("TextLabel")
result.Name = "ResultText"
result.Size = UDim2.fromScale(0.6, 0.22)
result.Position = RESULT_HOME
result.Text = "Press ROLL to begin!"
result.Font = Enum.Font.GothamBlack
result.TextScaled = true
result.BackgroundTransparency = 1
result.TextColor3 = TEXT_COLOR
result.TextStrokeTransparency = 1
result.Parent = gui

local counter = Instance.new("TextLabel")
counter.Size = UDim2.fromScale(0.16, 0.05)
counter.Position = UDim2.fromScale(0.02, 0.02)
counter.Text = "Rolls: 0"
counter.Font = Enum.Font.GothamBold
counter.TextScaled = true
counter.BackgroundTransparency = 1
counter.TextColor3 = TEXT_COLOR
counter.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.1)
banner.Position = UDim2.fromScale(0.15, 0.12)
banner.Text = ""
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.BackgroundColor3 = THEME_COLOR
banner.TextColor3 = BANNER_COLOR
banner.BackgroundTransparency = 1
banner.Visible = false
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2, 0); bnCorner.Parent = banner
banner.Parent = gui

-- 💡 WHITE FLASH overlay — covers the screen to hide the swap
local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.fromScale(1, 1)
flash.Position = UDim2.fromScale(0, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1
flash.ZIndex = 50
flash.Parent = gui

-- ────────────── helper: glow on/off ──────────────
local function setGlow(on)
	result.TextStrokeColor3 = result.TextColor3
	result.TextStrokeTransparency = on and GLOW_STROKE or 1
end

-- ────────────── shake function ──────────────
local function shakeLabel(label, homePos, rarity)
	local intensity = SHAKE_INTENSITY
	local duration  = SHAKE_DURATION
	if rarity >= 5000 then
		intensity = SHAKE_INTENSITY * 1.5
		duration  = SHAKE_DURATION * 1.4
	end
	if rarity >= 70000 then
		intensity = SHAKE_INTENSITY * 2.2
		duration  = SHAKE_DURATION * 1.8
	end
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		local ox = (math.random() - 0.5) * 2 * intensity
		local oy = (math.random() - 0.5) * 2 * intensity
		label.Position = UDim2.fromScale(homePos.X.Scale + ox, homePos.Y.Scale + oy)
		task.wait(0.02)
	end
	label.Position = homePos
end

-- ────────────── roll button + animation logic ──────────────
local isRolling = false

button.MouseButton1Click:Connect(function()
	if isRolling then return end
	isRolling = true
	button.Text = "..."

	-- clear instantly, reset everything
	result.Text = ""
	result.TextColor3 = TEXT_COLOR
	result.Position = RESULT_HOME
	result.Size = UDim2.fromScale(0.6, 0.22)
	setGlow(false)

	-- ask the server for the real result (runs in background)
	local gotResult = false
	local res
	task.spawn(function()
		res = RollFunction:InvokeServer()
		gotResult = true
	end)

	-- 🎬 PHASE 1: flicker fast → slow (suspense)
	for _, speed in ipairs(FLICKER_SPEEDS) do
		result.Text = auraNames[math.random(1, #auraNames)]
		task.wait(speed)
	end

	-- 🎬 PHASE 2: NEAR-MISS — zoom in a rare aura big & glowing
	if #rareAuras > 0 then
		local fake = rareAuras[math.random(1, #rareAuras)]
		result.TextColor3 = fake.Color
		setGlow(true)
		result.Text = fake.Name .. "\n1 in " .. fake.Rarity .. "  •  " .. fake.Tier

		-- zoom it up to look impressive
		result.Size = NEAR_MISS_SIZE
		result.Position = UDim2.fromScale(0.15, 0.34)
		local zoomIn = TweenService:Create(result, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.15, 0.30) })
		zoomIn:Play()
		task.wait(NEAR_MISS_HOLD)
	end

	-- 🎬 PHASE 3: WHITE FLASH — hide the swap so it's smooth!
	flash.BackgroundTransparency = 1
	local flashIn = TweenService:Create(flash, TweenInfo.new(FLASH_TIME * 0.4), { BackgroundTransparency = 0 })
	flashIn:Play()
	flashIn.Completed:Wait()

	-- (screen is white now — safe to swap)
	setGlow(false)
	result.Size = UDim2.fromScale(0.6, 0.22)

	-- wait for the server if it hasn't answered yet
	while not gotResult do
		task.wait(0.02)
	end

	button.Text = "ROLL"

	if not res then
		result.Text = "⏳ Too fast! Wait a moment."
		result.TextColor3 = TEXT_COLOR
		TweenService:Create(flash, TweenInfo.new(FLASH_TIME), { BackgroundTransparency = 1 }):Play()
		isRolling = false
		return
	end

	-- 🎬 PHASE 4: REVEAL the real result
	result.Text = res.Name .. "\n1 in " .. res.Rarity .. "  •  " .. res.Tier
	result.TextColor3 = res.Color or TEXT_COLOR
	counter.Text = "Rolls: " .. tostring(res.TotalRolls)

	-- start it above the screen
	result.Position = UDim2.fromScale(0.2, -0.3)

	-- fade the flash out to reveal!
	TweenService:Create(flash, TweenInfo.new(FLASH_TIME), { BackgroundTransparency = 1 }):Play()

	local reveal = TweenService:Create(result, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = RESULT_HOME })
	reveal:Play()
	reveal.Completed:Wait()

	-- glow + shake for good pulls
	if res.Rarity >= SHAKE_THRESHOLD then
		setGlow(true)
		shakeLabel(result, RESULT_HOME, res.Rarity)
	end

	isRolling = false
end)

-- ────────────── rare-pull banner from the server ──────────────
AnnounceEvent.OnClientEvent:Connect(function(info)
	banner.Text = "🎉  " .. info.Player .. " pulled " .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.Visible = true
	banner.BackgroundTransparency = 0.3
	banner.Position = UDim2.fromScale(0.15, -0.15)
	local tween = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.15, 0.12) })
	tween:Play()
	task.delay(5, function()
		banner.Visible = false
	end)
end)
