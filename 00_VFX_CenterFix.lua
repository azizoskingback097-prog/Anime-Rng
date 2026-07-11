-- ═══════════════════════════════════════════════════════════
-- 🔧 VFX CENTER + INVISIBILITY FIX
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Fixes:
--   1. Centers the rig on the player (bounding box calculation)
--   2. Makes EVERYTHING invisible (Parts, Meshes, Decals, etc.)
--   3. Removes ALL collision
--   4. Adds OFFSET option so you can fine-tune position
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local old = SPS:FindFirstChild("VFXClient")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "VFXClient"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CustomVFX = ReplicatedStorage:WaitForChild("CustomVFX")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")

local VFXConfig
pcall(function() VFXConfig = require(ReplicatedStorage:WaitForChild("VFXConfig")) end)

local TAG = "AuraVFX"

-- OFFSET: adjust where the rig sits on the player
-- X = left/right, Y = up/down, Z = forward/back
local OFFSET = Vector3.new(0, 0, 0)

print("VFX CLIENT LOADED! (center + invisibility fix)")

local function clearVFX(character)
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:GetAttribute(TAG) then
			if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
				obj.Enabled = false
			end
			obj:Destroy()
		end
	end
end

local function makeInvisible(obj)
	-- Parts: set transparency + remove collision
	if obj:IsA("BasePart") then
		obj.Transparency = 1
		obj.CanCollide = false
		obj.CanQuery = false
		obj.CanTouch = false
		obj.Massless = true
		obj.Anchored = false
		obj.CastShadow = false
	end
	-- Decals & Textures
	if obj:IsA("Decal") or obj:IsA("Texture") then
		obj.Transparency = 1
	end
	-- SpecialMesh: delete it (it's just a visual shape)
	if obj:IsA("SpecialMesh") then
		obj:Destroy()
	end
end

local function attachRig(character, rigName)
	local template = CustomVFX:FindFirstChild(rigName)
	if not template then
		print("VFX: No rig named '" .. rigName .. "'!")
		return false
	end

	print("VFX: Cloning '" .. rigName .. "'...")
	local clone = template:Clone()

	local parts = {}

	-- Collect all parts + make everything invisible
	for _, obj in ipairs(clone:GetDescendants()) do
		makeInvisible(obj)
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
		end
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
		end
		obj:SetAttribute(TAG, true)
	end

	-- Handle if clone itself is a Part
	if clone:IsA("BasePart") then
		makeInvisible(clone)
		table.insert(parts, clone)
	end

	if #parts == 0 then
		print("VFX: No parts in '" .. rigName .. "'!")
		clone:Destroy()
		return false
	end

	-- Calculate the CENTER of all parts (bounding box)
	local totalPos = Vector3.new(0, 0, 0)
	for _, part in ipairs(parts) do
		totalPos = totalPos + part.Position
	end
	local center = totalPos / #parts

	-- Pick a primary part (closest to center)
	local primaryPart = parts[1]
	local closestDist = math.huge
	for _, part in ipairs(parts) do
		local dist = (part.Position - center).Magnitude
		if dist < closestDist then
			closestDist = dist
			primaryPart = part
		end
	end

	-- Calculate offset from primaryPart to center
	local centerOffset = primaryPart.CFrame:Inverse() * center

	-- Save relative positions of all parts to primaryPart
	local offsets = {}
	for _, part in ipairs(parts) do
		if part ~= primaryPart then
			offsets[part] = primaryPart.CFrame:Inverse() * part.CFrame
		end
	end

	-- Find player's HumanoidRootPart
	local bodyPart = character:FindFirstChild("HumanoidRootPart")
	if not bodyPart then
		clone:Destroy()
		return false
	end

	-- Position the rig so its CENTER is at the player + OFFSET
	-- We move primaryPart to: player position - centerOffset (so center aligns)
	local targetCFrame = bodyPart.CFrame * CFrame.new(OFFSET) * CFrame.new(-centerOffset.X, 0, -centerOffset.Z)
	primaryPart.CFrame = CFrame.new(targetCFrame.Position, targetCFrame.Position + bodyPart.CFrame.LookVector)

	if clone:IsA("Model") then
		clone.PrimaryPart = primaryPart
	end

	clone:SetAttribute(TAG, true)
	clone.Parent = character

	-- Weld primaryPart to player
	local mainWeld = Instance.new("Weld")
	mainWeld.Part0 = bodyPart
	mainWeld.Part1 = primaryPart
	mainWeld.Parent = primaryPart

	-- Weld all other parts
	for part, offset in pairs(offsets) do
		local w = Instance.new("Weld")
		w.Part0 = primaryPart
		w.Part1 = part
		w.C0 = offset
		w.Parent = part
	end

	print("VFX: SUCCESS! '" .. rigName .. "' centered on player! (" .. #parts .. " parts)")
	return true
end

local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

local currentEquipped = nil

local function updateVFX()
	local character = player.Character
	if not character then return end
	clearVFX(character)
	if not currentEquipped or currentEquipped == "" then return end
	local baseName = parseName(currentEquipped)

	local rigName = nil
	if VFXConfig and VFXConfig.Rigs then
		rigName = VFXConfig.Rigs[baseName]
	end
	if not rigName then
		local auto = CustomVFX:FindFirstChild(baseName)
		if auto then rigName = baseName end
	end
	if rigName then
		attachRig(character, rigName)
	end
end

EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	currentEquipped = auraName
	updateVFX()
end)

player.CharacterAdded:Connect(function()
	task.wait(1.5)
	updateVFX()
end)
]==]

print("══════════════════════════════════════")
print("✅ VFX CENTER + INVISIBILITY FIX!")
print("══════════════════════════════════════")
print("🎯 Rig now centers on player automatically!")
print("👻 All parts, meshes, decals invisible!")
print("🚫 All collision removed!")
print("══════════════════════════════════════")
print("💡 If still off-center, open VFXClient and edit OFFSET:")
print("   local OFFSET = Vector3.new(0, 0, 0)")
print("   X = left/right, Y = up/down, Z = forward/back")
print("══════════════════════════════════════")
