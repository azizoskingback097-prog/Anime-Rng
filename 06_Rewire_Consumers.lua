-- ═══════════════════════════════════════════════════════════
-- 🔁  SYS2 #6 — REWIRE CONSUMERS to NumberFormatter + canonical ShopData
-- Paste in:  View ▸ Command Bar   →   Enter
-- Redeploys:  CoinUI, ShopUI  (FlexText + DialogueUI patched via #6b)
-- ═══════════════════════════════════════════════════════════
-- 📝 Makes the shared NumberFormatter the ONE source for number text.
--    Run AFTER #1 (NumberFormatter) and #2 (ShopData canonical).
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- ═══ COIN HUD ═══
local oldCoin = SPS:FindFirstChild("CoinUI"); if oldCoin then oldCoin:Destroy() end
task.wait(0.1)
local coinScript = Instance.new("LocalScript")
coinScript.Name = "CoinUI"
coinScript.Parent = SPS
coinScript.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local F = require(ReplicatedStorage:WaitForChild("NumberFormatter"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinRewardEvent = Remotes:WaitForChild("CoinRewardEvent")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "CoinUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15
gui.Parent = playerGui

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

local function updateHud(coins) hudText.Text = F.FormatNumber(coins) .. " 🪙" end
StatsUpdatedEvent.OnClientEvent:Connect(function(stats)
	if stats and stats.Coins then updateHud(stats.Coins) end
end)
task.spawn(function()
	local stats = GetStatsFunction:InvokeServer()
	if stats and stats.Coins then updateHud(stats.Coins) end
end)

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
	rewardText.Text = prefix .. " " .. F.FormatNumber(amount) .. " 🪙"
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

print("CoinUI loaded! (NumberFormatter) 🪙")
]==]

-- ═══ SHOP UI ═══
local oldShop = SPS:FindFirstChild("ShopUI"); if oldShop then oldShop:Destroy() end
task.wait(0.1)
local shopScript = Instance.new("LocalScript")
shopScript.Name = "ShopUI"
shopScript.Parent = SPS
shopScript.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local F = require(ReplicatedStorage:WaitForChild("NumberFormatter"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")
local PurchaseItemFunction = Remotes:WaitForChild("PurchaseItemFunction")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

-- 📚 items come from ShopData (single source of truth)
local SHOP_ITEMS
pcall(function()
	local SD = require(ReplicatedStorage:WaitForChild("ShopData"))
	SHOP_ITEMS = SD.GetDisplayItems and SD.GetDisplayItems()
end)
if not SHOP_ITEMS or #SHOP_ITEMS == 0 then
	SHOP_ITEMS = {
		{ Id="LuckPotion", Name="x2 Luck Potion", Description="Doubles luck for 5 min.", Price=10000, PriceText="10K", Color=Color3.fromRGB(120,200,120), Icon="🍀" },
		{ Id="CoinBoost", Name="x2 Coins Boost", Description="Doubles coins for 5 min.", Price=25000, PriceText="25K", Color=Color3.fromRGB(255,200,80), Icon="💰" },
	}
end

for _, c in ipairs(playerGui:GetChildren()) do if c.Name == "ShopGui" then c:Destroy() end end
local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 25
gui.Parent = playerGui

local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Size = UDim2.fromOffset(500, 400); window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 30); window.BackgroundTransparency = 0.05
window.Visible = false; window.ZIndex = 20
Instance.new("UICorner", window).CornerRadius = UDim.new(0.04, 0)
local wStroke = Instance.new("UIStroke", window); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(100, 80, 40)
window.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.12); title.Position = UDim2.fromScale(0, 0.02)
title.Text = "🏪  SHOP"; title.Font = Enum.Font.GothamBlack; title.TextScaled = true
title.BackgroundTransparency = 1; title.TextColor3 = Color3.fromRGB(255, 215, 0); title.ZIndex = 21
title.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(40, 40); closeBtn.Position = UDim2.fromScale(0.92, 0.02)
closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60); closeBtn.TextColor3 = Color3.fromRGB(255,255,255); closeBtn.ZIndex = 21
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
coinLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45); coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0); coinLabel.ZIndex = 21
Instance.new("UICorner", coinLabel).CornerRadius = UDim.new(0.1, 0)
coinLabel.Parent = window

local function createCard(item)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 0.3)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 45); card.BackgroundTransparency = 0.2; card.ZIndex = 21
	Instance.new("UICorner", card).CornerRadius = UDim.new(0.05, 0)
	local st = Instance.new("UIStroke", card); st.Thickness = 2; st.Color = item.Color; st.Transparency = 0.5

	local n = Instance.new("TextLabel")
	n.Size = UDim2.fromScale(0.7, 0.5); n.Position = UDim2.fromScale(0.05, 0.1); n.BackgroundTransparency = 1
	n.Text = item.Icon .. " " .. item.Name; n.Font = Enum.Font.GothamBlack; n.TextScaled = true
	n.TextColor3 = item.Color; n.TextXAlignment = Enum.TextXAlignment.Left; n.ZIndex = 22; n.Parent = card

	local d = Instance.new("TextLabel")
	d.Size = UDim2.fromScale(0.7, 0.3); d.Position = UDim2.fromScale(0.05, 0.55); d.BackgroundTransparency = 1
	d.Text = item.Description; d.Font = Enum.Font.Gotham; d.TextScaled = true
	d.TextColor3 = Color3.fromRGB(180, 180, 180); d.TextXAlignment = Enum.TextXAlignment.Left; d.ZIndex = 22; d.Parent = card

	local buy = Instance.new("TextButton")
	buy.Size = UDim2.fromOffset(120, 50); buy.Position = UDim2.fromScale(0.72, 0.25)
	buy.Text = "Buy\n" .. (item.PriceText or F.FormatNumber(item.Price)) .. " 🪙"
	buy.Font = Enum.Font.GothamBold; buy.TextScaled = true
	buy.BackgroundColor3 = item.Color; buy.TextColor3 = Color3.fromRGB(20,20,20); buy.ZIndex = 22
	Instance.new("UICorner", buy).CornerRadius = UDim.new(0.1, 0); buy.Parent = card

	buy.MouseButton1Click:Connect(function()
		buy.Text = "..."
		local ok = PurchaseItemFunction:InvokeServer(item.Id)
		if ok then buy.Text = "✓ Bought!"; buy.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		else buy.Text = "✗ Failed"; buy.BackgroundColor3 = Color3.fromRGB(200, 60, 60) end
		task.wait(1.5)
		buy.Text = "Buy\n" .. (item.PriceText or F.FormatNumber(item.Price)) .. " 🪙"; buy.BackgroundColor3 = item.Color
	end)
	return card
end
for _, item in ipairs(SHOP_ITEMS) do createCard(item).Parent = itemsFrame end

local function updateCoins(stats)
	if stats and stats.Coins then coinLabel.Text = "💰 Coins: " .. F.FormatNumber(stats.Coins) end
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

print("ShopUI loaded! (NumberFormatter + canonical ShopData)")
]==]

print("✅ CoinUI + ShopUI rewired to NumberFormatter.")
print("   Run SYS2 #6b to patch FlexText + DialogueUI odds/prices.")
