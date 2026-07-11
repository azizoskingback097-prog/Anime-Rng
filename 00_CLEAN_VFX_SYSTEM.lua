-- ═══════════════════════════════════════════════════════════
-- 🗑️ DELETE old VFX stuff + 🆕 Install clean system
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This does everything in ONE paste:
--   1. Deletes broken VFXData
--   2. Creates clean VFXConfig (strings only — NO .new calls!)
--   3. Creates clean VFXClient (clones your rigs)
--   4. Creates CustomVFX folder
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- Step 1: Delete broken VFXData
local oldData = RS:FindFirstChild("VFXData")
if oldData then oldData:Destroy() print("🗑️ Deleted broken VFXData") end

-- Delete old VFXClient
local oldClient = SPS:FindFirstChild("VFXClient")
if oldClient then oldClient:Destroy() print("🗑️ Deleted old VFXClient") end

-- Step 2: Create CustomVFX folder (where your rigs go!)
local cvx = RS:FindFirstChild("CustomVFX")
if not cvx then
	cvx = Instance.new("Folder")
	cvx.Name = "CustomVFX"
	cvx.Parent = RS
end
print("📁 CustomVFX folder ready")

-- Step 3: Create VFXConfig (SIMPLE — just strings, no .new calls!)
local cfg = RS:FindFirstChild("VFXConfig")
if cfg then cfg:Destroy() end
cfg = Instance.new("ModuleScript")
cfg.Name = "VFXConfig"
cfg.Parent = RS
cfg.Source = [==[
-- ============================================================
--  VFXConfig  (ModuleScript)
--  ReplicatedStorage > VFXConfig
-- ============================================================
--  Maps AURA NAMES to your VFX rig names in CustomVFX folder.
--
--  HOW TO ADD YOUR OWN VFX:
--    1. Put your VFX rig (Model with particle emitters) in
--       ReplicatedStorage > CustomVFX
--    2. Note the EXACT name of your rig
--    3. Add a line below: ["AuraName"] = "YourRigName",
--
--  Example:
--    ["Nine-Tails"] = "MyFireRig",
--    ["Genesis"] = "DivineWindRig",
-- ============================================================

local VFXConfig = {}

-- Map aura name to rig name in CustomVFX folder
VFXConfig.Rigs = {
	-- Left side = aura name (from AuraData, case sensitive!)
	-- Right side = name of your VFX Model in CustomVFX folder

	-- Add your rigs here! Examples:
	-- ["Nine-Tails"] = "Akaza",
	-- ["Genesis"] = "White",
	-- ["Tempest"] = "CrystalEffect",
}

return VFXConfig
]==]
print("✅ Created VFXConfig (clean, no .new calls!)")

-- Step 4: Create VFXClient (clones rigs, no scripted particles!)
local client = Instance.new("LocalScript")
client.Name = "VFXClient"
client.Parent = SPS
client.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CustomVFX = ReplicatedStorage:WaitForChild("CustomVFX")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")

-- Load VFXConfig (safe — if it errors, we still run)
local VFXConfig
local ok = pcall(function()
	VFXConfig = require(ReplicatedStorage:WaitForChild("VFXConfig"))
end)
if not ok then
	warn("VFX: VFXConfig has an error — but we can still use auto-detect!")
	VFXConfig = nil
end

local TAG = "AuraVFX"

print("==================================================")
print("VFX CLIENT LOADED!")
if VFXConfig and VFXConfig.Rigs then
	local count = 0
	for _ in pairs(VFXConfig.Rigs) do count = count + 1 end
	print("VFXConfig has " .. count .. " aura mappings")
end
print("CustomVFX folder has " .. #CustomVFX:GetChildren() .. " items:")
for _, item in ipairs(CustomVFX:GetChildren()) do
	print("   - " .. item.Name .. " (" .. item.ClassName .. ")")
end
print("==================================================")

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
		print("   Available rigs:")
		for _, item in ipairs(CustomVFX:GetChildren()) do
			print("   - " .. item.Name)
		end
		if #CustomVFX:GetChildren() == 0 then
			print("   (folder is empty! Put your VFX rigs here)")
		end
		return false
	end

	print("VFX: Cloning '" .. rigName .. "'...")
	local clone = template:Clone()

	local parts = {}
	local primaryPart = nil

	-- Find all parts and particles
	for _, obj in ipairs(clone:GetDescendants()) do
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
		if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = true
		end
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
		print("VFX: WARNING — no parts found in '" .. rigName .. "'!")
		clone:Destroy()
		return false
	end

	if clone:IsA("Model") then
		clone.PrimaryPart = primaryPart
	end

	-- Save offsets so rig keeps its shape
	local offsets = {}
	for _, part in ipairs(parts) do
		if part ~= primaryPart then
			offsets[part] = primaryPart.CFrame:Inverse() * part.CFrame
		end
	end

	-- Find player's body part
	local bodyPart = character:FindFirstChild("HumanoidRootPart")
	if not bodyPart then
		print("VFX: No HumanoidRootPart!")
		clone:Destroy()
		return false
	end

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

-- Parse mutation prefix ("Sandy|Nine-Tails" -> "Nine-Tails")
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
	print("VFX: Looking for VFX for '" .. baseName .. "'...")

	-- Step 1: Check VFXConfig for explicit mapping
	local rigName = nil
	if VFXConfig and VFXConfig.Rigs then
		rigName = VFXConfig.Rigs[baseName]
	end

	-- Step 2: If no mapping, try auto-detect (rig named same as aura)
	if not rigName then
		local auto = CustomVFX:FindFirstChild(baseName)
		if auto then
			rigName = baseName
			print("VFX: Auto-detected rig '" .. rigName .. "'")
		end
	end

	-- Step 3: Attach!
	if rigName then
		attachRig(character, rigName)
	else
		print("VFX: No VFX for '" .. baseName .. "'")
		print("   To add: put a rig in CustomVFX and map it in VFXConfig!")
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
print("✅ Created VFXClient (clean rig-cloning system!)")

print("══════════════════════════════════════")
print("✅ CLEAN VFX SYSTEM INSTALLED!")
print("══════════════════════════════════════")
print("📁 Put your VFX rigs in ReplicatedStorage > CustomVFX")
print("📋 Map them in VFXConfig (or just name them after auras!)")
print("🎮 Press Play → equip an aura → check Output!")
print("══════════════════════════════════════")
