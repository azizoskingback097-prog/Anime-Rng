-- ═══════════════════════════════════════════════════════════
-- 🌱 STEP 2: REBUILD DIALOGUE (Auto-Scan + Grow a Garden 2 UI)
-- ═══════════════════════════════════════════════════════════
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS = game:GetService("ReplicatedStorage")

local s = Instance.new("LocalScript")
s.Name = "DialogueUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

print("✅ Grow a Garden 2 (Auto-Scan) DialogueUI started...")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ShopOpenEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShopOpenEvent")

-- ⚙️ CUSTOMIZATION CONFIG
local CONFIG = {
	NPCName = "Shopkeeper",
	TalkDistance = 10, -- How close you need to be to talk
	Greetings = { "Hello, traveler! What do you need today?", "Welcome back! Take a look around.", "Ah, a new face! What brings you here?" },
	StoryResponse = "I've traveled these lands for decades, collecting rare brews and potions...",
	NevermindResponse = "Farewell, traveler! Come back anytime.",
	Options = {
		{ Text = "Open the shop", Action = "OpenShop" },
		{ Text = "Tell me about your story", Action = "Story" },
		{ Text = "Nevermind", Action = "Close" }
	}
}

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "DialogueGui" then c:Destroy() end
end

-- ═══ 1. BUILD UI HIERARCHY & VISUALS ═══
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "DialogueGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30

-- DialogueContainer
local container = Instance.new("Frame", gui)
container.Name = "DialogueContainer"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 0.9, 0)
container.Size = UDim2.new(0, 0, 0, 0) -- Start at 0 for pop-in
container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
container.BackgroundTransparency = 0.3
container.BorderSizePixel = 0
container.Visible = false

local corner = Instance.new("UICorner", container)
corner.CornerRadius = UDim.new(0, 12)

local padding = Instance.new("UIPadding", container)
padding.PaddingTop = UDim.new(0, 15); padding.PaddingBottom = UDim.new(0, 15)
padding.PaddingLeft = UDim.new(0, 20); padding.PaddingRight = UDim.new(0, 20)

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 10)

-- Nameplate
local nameplate = Instance.new("TextLabel", container)
nameplate.Size = UDim2.new(1, 0, 0, 30)
nameplate.BackgroundTransparency = 1
nameplate.Text = CONFIG.NPCName
nameplate.Font = Enum.Font.GothamBold
nameplate.TextSize = 24
nameplate.TextColor3 = Color3.fromRGB(255, 215, 0)
nameplate.TextXAlignment = Enum.TextXAlignment.Left
nameplate.TextStrokeTransparency = 0.5

-- Body Text
local bodyText = Instance.new("TextLabel", container)
bodyText.Size = UDim2.new(1, 0, 0, 80)
bodyText.BackgroundTransparency = 1
bodyText.Text = ""
bodyText.Font = Enum.Font.Gotham
bodyText.TextSize = 24
bodyText.TextColor3 = Color3.fromRGB(255, 255, 255)
bodyText.TextXAlignment = Enum.TextXAlignment.Left
bodyText.TextYAlignment = Enum.TextYAlignment.Top
bodyText.TextWrapped = true
bodyText.RichText = true
bodyText.TextStrokeTransparency = 0.5

-- Options Container
local optionsFrame = Instance.new("Frame", container)
optionsFrame.Size = UDim2.new(1, 0, 0, 120)
optionsFrame.BackgroundTransparency = 1

local optionsLayout = Instance.new("UIListLayout", optionsFrame)
optionsLayout.Padding = UDim.new(0, 5)
optionsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

-- ═══ 2. ANIMATIONS & LOGIC ═══
local isTyping = false
local menuOpen = false

local function typeText(text)
	isTyping = true
	bodyText.Text = text
	bodyText.MaxVisibleGraphemes = 0
	for i = 1, #text do
		if not isTyping then break end
		bodyText.MaxVisibleGraphemes = i
		task.wait(0.03)
	end
	isTyping = false
end

local function closeMenu()
	isTyping = false
	menuOpen = false
	TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()
	task.wait(0.2)
	container.Visible = false
end

local function openMenu()
	menuOpen = true
	container.Visible = true
	container.Size = UDim2.new(0, 0, 0, 0)
	
	-- Bouncy Pop-in
	TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.4, 0, 0.3, 0)
	}):Play()
	
	-- Start Typewriter
	task.spawn(function()
		task.wait(0.2)
		typeText(CONFIG.Greetings[math.random(1, #CONFIG.Greetings)])
	end)
end

-- Create Buttons
for i, opt in ipairs(CONFIG.Options) do
	local btn = Instance.new("TextButton", optionsFrame)
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundTransparency = 1
	btn.Text = '#' .. i .. ' ["' .. opt.Text .. '"]'
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 20
	btn.TextColor3 = Color3.fromRGB(235, 235, 235)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextStrokeTransparency = 0.5
	btn.AutoButtonColor = false
	
	-- Hover Animation
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { TextSize = 24, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { TextSize = 20, TextColor3 = Color3.fromRGB(235, 235, 235) }):Play()
	end)
	
	-- Click Logic
	btn.MouseButton1Click:Connect(function()
		if isTyping then
			isTyping = false
			bodyText.MaxVisibleGraphemes = -1
			return
		end
		
		if opt.Action == "OpenShop" then
			closeMenu()
			ShopOpenEvent:FireClient(player)
		elseif opt.Action == "Story" then
			typeText(CONFIG.StoryResponse)
		elseif opt.Action == "Close" then
			closeMenu()
		end
	end)
end

-- ═══ 3. AUTO-SCAN FOR NPC (Heartbeat) ═══
local npcHead = nil

RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Find NPC if not found
	if not npcHead then
		local map = Workspace:FindFirstChild("Map")
		local npc = map and map:FindFirstChild("ShopDealler", true) or Workspace:FindFirstChild("ShopDealler", true)
		if npc then
			npcHead = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
			if npcHead then print("✅ Found NPC Head!") end
		end
		return
	end

	-- Check distance to auto-open/close
	local dist = (hrp.Position - npcHead.Position).Magnitude
	
	if dist < CONFIG.TalkDistance then
		if not menuOpen then
			openMenu()
		end
	elseif dist > CONFIG.TalkDistance + 5 then
		if menuOpen then
			closeMenu()
		end
	end
end)

print("✅ Grow a Garden 2 Auto-Scan fully loaded! Walk near the NPC to talk!")
]==]

print("✅ STEP 2 COMPLETE! Walk near the NPC to automatically open the dialogue!")
