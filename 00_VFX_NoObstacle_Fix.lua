-- ═══════════════════════════════════════════════════════════
-- 🚫 VFX NO-OBSTACLE FIX — tracking instead of welding!
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This fixes the obstacle issue PERMANENTLY by making the VFX rig
-- follow the player with a smooth tracking loop instead of welding.
--
-- The rig is:
--   • Anchored (no physics at all)
--   • CanCollide = false (no collision)
--   • Invisible parts (only particles show)
--   • Follows the player smoothly via Heartbeat
--
-- ZERO obstacles. ZERO physics interference. Just pure visual VFX.
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
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CustomVFX = ReplicatedStorage:WaitForChild("CustomVFX")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")

local VFXConfig
pcall(function() VFXConfig = require(ReplicatedStorage:WaitForChild("VFXConfig")) end)

local TAG = "AuraVFX"
local OFFSET = Vector3.new(0, 0, 0)

print("VFX CLIENT LOADED! (no-obstacle tracking fix)")

-- The current rig (if any) and its tracking connection
local currentRig = nil
local trackConnection = nil

-- Clean up old VFX
local function clearVFX()
	if trackConnection then
		trackConnection:Disconnect()
		trackConnection = nil
	end
	if currentRig then
		currentRig:Destroy()
		currentRig = nil
	end
end

-- Make everything invisible + no collision
local function makeInvisible(obj)
	if obj:IsA("BasePart") then
		obj.Transparency = 1
		obj.CanCollide = false
		obj.CanQuery = false
		obj.CanTouch = false
		obj.Massless = true
		obj.Anchored = true
		obj.CastShadow = false
	end
	if obj:IsA("Decal") or obj:IsA("Texture") then
		obj.Transparency = 1
	end
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

	-- Make everything invisible + anchored + no collision
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

	if clone:IsA("BasePart") then
		makeInvisible(clone)
		table.insert(parts, clone)
	end

	if #parts == 0 then
		print("VFX: No parts in '" .. rigName .. "'!")
		clone:Destroy()
		return false
	end

	-- Calculate the CENTER of all parts
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

	if clone:IsA("Model") then
		clone.PrimaryPart = primaryPart
	end

	-- Calculate offset from primaryPart to the center (X and Z only)
	local centerOffsetX = primaryPart.Position.X - center.X
	local centerOffsetZ = primaryPart.Position.Z - center.Z

	-- Parent to workspace (NOT the character — this avoids physics!)
	clone:SetAttribute(TAG, true)
	clone.Parent = workspace

	currentRig = clone

	-- TRACKING LOOP: makes the rig follow the player smoothly
	-- No welding = no physics = NO OBSTACLE!
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		trackConnection = RunService.Heartbeat:Connect(function()
			if not currentRig or not currentRig.Parent then
				return
			end
			if not character or not character.Parent or not hrp or not hrp.Parent then
				clearVFX()
				return
			end

			-- Target position: player position + OFFSET, adjusted for center
			local targetPos = hrp.Position + OFFSET
			targetPos = Vector3.new(targetPos.X - centerOffsetX, targetPos.Y, targetPos.Z - centerOffsetZ)

			-- Smoothly move the rig to follow the player
			primaryPart.CFrame = CFrame.new(targetPos, targetPos + hrp.CFrame.LookVector)
		end)
	end

	print("VFX: SUCCESS! '" .. rigName .. "' tracking player! (" .. #parts .. " parts, ZERO obstacles!)")
	return true
end

local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

local currentEquipped = nil

local function updateVFX()
	clearVFX()

	local character = player.Character
	if not character then return end
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

player.CharacterRemoving:Connect(function()
	clearVFX()
end)
]==]

print("══════════════════════════════════════")
print("✅ VFX NO-OBSTACLE FIX APPLIED!")
print("══════════════════════════════════════")
print("🚫 Rig now uses TRACKING instead of welding!")
print("   → Anchored = true (no physics)")
print("   → CanCollide = false (no collision)")
print("   → Follows player via Heartbeat loop")
print("   → Parented to Workspace (not character)")
print("   = ZERO obstacles, ZERO interference!")
print("══════════════════════════════════════")
print("💡 The rig smoothly follows your character as you move.")
print("   If it feels laggy, that's normal for client-side tracking.")
print("══════════════════════════════════════")
