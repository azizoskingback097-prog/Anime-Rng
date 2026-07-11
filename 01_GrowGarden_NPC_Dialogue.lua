-- ═══════════════════════════════════════════════════════════
-- 🗣️ GROW A GARDEN STYLE NPC DIALOGUE (Premium Floating Text!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Features:
--   • No background panel (floating text only!)
--   • LuckiestGuy font (white bold rounded)
--   • Thick black TextStroke outline
--   • Smooth fade in (1→0) + pop scale (0.95→1)
--   • Slight rise on show (3.0→3.2), drop on hide
--   • Fully customizable config table!
--   • 3 Dialogue Options: Open Shop, Story, Nevermind
--   • Random greetings, story responses, goodbye responses
--   • Idle chatter when players are nearby
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
-- ⚙️ CONFIG TABLE (Customize everything here!)
-- ═══════════════════════════════════════════════════════════
local CONFIG = {
	-- Visuals
	Font = Enum.Font.LuckiestGuy,         -- White bold rounded font
	TextColor = Color3.fromRGB(255, 255, 255), -- White text
	StrokeColor = Color3.fromRGB(0, 0, 0),     -- Thick black outline
	StrokeThickness = 4,
	TextSize = 22,
	
	-- Size (Small!)
	BaseSize = UDim2.fromOffset(240, 52),  -- Hidden/resting size
	PopSize = UDim2.fromOffset(260, 60),  -- Pop size (slightly bigger)
	
	-- Position (Floating above head)
	BaseOffset = Vector3.new(0, 3.0, 0),  -- Resting Y
	PopOffset = Vector3.new(0, 3.2, 0),  -- Rises slightly on show
	
	-- Distance
	MaxDistance = 40,  -- Text disappears beyond this distance
	
	-- Animation Timings
	FadeInTime = 0.18,
	FadeOutTime = 0.15,
	HoldTime = 5,       -- How long idle greetings stay (seconds)
	GreetingHoldTime = 3, -- How long interaction greetings stay
	StoryHoldTime = 7,  -- How long story responses stay
}

-- ═══════════════════════════════════════════════════════════
-- ⚙️ DIALOGUE TEXTS (Customize messages here!)
-- ═══════════════════════════════════════════════════════════
local GREETINGS = {
	"Hello, traveler!",
	"Welcome to my shop!",
	"Ah, a new face!",
	"Come, come! Don't be shy!",
	"Greetings, young one!",
	"What can I do for you?",
	"Looking for potions?",
	"Need a boost, friend?",
}

local STORY_RESPONSES = {
	"I've traveled these lands for decades, collecting rare brews...",
	"Long ago, I was an adventurer like you. Now I sell my findings!",
	"This shop has been in my family for generations.",
	"I once rolled a Genesis aura myself... but that's a tale for another day.",
	"The auras in this world are mysterious. I've seen things you wouldn't believe!",
	"Every potion tells a story, friend. Every potion.",
}

local NEVERMIND_RESPONSES = {
	"Farewell, traveler!",
	"Safe journeys, friend!",
	"Until we meet again!",
	"Goodbye for now!",
	"Take care! May luck be with you!",
}

local SHOP_OPEN_LINE = "Here, take a look!"

-- ═══════════════════════════════════════════════════════════
-- FIND THE NPC
-- ═══════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
-- BUILD THE FLOATING TEXT (BillboardGui)
-- ═══════════════════════════════════════════════════════════
-- Destroy old BillboardGui if it exists
local oldBB = head:FindFirstChild("DialogueGui")
if oldBB then oldBB:Destroy() end

local billboard = Instance.new("BillboardGui")
billboard.Name = "DialogueGui"
billboard.Adornee = head
billboard.Size = CONFIG.BaseSize
billboard.StudsOffset = CONFIG.BaseOffset
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.MaxDistance = CONFIG.MaxDistance
billboard.Enabled = false -- Hidden by default
billboard.Parent = head

-- The Text Label (No background!)
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1             -- NO background panel!
label.Text = ""
label.Font = CONFIG.Font
label.TextSize = CONFIG.TextSize
label.TextColor3 = CONFIG.TextColor
label.TextStrokeColor3 = CONFIG.StrokeColor
label.TextStrokeTransparency = 1             -- Hidden initially
label.TextTransparency = 1                   -- Hidden initially
label.TextWrapped = true
label.Parent = billboard

-- ═══════════════════════════════════════════════════════════
-- ANIMATION FUNCTIONS (TweenService)
-- ═══════════════════════════════════════════════════════════
local function tweenBB(props, time, style, dir)
	local info = TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	return TweenService:Create(billboard, info, props)
end

local function tweenLabel(props, time, style, dir)
	local info = TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	return TweenService:Create(label, info, props)
end

-- SHOW: Fade in + Pop + Rise
local function Show(text, holdTime)
	label.Text = text
	billboard.Enabled = true
	
	-- Start hidden
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	billboard.Size = CONFIG.BaseSize
	billboard.StudsOffset = CONFIG.BaseOffset
	
	-- Fade in text + stroke
	tweenLabel({TextTransparency = 0, TextStrokeTransparency = 0.2}, CONFIG.FadeInTime):Play()
	
	-- Pop size (slightly bigger) + rise
	tweenBB({Size = CONFIG.PopSize, StudsOffset = CONFIG.PopOffset}, CONFIG.FadeInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
	
	-- Auto-hide after hold time
	if holdTime then
		task.delay(holdTime, function()
			Hide()
		end)
	end
end

-- HIDE: Fade out + Drop
function Hide()
	-- Fade out text + stroke
	tweenLabel({TextTransparency = 1, TextStrokeTransparency = 1}, CONFIG.FadeOutTime):Play()
	
	-- Drop down
	tweenBB({Size = CONFIG.BaseSize, StudsOffset = CONFIG.BaseOffset}, CONFIG.FadeOutTime):Play()
	
	-- Disable after fade
	task.delay(CONFIG.FadeOutTime + 0.05, function()
		billboard.Enabled = false
	end)
end

-- ═══════════════════════════════════════════════════════════
-- PROXIMITY PROMPT (Press E to interact)
-- ═══════════════════════════════════════════════════════════
local humanoid = npc:FindFirstChildOfClass("Humanoid")
local promptPart = humanoid and humanoid.RootPart or npc.PrimaryPart or head

-- Destroy old prompt
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

-- When player presses E
prompt.Triggered:Connect(function(player)
	-- Pick random greeting
	local greeting = GREETINGS[math.random(1, #GREETINGS)]
	
	-- Show floating text with Grow a Garden animation!
	Show(greeting, CONFIG.GreetingHoldTime)
	
	-- Send dialogue options to client
	DialogueEvent:FireClient(player, {
		Greeting = greeting,
		StoryResponses = STORY_RESPONSES,
		NevermindResponses = NEVERMIND_RESPONSES
	})
end)

-- Listen for client button responses
DialogueEvent.OnServerEvent:Connect(function(player, action)
	if action == "OpenShop" then
		Show(SHOP_OPEN_LINE, CONFIG.GreetingHoldTime)
		task.wait(0.5)
		ShopOpenEvent:FireClient(player)
		
	elseif action == "Story" then
		local response = STORY_RESPONSES[math.random(1, #STORY_RESPONSES)]
		Show(response, CONFIG.StoryHoldTime)
		
	elseif action == "Nevermind" then
		local response = NEVERMIND_RESPONSES[math.random(1, #NEVERMIND_RESPONSES)]
		Show(response, CONFIG.GreetingHoldTime)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- IDLE CHATTER (NPC talks when players walk by)
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(math.random(10, 20))
		
		-- Check if any players are nearby
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and promptPart then
				local dist = (char.HumanoidRootPart.Position - promptPart.Position).Magnitude
				if dist < 20 then
					-- Player is nearby, show random greeting!
					local greeting = GREETINGS[math.random(1, #GREETINGS)]
					Show(greeting, CONFIG.HoldTime)
					break -- Only show one at a time
				end
			end
		end
	end
end)

print("✅ Grow a Garden NPC Dialogue ready! (Premium floating text + animations)")
]==]

print("✅ GROW A GARDEN NPC DIALOGUE INSTALLED!")
print("🗣️ LuckiestGuy font + thick black stroke!")
print("✨ Smooth fade + pop animation!")
print("📏 Small size (240x52), no background panel!")
