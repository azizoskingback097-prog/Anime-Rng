-- ═══════════════════════════════════════════════════════════
-- 🛑 VFX NO-PUSH FIX — removes hidden physics engines!
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This fixes the "pushing player" bug by deleting ALL hidden 
-- scripts, forces, and constraints inside the VFX rig.
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

print("VFX CLIENT LOADED! (No-Push Fix)")

local currentRig = nil
local trackConnection = nil

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

local function attachRig(character, rigName)
	local template = CustomVFX:FindFirstChild(rigName)
	if not template then return false end

	print("VFX: Cloning '" .. rigName .. "'...")
	local clone = template:Clone()
	local parts = {}

	-- 1️⃣ PURGE HIDDEN DANGER: Destroy all scripts, constraints, and forces!
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			obj:Destroy()
		elseif obj:IsA("Constraint") or obj:IsA("BodyMover") or obj:IsA("VectorForce") or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") then
			obj:Destroy()
		end
	end

	-- 2️⃣ MAKE EVERYTHING INVISIBLE & NO COLLISION
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CanTouch = false
			obj.Massless = true
			obj.Anchored = true
			obj.CastShadow = false
			table.insert(parts, obj)
		end
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		end
		if obj:IsA("SpecialMesh") then
			obj:Destroy()
		end
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
		end
		obj:SetAttribute(TAG, true)
	end

	if clone:IsA("BasePart") then
		clone.Transparency = 1
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.Massless = true
		clone.Anchored = true
		clone.CastShadow = false
		table.insert(parts, clone)
	end

	if #parts == 0 then
		clone:Destroy()
		return false
	end

	-- Calculate center
	local totalPos = Vector3.new(0, 0, 0)
	for _, part in ipairs(parts) do totalPos = totalPos + part.Position end
	local center = totalPos / #parts

	-- Pick primary part
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

	local centerOffsetX = primaryPart.Position.X - center.X
	local centerOffsetZ = primaryPart.Position.Z - center.Z

	-- 3️⃣ WELD EVERYTHING TOGETHER
	-- (Delete old welds first so they don't conflict)
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") then
			obj:Destroy()
		end
	end

	-- Weld all parts to the primaryPart
	for _, part in ipairs(parts) do
		if part ~= primaryPart then
			local weld = Instance.new("Weld")
			weld.Part0 = primaryPart
			weld.Part1 = part
			weld.C0 = primaryPart.CFrame:Inverse() * part.CFrame
			weld.Parent = part
		end
	end

	-- Parent to workspace
	clone.Parent = workspace
	currentRig = clone

	-- 4️⃣ TRACKING LOOP
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		trackConnection = RunService.Heartbeat:Connect(function()
			if not currentRig or not currentRig.Parent then return end
			if not character or not character.Parent or not hrp or not hrp.Parent then
				clearVFX()
				return
			end

			local targetPos = hrp.Position + OFFSET
			targetPos = Vector3.new(targetPos.X - centerOffsetX, targetPos.Y, targetPos.Z - centerOffsetZ)

			primaryPart.CFrame = CFrame.new(targetPos, targetPos + hrp.CFrame.LookVector)
		end)
	end

	print("VFX: SUCCESS! '" .. rigName .. "' attached! (" .. #parts .. " parts) - ZERO pushing!")
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
	if VFXConfig and VFXConfig.Rigs then rigName = VFXConfig.Rigs[baseName] end
	if not rigName then
		local auto = CustomVFX:FindFirstChild(baseName)
		if auto then rigName = baseName end
	end
	if rigName then attachRig(character, rigName) end
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

print("✅ VFX NO-PUSH FIX APPLIED!")
print("🛑 All hidden scripts and forces are deleted before attaching!")
print("🎮 Test it now — no more getting pushed off the map!")
