-- ═══════════════════════════════════════════════════════════
-- 💣 NUKE OLD UI + 🌱 INSTALL "GROW A GARDEN" RIGHT-SIDE DIALOGUE
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Creates a TINY, elegant dialogue menu on the RIGHT side of screen.
--   • No backgrounds (Transparent text only)
--   • Pure White text + Thick Black outline
--   • Bouncy pop-in animation (Back/Out)
--   • Super small and clean!
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("DialogueUI")
if old then old:Destroy() end

-- Also nuke any leftover ScreenGuis just in case
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "DialogueGui" then c:Destroy() end
end

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

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RightDialogueGui" then c:Destroy() end
end

-- BUILD SCREEN GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RightDialogueGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 25
gui.Parent = playerGui

-- ═══ MAIN CONTAINER (RIGHT SIDE, VERTICALLY CENTERED) ═══
local container = Instance.new("Frame")
container.Name = "DialogueContainer"
container.AnchorPoint = Vector2.new(1, 0.5) -- Anchored to the Right, Center
container.Size = UDim2.fromOffset(300, 250)  -- TINY width!
container.Position = UDim2.fromScale(0.98, 0.5) -- Far right edge, middle of screen
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.Visible = false
container.Parent = gui

-- Layout for stacking vertically
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8) -- 8px padding between elements
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- ═══ NPC TEXT (The greeting/story) ═══
local npcText = Instance.new("TextLabel")
npcText.Name = "NpcText"
npcText.Size = UDim2.fromOffset(280, 40) -- SMALL size
npcText.BackgroundTransparency = 1
npcText.BorderSizePixel = 0
npcText.Text = ""
npcText.Font = Enum.Font.FredokaOne
npcText.TextColor3 = Color3.fromRGB(255, 255, 255)
npcText.TextStrokeTransparency = 0
npcText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
npcText.TextScaled = true
npcText.TextWrapped = true
npcText.LayoutOrder = 1
npcText.TextXAlignment = Enum.TextXAlignment.Right -- Align right!
npcText.Parent = container

local npcPadding = Instance.new("UIPadding")
npcPadding.PaddingRight = UDim.new(0, 5); npcPadding.PaddingLeft = UDim.new(0, 5)
npcPadding.Parent = npcText

local npcScale = Instance.new("UIScale")
npcScale.Scale = 0
npcScale.Parent = npcText

-- ═══ CHOICE BUTTON FACTORY (TINY!) ═══
local function createChoiceButton(index, choiceData)
	local btn = Instance.new("TextButton")
	btn.Name = "Choice" .. index
	btn.Size = UDim2.fromOffset(260, 30) -- VERY SMALL BUTTONS
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = "#" .. index .. " [" .. choiceData.Text .. "]"
	btn.Font = Enum.Font.FredokaOne
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	btn.AutoButtonColor = false
	btn.LayoutOrder = index + 1
	btn.TextXAlignment = Enum.TextXAlignment.Right -- Align right!
	btn.Parent = container

	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 5); padding.PaddingLeft = UDim.new(0, 5)
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

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		-- Shrink everything out
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		TweenService:Create(npcScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()

		task.wait(0.2)
		DialogueEvent:FireServer(choiceData.Action)
		container.Visible = false
	end)

	return scale
end

-- ═══ SHOW DIALOGUE (With Bouncy Pop-in) ═══
local function showDialogue(npcMessage, choices)
	-- Clear old buttons
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Set NPC text
	npcText.Text = npcMessage

	-- Create new buttons
	local scales = {}
	for i, choiceData in ipairs(choices) do
		local scale = createChoiceButton(i, choiceData)
		table.insert(scales, scale)
	end

	-- Show container
	container.Visible = true

	-- Bouncy pop-in for NPC Text
	npcScale.Scale = 0
	local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(npcScale, info, { Scale = 1 }):Play()

	-- Staggered bouncy pop-in for choices
	for i, scale in ipairs(scales) do
		task.delay(0.1 + ((i - 1) * 0.06), function()
			TweenService:Create(scale, info, { Scale = 1 }):Play()
		end)
	end
end

-- LISTEN FOR DIALOGUE FROM SERVER
DialogueEvent.OnClientEvent:Connect(function(data)
	if data.Type == "ShowChoices" then
		showDialogue(data.NpcText, data.Choices)
	end
end)

print("✅ Right-Side Grow a Garden UI loaded! (Tiny & Clean)")
]==]

print("✅ GROW A GARDEN RIGHT-SIDE UI INSTALLED!")
print("📏 Tiny text (280px wide, 30px buttons)!")
print("➡️ Positioned exactly on the right edge of the screen!")
print("✨ Bouncy pop-in cascade!")
