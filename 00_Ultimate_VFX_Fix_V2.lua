-- ═══════════════════════════════════════════════════════════
-- 🚀 ULTIMATE VFX FIX V2 — Fixes single Part crash!
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
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

print("VFX CLIENT LOADED! (Ultimate Fix V2)")

local currentRig = nil
local trackConnection = nil

local function clearVFX()
	if trackConnection then trackConnection:Disconnect() trackConnection = nil end
	if currentRig then currentRig:Destroy() currentRig = nil end
end

local function attachRig(character, rigName)
	local template = CustomVFX:FindFirstChild(rigName)
	if not template then return false end

	print("VFX: Cloning '" .. rigName .. "'...")
	local clone = template:Clone()
	local parts = {}

	-- PURGE pushing forces (VectorForce, BodyVelocity, etc)
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Constraint") or obj:IsA("BodyMover") or obj:IsA("VectorForce") or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyVelocity") or obj:IsA("BodyForce") or obj:IsA("BodyThrust") then
			obj:Destroy()
		end
	end

	-- Make all parts massless and non-collidable
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CanTouch = false
			obj.Massless = true
			obj.Anchored = false
			obj.CastShadow = false
			table.insert(parts, obj)
		end
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		end
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
		end
		obj:SetAttribute(TAG, true)
	end

	-- If the rig itself is just a Part (not a Model), add it to the list!
	if clone:IsA("BasePart") then
		clone.Transparency = 1
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.Massless = true
		clone.Anchored = false
		clone.CastShadow = false
		table.insert(parts, clone)
	end

	if #parts == 0 then clone:Destroy() return false end

	-- 🔧 FIX: Safely find the primary part WITHOUT crashing if it's just a Part
	local primaryPart = nil
	
	-- Only check for PrimaryPart if it's a Model!
	if clone:IsA("Model") then
		primaryPart = clone.PrimaryPart
	end
	
	-- If it didn't have one, look for a part named "Handle", "Main", or just use the first one
	if not primaryPart then
		for _, p in ipairs(parts) do
			if p.Name == "Handle" or p.Name == "Main" or p.Name == "HumanoidRootPart" then
				primaryPart = p
				break
			end
		end
	end
	if not primaryPart then primaryPart = parts[1] end

	-- 1️⃣ CREATE THE TRACKER PART
	local tracker = Instance.new("Part")
	tracker.Name = "VFXTracker"
	tracker.Size = Vector3.new(1, 1, 1)
	tracker.Transparency = 1
	tracker.CanCollide = false
	tracker.CanQuery = false
	tracker.CanTouch = false
	tracker.Anchored = true
	tracker:SetAttribute(TAG, true)
	tracker.Parent = workspace

	-- 2️⃣ WELD THE RIG TO THE TRACKER
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") then
			obj:Destroy()
		end
	end

	local mainWeld = Instance.new("WeldConstraint")
	mainWeld.Part0 = tracker
	mainWeld.Part1 = primaryPart
	mainWeld.Parent = tracker

	for _, p in ipairs(parts) do
		if p ~= primaryPart then
			local w = Instance.new("WeldConstraint")
			w.Part0 = primaryPart
			w.Part1 = p
			w.Parent = tracker
		end
	end

	clone.Parent = workspace
	currentRig = clone

	-- 3️⃣ MOVE ONLY THE TRACKER
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		tracker.CFrame = hrp.CFrame

		trackConnection = RunService.Heartbeat:Connect(function()
			if not currentRig or not currentRig.Parent or not tracker.Parent then return end
			if not character or not character.Parent or not hrp or not hrp.Parent then
				clearVFX()
				return
			end
			tracker.CFrame = hrp.CFrame
		end)
	end

	print("VFX: SUCCESS! '" .. rigName .. "' attached via Tracker! (" .. #parts .. " parts)")
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

player.CharacterAdded:Connect(function() task.wait(1.5) updateVFX() end)
player.CharacterRemoving:Connect(function() clearVFX() end)
]==]

print("✅ ULTIMATE VFX FIX V2 APPLIED!")
print("🛡️ Safely handles both Models and single Parts!")
