-- ═══════════════════════════════════════════════════════════
-- 💰  COIN + SHOP FIX  (bulletproof 1K formatting — no crash!)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Redeploys: StarterPlayerScripts ▸ CoinUI  AND  ShopUI
-- ═══════════════════════════════════════════════════════════
-- 🐛 THE BUG YOU HIT:
--   "attempt to call a nil value" at CoinUI:14 / ShopUI:15
--   = the scripts called ShopData.Abbreviate, but your ShopData
--     didn't have that function yet → crash on every coin update.
--
-- ✅ THE FIX:
--   The number formatter is now SELF-CONTAINED in each script.
--   It uses ShopData.Abbreviate IF available, otherwise a built-in
--   fallback copy. It can NEVER crash, no matter what. 🛡️
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS  = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════════════════════════
-- 💰  COIN HUD  (bulletproof — self-contained formatter)
-- ═══════════════════════════════════════════════════════════
local oldCoin = SPS:FindFirstChild("CoinUI"); if oldCoin then oldCoin:Destroy() end
task.wait(0.1)

local coinScript = Instance.new("LocalScript")
coinScript.Name = "CoinUI"
coinScript.Parent = SPS
coinScript.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinRewardEvent = Remotes:WaitForChild("CoinRewardEvent")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

-- 🔢 SELF-CONTAINED formatter: 1000 → "1K", 25000 → "25K", 1500000 → "1.5M"
-- Uses ShopData.Abbreviate if it exists; otherwise a built-in copy. Never crashes.
local _shopAbbrev
pcall(function() _shopAbbrev = require(ReplicatedStorage:FindFirstChild("ShopData")).Abbreviate end)
local function abbr(n)
	if _shopAbbrev then return _shopAbbrev(n) end
	n = math.floor(tonumber(n) or 0)
	if n < 0 then return "-" .. abbr(-n) end
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	while n >= 1000 and i < #suffixes do n = n / 1000; i = i + 1 end
	local s = string.format("%.2f", n):gsub("%.?0+$", "")
	return s .. suffixes[i]
end

local gui = Instance.new("ScreenGui")
gui.Name = "CoinUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15
gui.Parent = playerGui

-- 1. PERMANENT HUD COUNTER (Top Center)
local hudFrame = Instance.new("Frame")
hudFrame.AnchorPoint = Vector2.new(0.5, 0.5)
hudFrame.Size = UDim2.fromOffset(220, 55); hudFrame.Position = UDim2.fromScale(0.5, 0.08)
hudFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30); hudFrame.BackgroundTransparency = 0.3
hudFrame.BorderSizePixel = 0; hudFrame.ZIndex = 10
Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0.2, 0)
local hudStroke = Instance.new("UIStroke", hudFrame); hudStroke.Thickness = 2
hudStroke.Color = Color3.fromRGB(255, 215, 0)
hudFrame.Parent = gui

local hudText = Instance.new("TextLabel")
hudText.Size = UDim2.fromScale(1, 1); hudText.BackgroundTransparency = 1
hudText.Text = "0 🪙"; hudText.Font = Enum.Font.GothamBlack; hudText.TextScaled = true
hudText.TextColor3 = Color3.fromRGB(255, 215, 0); hudText.ZIndex = 11
local hudPad = Instance.new("UIPadding", hudText)
hudPad.PaddingLeft = UDim.new(0, 15); hudPad.PaddingRight = UDim.new(0, 15)
hudText.Parent = hudFrame

local function updateHud(coins)
	hudText.Text = abbr(coins) .. " 🪙"
end

StatsUpdatedEvent.OnClientEvent:Connect(function(stats)
	if stats and stats.Coins then updateHud(stats.Coins) end
end)
task.spawn(function()
	local stats = GetStatsFunction:InvokeServer()
	if stats and stats.Coins then updateHud(stats.Coins) end
end)

