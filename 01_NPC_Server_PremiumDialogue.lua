-- ═══════════════════════════════════════════════════════════
-- 🗣️ PREMIUM NPC DIALOGUE SERVER (Custom System - No Roblox Dialog)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- STRICT VISUAL SPECIFICATIONS:
--   • BillboardGui: Floating text above NPC head (no background panel)
--   • TextLabel: BackgroundTransparency = 1, BorderSizePixel = 0
--   • Font: FredokaOne (bold, bubbly cartoon font)
--   • TextColor3: Pure White (255,255,255)
--   • TextStrokeTransparency: 0 (thick crisp black outline)
--   • TextStrokeColor3: Pure Black (0,0,0)
--   • TextScaled: true
--   • Bouncy pop-in animation (UIScale 0→1, Back/Out, 0.35s)
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
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")

-- ═══════════════════════════════════════════════════════════
-- ⚙️ DIALOGUE CONFIG (Fully Customizable!)
-- ═══════════════════════════════════════════════════════════
local GREETINGS = {
	"Hello, traveler!",
	"Welcome to my shop!",
	"Ah, a new face!",
	"Come, come! Don't be shy!",
	"Greetings, young one!",
	"What can I do for you?",
}

local STORY_RESPONSES = {
	"I've traveled these lands for decades, collecting rare brews...",
	"Long ago, I was an adventurer like you. Now I sell my findings!",
	"This shop has been in my family for generations.",
	"I once rolled a Genesis aura myself... but that's a tale for another day.",
	"The auras in this world are mysterious. I've seen things you wouldn't believe!",
}

local NEVERMIND_RESPONSES = {
	"Farewell, traveler!",
	"Safe journeys, friend!",
	"Until we meet again!",
	"Goodbye for now!",
}

local SHOP_OPEN_LINE = "Here, take a look at my wares!"

-- ═══════════════════════════════════════════════════════════
-- FIND THE NPC
-- ═══════════════════════════════════════════════════════════
local npc = nil
local map = Workspace:FindFirstChild("Map")
if map then npc = map:FindFirstChild("ShopDealler") end
if not npc then npc = Workspace:FindFirstChild("ShopDealler") end

if not npc then
	warn("❌ Could not find ShopDealler NPC! Make sure it's named 'ShopDealler'.")
	return
end

local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
if not head then
	warn("❌ ShopDealler has no Head or HumanoidRootPart!")
	return
end

print("✅ Found Shop NPC: " .. npc:GetFullName())

-- ═══════════════════════════════════════════════════════════
-- BUILD THE FLOATING BILLBOARD GUI (Strict Visual Spec)
-- ═══════════════════════════════════════════════════════════
local oldBB = head:FindFirstChild("DialogueGui")
if oldBB then oldBB:Destroy() end

local billboard = Instance.new("BillboardGui")
billboard.Name = "DialogueGui"
billboard.Adornee = head
billboard.Size = UDim2.fromOffset(400, 80)
billboard.StudsOffset = Vector3.new(0, 2.8, 0) -- Floats above hat
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.MaxDistance = 40
billboard.Enabled = false
billboard.Parent = head

-- The Text Label (STRICT SPEC: No background!)
local npcLabel = Instance.new("TextLabel")
npcLabel.Name = "NpcText"
npcLabel.Size = UDim2.fromScale(1, 1)
npcLabel.BackgroundTransparency = 1            -- MANDATORY: No box!
npcLabel.BorderSizePixel = 0                   -- MANDATORY: No border!
npcLabel.Text = ""
npcLabel.Font = Enum.Font.FredokaOne           -- Bold, bubbly cartoon font
npcLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Pure White
npcLabel.TextStrokeTransparency = 0            -- MANDATORY: Thick outline!
npcLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)  -- Pure Black
npcLabel.TextScaled = true
npcLabel.TextWrapped = true
npcLabel.Parent = billboard

-- UIScale for bouncy pop-in
local npcScale = Instance.new("UIScale")
npcScale.Name = "BounceScale"
npcScale.Scale = 0  -- Start at 0 (invisible)
npcScale.Parent = npcLabel

