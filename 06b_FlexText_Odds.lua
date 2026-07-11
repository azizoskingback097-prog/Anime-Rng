-- ═══════════════════════════════════════════════════════════
-- ✨  SYS2 #6b — FLEX TEXT (compact odds via FormatOddsNumber)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Replaces:  StarterPlayerScripts ▸ FlexTextClient  (LocalScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 Same flex text you have now, but the "1 in X" number uses
--    FormatOddsNumber so it stays short (1 in 70K, 1 in 999K, 1 in 1M).
--    Run AFTER #1 (NumberFormatter).
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

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")
local AuraData = require(ReplicatedStorage:WaitForChild("AuraData"))
local F = require(ReplicatedStorage:WaitForChild("NumberFormatter"))   -- 🔢 compact odds

local currentBillboard = nil
local currentParticles = nil

-- 🎨 CUSTOM AURA STYLES (Add more here!)
local CUSTOM_STYLES = {
	["Conqueror Haki"] = {
		Color = Color3.fromRGB(200, 0, 0), StrokeColor = Color3.fromRGB(150, 0, 0),
		Particles = { Texture = "rbxassetid://243660364", Color = ColorSequence.new(Color3.fromRGB(255, 50, 50)),
			Rate = 30, Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(45, 45) },
	},
	["Genesis"] = {
		Color = Color3.fromRGB(255, 255, 200), StrokeColor = Color3.fromRGB(200, 150, 0),
		Particles = { Texture = "rbxassetid://243660364", Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
			Rate = 20, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180) },
	},
}

local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

local function clearText()
	if currentBillboard then currentBillboard:Destroy(); currentBillboard = nil end
	if currentParticles then currentParticles:Destroy(); currentParticles = nil end
end

local function applyText(character, auraName)
	clearText()
	if not auraName or auraName == "" then return end

	local baseName = parseName(auraName)
	local aura = AuraData.GetByName(baseName)
	if not aura then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	local style = CUSTOM_STYLES[baseName] or {
		Color = aura.Color or Color3.fromRGB(255, 255, 255),
		StrokeColor = Color3.fromRGB(0, 0, 0),
		Particles = nil,
	}

	local bb = Instance.new("BillboardGui")
	bb.Name = "FlexText"; bb.Adornee = head
	bb.Size = UDim2.new(5, 0, 1.5, 0); bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.Parent = head
	currentBillboard = bb

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 1
	-- 🔢 compact odds: 1 in 1000 .. 1 in 70K .. 1 in 1M  (stays short)
	lbl.Text = baseName .. "\n1 in " .. F.FormatOddsNumber(aura.Rarity)
	lbl.Font = Enum.Font.GothamBlack; lbl.TextScaled = true
	lbl.TextColor3 = style.Color; lbl.ZIndex = 2; lbl.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4; stroke.Color = style.StrokeColor; stroke.Transparency = 0; stroke.Parent = lbl

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, style.Color),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, style.Color),
	})
	grad.Parent = lbl

	if style.Particles then
		local pPart = Instance.new("Part")
		pPart.Name = "ParticleHolder"; pPart.Size = Vector3.new(1, 1, 1)
		pPart.Transparency = 1; pPart.CanCollide = false; pPart.CanQuery = false
		pPart.Anchored = false; pPart.Massless = true
		local w = Instance.new("Weld")
		w.Part0 = head; w.Part1 = pPart; w.C0 = CFrame.new(0, 1.5, 0); w.Parent = pPart
		pPart.Parent = character

		local emit = Instance.new("ParticleEmitter")
		emit.Texture = style.Particles.Texture; emit.Color = style.Particles.Color
		emit.Rate = style.Particles.Rate; emit.Lifetime = style.Particles.Lifetime
		emit.Speed = style.Particles.Speed; emit.SpreadAngle = style.Particles.SpreadAngle
		emit.LightEmission = 1; emit.Parent = pPart
		currentParticles = pPart
	end
end

EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	local char = player.Character
	if char then applyText(char, auraName) end
end)

player.CharacterAdded:Connect(function(char) task.wait(1) end)

print("FlexTextClient V3 loaded! (compact odds: 1 in 70K style)")
]==]

print("✅ FlexText updated! Odds now use FormatOddsNumber (stays short).")
