-- ═══════════════════════════════════════════════════════════
-- 🖥️  ROLL CLIENT  —  LocalScript   |   PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- Builds the Roll UI. Click ROLL → it plays a quick "slot machine"
-- animation (aura names flicker fast), asks the server for the real
-- result, then REVEALS the aura sliding in from the TOP to its spot,
-- colored in the aura's color. Also: rolls counter + rare-pull banner.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Roll animation speed  → change CYCLE_SPEED / REVEAL_TIME
--   • Reveal direction      → swap the two Position values (see ⚙️ ANIMATION)
--   • Colors / theme        → edit the ⚙️ UI THEME block
--   • Button size/pos       → edit button.Size / button.Position
--
-- 🔗 RELATED SCRIPTS:
--   • RNGManager (server) → answers RollFunction when this calls it
--   • AnnounceEvent       → server fires it; this listens + shows banner
--   • AuraData            → this reads the name list for the cycling animation
--     ⚠️ If you rename AuraData, update the require() line below.
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Make the cycling SLOW DOWN near the end for suspense:
--     replace the fixed task.wait(0.05) loop with one where the wait
--     gradually increases (0.04 → 0.08 → 0.15) before the reveal.
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction  = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

-- read the aura list so we can cycle names during the animation
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
-- ⚙️ ─────────────── CUSTOMIZE: ANIMATION ──────────────
local CYCLE_SPEED = 0.05   -- seconds between name flickers
local REVEAL_TIME = 0.8    -- how long the slot-machine plays before reveal
local RESULT_HOME = UDim2.fromScale(0.2, 0.36)  -- where the text sits normally
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

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
result.Size = UDim2.fromScale(0.6, 0.22)
result.Position = RESULT_HOME
result.Text = "Press ROLL to begin!"
result.Font = Enum.Font.GothamBlack
result.TextScaled = true
result.BackgroundTransparency = 1
result.TextColor3 = TEXT_COLOR
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

-- ────────────── roll button + animation logic ──────────────
local isRolling = false

button.MouseButton1Click:Connect(function()
	if isRolling then return end
	isRolling = true
	button.Text = "..."

	-- reset text position & color for a clean start
	result.TextColor3 = TEXT_COLOR
	result.Position = RESULT_HOME

	-- 🎰 SLOT-MACHINE: flicker random aura names while we wait
	local cycling = true
	task.spawn(function()
		while cycling do
			result.Text = auraNames[math.random(1, #auraNames)]
			task.wait(CYCLE_SPEED)
		end
	end)

	-- ask the server (runs alongside the animation)
	local res = RollFunction:InvokeServer()

	-- let the flicker play a beat longer for suspense
	task.wait(REVEAL_TIME)
	cycling = false

	button.Text = "ROLL"

	if not res then
		result.Text = "⏳ Rolling too fast — wait a moment."
		isRolling = false
		return
	end

	-- set the final text in the aura's color
	result.Text = res.Name .. "\n1 in " .. res.Rarity .. "  •  " .. res.Tier
	result.TextColor3 = res.Color or TEXT_COLOR
	counter.Text = "Rolls: " .. tostring(res.TotalRolls)

	-- ⬇️ REVEAL: slide in from the TOP (above the screen) down to its spot
	result.Position = UDim2.fromScale(0.2, -0.25)
	local reveal = TweenService:Create(
		result,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = RESULT_HOME }
	)
	reveal:Play()

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
