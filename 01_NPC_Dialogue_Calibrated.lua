-- ═══════════════════════════════════════════════════════════
-- 🎯 NPC DIALOGUE SERVER (Calibration-Ready Edition)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Features:
--   • Attachment-based anchoring (stable, no drift!)
--   • Config table for easy calibration
--   • UITextSizeConstraint (consistent text size!)
--   • Debug mode (prints values to Output)
--   • Bouncy pop-in animation
--   • Grow a Garden style (no background, outlined text)
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
local DialogueEvent = Remotes:WaitForChild("DialogueEvent")

-- ═══════════════════════════════════════════════════════════
-- ⚙️ CALIBRATION CONFIG (Tweak these values!)
-- ═══════════════════════════════════════════════════════════
local CONFIG = {
	-- BillboardGui Size (fixed pixels - consistent at all distances!)
	SizePx = Vector2.new(260, 60),           -- Width x Height in pixels
	Offset = Vector3.new(0, 3.2, 0),         -- X=0 (centered), Y=height, Z=0
	MaxDistance = 20,                         -- Text disappears beyond this (studs)
	TextSizeMin = 18,                         -- Minimum text size
	TextSizeMax = 28,                         -- Maximum text size
	Font = Enum.Font.FredokaOne,             -- Bold bubbly cartoon font
	TextColor = Color3.fromRGB(255, 255, 255), -- Pure white
	StrokeColor = Color3.fromRGB(0, 0, 0),   -- Pure black outline
	StrokeTransparency = 0,                   -- 0 = fully visible outline
	
	-- Animation timings
	FadeInTime = 0.35,
	FadeOutTime = 0.2,
	PopScale = 1.0,                           -- Final scale (1.0 = 100%)
	
	-- Debug mode (prints values to Output when dialogue shows)
	Debug = true,                             -- Set to false to disable prints
}

-- ═══════════════════════════════════════════════════════════
-- ⚙️ DIALOGUE TEXTS
-- ═══════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
-- FIND THE NPC
-- ═══════════════════════════════════════════════════════════
local npc = nil
local map = Workspace:FindFirstChild("Map")
if map then npc = map:FindFirstChild("ShopDealler") end
if not npc then npc = Workspace:FindFirstChild("ShopDealler") end
if not npc then warn("❌ ShopDealler NPC not found!") return end

-- Find Head (for R15) or Torso (for R6) or HumanoidRootPart
local head = npc:FindFirstChild("Head") or npc:FindFirstChild("Torso") or npc:FindFirstChild("HumanoidRootPart")
if not head then warn("❌ ShopDealler has no Head/Torso/HumanoidRootPart!") return end

local humanoid = npc:FindFirstChildOfClass("Humanoid")
local isR15 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15

print("✅ Found NPC: " .. npc:GetFullName() .. " | Rig: " .. (isR15 and "R15" or "R6") .. " | Attach: " .. head.Name)

-- ═══════════════════════════════════════════════════════════
-- CREATE ATTACHMENT (Stable anchoring - no camera drift!)
-- ═══════════════════════════════════════════════════════════
local oldAtt = head:FindFirstChild("DialogAttachment")
if oldAtt then oldAtt:Destroy() end

local attachment = Instance.new("Attachment")
attachment.Name = "DialogAttachment"
attachment.Position = Vector3.new(0, 0, 0) -- Position is on the part itself
attachment.Parent = head

-- ═══════════════════════════════════════════════════════════
-- BUILD BILLBOARD GUI (Calibrated!)
-- ═══════════════════════════════════════════════════════════
local oldBB = head:FindFirstChild("DialogueGui")
if oldBB then oldBB:Destroy() end

local billboard = Instance.new("BillboardGui")
billboard.Name = "DialogueGui"
billboard.Adornee = head          -- Anchored to Head part
billboard.Size = UDim2.fromOffset(CONFIG.SizePx.X, CONFIG.SizePx.Y)  -- Fixed pixels!
billboard.StudsOffset = CONFIG.Offset  -- Y offset for height
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.MaxDistance = CONFIG.MaxDistance
billboard.Enabled = false
billboard.Parent = head

-- The Text Label (No background!)
local npcLabel = Instance.new("TextLabel")
npcLabel.Size = UDim2.fromScale(1, 1)
npcLabel.BackgroundTransparency = 1
npcLabel.BorderSizePixel = 0
npcLabel.Text = ""
npcLabel.Font = CONFIG.Font
npcLabel.TextColor3 = CONFIG.TextColor
npcLabel.TextStrokeTransparency = CONFIG.StrokeTransparency
npcLabel.TextStrokeColor3 = CONFIG.StrokeColor
npcLabel.TextWrapped = true
npcLabel.Parent = billboard

-- UITextSizeConstraint (Consistent text size!)
local textConstraint = Instance.new("UITextSizeConstraint")
textConstraint.MaxTextSize = CONFIG.TextSizeMax
textConstraint.MinTextSize = CONFIG.TextSizeMin
textConstraint.Parent = npcLabel

-- UIPadding (so text doesn't touch edges)
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 5)
padding.PaddingRight = UDim.new(0, 5)
padding.PaddingTop = UDim.new(0, 2)
padding.PaddingBottom = UDim.new(0, 2)
padding.Parent = npcLabel

-- UIScale for bouncy pop-in
local npcScale = Instance.new("UIScale")
npcScale.Scale = 0
npcScale.Parent = npcLabel

-- ═══════════════════════════════════════════════════════════
-- ANIMATION FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function showText(text, duration)
	npcLabel.Text = text
	billboard.Enabled = true
	npcScale.Scale = 0

	-- Debug print
	if CONFIG.Debug then
		print("🔍 [Dialogue Debug]")
		print("   Text: '" .. text .. "'")
		print("   Size: " .. CONFIG.SizePx.X .. "x" .. CONFIG.SizePx.Y .. "px")
		print("   Offset: " .. tostring(CONFIG.Offset))
		print("   MaxDist: " .. CONFIG.MaxDistance)
		print("   Attached to: " .. head.Name)
		print("   TextSize: " .. CONFIG.TextSizeMin .. "-" .. CONFIG.TextSizeMax)
	end

	-- Bouncy pop-in
	local info = TweenInfo.new(CONFIG.FadeInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(npcScale, info, { Scale = CONFIG.PopScale }):Play()

	if duration then
		task.delay(duration, function()
			local info2 = TweenInfo.new(CONFIG.FadeOutTime, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			TweenService:Create(npcScale, info2, { Scale = 0 }):Play()
			task.delay(CONFIG.FadeOutTime + 0.05, function()
				billboard.Enabled = false
			end)
		end)
	end
end

-- ═══════════════════════════════════════════════════════════
-- PROXIMITY PROMPT
-- ═══════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
-- INTERACTION LOGIC
-- ═══════════════════════════════════════════════════════════
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

print("✅ NPC Dialogue Server ready! (Calibrated + Debug Mode ON)")
print("⚙️ Config: Size=" .. CONFIG.SizePx.X .. "x" .. CONFIG.SizePx.Y .. "px | Offset=" .. tostring(CONFIG.Offset) .. " | MaxDist=" .. CONFIG.MaxDistance)
]==]

print("✅ CALIBRATION-READY NPC DIALOGUE INSTALLED!")
print("🎯 Attachment-based anchoring (no camera drift!)")
print("📏 Fixed pixel size + UITextSizeConstraint!")
print("🔍 Debug mode ON (prints values to Output)")
print("⚙️ Edit CONFIG table at top of script to fine-tune!")
