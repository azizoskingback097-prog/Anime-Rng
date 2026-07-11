-- ═══════════════════════════════════════════════════════════
-- 💰 COIN HUD FIX (Permanent Counter + Animation)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("CoinUI")
if old then old:Destroy() end
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

local gui = Instance.new("ScreenGui")
gui.Name = "CoinUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15
gui.Parent = playerGui

-- 1. PERMANENT HUD COUNTER (Top Center)
local hudFrame = Instance.new("Frame")
hudFrame.AnchorPoint = Vector2.new(0.5, 0.5)
hudFrame.Size = UDim2.fromOffset(220, 55)
hudFrame.Position = UDim2.fromScale(0.5, 0.08)
hudFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hudFrame.BackgroundTransparency = 0.3
hudFrame.BorderSizePixel = 0
hudFrame.ZIndex = 10
local hudCorner = Instance.new("UICorner"); hudCorner.CornerRadius = UDim.new(0.2, 0); hudCorner.Parent = hudFrame
local hudStroke = Instance.new("UIStroke"); hudStroke.Thickness = 2; hudStroke.Color = Color3.fromRGB(255, 215, 0); hudStroke.Parent = hudFrame
hudFrame.Parent = gui

local hudText = Instance.new("TextLabel")
hudText.Size = UDim2.fromScale(1, 1)
hudText.BackgroundTransparency = 1
hudText.Text = "0 Coins"
hudText.Font = Enum.Font.GothamBlack
hudText.TextScaled = true
hudText.TextColor3 = Color3.fromRGB(255, 215, 0)
hudText.ZIndex = 11
local hudPadding = Instance.new("UIPadding"); hudPadding.PaddingLeft = UDim.new(0, 15); hudPadding.PaddingRight = UDim.new(0, 15); hudPadding.Parent = hudText
hudText.Parent = hudFrame

-- Update HUD from Server Stats
local function updateHud(coins)
	hudText.Text = tostring(coins) .. " Coins"
end

StatsUpdatedEvent.OnClientEvent:Connect(function(stats)
	if stats and stats.Coins then
		updateHud(stats.Coins)
	end
end)

-- Load initial stats
task.spawn(function()
	local stats = GetStatsFunction:InvokeServer()
	if stats and stats.Coins then
		updateHud(stats.Coins)
	end
end)

-- 2. REWARD ANIMATION (Pop-up)
local rewardText = Instance.new("TextLabel")
rewardText.AnchorPoint = Vector2.new(0.5, 0.5)
rewardText.Size = UDim2.fromOffset(300, 50)
rewardText.Position = UDim2.fromScale(0.5, 0.17)
rewardText.Text = "+0 Coins"
rewardText.Font = Enum.Font.GothamBlack
rewardText.TextScaled = true
rewardText.BackgroundTransparency = 1
rewardText.TextColor3 = Color3.fromRGB(255, 255, 255)
rewardText.TextTransparency = 1
rewardText.ZIndex = 20
rewardText.Parent = gui

CoinRewardEvent.OnClientEvent:Connect(function(info)
	local amount = info.Amount
	local isMutated = info.Mutated
	
	local prefix = isMutated and "✨ + " or "+ "
	rewardText.Text = prefix .. amount .. " Coins"
	
	if isMutated then
		rewardText.TextColor3 = Color3.fromRGB(180, 100, 255)
	else
		rewardText.TextColor3 = Color3.fromRGB(255, 215, 0)
	end
	
	rewardText.TextTransparency = 1
	rewardText.Position = UDim2.fromScale(0.5, 0.20)
	
	-- Pop in
	TweenService:Create(rewardText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		Position = UDim2.fromScale(0.5, 0.15)
	}):Play()
	
	-- Bump the HUD Counter (Squash and Stretch)
	hudFrame.Size = UDim2.fromOffset(240, 65)
	TweenService:Create(hudFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(220, 55)
	}):Play()
	
	-- Fade out
	task.delay(1.5, function()
		TweenService:Create(rewardText, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			TextTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.10)
		}):Play()
	end)
end)

print("CoinUI loaded! (Permanent HUD + Reward Animation)")
]==]

print("✅ COIN HUD FIX APPLIED! You now have a permanent counter at the top of the screen.")
