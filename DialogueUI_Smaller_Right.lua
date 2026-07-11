-- ═══════════════════════════════════════════════════════════
-- 💬 PREMIUM DIALOGUE UI (Smaller + Right Side Positioning)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Changes:
--   • Smaller text (350x35 instead of 450x50)
--   • Positioned on the RIGHT side of screen
--   • Vertically centered
--   • Same bouncy pop-in + hover effects!
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

-- BUILD SCREEN GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DialogueGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 22
gui.Parent = playerGui

-- Container (RIGHT SIDE, vertically centered)
local container = Instance.new("Frame")
container.Name = "ChoiceContainer"
container.AnchorPoint = Vector2.new(1, 0.5) -- Right-aligned, vertically centered
container.Size = UDim2.fromOffset(360, 200)
container.Position = UDim2.fromScale(0.98, 0.5) -- Far right, center vertically
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.Visible = false
container.Parent = gui

-- UIListLayout: Padding 4px, Top alignment
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4) -- Smaller padding
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right -- Right-aligned!
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- CREATE CHOICE BUTTON (Smaller!)
local function createChoiceButton(index, choiceData)
	local btn = Instance.new("TextButton")
	btn.Name = "Choice" .. index
	btn.Size = UDim2.fromOffset(340, 35) -- SMALLER! (was 450x50)
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

	-- Padding so text doesn't touch edges
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = btn

	-- UIScale for bouncy pop-in
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = btn

	-- HOVER EFFECTS
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			TextColor3 = Color3.fromRGB(255, 235, 100) -- Yellow
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			TextColor3 = Color3.fromRGB(255, 255, 255) -- White
		}):Play()
	end)

	-- CLICK HANDLER
	btn.MouseButton1Click:Connect(function()
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

-- SHOW CHOICES (Staggered Bouncy Pop-in)
local function showChoices(choices)
	-- Clear old buttons
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Create new buttons
	local scales = {}
	for i, choiceData in ipairs(choices) do
		local scale = createChoiceButton(i, choiceData)
		table.insert(scales, scale)
	end

	-- Show container
	container.Visible = true

	-- Staggered bouncy pop-in (0.06s delay each)
	for i, scale in ipairs(scales) do
		task.delay((i - 1) * 0.06, function()
			local info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(scale, info, { Scale = 1 }):Play()
		end)
	end
end

-- HIDE CHOICES
local function hideChoices()
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then
			local scale = child:FindFirstChildOfClass("UIScale")
			if scale then
				TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
					Scale = 0
				}):Play()
			end
		end
	end
	task.wait(0.2)
	container.Visible = false
end

-- LISTEN FOR DIALOGUE FROM SERVER
DialogueEvent.OnClientEvent:Connect(function(data)
	if data.Type == "ShowChoices" then
		showChoices(data.Choices)
	end
end)

print("✅ DialogueUI loaded! (Smaller + Right Side)")
]==]

print("✅ DIALOGUE UI UPDATED!")
print("📏 Smaller buttons (340x35)!")
print("➡️ Positioned on the RIGHT side of screen!")
print("✨ Same bouncy pop-in + hover effects!")
