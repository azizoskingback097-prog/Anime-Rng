-- ═══════════════════════════════════════════════════════════
-- 🔧 FIX NPC SERVER (Players service missing)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local old = SSS:FindFirstChild("NPCShopServer")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("Script")
s.Name = "NPCShopServer"
s.Parent = SSS
s.Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players") -- ⚠️ FIX: Added Players service!
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")

-- ⚙️ DIALOGUE CONFIGURATION
local GREETINGS = {
	"Hello, traveler! What can I do for you?",
	"Welcome to my shop! How can I help?",
	"Ah, a new face! What do you need?",
	"Come, come! Don't be shy!",
	"Greetings, young one! What brings you here?"
}

local STORY_RESPONSES = {
	"I've traveled these lands for decades, collecting rare brews and potions...",
	"Long ago, I was an adventurer like you. Now I sell my findings to worthy travelers!",
	"This shop has been in my family for generations. Every potion tells a story!",
	"I once rolled a Genesis aura myself... but that's a tale for another day.",
	"The auras in this world are mysterious. I've seen things you wouldn't believe!"
}

local NEVERMIND_RESPONSES = {
	"Farewell, traveler! Come back anytime!",
	"Safe journeys! My door is always open.",
	"Until we meet again, friend!",
	"Goodbye for now! May luck be with you!",
	"Take care! I'll have new stock soon!"
}

-- Find the ShopDealler NPC
local npc = nil
local map = Workspace:FindFirstChild("Map")
if map then npc = map:FindFirstChild("ShopDealler") end
if not npc then npc = Workspace:FindFirstChild("ShopDealler") end

if not npc then
	warn("❌ Could not find ShopDealler NPC!")
	return
end

local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
if not head then warn("❌ ShopDealler has no Head!") return end

print("✅ Found Shop NPC: " .. npc:GetFullName())

-- Create BillboardGui for floating dialogue
local oldBB = head:FindFirstChild("DialogueGui")
if oldBB then oldBB:Destroy() end

local bbGui = Instance.new("BillboardGui")
bbGui.Name = "DialogueGui"
bbGui.Adornee = head
bbGui.Size = UDim2.new(0, 500, 0, 120)
bbGui.StudsOffset = Vector3.new(0, 3.5, 0)
bbGui.AlwaysOnTop = true
bbGui.LightInfluence = 0
bbGui.MaxDistance = 40
bbGui.Enabled = false
bbGui.Parent = head

local dialogueText = Instance.new("TextLabel")
dialogueText.Size = UDim2.fromScale(1, 1)
dialogueText.BackgroundTransparency = 1
dialogueText.Text = ""
dialogueText.Font = Enum.Font.GothamBold
dialogueText.TextSize = 18
dialogueText.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogueText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
dialogueText.TextStrokeTransparency = 0.2
dialogueText.TextWrapped = true
dialogueText.Parent = bbGui

-- Show text with fade
local function showDialogue(text, duration)
	dialogueText.Text = text
	dialogueText.TextTransparency = 0
	dialogueText.TextStrokeTransparency = 0.2
	bbGui.Enabled = true

	if duration then
		task.delay(duration, function()
			TweenService:Create(dialogueText, TweenInfo.new(1), {
				TextTransparency = 1, TextStrokeTransparency = 1
			}):Play()
		end)
	end
end

-- Proximity Prompt
local humanoid = npc:FindFirstChildOfClass("Humanoid")
local promptPart = humanoid and humanoid.RootPart or npc.PrimaryPart or head

local oldPrompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
if oldPrompt then oldPrompt:Destroy() end

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Talk"
prompt.ObjectText = "Shopkeeper"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false
prompt.Parent = promptPart

-- Ensure DialogueEvent exists
local DialogueEvent = Remotes:FindFirstChild("DialogueEvent")
if not DialogueEvent then
	DialogueEvent = Instance.new("RemoteEvent")
	DialogueEvent.Name = "DialogueEvent"
	DialogueEvent.Parent = Remotes
end

prompt.Triggered:Connect(function(player)
	local greeting = GREETINGS[math.random(1, #GREETINGS)]
	showDialogue(greeting)
	DialogueEvent:FireClient(player, {
		Greeting = greeting,
		StoryResponses = STORY_RESPONSES,
		NevermindResponses = NEVERMIND_RESPONSES
	})
end)

DialogueEvent.OnServerEvent:Connect(function(player, action)
	if action == "OpenShop" then
		showDialogue("Here, take a look at my wares!", 3)
		task.wait(0.5)
		ShopOpenEvent:FireClient(player)
	elseif action == "Story" then
		local response = STORY_RESPONSES[math.random(1, #STORY_RESPONSES)]
		showDialogue(response, 6)
	elseif action == "Nevermind" then
		local response = NEVERMIND_RESPONSES[math.random(1, #NEVERMIND_RESPONSES)]
		showDialogue(response, 3)
	end
end)

-- Show idle greetings when players are nearby
task.spawn(function()
	while true do
		task.wait(math.random(10, 20))
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and promptPart then
				local dist = (char.HumanoidRootPart.Position - promptPart.Position).Magnitude
				if dist < 20 then
					showDialogue(GREETINGS[math.random(1, #GREETINGS)], 4)
					break
				end
			end
		end
	end
end)

print("✅ NPC Dialogue System ready! (Fixed - Players service added)")
]==]

print("✅ NPC SERVER FIXED! (Players service error resolved)")
