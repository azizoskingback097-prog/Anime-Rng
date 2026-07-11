-- ═══════════════════════════════════════════════
-- ✨ NEW VFXClient — NO VFXData needed!
-- ═══════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- HOW IT WORKS (super simple!):
--   1. Put your VFX rig in ReplicatedStorage > CustomVFX
--   2. Rename it to EXACTLY match the aura name
--      (e.g. "Nine-Tails" — NOT "NINE-TAILS" or "nine tails")
--   3. Equip that aura → your rig appears on your character!
--
-- NO VFXData editing. NO code to break. Just drag + rename.
-- ═══════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- Delete old VFXClient first
local oldClient = SPS:FindFirstChild("VFXClient")
if oldClient then oldClient:Destroy() end
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

local TAG = "AuraVFX"

print("==================================================")
print("VFX CLIENT LOADED!")
print("CustomVFX folder has " .. #CustomVFX:GetChildren() .. " items:")
for _, item in ipairs(CustomVFX:GetChildren()) do
	print("   - " .. item.Name .. " (type: " .. item.ClassName .. ")")
end
if #CustomVFX:GetChildren() == 0 then
	print("   (empty! Put your VFX rigs here)")
end
print("==================================================")

-- CLEAN UP old VFX from character
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

-- ATTACH RIG: clones your VFX model and welds it to the player
local function attachRig(character, rigName)
	local template = CustomVFX:FindFirstChild(rigName)

	if not template then
		print("VFX: No rig named '" .. rigName .. "' found in CustomVFX!")
		local items = CustomVFX:GetChildren()
		if #items > 0 then
			print("   These rigs ARE available:")
			for _, item in ipairs(items) do
				print("   - " .. item.Name)
			end
		end
		return false
	end

	print("VFX: Cloning rig '" .. rigName .. "' (" .. template.ClassName .. ")...")
	local clone = template:Clone()
	local parts = {}
	local primaryPart = nil

	-- Find all parts and particles in the rig
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
			if not primaryPart then
				primaryPart = obj
			end
			-- Make the part invisible (we only want to see particles!)
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CanTouch = false
			obj.Massless = true
			obj.Anchored = false
		end

		-- Turn ON all particle emitters, fire, smoke
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
			print("   -> Enabled " .. obj.ClassName .. " on " .. tostring(obj.Parent and obj.Parent.Name or "?"))
		end

		-- Tag everything for cleanup
		obj:SetAttribute(TAG, true)
	end

	-- If no parts found, try using the template itself (if it IS a Part)
	if not primaryPart then
		if clone:IsA("BasePart") then
			primaryPart = clone
			table.insert(parts, clone)
			clone.Transparency = 1
			clone.CanCollide = false
			clone.CanQuery = false
			clone.CanTouch = false
			clone.Massless = true
			clone.Anchored = false
		else
			print("VFX: WARNING - No parts found in '" .. rigName .. "'!")
			print("   Make sure your rig has Parts with ParticleEmitters inside.")
			clone:Destroy()
			return false
		end
	end

	-- Set primary part
	clone.PrimaryPart = primaryPart

	-- Record where each part is relative to the primary part
	-- (so the rig keeps its shape when we weld it)
	local offsets = {}
	for _, part in ipairs(parts) do
		if part ~= primaryPart then
			offsets[part] = primaryPart.CFrame:Inverse() * part.CFrame
		end
	end

	-- Find the player's HumanoidRootPart
	local bodyPart = character:FindFirstChild("HumanoidRootPart")
	if not bodyPart then
		print("VFX: WARNING - No HumanoidRootPart on character!")
		clone:Destroy()
		return false
	end

	-- Position the rig at the player
	primaryPart.CFrame = bodyPart.CFrame
	clone:SetAttribute(TAG, true)
	clone.Parent = character

	-- Weld the primary part to the player
	local mainWeld = Instance.new("Weld")
	mainWeld.Part0 = bodyPart
	mainWeld.Part1 = primaryPart
	mainWeld.Parent = primaryPart

	-- Weld all other parts to the primary part (keeps rig shape)
	for part, offset in pairs(offsets) do
		local weld = Instance.new("Weld")
		weld.Part0 = primaryPart
		weld.Part1 = part
		weld.C0 = offset
		weld.Parent = part
	end

	print("VFX: SUCCESS! Rig '" .. rigName .. "' attached! (" .. #parts .. " parts)")
	return true
end

-- Parse aura name (handles mutations like "Sandy|Nine-Tails" -> "Nine-Tails")
local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then
		return string.sub(stored, sep + 1)
	end
	return stored
end

-- Main update function
local currentEquipped = nil

local function updateVFX()
	local character = player.Character
	if not character then
		print("VFX: No character found yet")
		return
	end

	-- Clean up old VFX
	clearVFX(character)

	-- If nothing equipped, we're done
	if not currentEquipped or currentEquipped == "" then
		print("VFX: Nothing equipped, VFX removed")
		return
	end

	-- Get the base aura name
	local baseName = parseName(currentEquipped)
	print("VFX: Looking for rig named '" .. baseName .. "' in CustomVFX...")

	-- Attach the rig!
	attachRig(character, baseName)
end

-- Listen for equip changes from the server
EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	print("VFX: Equip event received: " .. tostring(auraName))
	currentEquipped = auraName
	updateVFX()
end)

-- Re-attach VFX after respawn
player.CharacterAdded:Connect(function()
	print("VFX: Character respawned, re-attaching VFX...")
	task.wait(1.5)
	updateVFX()
end)

print("VFX: Ready! Waiting for equip events...")
]==]

print("══════════════════════════════════════")
print("✅ NEW VFXClient INSTALLED!")
print("══════════════════════════════════════")
print("📁 VFXData has been REMOVED (no more corruption!)")
print("✨ VFXClient now does EVERYTHING by itself")
print("══════════════════════════════════════")
print("🎮 HOW TO USE YOUR VFX:")
print("   1. Put your VFX rig in ReplicatedStorage > CustomVFX")
print("   2. Rename it to EXACTLY match the aura name")
print("      Example: 'Nine-Tails' (capital N, capital T)")
print("   3. Equip that aura → VFX appears!")
print("══════════════════════════════════════")
print("📋 The aura names you can use:")
print("   Flicker, Spark, Glow, Ember, Surge, Bloom")
print("   Spirit Bomb, Tempest, Nine-Tails, Eclipse")
print("   Conqueror Haki, Cursed Energy, Hollow Mask, Genesis")
print("══════════════════════════════════════")
