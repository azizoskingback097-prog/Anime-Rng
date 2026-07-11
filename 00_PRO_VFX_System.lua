-- ═══════════════════════════════════════════════════════════
-- 💎 ULTIMATE PRO VFX SYSTEM (Final Fix)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- ✅ HANDLES ALL 3 TYPES (Parts, Models, Rigs)
-- ✅ ZERO PUSHING (Uses anchored Tracker part)
-- ✅ PERFECT ALIGNMENT (Matches HumanoidRootPart exactly)
-- ✅ INVISIBLE HANDLERS (Hides the blocks, shows only the VFX)
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

print("VFX CLIENT LOADED! (PRO VFX System)")

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

	-- 1️⃣ PURGE ALL PHYSICS ENGINES & SCRIPTS
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			obj:Destroy()
		elseif obj:IsA("Constraint") or obj:IsA("BodyMover") or obj:IsA("VectorForce") or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyVelocity") or obj:IsA("BodyForce") or obj:IsA("BodyThrust") then
			obj:Destroy()
		end
	end

	-- 2️⃣ CONFIGURE ALL PARTS (Invisible Handlers + No Collision/Weight)
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			-- Make the handler parts invisible so only VFX/Particles show
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CanTouch = false
			obj.Massless = true
			obj.Anchored = false
			obj.CastShadow = false
			table.insert(parts, obj)
		end
		
		-- Turn on all visual effects
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Beam") or obj:IsA("Trail") then
			obj.Enabled = true
		end
		
		obj:SetAttribute(TAG, true)
	end

	-- If the clone itself is just a single Part
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

	-- 3️⃣ FIND THE ROOT OF THE VFX (Perfect Alignment!)
	local primaryPart = nil
	
	-- First, try to find a HumanoidRootPart or Torso (Perfect for Rigs!)
	for _, p in ipairs(parts) do
		if p.Name == "HumanoidRootPart" or p.Name == "RootPart" or p.Name == "Torso" then
			primaryPart = p
			break
		end
	end
	
	-- Second, try to use the Model's assigned PrimaryPart
	if not primaryPart and clone:IsA("Model") then
		primaryPart = clone.PrimaryPart
	end
	
	-- Third, look for a part named "Handle" or "Main"
	if not primaryPart then
		for _, p in ipairs(parts) do
			if p.Name == "Handle" or p.Name == "Main" or p.Name == "Center" then
				primaryPart = p
				break
			end
		end
	end
	
	-- Fallback: Just use the first part we found
	if not primaryPart then primaryPart = parts[1] end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then clone:Destroy() return false end

	-- 4️⃣ CREATE THE INVISIBLE TRACKER (The Anti-Push secret)
	local tracker = Instance.new("Part")
	tracker.Name = "VFXTracker"
	tracker.Size = Vector3.new(2, 2, 1) -- Matches player HRP roughly
	tracker.Transparency = 1
	tracker.CanCollide = false
	tracker.CanQuery = false
	tracker.CanTouch = false
	tracker.Anchored = true
	tracker:SetAttribute(TAG, true)
	
	-- Place tracker exactly on the player BEFORE welding
	tracker.CFrame = hrp.CFrame
	tracker.Parent = workspace

	-- 5️⃣ PERFECT ALIGNMENT (Match RootParts)
	-- Move the VFX's root part EXACTLY to the player's root part
	primaryPart.CFrame = tracker.CFrame

	-- Parent the clone to workspace
	clone.Parent = workspace
	currentRig = clone

	-- 6️⃣ WELD THE VFX TO THE TRACKER
	-- Delete old Motor6Ds so the rig doesn't try to walk on its own
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Motor6D") then
			obj:Destroy()
		end
	end

	-- Weld the main part to the Tracker
	local mainWeld = Instance.new("WeldConstraint")
	mainWeld.Part0 = tracker
	mainWeld.Part1 = primaryPart
	mainWeld.Parent = tracker

	-- Weld all other parts to the main part so the rig keeps its shape
	for _, p in ipairs(parts) do
		if p ~= primaryPart then
			local w = Instance.new("WeldConstraint")
			w.Part0 = primaryPart
			w.Part1 = p
			w.Parent = tracker
		end
	end

	-- 7️⃣ TRACKING LOOP (Move only the Tracker)
	trackConnection = RunService.Heartbeat:Connect(function()
		if not currentRig or not currentRig.Parent or not tracker.Parent then return end
		if not character or not character.Parent or not hrp or not hrp.Parent then
			clearVFX()
			return
		end
		-- Smoothly follow the player
		tracker.CFrame = hrp.CFrame
	end)

	print("VFX: SUCCESS! '" .. rigName .. "' professionally attached! (" .. #parts .. " parts)")
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

print("✅ PRO VFX SYSTEM APPLIED!")
print("💎 Invisible Handlers, Perfect Alignment, Zero Pushing.")
