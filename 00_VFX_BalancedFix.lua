-- VFX BALANCED FIX — particles show AND no pushing!
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

print("VFX CLIENT LOADED! (Balanced Fix)")

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

	-- Process everything: freeze parts, remove forces, enable particles
	for _, obj in ipairs(clone:GetDescendants()) do

		-- Freeze ALL parts (no physics = no pushing!)
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

		-- Remove physics forces (the things that push you!)
		if obj:IsA("Constraint") or obj:IsA("VectorForce") or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyVelocity") or obj:IsA("BodyForce") or obj:IsA("BodyThrust") then
			obj:Destroy()
		end

		-- Enable particles
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
		end

		-- Make visuals invisible
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		end
		if obj:IsA("SpecialMesh") then
			obj:Destroy()
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

	if #parts == 0 then clone:Destroy() return false end

	-- Calculate center
	local totalPos = Vector3.new(0,0,0)
	for _, p in ipairs(parts) do totalPos = totalPos + p.Position end
	local center = totalPos / #parts

	-- Pick primary part
	local primaryPart = parts[1]
	local closestDist = math.huge
	for _, p in ipairs(parts) do
		local d = (p.Position - center).Magnitude
		if d < closestDist then closestDist = d primaryPart = p end
	end

	if clone:IsA("Model") then clone.PrimaryPart = primaryPart end

	local cx = primaryPart.Position.X - center.X
	local cz = primaryPart.Position.Z - center.Z

	-- Weld parts together
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") then
			obj:Destroy()
		end
	end
	for _, p in ipairs(parts) do
		if p ~= primaryPart then
			local w = Instance.new("Weld")
			w.Part0 = primaryPart
			w.Part1 = p
			w.C0 = primaryPart.CFrame:Inverse() * p.CFrame
			w.Parent = p
		end
	end

	clone.Parent = workspace
	currentRig = clone

	-- Tracking loop
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		trackConnection = RunService.Heartbeat:Connect(function()
			if not currentRig or not currentRig.Parent then return end
			if not character or not character.Parent or not hrp or not hrp.Parent then
				clearVFX()
				return
			end
			local tp = hrp.Position + OFFSET
			tp = Vector3.new(tp.X - cx, tp.Y, tp.Z - cz)
			primaryPart.CFrame = CFrame.new(tp, tp + hrp.CFrame.LookVector)
		end)
	end

	print("VFX: SUCCESS! '" .. rigName .. "' attached! (" .. #parts .. " parts)")
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

print("✅ VFX BALANCED FIX APPLIED!")
print("   Particles SHOW + parts FROZEN + forces REMOVED")
print("🎮 Test it — VFX should show AND no pushing!")
