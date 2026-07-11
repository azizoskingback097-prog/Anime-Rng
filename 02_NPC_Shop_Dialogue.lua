-- ═══════════════════════════════════════════════════════════
-- 🏪 NPC SHOP: PROXIMITY PROMPT + RANDOMIZED DIALOGUE
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Finds your ShopDealler NPC and adds:
--   • ProximityPrompt (Press E to interact)
--   • Floating BillboardGui with randomized greetings
--   • Opens Shop UI when triggered
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local old = SSS:FindFirstChild("NPCShopServer")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("Script")
s.Name = "NPCShopServer"
s.Parent = SSS
s.Source = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopOpenEvent = Remotes:WaitForChild("ShopOpenEvent")

-- 🎭 RANDOM GREETINGS (Add more here!)
local GREETINGS = {
	"Hello, traveler! What do you need today?",
	"Welcome to my shop! Take a look around!",
	"Got some rare auras? I've got potions for sale!",
	"Ah, a new face! Care to browse my wares?",
	"Lucky potions, coin boosts... I've got it all!",
	"Come, come! Don't be shy!",
	"The finest brews in all the land, just for you!",
	"Need a boost? I've got just the thing!"
}

-- Find the ShopDealler NPC
local function findShopNPC()
	-- Search in Workspace.Map.ShopDealler first
	local map = Workspace:FindFirstChild("Map")
	if map then
		local npc = map:FindFirstChild("ShopDealler")
		if npc then return npc end
	end
	-- Search entire Workspace
	return Workspace:FindFirstChild("ShopDealler")
end

local npc = findShopNPC()
if not npc then
	warn("❌ Could not find ShopDealler NPC! Make sure it's named 'ShopDealler' in Workspace.")
	return
end

print("✅ Found Shop NPC: " .. npc:GetFullName())

-- Find the Head or HumanoidRootPart for attaching the BillboardGui
local head = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
if not head then
	warn("❌ ShopDealler NPC has no Head or HumanoidRootPart!")
	return
end

-- 1. Create BillboardGui for floating dialogue
local bbGui = Instance.new("BillboardGui")
bbGui.Name = "DialogueGui"
bbGui.Adornee = head
bbGui.Size = UDim2.new(0, 400, 0, 60)
bbGui.StudsOffset = Vector3.new(0, 3, 0) -- Float above head
bbGui.AlwaysOnTop = true
bbGui.LightInfluence = 0
bbGui.MaxDistance = 50 -- Only visible within 50 studs
bbGui.Parent = head

-- Text label for dialogue
local dialogueText = Instance.new("TextLabel")
dialogueText.Size = UDim2.fromScale(1, 1)
dialogueText.BackgroundTransparency = 1
dialogueText.Text = ""
dialogueText.Font = Enum.Font.GothamBold
dialogueText.TextSize = 20
dialogueText.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogueText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
dialogueText.TextStrokeTransparency = 0.3
dialogueText.TextWrapped = true
dialogueText.Parent = bbGui

-- Show a random greeting
local function showGreeting()
	dialogueText.Text = GREETINGS[math.random(1, #GREETINGS)]
	dialogueText.TextTransparency = 0
	dialogueText.TextStrokeTransparency = 0.3

	-- Auto-hide after 5 seconds
	task.delay(5, function()
		TweenService:Create(dialogueText, TweenInfo.new(1), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}):Play()
	end)
end

-- Show greeting when player approaches
bbGui.Enabled = false
local nearbyPlayers = {}

-- 2. Create ProximityPrompt on the NPC
local humanoid = npc:FindFirstChildOfClass("Humanoid")
local promptPart = humanoid and humanoid.RootPart or npc.PrimaryPart or head

local existingPrompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
if existingPrompt then existingPrompt:Destroy() end

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Open Shop"
prompt.ObjectText = "Shopkeeper"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
prompt.HoldDuration = 0 -- Instant tap
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false
prompt.Parent = promptPart

-- Show greeting when prompt becomes visible
prompt.Triggered:Connect(function(player)
	-- Show a greeting first!
	showGreeting()

	-- Small delay for natural feel, then open shop
	task.wait(0.3)
	ShopOpenEvent:FireClient(player)
end)

-- Show idle greetings when players are nearby
task.spawn(function()
	while true do
		task.wait(math.random(8, 15)) -- Random interval
		-- Check if any players are nearby
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and promptPart then
				local dist = (char.HumanoidRootPart.Position - promptPart.Position).Magnitude
				if dist < 20 then
					showGreeting()
					break
				end
			end
		end
	end
end)

print("✅ NPC Shop ProximityPrompt + Dialogue ready! Press E near the ShopDealler!")
]==]

print("✅ NPC SHOP DIALOGUE INSTALLED!")
print("🏪 ProximityPrompt + Randomized Greetings active!")
print("🎮 Walk up to ShopDealler and press E!")
