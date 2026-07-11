-- ═══════════════════════════════════════════════════════════
-- 🎯 ALL-IN-ONE DIALOGUE SYSTEM (No Server Needed!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- 1. DELETE OLD SCRIPTS
local oldS = SSS:FindFirstChild("NPCShopServer"); if oldS then oldS:Destroy() end
local oldC = SPS:FindFirstChild("DialogueUI"); if oldC then oldC:Destroy() end
task.wait(0.1)

-- Ensure Remotes exist just in case ShopUI needs them
local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder", RS)
remotes.Name = "Remotes"
if not remotes:FindFirstChild("ShopOpenEvent") then Instance.new("RemoteEvent", remotes).Name = "ShopOpenEvent" end

-- 2. INSTALL THE NEW ALL-IN-ONE SCRIPT
local s = Instance.new("LocalScript")
s.Name = "DialogueUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- ⚙️ CUSTOMIZATION CONFIG
local CONFIG = {
	TextSizeX = 280,
	TextSizeY = 35,
	Font = Enum.Font.FredokaOne,
	TextColor = Color3.fromRGB(255, 255, 255),
	HoverColor = Color3.fromRGB(255, 235, 100),
	StrokeColor = Color3.fromRGB(0, 0, 0),
}

-- DIALOGUE TEXTS
local GREETINGS = { "Hello, traveler!", "Welcome to my shop!", "Ah, a new face!", "Come, come! Don't be shy!" }
local STORY_RESPONSES = { "I've traveled these lands for decades...", "Long ago, I was an adventurer like you!", "This shop has been in my family for generations." }
local NEVERMIND_RESPONSES = { "Farewell, traveler!", "Safe journeys, friend!", "Until we meet again!" }
local SHOP_OPEN_LINE = "Here, take a look!"

local CHOICES = {
	{ Text = "Open Shop", Action = "OpenShop" },
	{ Text = "Ask About Story", Action = "Story" },
	{ Text = "Nevermind", Action = "Nevermind" }
}

-- Find NPC
local npc = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("ShopDealler") or Workspace:FindFirstChild("ShopDealler")
if not npc then warn("❌ ShopDealler NPC not found!") return end

local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
if not head then return end

local humanoid = npc:FindFirstChildOfClass("Humanoid")
local promptPart = humanoid and humanoid.RootPart or npc.PrimaryPart or head

-- Clean old instances
local oldBB = head:FindFirstChild("DialogueGui"); if oldBB then oldBB:Destroy() end
local oldPrompt = promptPart:FindFirstChildOfClass("ProximityPrompt"); if oldPrompt then oldPrompt:Destroy() end
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RightDialogueGui" then c:Destroy() end
end

-- 1. CREATE BILLBOARD GUI ON NPC
local billboard = Instance.new("BillboardGui", head)
billboard.Name = "DialogueGui"
billboard.Size = UDim2.fromOffset(260, 60)
billboard.StudsOffset = Vector3.new(0, 3.2, 0)
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.MaxDistance = 20
billboard.Enabled = false

local npcLabel = Instance.new("TextLabel", billboard)
npcLabel.Size = UDim2.fromScale(1, 1)
npcLabel.BackgroundTransparency = 1
npcLabel.Font = CONFIG.Font
npcLabel.TextColor3 = CONFIG.TextColor
npcLabel.TextStrokeTransparency = 0
npcLabel.TextStrokeColor3 = CONFIG.StrokeColor
npcLabel.TextScaled = true
npcLabel.TextWrapped = true

local npcScale = Instance.new("UIScale", npcLabel)
npcScale.Scale = 0

local function showNpcText(text, duration)
	npcLabel.Text = text
	billboard.Enabled = true
	npcScale.Scale = 0
	TweenService:Create(npcScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	if duration then
		task.delay(duration, function()
			TweenService:Create(npcScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
			task.delay(0.25, function() billboard.Enabled = false end)
		end)
	end
end

-- 2. CREATE PROXIMITY PROMPT
local prompt = Instance.new("ProximityPrompt", promptPart)
prompt.ActionText = "Talk"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 8

-- 3. CREATE SCREEN GUI (Right Side)
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "RightDialogueGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 25

local container = Instance.new("Frame", gui)
container.AnchorPoint = Vector2.new(1, 0.5)
container.Size = UDim2.fromOffset(300, 250)
container.Position = UDim2.fromScale(0.98, 0.5)
container.BackgroundTransparency = 1
container.Visible = false

local listLayout = Instance.new("UIListLayout", container)
listLayout.Padding = UDim.new(0, 8)
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local npcText = Instance.new("TextLabel", container)
npcText.Size = UDim2.fromOffset(CONFIG.TextSizeX, CONFIG.TextSizeY)
npcText.BackgroundTransparency = 1
npcText.Font = CONFIG.Font
npcText.TextColor3 = CONFIG.TextColor
npcText.TextStrokeColor3 = CONFIG.StrokeColor
npcText.TextStrokeTransparency = 0
npcText.TextScaled = true
npcText.TextWrapped = true
npcText.TextXAlignment = Enum.TextXAlignment.Right
local npcTextScale = Instance.new("UIScale", npcText)
npcTextScale.Scale = 0

local function createChoiceButton(index, choiceData)
	local btn = Instance.new("TextButton", container)
	btn.Size = UDim2.fromOffset(CONFIG.TextSizeX - 20, CONFIG.TextSizeY)
	btn.BackgroundTransparency = 1
	btn.Text = "#" .. index .. " [" .. choiceData.Text .. "]"
	btn.Font = CONFIG.Font
	btn.TextScaled = true
	btn.TextColor3 = CONFIG.TextColor
	btn.TextStrokeColor3 = CONFIG.StrokeColor
	btn.TextStrokeTransparency = 0
	btn.AutoButtonColor = false
	btn.TextXAlignment = Enum.TextXAlignment.Right

	local scale = Instance.new("UIScale", btn)
	scale.Scale = 0

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { TextColor3 = CONFIG.HoverColor }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { TextColor3 = CONFIG.TextColor }):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		TweenService:Create(npcTextScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.wait(0.2)
		container.Visible = false
		
		-- HANDLE ACTION LOCALLY!
		if choiceData.Action == "OpenShop" then
			showNpcText(SHOP_OPEN_LINE, 3)
			local ShopOpenEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ShopOpenEvent")
			if ShopOpenEvent then
				ShopOpenEvent:FireClient(player) -- Open the shop UI
			end
		elseif choiceData.Action == "Story" then
			showNpcText(STORY_RESPONSES[math.random(1, #STORY_RESPONSES)], 5)
		elseif choiceData.Action == "Nevermind" then
			showNpcText(NEVERMIND_RESPONSES[math.random(1, #NEVERMIND_RESPONSES)], 3)
		end
	end)
	return scale
end

local function showDialogue(npcMessage, choices)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	npcText.Text = npcMessage

	local scales = {}
	for i, choiceData in ipairs(choices) do
		table.insert(scales, createChoiceButton(i, choiceData))
	end

	container.Visible = true
	npcTextScale.Scale = 0
	local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(npcTextScale, info, { Scale = 1 }):Play()

	for i, scale in ipairs(scales) do
		task.delay(0.1 + ((i - 1) * 0.06), function()
			TweenService:Create(scale, info, { Scale = 1 }):Play()
		end)
	end
end

-- 4. CONNECT PROMPT
prompt.Triggered:Connect(function()
	local greeting = GREETINGS[math.random(1, #GREETINGS)]
	showNpcText(greeting, 10)
	showDialogue(greeting, CHOICES)
end)

print("✅ All-In-One Dialogue UI loaded successfully!")
]==]

print("✅ ALL-IN-ONE DIALOGUE SYSTEM INSTALLED!")
print("🎯 Everything runs in one place now. No more communication errors!")
