-- ═══════════════════════════════════════════════════════════
-- ✨ EQUIPPED FLEX TEXT (Rarity Above Head)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Displays a stylized "1 in X" rarity text above the player's head
-- when an aura is equipped. Uses a UIGradient to match the aura's color.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("FlexTextClient")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "FlexTextClient"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))

local currentBillboard = nil
local gradientOffset = 0

-- Parse aura name (handles "Sandy|Nine-Tails")
local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

local function clearText()
	if currentBillboard then
		currentBillboard:Destroy()
		currentBillboard = nil
	end
end

local function applyText(character, auraName)
	clearText()
	if not auraName or auraName == "" then return end

	local baseName = parseName(auraName)
	local aura = AuraData.GetByName(baseName)
	if not aura then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Create Billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "FlexText"
	bb.Adornee = head
	bb.Size = UDim2.new(4, 0, 1, 0)
	bb.StudsOffset = Vector3.new(0, 2.5, 0) -- Above head
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = head
	currentBillboard = bb

	-- Text Label
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "1 in " .. aura.Rarity
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.ZIndex = 2
	lbl.Parent = bb

	-- Stroke (Outline)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.2
	stroke.Parent = lbl

	-- Gradient (Color changing effect to match aura)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, aura.Color or Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, aura.Color or Color3.fromRGB(255,255,255))
	})
	grad.Rotation = 0
	grad.Parent = lbl

	-- Animate the gradient
	task.spawn(function()
		while currentBillboard == bb and bb.Parent do
			gradientOffset = (gradientOffset + 0.05) % 1
			grad.Offset = Vector2.new(gradientOffset, 0)
			task.wait(0.03)
		end
	end)
end

-- Listen for equip changes
EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	local char = player.Character
	if char then
		applyText(char, auraName)
	end
end)

-- Re-apply on respawn
player.CharacterAdded:Connect(function(char)
	task.wait(1) -- Wait for character to load
	-- We don't know the equipped aura here locally without asking server, 
	-- but the server fires EquippedChangedEvent on join automatically.
end)

print("FlexTextClient loaded! (Rarity Text Above Head)")
]==]

print("✅ EQUIPPED FLEX TEXT INSTALLED!")
print("✨ Rarity text will now float above your head with a color gradient!")
