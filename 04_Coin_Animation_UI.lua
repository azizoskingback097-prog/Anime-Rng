-- ═══════════════════════════════════════════════════════════
-- 💰 COIN REWARD UI (Clean Text Animation)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Listens for CoinRewardEvent and pops up a smooth animation.
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

local gui = Instance.new("ScreenGui")
gui.Name = "CoinUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15
gui.Parent = playerGui

-- The Coin Text Label
local coinText = Instance.new("TextLabel")
coinText.AnchorPoint = Vector2.new(0.5, 0.5)
coinText.Size = UDim2.fromOffset(300, 60)
coinText.Position = UDim2.fromScale(0.85, 0.25)
coinText.Text = "+0 Coins"
coinText.Font = Enum.Font.GothamBlack
coinText.TextScaled = true
coinText.BackgroundTransparency = 1
coinText.TextColor3 = Color3.fromRGB(255, 215, 0)
coinText.TextTransparency = 1
coinText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
coinText.TextStrokeTransparency = 0.2
coinText.ZIndex = 50
coinText.Parent = gui

CoinRewardEvent.OnClientEvent:Connect(function(info)
	local amount = info.Amount
	local isMutated = info.Mutated
	
	-- Format the string (e.g., +150 Coins)
	local prefix = isMutated and "✨ + " or "+ "
	coinText.Text = prefix .. amount .. " Coins"
	
	-- Change color if mutated
	if isMutated then
		coinText.TextColor3 = Color3.fromRGB(180, 100, 255) -- Purple for mutations
	else
		coinText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold for normal
	end
	
	-- Reset state
	coinText.TextTransparency = 1
	coinText.Position = UDim2.fromScale(0.85, 0.35) -- Start lower
	
	-- Animation 1: Pop in
	TweenService:Create(coinText, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		Position = UDim2.fromScale(0.85, 0.25) -- Move up
	}):Play()
	
	-- Wait a moment
	task.delay(1.5, function()
		-- Animation 2: Fade out
		TweenService:Create(coinText, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			TextTransparency = 1,
			Position = UDim2.fromScale(0.85, 0.15) -- Continue drifting up
		}):Play()
	end)
end)

print("CoinUI loaded! (Reward Animation Active)")
]==]

print("✅ COIN UI ANIMATION APPLIED!")
