-- ═══════════════════════════════════════════════════════════
-- 💬 DIALOGUE UI (3 Options: Shop, Story, Nevermind)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("DialogueUI")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "DialogueUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DialogueEvent = Remotes:WaitForChild("DialogueEvent")

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "DialogueGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "DialogueGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 22
gui.Parent = playerGui

-- Main Window
local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 1)
window.Size = UDim2.fromOffset(500, 250)
window.Position = UDim2.fromScale(0.5, 0.92)
window.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
window.BackgroundTransparency = 0.05
window.Visible = false
window.ZIndex = 20
local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.05, 0); wCorner.Parent = window
local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = Color3.fromRGB(100, 80, 40); wStroke.Parent = window
window.Parent = gui

-- NPC Text (Greeting)
local npcText = Instance.new("TextLabel")
npcText.Size = UDim2.fromScale(0.9, 0.4)
npcText.Position = UDim2.fromScale(0.05, 0.05)
npcText.BackgroundTransparency = 1
npcText.Text = ""
npcText.Font = Enum.Font.GothamBold; npcText.TextScaled = true
npcText.TextColor3 = Color3.fromRGB(255, 255, 255)
npcText.TextWrapped = true
npcText.ZIndex = 21; npcText.Parent = window

-- Options Container
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.fromScale(0.9, 0.45)
optionsFrame.Position = UDim2.fromScale(0.05, 0.5)
optionsFrame.BackgroundTransparency = 1
optionsFrame.ZIndex = 21
optionsFrame.Parent = window

local optionsLayout = Instance.new("UIListLayout")
optionsLayout.Padding = UDim.new(0.05, 0)
optionsLayout.Parent = optionsFrame

-- Button Factory
local function createButton(text, color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 0.28)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold; btn.TextScaled = true
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.ZIndex = 22
	local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.1, 0); bCorner.Parent = btn
	return btn
end

-- Create 3 buttons
local shopBtn = createButton("🏪 Open Shop", Color3.fromRGB(80, 150, 80))
shopBtn.Parent = optionsFrame

local storyBtn = createButton("📖 Ask About His Story", Color3.fromRGB(100, 120, 180))
storyBtn.Parent = optionsFrame

local neverBtn = createButton("🚶 Nevermind", Color3.fromRGB(120, 70, 70))
neverBtn.Parent = optionsFrame

-- Open dialogue
local function openDialogue(data)
	npcText.Text = data.Greeting or "Hello!"
	window.Visible = true
	window.Size = UDim2.fromOffset(500, 0)
	TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(500, 250)
	}):Play()
end

-- Close dialogue
local function closeDialogue()
	TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(500, 0)
	}):Play()
	task.wait(0.2)
	window.Visible = false
end

-- Listen for dialogue from server
DialogueEvent.OnClientEvent:Connect(function(data)
	openDialogue(data)
end)

-- Button Actions
shopBtn.MouseButton1Click:Connect(function()
	closeDialogue()
	DialogueEvent:FireServer("OpenShop")
end)

storyBtn.MouseButton1Click:Connect(function()
	-- Keep window open but update text
	local responses = { "Let me tell you a story..." }
	-- We'll just fire the event and let server send a new greeting
	closeDialogue()
	DialogueEvent:FireServer("Story")
end)

neverBtn.MouseButton1Click:Connect(function()
	closeDialogue()
	DialogueEvent:FireServer("Nevermind")
end)

print("DialogueUI loaded! (3 Options: Shop, Story, Nevermind)")
]==]

print("✅ DIALOGUE UI INSTALLED!")
print("💬 3 buttons appear when talking to NPC!")