-- 2. REWARD ANIMATION (Pop-up)
local rewardText = Instance.new("TextLabel")
rewardText.AnchorPoint = Vector2.new(0.5, 0.5)
rewardText.Size = UDim2.fromOffset(300, 50); rewardText.Position = UDim2.fromScale(0.5, 0.17)
rewardText.Text = "+0 🪙"; rewardText.Font = Enum.Font.GothamBlack; rewardText.TextScaled = true
rewardText.BackgroundTransparency = 1; rewardText.TextColor3 = Color3.fromRGB(255, 255, 255)
rewardText.TextTransparency = 1; rewardText.ZIndex = 20
rewardText.Parent = gui

CoinRewardEvent.OnClientEvent:Connect(function(info)
	local amount = info.Amount or 0
	local isMutated = info.Mutated
	local prefix = isMutated and "✨ +" or "+"
	rewardText.Text = prefix .. " " .. abbr(amount) .. " 🪙"
	rewardText.TextColor3 = isMutated and Color3.fromRGB(180, 100, 255) or Color3.fromRGB(255, 215, 0)
	rewardText.TextTransparency = 1
	rewardText.Position = UDim2.fromScale(0.5, 0.20)

	TweenService:Create(rewardText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.15) }):Play()

	hudFrame.Size = UDim2.fromOffset(240, 65)
	TweenService:Create(hudFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(220, 55) }):Play()

	task.delay(1.5, function()
		TweenService:Create(rewardText, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ TextTransparency = 1, Position = UDim2.fromScale(0.5, 0.10) }):Play()
	end)
end)

print("CoinUI loaded! (1K formatting — bulletproof) 🪙")
]==]

-- ═══════════════════════════════════════════════════════════
-- 🛒  SHOP UI  (bulletproof — reads ShopData if present, fallback otherwise)
-- ═══════════════════════════════════════════════════════════
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

-- 🔢 SELF-CONTAINED formatter (same as CoinUI — never crashes)
local _shopAbbrev
local _shopItems
pcall(function()
	local SD = require(ReplicatedStorage:FindFirstChild("ShopData"))
	_shopAbbrev = SD.Abbreviate
	_shopItems = SD.Items
end)
local function abbr(n)
	if _shopAbbrev then return _shopAbbrev(n) end
	n = math.floor(tonumber(n) or 0)
	if n < 0 then return "-" .. abbr(-n) end
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	while n >= 1000 and i < #suffixes do n = n / 1000; i = i + 1 end
	local s = string.format("%.2f", n):gsub("%.?0+$", "")
	return s .. suffixes[i]
end

-- Build the item list: from ShopData if available, else a safe fallback
local SHOP_ITEMS = {}
if _shopItems then
	for id, cfg in pairs(_shopItems) do
		table.insert(SHOP_ITEMS, {
			Id = id, Name = cfg.DisplayName or cfg.Name or id,
			Description = cfg.Description or "", Price = cfg.Price or 0,
			Color = cfg.Color or Color3.fromRGB(120,120,140), Icon = cfg.Icon or "🧪",
		})
	end
else
	-- Fallback (only used if ShopData module is somehow missing)
	SHOP_ITEMS = {
		{ Id="LuckPotion", Name="x2 Luck Potion", Description="Doubles luck for 5 min.", Price=10000, Color=Color3.fromRGB(120,200,120), Icon="🍀" },
		{ Id="CoinBoost", Name="x2 Coins Boost", Description="Doubles coins for 5 min.", Price=25000, Color=Color3.fromRGB(255,200,80), Icon="💰" },
	}
end
table.sort(SHOP_ITEMS, function(a, b) return a.Price < b.Price end)

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "ShopGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 25
gui.Parent = playerGui

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Size = UDim2.fromOffset(500, 400); window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 30); window.BackgroundTransparency = 0.05
window.Visible = false; window.ZIndex = 20
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
Instance.new("UIListLayout", itemsFrame).Padding = UDim.new(0.02, 0)

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
	if stats and stats.Coins then coinLabel.Text = "💰 Coins: " .. abbr(stats.Coins) end
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

print("ShopUI loaded! (reads ShopData + bulletproof 1K prices)")
]==]

print("✅✅ COIN + SHOP FIX APPLIED!")
print("   💰 CoinUI now shows coins again (with 1K format, never crashes)")
print("   🛒 ShopUI reads ShopData prices + shows 1K (with safe fallback)")
print("   🎮 Press Play — coins should work now! 🪙")
