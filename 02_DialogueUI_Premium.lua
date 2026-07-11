-- ═══════════════════════════════════════════════════════════
-- 💬 PREMIUM DIALOGUE UI (Player Choices - Strict Visual Spec)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- STRICT VISUAL SPECIFICATIONS:
--   • ScreenGui: Player choices at center-bottom
--   • UIListLayout: Padding 5px, VerticalAlignment Top
--   • TextButton: BackgroundTransparency = 1, BorderSizePixel = 0
--   • Font: FredokaOne (bold, bubbly cartoon font)
--   • TextColor3: Pure White (255,255,255)
--   • TextStrokeTransparency: 0 (thick crisp black outline)
--   • TextStrokeColor3: Pure Black (0,0,0)
--   • TextScaled: true
--   • Text format: "#1 [Option Text here]"
--   • Hover: MouseEnter → Yellow, MouseLeave → White
--   • Bouncy pop-in: UIScale 0→1, Back/Out, 0.35s (staggered)
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
	if c.Name == "DialogueGui" then c:Destroy() end
end

-- ═══════════════════════════════════════════════════════════
-- BUILD THE SCREEN GUI
-- ═══════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "DialogueGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 22
gui.Parent = playerGui

-- Container for choices (center-bottom)
local container = Instance.new("Frame")
container.Name = "ChoiceContainer"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Size = UDim2.fromOffset(500, 300)
container.Position = UDim2.fromScale(0.5, 0.92) -- Center-bottom
container.BackgroundTransparency = 1 -- NO background!
container.BorderSizePixel = 0
container.Visible = false
container.Parent = gui

-- UIListLayout: Padding 5px, VerticalAlignment Top
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5) -- 5px padding
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- ═══════════════════════════════════════════════════════════
-- CHOICE BUTTON FACTORY (Strict Visual Spec)
-- ═══════════════════════════════════════════════════════════
local function createChoiceButton(index, choiceData)
	-- The TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "Choice" .. index
	btn.Size = UDim2.fromOffset(450, 50)
	btn.BackgroundTransparency = 1 -- MANDATORY: No box!
	btn.BorderSizePixel = 0 -- MANDATORY: No border!
	-- Text format: "#1 [Option Text]"
	btn.Text = "#" .. index .. " [" .. choiceData.Text .. "]"
	btn.Font = Enum.Font.FredokaOne -- Bold, bubbly cartoon font
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(255, 255, 255) -- Pure White
	btn.TextStrokeTransparency = 0 -- MANDATORY: Thick outline!
	btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Pure Black
	btn.AutoButtonColor = false -- We handle hover manually
	btn.LayoutOrder = index
	btn.Parent = container

	-- Add padding so text doesn't touch edges
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = btn

	-- UIScale for bouncy pop-in
	local scale = Instance.new("UIScale")
	scale.Name = "BounceScale"
	scale.Scale = 0 -- Start hidden!
	scale.Parent = btn

	-- ═══ HOVER EFFECTS ═══
	btn.MouseEnter:Connect(function()
		-- Hover: Yellow
		TweenService:Create(btn, TweenInfo.new(0.1), {
			TextColor3 = Color3.fromRGB(255, 235, 100) -- Yellow
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		-- Leave: Back to White
		TweenService:Create(btn, TweenInfo.new(0.1), {
			TextColor3 = Color3.fromRGB(255, 255, 255) -- White
		}):Play()
	end)

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		-- Shrink out animation
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Scale = 0
		}):Play()

		-- Wait for shrink
		task.wait(0.2)

		-- Fire action to server
		DialogueEvent:FireServer(choiceData.Action)

		-- Hide all choices
		container.Visible = false
	end)

	return btn, scale
end

-- ═══════════════════════════════════════════════════════════
-- SHOW CHOICES (With Bouncy Pop-in Animation)
-- ═══════════════════════════════════════════════════════════
local function showChoices(choices)
	-- Clear old buttons
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Create new buttons
	local buttons = {}
	for i, choiceData in ipairs(choices) do
		local btn, scale = createChoiceButton(i, choiceData)
		table.insert(buttons, { Button = btn, Scale = scale })
	end

	-- Show container
	container.Visible = true

	-- Staggered bouncy pop-in
	for i, data in ipairs(buttons) do
		-- Delay each button slightly for cascading effect
		task.delay((i - 1) * 0.06, function()
			-- Bouncy pop-in: UIScale 0 → 1, Back/Out, 0.35s
			local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(data.Scale, tweenInfo, { Scale = 1 }):Play()
		end)
	end
end

-- ═══════════════════════════════════════════════════════════
-- HIDE CHOICES
-- ═══════════════════════════════════════════════════════════
local function hideChoices()
	-- Shrink all buttons out
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then
			local scale = child:FindFirstChild("BounceScale")
			if scale then
				TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
					Scale = 0
				}):Play()
			end
		end
	end

	-- Hide container after shrink
	task.wait(0.2)
	container.Visible = false
end

-- ═══════════════════════════════════════════════════════════
-- LISTEN FOR DIALOGUE FROM SERVER
-- ═══════════════════════════════════════════════════════════
DialogueEvent.OnClientEvent:Connect(function(data)
	if data.Type == "ShowChoices" then
		showChoices(data.Choices)
	end
end)

print("✅ Premium Dialogue UI loaded! (Strict Visual Spec + Bouncy Pop-in)")
]==]

print("✅ PREMIUM DIALOGUE UI INSTALLED!")
print("💬 Player choices: #1 [Option Text] format!")
print("🎨 No backgrounds! White text, black stroke, FredokaOne!")
print("✨ Bouncy pop-in (staggered, Back/Out, 0.35s)!")
print("🖱️ Hover: Yellow on enter, White on leave!")
