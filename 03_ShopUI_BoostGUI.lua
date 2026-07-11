-- ═══════════════════════════════════════════════════════════
-- 🛒 SHOP UI + 🧪 BOOST GUI (Bottom Left)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Creates:
--   • Shop Window (opens when pressing E on NPC)
--   • Boost GUI (bottom left: coin icon + multiplier + timer)
--   • Live countdown timers that pause offline
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS = game:GetService("ReplicatedStorage")

-- Delete old versions
local oldShop = SPS:FindFirstChild("ShopUI"); if oldShop then oldShop:Destroy() end
local oldBoost = SPS:FindFirstChild("BoostGUI"); if oldBoost then oldBoost:Destroy() end
task.wait(0.1)

-- ═══ 1. SHOP UI ═══
local shopScript = Instance.new("LocalScript")
shopScript.Name = "ShopUI"
shopScript.Parent = SPS
shopScript.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")
local PurchaseItemFunction = Remotes:WaitForChild("PurchaseItemFunction")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "ShopGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 25
gui.Parent = playerGui

-- Main Window
local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Size = UDim2.fromOffset(500, 400)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
window.BackgroundTransparency = 0.05
window.Visible = false
window.ZIndex = 20
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04, 0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(100, 80, 40); wStroke.Parent = window
window.Parent = gui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.12)
title.Position = UDim2.fromScale(0, 0.02)
title.Text = "🏪  SHOP"
title.Font = Enum.Font.GothamBlack; title.TextScaled = true
title.BackgroundTransparency = 1; title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.ZIndex = 21; title.Parent = window

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.fromScale(0.92, 0.02)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60); closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.ZIndex = 21
local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0.2, 0); cCorner.Parent = closeBtn
closeBtn.Parent = window

-- Items Container
local itemsFrame = Instance.new("ScrollingFrame")
itemsFrame.Size = UDim2.fromScale(0.9, 0.7)
itemsFrame.Position = UDim2.fromScale(0.05, 0.18)
itemsFrame.BackgroundTransparency = 1
itemsFrame.ScrollBarThickness = 6
itemsFrame.CanvasSize = UDim2.fromScale(0, 0)
itemsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemsFrame.ZIndex = 21
itemsFrame.Parent = window

local itemsLayout = Instance.new("UIListLayout")
itemsLayout.Padding = UDim.new(0.02, 0)
itemsLayout.Parent = itemsFrame

-- Coin Display
local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.fromScale(0.9, 0.08)
coinLabel.Position = UDim2.fromScale(0.05, 0.9)
coinLabel.Text = "Coins: 0"
coinLabel.Font = Enum.Font.GothamBold; coinLabel.TextScaled = true
coinLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.ZIndex = 21
local clCorner = Instance.new("UICorner"); clCorner.CornerRadius = UDim.new(0.1, 0); clCorner.Parent = coinLabel
coinLabel.Parent = window

-- ⚙️ SHOP ITEMS (Add more here!)
local SHOP_ITEMS = {
	{
		Id = "LuckPotion",
		Name = "x2 Luck Potion",
		Description = "Doubles your luck for 5 minutes!",
		Price = 100000,
		Color = Color3.fromRGB(100, 200, 255),
		Icon = "🍀"
	},
	{
		Id = "CoinBoost",
		Name = "x2 Coins Boost",
		Description = "Doubles all coin rewards for 5 minutes!",
		Price = 200000,
		Color = Color3.fromRGB(255, 200, 0),
		Icon = "💰"
	}
}

-- Create item cards
local function createItemCard(item)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 0.3)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	card.BackgroundTransparency = 0.2
	card.ZIndex = 21
	local cardCorner = Instance.new("UICorner"); cardCorner.CornerRadius = UDim.new(0.05, 0); cardCorner.Parent = card
	local cardStroke = Instance.new("UIStroke"); cardStroke.Thickness = 2; cardStroke.Color = item.Color; cardStroke.Transparency = 0.5; cardStroke.Parent = card

	-- Name & Description
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(0.7, 0.5)
	nameLabel.Position = UDim2.fromScale(0.05, 0.1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.Icon .. " " .. item.Name
	nameLabel.Font = Enum.Font.GothamBlack; nameLabel.TextScaled = true
	nameLabel.TextColor3 = item.Color; nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 22; nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.fromScale(0.7, 0.3)
	descLabel.Position = UDim2.fromScale(0.05, 0.55)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = item.Description
	descLabel.Font = Enum.Font.Gotham; descLabel.TextScaled = true
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180); descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 22; descLabel.Parent = card

	-- Price & Buy Button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.fromOffset(120, 50)
	buyBtn.Position = UDim2.fromScale(0.72, 0.25)
	buyBtn.Text = "Buy\n" .. tostring(item.Price)
	buyBtn.Font = Enum.Font.GothamBold; buyBtn.TextScaled = true
	buyBtn.BackgroundColor3 = item.Color; buyBtn.TextColor3 = Color3.fromRGB(20,20,20)
	buyBtn.ZIndex = 22
	local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.1, 0); bCorner.Parent = buyBtn
	buyBtn.Parent = card

	-- Purchase logic
	buyBtn.MouseButton1Click:Connect(function()
		buyBtn.Text = "..."
		local success, message = PurchaseItemFunction:InvokeServer(item.Id)
		if success then
			buyBtn.Text = "✓ Bought!"
			buyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		else
			buyBtn.Text = "✗ Failed"
			buyBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		end
		task.wait(1.5)
		buyBtn.Text = "Buy\n" .. tostring(item.Price)
		buyBtn.BackgroundColor3 = item.Color
	end)

	return card
