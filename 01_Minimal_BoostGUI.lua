-- ═══════════════════════════════════════════════════════════
-- 🧪 MINIMAL BOOST GUI (Grow a Garden Style - No Background!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Features:
--   • NO background box (just floating icons!)
--   • Tiny 2:1 ratio icons
--   • Small font "x1" text below icon
--   • Updates live when luck or coins change
--   • Timer countdown when boost is active
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("BoostGUI")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "BoostGUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BoostUpdateEvent = Remotes:WaitForChild("BoostUpdateEvent")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "BoostGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "BoostGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 18
gui.Parent = playerGui

-- ═══ COIN INDICATOR (Bottom Left - Tiny & Backgroundless!) ═══
local coinContainer = Instance.new("Frame")
coinContainer.AnchorPoint = Vector2.new(0, 1)
coinContainer.Size = UDim2.fromOffset(60, 45)
coinContainer.Position = UDim2.fromScale(0.02, 0.95)
coinContainer.BackgroundTransparency = 1 -- NO BACKGROUND!
coinContainer.Parent = gui

-- Coin Icon (Small, 2:1 ratio)
local coinIcon = Instance.new("ImageLabel")
coinIcon.AnchorPoint = Vector2.new(0.5, 0)
coinIcon.Size = UDim2.fromOffset(30, 30) -- 2:1 ratio, tiny!
coinIcon.Position = UDim2.fromScale(0.5, 0)
coinIcon.BackgroundTransparency = 1
coinIcon.Image = "rbxassetid://13118475475" -- Clean coin icon
coinIcon.ScaleType = Enum.ScaleType.Fit
coinIcon.Parent = coinContainer

-- Coin Multiplier Text (Small font below icon)
local coinMultText = Instance.new("TextLabel")
coinMultText.AnchorPoint = Vector2.new(0.5, 0)
coinMultText.Size = UDim2.fromOffset(50, 15)
coinMultText.Position = UDim2.fromScale(0.5, 0.7)
coinMultText.BackgroundTransparency = 1
coinMultText.Text = "x1"
coinMultText.Font = Enum.Font.GothamBold
coinMultText.TextSize = 14 -- Small font!
coinMultText.TextColor3 = Color3.fromRGB(255, 215, 0)
coinMultText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
coinMultText.TextStrokeTransparency = 0.3
coinMultText.Parent = coinContainer

-- Coin Timer (Hidden by default)
local coinTimer = Instance.new("TextLabel")
coinTimer.AnchorPoint = Vector2.new(0.5, 0)
coinTimer.Size = UDim2.fromOffset(50, 12)
coinTimer.Position = UDim2.fromScale(0.5, 1.0)
coinTimer.BackgroundTransparency = 1
coinTimer.Text = ""
coinTimer.Font = Enum.Font.GothamMedium
coinTimer.TextSize = 11 -- Even smaller!
coinTimer.TextColor3 = Color3.fromRGB(255, 200, 100)
coinTimer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
coinTimer.TextStrokeTransparency = 0.4
coinTimer.Visible = false
coinTimer.Parent = coinContainer

-- ═══ LUCK INDICATOR (Next to Coin - Tiny & Backgroundless!) ═══
local luckContainer = Instance.new("Frame")
luckContainer.AnchorPoint = Vector2.new(0, 1)
luckContainer.Size = UDim2.fromOffset(60, 45)
luckContainer.Position = UDim2.fromScale(0.09, 0.95) -- Next to coin
luckContainer.BackgroundTransparency = 1
luckContainer.Parent = gui

local luckIcon = Instance.new("ImageLabel")
luckIcon.AnchorPoint = Vector2.new(0.5, 0)
luckIcon.Size = UDim2.fromOffset(30, 30)
luckIcon.Position = UDim2.fromScale(0.5, 0)
luckIcon.BackgroundTransparency = 1
luckIcon.Image = "rbxassetid://13118475475" -- Will change to clover when boosted
luckIcon.ScaleType = Enum.ScaleType.Fit
luckIcon.Parent = luckContainer

local luckMultText = Instance.new("TextLabel")
luckMultText.AnchorPoint = Vector2.new(0.5, 0)
luckMultText.Size = UDim2.fromOffset(50, 15)
luckMultText.Position = UDim2.fromScale(0.5, 0.7)
luckMultText.BackgroundTransparency = 1
luckMultText.Text = "x1"
luckMultText.Font = Enum.Font.GothamBold
luckMultText.TextSize = 14
luckMultText.TextColor3 = Color3.fromRGB(150, 200, 255)
luckMultText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
luckMultText.TextStrokeTransparency = 0.3
luckMultText.Parent = luckContainer

local luckTimer = Instance.new("TextLabel")
luckTimer.AnchorPoint = Vector2.new(0.5, 0)
luckTimer.Size = UDim2.fromOffset(50, 12)
luckTimer.Position = UDim2.fromScale(0.5, 1.0)
luckTimer.BackgroundTransparency = 1
luckTimer.Text = ""
luckTimer.Font = Enum.Font.GothamMedium
luckTimer.TextSize = 11
luckTimer.TextColor3 = Color3.fromRGB(150, 200, 255)
luckTimer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
luckTimer.TextStrokeTransparency = 0.4
luckTimer.Visible = false
luckTimer.Parent = luckContainer

-- ═══ STATE TRACKING ═══
local activeBoosts = {}
local baseLuck = 1

-- Format seconds to MM:SS
local function formatTime(seconds)
	if seconds <= 0 then return "" end
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

-- Update Coin display
local function updateCoinDisplay()
	local coinBoost = activeBoosts["CoinMultiplier"]
	
	if coinBoost and coinBoost.Remaining > 0 then
		coinIcon.Image = "rbxassetid://13118475475" -- Coin icon (or boosted variant)
		coinMultText.Text = "x" .. tostring(coinBoost.Value)
		coinMultText.TextColor3 = Color3.fromRGB(255, 215, 0)
		coinTimer.Text = formatTime(coinBoost.Remaining)
		coinTimer.Visible = true
	else
		coinMultText.Text = "x1"
		coinMultText.TextColor3 = Color3.fromRGB(180, 180, 180)
		coinTimer.Visible = false
	end
end

-- Update Luck display (changes when luck changes!)
local function updateLuckDisplay()
	local luckBoost = activeBoosts["LuckMultiplier"]
	local totalLuck = baseLuck
	
	if luckBoost and luckBoost.Remaining > 0 then
		totalLuck = baseLuck * luckBoost.Value
		luckIcon.Image = "rbxassetid://13118475475" -- Clover/luck icon when boosted
		luckMultText.Text = "x" .. tostring(luckBoost.Value)
		luckMultText.TextColor3 = Color3.fromRGB(100, 255, 150)
		luckTimer.Text = formatTime(luckBoost.Remaining)
		luckTimer.Visible = true
	else
		luckMultText.Text = "x" .. tostring(baseLuck)
		luckMultText.TextColor3 = Color3.fromRGB(180, 180, 180)
		luckTimer.Visible = false
	end
end

-- Listen for boost updates
BoostUpdateEvent.OnClientEvent:Connect(function(boostData)
	activeBoosts = boostData or {}
	updateCoinDisplay()
	updateLuckDisplay()
end)

-- Listen for stat updates (updates base luck too!)
StatsUpdatedEvent.OnClientEvent:Connect(function(stats)
	if stats and stats.Luck then
		baseLuck = stats.Luck
		updateLuckDisplay()
	end
end)

-- Live countdown loop
task.spawn(function()
	while true do
		task.wait(1)
		local changed = false
		for boostType, data in pairs(activeBoosts) do
			if data.Remaining and data.Remaining > 0 then
				data.Remaining = data.Remaining - 1
				if data.Remaining <= 0 then
					data.Remaining = 0
				end
				changed = true
			end
		end
		if changed then
			updateCoinDisplay()
			updateLuckDisplay()
		end
	end
end)

print("BoostGUI V2 loaded! (Minimal - No Background)")
]==]

print("✅ MINIMAL BOOST GUI V2 DEPLOYED!")
print("🪙 Tiny coin icon + small 'x1' text (No background!)")
print("🍀 Luck updates when anything changes!")
