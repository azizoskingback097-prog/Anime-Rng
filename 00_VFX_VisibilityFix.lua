-- ═══════════════════════════════════════════════════════════
-- 🔧 VFX VISIBILITY FIX — makes rig parts fully invisible + no collision
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This fixes the "obstacle" issue by making EVERYTHING in the rig
-- invisible (Parts, Decals, Textures, Meshes) + removes all collision.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- Delete old VFXClient
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
local ok = pcall(function() VFXConfig = require(ReplicatedStorage:WaitForChild("VFXConfig")) end)
if not ok then VFXConfig = nil end

local TAG = "AuraVFX"

print("VFX CLIENT LOADED! (visibility fix)")

-- Clean up old VFX
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

-- Attach a VFX rig to the character
local function attachRig(character, rigName)
	local template = CustomVFX:FindFirstChild(rigName)

	if not template then
		print("VFX: No rig named '" .. rigName .. "' in CustomVFX!")
		return false
	end

	print("VFX: Cloning '" .. rigName .. "'...")
	local clone = template:Clone()

	local parts = {}
	local primaryPart = nil

	for _, obj in ipairs(clone:GetDescendants()) do

		-- Make ALL parts invisible + no collision
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
			if not primaryPart then primaryPart = obj end
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CanTouch = false
			obj.Massless = true
			obj.Anchored = false
		end

		-- Make Decals invisible (they stick to parts!)
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		end

		-- Turn ON all particle emitters, fire, smoke
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
		end

		-- Tag everything for cleanup
		obj:SetAttribute(TAG, true)
	end

	-- If clone itself is a Part (not a Model)
	if not primaryPart and clone:IsA("BasePart") then
		primaryPart = clone
		table.insert(parts, clone)
		clone.Transparency = 1
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.Massless = true
		clone.Anchored = false
	end

	if not primaryPart then
		print("VFX: No parts found in '" .. rigName .. "'!")
		clone:Destroy()
		return false
	end

	if clone:IsA("Model") then
		clone.PrimaryPart = primaryPart
	end

	-- Save offsets (keeps rig shape)
	local offsets = {}
	for _, part in ipairs(parts) do
		if part ~= primaryPart then
			offsets[part] = primaryPart.CFrame:Inverse() * part.CFrame
		end
	end

	local bodyPart = character:FindFirstChild("HumanoidRootPart")
	if not bodyPart then clone:Destroy() return false end

	-- Position and weld
	primaryPart.CFrame = bodyPart.CFrame
	clone:SetAttribute(TAG, true)
	clone.Parent = character

	local mainWeld = Instance.new("Weld")
	mainWeld.Part0 = bodyPart
	mainWeld.Part1 = primaryPart
	mainWeld.Parent = primaryPart

	for part, offset in pairs(offsets) do
		local w = Instance.new("Weld")
		w.Part0 = primaryPart
		w.Part1 = part
		w.C0 = offset
		w.Parent = part
	end

	print("VFX: SUCCESS! '" .. rigName .. "' attached! (" .. #parts .. " parts)")
	return true
end

-- Parse mutation prefix
local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

-- Main update
local currentEquipped = nil

local function updateVFX()
	local character = player.Character
	if not character then return end
	clearVFX(character)
	if not currentEquipped or currentEquipped == "" then return end
	local baseName = parseName(currentEquipped)

	-- Check VFXConfig for explicit mapping
	local rigName = nil
	if VFXConfig and VFXConfig.Rigs then
		rigName = VFXConfig.Rigs[baseName]
	end

	-- Auto-detect if no mapping
	if not rigName then
		local auto = CustomVFX:FindFirstChild(baseName)
		if auto then rigName = baseName end
	end

	-- Attach!
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

print("✅ VFX VISIBILITY FIX APPLIED!")
print("🔧 Rig parts + Decals + Textures all invisible now!")
print("🔧 All collision removed!")
print("🎮 Press Play → equip → the obstacle should be gone!")