end

for _, item in ipairs(SHOP_ITEMS) do
	createItemCard(item).Parent = itemsFrame
end

-- Update coin display
local function updateCoins(stats)
	if stats and stats.Coins then
		coinLabel.Text = "💰 Coins: " .. tostring(stats.Coins)
	end
end

StatsUpdatedEvent.OnClientEvent:Connect(updateCoins)
task.spawn(function() updateCoins(GetStatsFunction:InvokeServer()) end)

-- Open/Close logic
local isOpen = false
ShopOpenEvent.OnClientEvent:Connect(function()
	isOpen = true
	window.Visible = true
	window.Size = UDim2.fromOffset(0, 0)
	TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(500, 400)
	}):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
	isOpen = false
	TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0)
	}):Play()
	task.wait(0.2)
	window.Visible = false
end)

print("ShopUI loaded! (Press E near ShopDealler)")
]==]


-- ═══ 2. BOOST GUI (Bottom Left) ═══
local boostScript = Instance.new("LocalScript")
boostScript.Name = "BoostGUI"
boostScript.Parent = SPS
boostScript.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BoostUpdateEvent = Remotes:WaitForChild("BoostUpdateEvent")

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "BoostGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "BoostGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 18
gui.Parent = playerGui

-- Main Container (Bottom Left)
local container = Instance.new("Frame")
container.AnchorPoint = Vector2.new(0, 1)
container.Size = UDim2.fromOffset(180, 90)
container.Position = UDim2.fromScale(0.02, 0.95)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
container.BackgroundTransparency = 0.2
container.ZIndex = 15
local conCorner = Instance.new("UICorner"); conCorner.CornerRadius = UDim.new(0.1, 0); conCorner.Parent = container
local conStroke = Instance.new("UIStroke"); conStroke.Thickness = 2; conStroke.Color = Color3.fromRGB(255, 215, 0); conStroke.Transparency = 0.5; conStroke.Parent = container
container.Parent = gui

-- Icon (Coin/Potion)
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromOffset(50, 50)
icon.Position = UDim2.fromScale(0.05, 0.15)
icon.Text = "💰"
icon.Font = Enum.Font.GothamBlack; icon.TextScaled = true
icon.BackgroundTransparency = 1
icon.ZIndex = 16; icon.Parent = container

-- Multiplier Text
local multiplierText = Instance.new("TextLabel")
multiplierText.Size = UDim2.fromOffset(100, 40)
multiplierText.Position = UDim2.fromScale(0.4, 0.1)
multiplierText.Text = "x1"
multiplierText.Font = Enum.Font.GothamBlack; multiplierText.TextScaled = true
multiplierText.BackgroundTransparency = 1
multiplierText.TextColor3 = Color3.fromRGB(255, 215, 0)
multiplierText.ZIndex = 16; multiplierText.Parent = container

-- Timer Text
local timerText = Instance.new("TextLabel")
timerText.Size = UDim2.fromOffset(120, 25)
timerText.Position = UDim2.fromScale(0.15, 0.65)
timerText.Text = ""
timerText.Font = Enum.Font.GothamBold; timerText.TextScaled = true
timerText.BackgroundTransparency = 1
timerText.TextColor3 = Color3.fromRGB(200, 200, 200)
timerText.ZIndex = 16; timerText.Parent = container

-- State tracking
local activeBoosts = {}

-- Format seconds to MM:SS
local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

-- Update the GUI based on active boosts
local function updateDisplay()
	local coinBoost = activeBoosts["CoinMultiplier"]
	local luckBoost = activeBoosts["LuckMultiplier"]

	if coinBoost and coinBoost.Remaining > 0 then
		-- Show Coin Boost
		icon.Text = "💰"
		multiplierText.Text = "x" .. tostring(coinBoost.Value)
		multiplierText.TextColor3 = Color3.fromRGB(255, 215, 0)
		conStroke.Color = Color3.fromRGB(255, 215, 0)
		timerText.Text = formatTime(coinBoost.Remaining)
		timerText.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif luckBoost and luckBoost.Remaining > 0 then
		-- Show Luck Boost
		icon.Text = "🍀"
		multiplierText.Text = "x" .. tostring(luckBoost.Value)
		multiplierText.TextColor3 = Color3.fromRGB(100, 200, 255)
		conStroke.Color = Color3.fromRGB(100, 200, 255)
		timerText.Text = formatTime(luckBoost.Remaining)
		timerText.TextColor3 = Color3.fromRGB(100, 200, 255)
	else
		-- Default State
		icon.Text = "💰"
		multiplierText.Text = "x1"
		multiplierText.TextColor3 = Color3.fromRGB(150, 150, 150)
		conStroke.Color = Color3.fromRGB(80, 80, 80)
		timerText.Text = ""
	end
end

-- Listen for boost updates from server
BoostUpdateEvent.OnClientEvent:Connect(function(boostData)
	activeBoosts = boostData or {}
	updateDisplay()
end)

-- Live countdown timer
task.spawn(function()
	while true do
		task.wait(1)
		local changed = false
		for boostType, data in pairs(activeBoosts) do
			if data.Remaining > 0 then
				data.Remaining = data.Remaining - 1
				if data.Remaining <= 0 then
					data.Remaining = 0
					changed = true
				end
			end
		end
		updateDisplay()
	end
end)

print("BoostGUI loaded! (Bottom Left)")
]==]

print("✅ SHOP UI + BOOST GUI DEPLOYED!")
print("🛒 Shop opens when pressing E on the NPC!")
print("🧪 Boost GUI shows in bottom left with live countdown!")
