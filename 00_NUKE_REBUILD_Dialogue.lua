-- ═══════════════════════════════════════════════════════════
-- 💣 NUKE OLD DIALOGUE + 🆕 REBUILD GROW A GARDEN SYSTEM
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This DESTROYS all old dialogue scripts and installs:
--   • Server: NPC BillboardGui (floating text, FredokaOne, no bg)
--   • Client: Player choices (center-bottom, #1 [Option], hover yellow)
--   • Both: Bouncy pop-in animation (UIScale 0→1, Back/Out)
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- ═══ 1. NUKE EVERYTHING ═══
print("💣 Nuking old dialogue scripts...")

-- Server scripts
local oldNPC = SSS:FindFirstChild("NPCShopServer")
if oldNPC then oldNPC:Destroy(); print("🗑️ Deleted NPCShopServer") end

-- Client scripts
local oldDialogue = SPS:FindFirstChild("DialogueUI")
if oldDialogue then oldDialogue:Destroy(); print("🗑️ Deleted DialogueUI") end

-- Old ScreenGuis in StarterGui
local SG = game:GetService("StarterGui")
for _, child in ipairs(SG:GetChildren()) do
	if child.Name == "DialogueGui" then
		child:Destroy(); print("🗑️ Deleted StarterGui/DialogueGui")
	end
end

-- Old BillboardGuis on NPC
local npc = nil
local map = Workspace:FindFirstChild("Map")
if map then npc = map:FindFirstChild("ShopDealler") end
if not npc then npc = Workspace:FindFirstChild("ShopDealler") end

if npc then
	local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
	if head then
		local oldBB = head:FindFirstChild("DialogueGui")
		if oldBB then oldBB:Destroy(); print("🗑️ Deleted NPC BillboardGui") end
	end
	local hum = npc:FindFirstChildOfClass("Humanoid")
	local promptPart = hum and hum.RootPart or npc.PrimaryPart or head
	if promptPart then
		local oldPrompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
		if oldPrompt then oldPrompt:Destroy(); print("🗑️ Deleted old ProximityPrompt") end
	end
end

-- Ensure DialogueEvent exists
local remotes = RS:FindFirstChild("Remotes")
if remotes then
	if not remotes:FindFirstChild("DialogueEvent") then
		local ev = Instance.new("RemoteEvent"); ev.Name = "DialogueEvent"; ev.Parent = remotes
	end
	if not remotes:FindFirstChild("ShopOpenEvent") then
		local ev = Instance.new("RemoteEvent"); ev.Name = "ShopOpenEvent"; ev.Parent = remotes
	end
end

task.wait(0.5)
print("✅ Nuke complete! Installing new system...")

-- ═══ 2. INSTALL SERVER SCRIPT ═══
local serverScript = Instance.new("Script")
serverScript.Name = "NPCShopServer"
serverScript.Parent = SSS
serverScript.Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")
local DialogueEvent = Remotes:WaitForChild("DialogueEvent")

-- DIALOGUE TEXTS
local GREETINGS = {
	"Hello, traveler!",
	"Welcome to my shop!",
	"Ah, a new face!",
	"Come, come! Don't be shy!",
	"Greetings, young one!",
}

local STORY_RESPONSES = {
	"I've traveled these lands for decades...",
	"Long ago, I was an adventurer like you!",
	"This shop has been in my family for generations.",
	"I once rolled a Genesis aura myself...",
}

local NEVERMIND_RESPONSES = {
	"Farewell, traveler!",
	"Safe journeys, friend!",
	"Until we meet again!",
}

local SHOP_OPEN_LINE = "Here, take a look!"

-- CHOICES
local CHOICES = {
	{ Text = "Open Shop", Action = "OpenShop" },
	{ Text = "Ask About Story", Action = "Story" },
	{ Text = "Nevermind", Action = "Nevermind" }
}

-- FIND NPC
local npc = nil
local map = Workspace:FindFirstChild("Map")
if map then npc = map:FindFirstChild("ShopDealler") end
if not npc then npc = Workspace:FindFirstChild("ShopDealler") end
if not npc then warn("❌ ShopDealler NPC not found!") return end

local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
if not head then warn("❌ ShopDealler has no Head!") return end

print("✅ Found NPC: " .. npc:GetFullName())

-- BUILD BILLBOARD GUI
local billboard = Instance.new("BillboardGui")
billboard.Name = "DialogueGui"
billboard.Adornee = head
billboard.Size = UDim2.fromOffset(400, 80)
billboard.StudsOffset = Vector3.new(0, 2.8, 0)
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.MaxDistance = 40
billboard.Enabled = false
billboard.Parent = head

local npcLabel = Instance.new("TextLabel")
npcLabel.Size = UDim2.fromScale(1, 1)
npcLabel.BackgroundTransparency = 1
npcLabel.BorderSizePixel = 0
npcLabel.Text = ""
npcLabel.Font = Enum.Font.FredokaOne
npcLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
npcLabel.TextStrokeTransparency = 0
npcLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
npcLabel.TextScaled = true
npcLabel.TextWrapped = true
npcLabel.Parent = billboard

local npcScale = Instance.new("UIScale")
npcScale.Scale = 0
npcScale.Parent = npcLabel

-- ANIMATION FUNCTIONS
local function showText(text, duration)
	npcLabel.Text = text
	billboard.Enabled = true
	npcScale.Scale = 0
	local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(npcScale, info, { Scale = 1 }):Play()
	if duration then
		task.delay(duration, function()
			local info2 = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			TweenService:Create(npcScale, info2, { Scale = 0 }):Play()
			task.delay(0.25, function() billboard.Enabled = false end)
		end)
	end
end

-- PROXIMITY PROMPT
local humanoid = npc:FindFirstChildOfClass("Humanoid")
local promptPart = humanoid and humanoid.RootPart or npc.PrimaryPart or head

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Talk"
prompt.ObjectText = "Shopkeeper"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false
prompt.Parent = promptPart

-- INTERACTION
prompt.Triggered:Connect(function(player)
	local greeting = GREETINGS[math.random(1, #GREETINGS)]
	showText(greeting, 5)
	DialogueEvent:FireClient(player, {
		Type = "ShowChoices",
		NpcText = greeting,
		Choices = CHOICES
	})
end)

DialogueEvent.OnServerEvent:Connect(function(player, action)
	if action == "OpenShop" then
		showText(SHOP_OPEN_LINE, 3)
		task.wait(0.5)
		ShopOpenEvent:FireClient(player)
	elseif action == "Story" then
		local response = STORY_RESPONSES[math.random(1, #STORY_RESPONSES)]
		showText(response, 7)
		task.delay(7, function()
			if player and player.Parent then
				local greeting = GREETINGS[math.random(1, #GREETINGS)]
				showText(greeting, 5)
				DialogueEvent:FireClient(player, { Type = "ShowChoices", NpcText = greeting, Choices = CHOICES })
			end
		end)
	elseif action == "Nevermind" then
		local response = NEVERMIND_RESPONSES[math.random(1, #NEVERMIND_RESPONSES)]
		showText(response, 3)
	end
end)

-- IDLE CHATTER
task.spawn(function()
	while true do
		task.wait(math.random(10, 20))
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and promptPart then
				local dist = (char.HumanoidRootPart.Position - promptPart.Position).Magnitude
				if dist < 20 then
					showText(GREETINGS[math.random(1, #GREETINGS)], 4)
					break
				end
			end
		end
	end
end)

print("✅ NPC Server ready! (Grow a Garden Style)")
]==]

-- ═══ 3. INSTALL CLIENT SCRIPT ═══
local clientScript = Instance.new("LocalScript")
clientScript.Name = "DialogueUI"
clientScript.Parent = SPS
clientScript.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DialogueEvent = Remotes:WaitForChild("DialogueEvent")

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "DialogueGui" then c:Destroy() end
end

-- BUILD SCREEN GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DialogueGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 22
gui.Parent = playerGui

local container = Instance.new("Frame")
container.AnchorPoint = Vector2.new(0.5, 1)
container.Size = UDim2.fromOffset(500, 300)
container.Position = UDim2.fromScale(0.5, 0.92)
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.Visible = false
container.Parent = gui

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- CREATE CHOICE BUTTON
local function createChoiceButton(index, choiceData)
	local btn = Instance.new("TextButton")
	btn.Name = "Choice" .. index
	btn.Size = UDim2.fromOffset(450, 50)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = "#" .. index .. " [" .. choiceData.Text .. "]"
	btn.Font = Enum.Font.FredokaOne
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	btn.AutoButtonColor = false
	btn.LayoutOrder = index
	btn.Parent = container

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = btn

	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = btn

	-- Hover effects
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { TextColor3 = Color3.fromRGB(255, 235, 100) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)

	-- Click
	btn.MouseButton1Click:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.wait(0.2)
		DialogueEvent:FireServer(choiceData.Action)
		container.Visible = false
	end)

	return scale
end

-- SHOW CHOICES
local function showChoices(choices)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local scales = {}
	for i, choiceData in ipairs(choices) do
		local scale = createChoiceButton(i, choiceData)
		table.insert(scales, scale)
	end

	container.Visible = true

	-- Staggered bouncy pop-in
	for i, scale in ipairs(scales) do
		task.delay((i - 1) * 0.06, function()
			local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(scale, info, { Scale = 1 }):Play()
		end)
	end
end

DialogueEvent.OnClientEvent:Connect(function(data)
	if data.Type == "ShowChoices" then
		showChoices(data.Choices)
	end
end)

print("✅ DialogueUI loaded! (Grow a Garden Style)")
]==]

print("══════════════════════════════════════")
print("✅ GROW A GARDEN DIALOGUE SYSTEM INSTALLED!")
print("══════════════════════════════════════")
print("💣 Old scripts nuked completely!")
print("🆕 New system installed:")
print("   • NPC: BillboardGui (FredokaOne, no bg, bouncy pop-in)")
print("   • Player: ScreenGui (#1 [Option], hover yellow)")
print("   • Animation: UIScale 0→1, Back/Out, 0.35s")
print("══════════════════════════════════════")
