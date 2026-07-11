-- ═══════════════════════════════════════════════════════════
-- 💰  ECONOMY STEP 4 — COIN HUD  (1K formatting)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Replaces:  StarterPlayerScripts ▸ CoinUI  (LocalScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 Same Coin HUD you have now (permanent counter + reward pop-up),
--    but coins show as "1.5K", "25K", "1.2M" instead of long numbers.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("CoinUI"); if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "CoinUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CoinRewardEvent = Remotes:WaitForChild("CoinRewardEvent")
local GetStatsFunction = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

-- 🔢 Shared number formatter from ShopData (1000 → "1K")
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))
local function abbr(n) return ShopData.Abbreviate(n) end

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

print("CoinUI loaded! (1K formatting) 🪙")
]==]

print("✅ STEP 4 done! Coin HUD now shows 1K / 1.5M style numbers.")
