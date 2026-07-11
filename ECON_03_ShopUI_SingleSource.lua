-- ═══════════════════════════════════════════════════════════
-- 🛒  ECONOMY STEP 3 — SHOP UI  (reads ShopData + 1K prices)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Replaces:  StarterPlayerScripts ▸ ShopUI  (LocalScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   • Shop window now READS items straight from ShopData (single source!).
--   • Prices + your coin count show as "10K", "25K", etc.
--   • Boost GUI is untouched (kept as-is).
--   Run AFTER ECON_01 (ShopData) and ECON_02 (GameServer sync).
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local oldShop = SPS:FindFirstChild("ShopUI"); if oldShop then oldShop:Destroy() end
task.wait(0.1)

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

-- 📚 Read items + number formatter from ShopData (single source of truth)
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))
local function abbr(n) return ShopData.Abbreviate(n) end

-- Build an ordered list from ShopData.Items (dict)
local SHOP_ITEMS = {}
for id, cfg in pairs(ShopData.Items) do
	table.insert(SHOP_ITEMS, {
		Id = id,
		Name = cfg.DisplayName or cfg.Name or id,
		Description = cfg.Description or "",
		Price = cfg.Price or 0,
		Color = cfg.Color or Color3.fromRGB(120,120,140),
		Icon = cfg.Icon or "🧪",
	})
end
table.sort(SHOP_ITEMS, function(a, b) return a.Price < b.Price end)

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "ShopGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 25
gui.Parent = playerGui

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Size = UDim2.fromOffset(500, 400)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
window.BackgroundTransparency = 0.05
window.Visible = false
window.ZIndex = 20
Instance.new("UICorner", window).CornerRadius = UDim.new(0.04, 0)
local wStroke = Instance.new("UIStroke", window); wStroke.Thickness = 2
wStroke.Color = Color3.fromRGB(100, 80, 40)
window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.12); title.Position = UDim2.fromScale(0, 0.02)
title.Text = "🏪  SHOP"; title.Font = Enum.Font.GothamBlack; title.TextScaled = true
title.BackgroundTransparency = 1; title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.ZIndex = 21; title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(40, 40); closeBtn.Position = UDim2.fromScale(0.92, 0.02)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60); closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.ZIndex = 21
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.2, 0)
closeBtn.Parent = window

local itemsFrame = Instance.new("ScrollingFrame")
itemsFrame.Size = UDim2.fromScale(0.9, 0.7); itemsFrame.Position = UDim2.fromScale(0.05, 0.18)
itemsFrame.BackgroundTransparency = 1; itemsFrame.ScrollBarThickness = 6
itemsFrame.CanvasSize = UDim2.fromScale(0, 0); itemsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemsFrame.ZIndex = 21; itemsFrame.Parent = window
local itemsLayout = Instance.new("UIListLayout", itemsFrame); itemsLayout.Padding = UDim.new(0.02, 0)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.fromScale(0.9, 0.08); coinLabel.Position = UDim2.fromScale(0.05, 0.9)
coinLabel.Text = "💰 Coins: 0"; coinLabel.Font = Enum.Font.GothamBold; coinLabel.TextScaled = true
coinLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45); coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.ZIndex = 21
Instance.new("UICorner", coinLabel).CornerRadius = UDim.new(0.1, 0)
coinLabel.Parent = window

local function createItemCard(item)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 0.3)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 45); card.BackgroundTransparency = 0.2; card.ZIndex = 21
	Instance.new("UICorner", card).CornerRadius = UDim.new(0.05, 0)
	local cardStroke = Instance.new("UIStroke", card); cardStroke.Thickness = 2
	cardStroke.Color = item.Color; cardStroke.Transparency = 0.5

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(0.7, 0.5); nameLabel.Position = UDim2.fromScale(0.05, 0.1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.Icon .. " " .. item.Name
	nameLabel.Font = Enum.Font.GothamBlack; nameLabel.TextScaled = true
	nameLabel.TextColor3 = item.Color; nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 22; nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.fromScale(0.7, 0.3); descLabel.Position = UDim2.fromScale(0.05, 0.55)
	descLabel.BackgroundTransparency = 1; descLabel.Text = item.Description
	descLabel.Font = Enum.Font.Gotham; descLabel.TextScaled = true
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180); descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 22; descLabel.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.fromOffset(120, 50); buyBtn.Position = UDim2.fromScale(0.72, 0.25)
	buyBtn.Text = "Buy\n" .. abbr(item.Price) .. " 🪙"
	buyBtn.Font = Enum.Font.GothamBold; buyBtn.TextScaled = true
	buyBtn.BackgroundColor3 = item.Color; buyBtn.TextColor3 = Color3.fromRGB(20,20,20)
	buyBtn.ZIndex = 22
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0.1, 0)
	buyBtn.Parent = card

	buyBtn.MouseButton1Click:Connect(function()
		buyBtn.Text = "..."
		local success = PurchaseItemFunction:InvokeServer(item.Id)
		if success then
			buyBtn.Text = "✓ Bought!"; buyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		else
			buyBtn.Text = "✗ Failed"; buyBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		end
		task.wait(1.5)
		buyBtn.Text = "Buy\n" .. abbr(item.Price) .. " 🪙"; buyBtn.BackgroundColor3 = item.Color
	end)
	return card
end

for _, item in ipairs(SHOP_ITEMS) do
	createItemCard(item).Parent = itemsFrame
end

local function updateCoins(stats)
	if stats and stats.Coins then
		coinLabel.Text = "💰 Coins: " .. abbr(stats.Coins)
	end
end
StatsUpdatedEvent.OnClientEvent:Connect(updateCoins)
task.spawn(function() updateCoins(GetStatsFunction:InvokeServer()) end)

ShopOpenEvent.OnClientEvent:Connect(function()
	window.Visible = true; window.Size = UDim2.fromOffset(0, 0)
	TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(500, 400) }):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
	TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(0, 0) }):Play()
	task.wait(0.2); window.Visible = false
end)

print("ShopUI loaded! (reads ShopData + 1K prices)")
]==]

print("✅ STEP 3 done! ShopUI now reads from ShopData with abbreviated prices.")
print("   💡 BoostGUI was left untouched — no need to redo it.")