-- ═══════════════════════════════════════════════════════════
-- BOUNCY POP-IN ANIMATION (Back/Out, 0.35s)
-- ═══════════════════════════════════════════════════════════
local function showText(text, duration)
	npcLabel.Text = text
	billboard.Enabled = true

	-- Start at scale 0 (hidden)
	npcScale.Scale = 0

	-- Bouncy pop-in: UIScale 0 → 1, Back/Out, 0.35s
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(npcScale, tweenInfo, { Scale = 1 }):Play()

	-- Auto-hide after duration
	if duration then
		task.delay(duration, function()
			hideText()
		end)
	end
end

local function hideText()
	-- Shrink out
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	TweenService:Create(npcScale, tweenInfo, { Scale = 0 }):Play()

	-- Disable after shrink
	task.delay(0.25, function()
		billboard.Enabled = false
	end)
end

-- ═══════════════════════════════════════════════════════════
-- PROXIMITY PROMPT
-- ═══════════════════════════════════════════════════════════
local humanoid = npc:FindFirstChildOfClass("Humanoid")
local promptPart = humanoid and humanoid.RootPart or npc.PrimaryPart or head

local oldPrompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
if oldPrompt then oldPrompt:Destroy() end

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Talk"
prompt.ObjectText = "Shopkeeper"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false
prompt.Parent = promptPart

-- Ensure DialogueEvent RemoteEvent exists
local DialogueEvent = Remotes:FindFirstChild("DialogueEvent")
if not DialogueEvent then
	DialogueEvent = Instance.new("RemoteEvent")
	DialogueEvent.Name = "DialogueEvent"
	DialogueEvent.Parent = Remotes
end

-- ═══════════════════════════════════════════════════════════
-- DIALOGUE CHOICES (Sent to client)
-- Format: "#1 [Option Text]"
-- ═══════════════════════════════════════════════════════════
local CHOICES = {
	{
		Text = "Open Shop",
		Action = "OpenShop"
	},
	{
		Text = "Ask About Story",
		Action = "Story"
	},
	{
		Text = "Nevermind",
		Action = "Nevermind"
	}
}

-- ═══════════════════════════════════════════════════════════
-- INTERACTION LOGIC
-- ═══════════════════════════════════════════════════════════
prompt.Triggered:Connect(function(player)
	-- Show random greeting with bouncy animation
	local greeting = GREETINGS[math.random(1, #GREETINGS)]
	showText(greeting, 5)

	-- Send choices to client (Client builds the ScreenGui buttons)
	DialogueEvent:FireClient(player, {
		Type = "ShowChoices",
		NpcText = greeting,
		Choices = CHOICES
	})
end)

-- Listen for player's button click
DialogueEvent.OnServerEvent:Connect(function(player, action)
	if action == "OpenShop" then
		showText(SHOP_OPEN_LINE, 3)
		task.wait(0.5)
		ShopOpenEvent:FireClient(player)

	elseif action == "Story" then
		local response = STORY_RESPONSES[math.random(1, #STORY_RESPONSES)]
		showText(response, 7)

		-- Re-send choices after story
		task.delay(7, function()
			if player and player.Parent then
				local greeting = GREETINGS[math.random(1, #GREETINGS)]
				showText(greeting, 5)
				DialogueEvent:FireClient(player, {
					Type = "ShowChoices",
					NpcText = greeting,
					Choices = CHOICES
				})
			end
		end)

	elseif action == "Nevermind" then
		local response = NEVERMIND_RESPONSES[math.random(1, #NEVERMIND_RESPONSES)]
		showText(response, 3)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- IDLE CHATTER
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(math.random(10, 20))
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and promptPart then
				local dist = (char.HumanoidRootPart.Position - promptPart.Position).Magnitude
				if dist < 20 then
					local greeting = GREETINGS[math.random(1, #GREETINGS)]
					showText(greeting, 4)
					break
				end
			end
		end
	end
end)

print("✅ Premium NPC Dialogue Server ready! (FredokaOne + Bouncy Pop-in)")
]==]

print("✅ PREMIUM NPC SERVER INSTALLED!")
print("🎨 BillboardGui: FredokaOne, White text, Black stroke, no background!")
print("🎬 Bouncy pop-in animation (UIScale 0→1, Back/Out, 0.35s)!")
