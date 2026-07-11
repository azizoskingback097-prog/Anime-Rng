-- ═══════════════════════════════════════════════════════════
-- 💬 DIALOGUE UI (Repositioned: Center-Right + Gold Numbers!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Changes:
--   • Position: Center-right (45% X, 52% Y) - NOT hugging edge!
--   • Alignment: LEFT-aligned (not right)
--   • Numbers: Gold/Yellow (#E7D48A)
--   • Text: Pure White (#FFFFFF)
--   • Font: GothamBold (clean sans-serif)
--   • Size: 32-36px (large and readable)
--   • Thick black outline (TextStroke = 0)
--   • No background panel!
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

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RightDialogueGui" or c.Name == "DialogueGui" then c:Destroy() end
end

-- ⚙️ CONFIG (Easy to customize!)
local CONFIG = {
	-- Position (Center-right area, in front of NPC stall)
	PosX = 0.45,            -- 45% from left (slightly right of center)
	PosY = 0.52,            -- 52% from top (middle-lower)
	
	-- Size
	ButtonWidth = 400,       -- Width in pixels
	ButtonHeight = 36,       -- Height in pixels (large & readable!)
	
	-- Colors (Two-tone!)
	NumberColor = Color3.fromRGB(231, 212, 138),  -- Gold/Yellow (#E7D48A)
	TextColor = Color3.fromRGB(255, 255, 255),     -- Pure White
	HoverColor = Color3.fromRGB(255, 235, 100),   -- Yellow on hover
	
	-- Outline
	StrokeColor = Color3.fromRGB(0, 0, 0),        -- Pure Black
	StrokeTransparency = 0,                        -- 0 = fully visible
	
	-- Font
	Font = Enum.Font.GothamBold,                   -- Clean sans-serif
	
	-- Spacing
	Padding = 8,                                   -- 8px between lines
}

-- ═══ BUILD SCREEN GUI ═══
local gui = Instance.new("ScreenGui")
gui.Name = "DialogueGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 25
gui.Parent = playerGui

-- Container (Center-right position!)
local container = Instance.new("Frame")
container.Name = "ChoiceContainer"
container.AnchorPoint = Vector2.new(0, 0) -- Top-left corner
container.Size = UDim2.fromOffset(CONFIG.ButtonWidth, 300)
container.Position = UDim2.fromScale(CONFIG.PosX, CONFIG.PosY) -- 45% X, 52% Y
container.BackgroundTransparency = 1 -- NO background panel!
container.BorderSizePixel = 0
container.Visible = false
container.Parent = gui

-- UIListLayout: Left-aligned, stacked vertically
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, CONFIG.Padding) -- 8px spacing
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- LEFT-aligned!
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- ═══ CHOICE BUTTON FACTORY (Two-tone colors!) ═══
local function createChoiceButton(index, choiceData)
	-- The number part (Gold/Yellow)
	local numberLabel = Instance.new("TextLabel")
	numberLabel.Name = "Number"
	numberLabel.Size = UDim2.fromOffset(35, CONFIG.ButtonHeight)
	numberLabel.BackgroundTransparency = 1
	numberLabel.BorderSizePixel = 0
	numberLabel.Text = "#" .. index
	numberLabel.Font = CONFIG.Font
	numberLabel.TextScaled = true
	numberLabel.TextColor3 = CONFIG.NumberColor -- Gold/Yellow!
	numberLabel.TextStrokeTransparency = CONFIG.StrokeTransparency
	numberLabel.TextStrokeColor3 = CONFIG.StrokeColor
	numberLabel.TextXAlignment = Enum.TextXAlignment.Left
	numberLabel.LayoutOrder = index

	-- Padding for number
	local numPad = Instance.new("UIPadding", numberLabel)
	numPad.PaddingLeft = UDim.new(0, 2)

	-- The text part (Pure White)
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromOffset(CONFIG.ButtonWidth - 35, CONFIG.ButtonHeight)
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Text = ' ["' .. choiceData.Text .. '"]'
	textLabel.Font = CONFIG.Font
	textLabel.TextScaled = true
	textLabel.TextColor3 = CONFIG.TextColor -- Pure White!
	textLabel.TextStrokeTransparency = CONFIG.StrokeTransparency
	textLabel.TextStrokeColor3 = CONFIG.StrokeColor
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.LayoutOrder = index

	-- Combine into a row frame
	local row = Instance.new("Frame")
	row.Name = "Row" .. index
	row.Size = UDim2.fromOffset(CONFIG.ButtonWidth, CONFIG.ButtonHeight)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Parent = container

	-- Row layout (number on left, text next to it)
	local rowLayout = Instance.new("UIListLayout", row)
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 0)
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	numberLabel.Parent = row
	textLabel.Parent = row

	-- UIScale for bouncy pop-in
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = row

	-- Hover effects (Both labels change to yellow)
	row.MouseEnter:Connect(function()
		TweenService:Create(numberLabel, TweenInfo.new(0.1), { TextColor3 = CONFIG.HoverColor }):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.1), { TextColor3 = CONFIG.HoverColor }):Play()
	end)

	-- We need a TextButton overlay for clicking (invisible)
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.fromScale(1, 1)
	clickBtn.BackgroundTransparency = 1
	clickBtn.BorderSizePixel = 0
	clickBtn.Text = ""
	clickBtn.AutoButtonColor = false
	clickBtn.Parent = row

	clickBtn.MouseEnter:Connect(function()
		TweenService:Create(numberLabel, TweenInfo.new(0.1), { TextColor3 = CONFIG.HoverColor }):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.1), { TextColor3 = CONFIG.HoverColor }):Play()
	end)
	clickBtn.MouseLeave:Connect(function()
		TweenService:Create(numberLabel, TweenInfo.new(0.1), { TextColor3 = CONFIG.NumberColor }):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.1), { TextColor3 = CONFIG.TextColor }):Play()
	end)

	-- Click handler
	clickBtn.MouseButton1Click:Connect(function()
		-- Shrink out
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Scale = 0
		}):Play()

		task.wait(0.2)
		DialogueEvent:FireServer(choiceData.Action)
		container.Visible = false
	end)

	return scale
end

-- ═══ SHOW CHOICES (Staggered Bouncy Pop-in) ═══
local function showChoices(choices)
	-- Clear old buttons
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("Row") then child:Destroy() end
	end

	-- Create new rows
	local scales = {}
	for i, choiceData in ipairs(choices) do
		local scale = createChoiceButton(i, choiceData)
		table.insert(scales, scale)
	end

	-- Show container
	container.Visible = true

	-- Staggered bouncy pop-in
	for i, scale in ipairs(scales) do
		task.delay((i - 1) * 0.06, function()
			local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(scale, info, { Scale = 1 }):Play()
		end)
	end
end

-- ═══ LISTEN FOR DIALOGUE FROM SERVER ═══
DialogueEvent.OnClientEvent:Connect(function(data)
	if data.Type == "ShowChoices" then
		showChoices(data.Choices)
	end
end)

print("✅ Dialogue UI loaded! (Repositioned: Center-Right + Gold Numbers)")
]==]

print("✅ DIALOGUE UI REPOSITIONED!")
print("📍 Position: 45% X, 52% Y (Center-right, in front of stall)")
print("🎨 Numbers: Gold/Yellow | Text: Pure White")
print("📏 Large text (400x36px) with thick black outline!")
print("⬅️ Left-aligned, 8px spacing between lines!")
