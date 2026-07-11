-- ═══════════════════════════════════════════════════════════
-- 🎬 AUTO-DETECT ANIMATION SYSTEM
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- HOW TO ADD AN ANIMATION TO AN AURA (No coding required!):
--   1. In ReplicatedStorage, find the folder named "CustomAnimations"
--   2. Add an "Animation" object inside it (hover over folder, click +, search Animation)
--   3. Click your new Animation object
--   4. In Properties, find "AnimationId" and paste your ID (rbxassetid://123...)
--   5. Rename the Animation object to EXACTLY match the aura (e.g., "Nine-Tails")
--   6. Done! When you equip that aura, the animation plays automatically!
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- 1. Create the CustomAnimations folder
local animFolder = RS:FindFirstChild("CustomAnimations")
if not animFolder then
	animFolder = Instance.new("Folder")
	animFolder.Name = "CustomAnimations"
	animFolder.Parent = RS
end

-- 2. Update AnimationClient to use Auto-Detect
local oldClient = SPS:FindFirstChild("AnimationClient")
if oldClient then oldClient:Destroy() end
task.wait(0.1)

local client = Instance.new("LocalScript")
client.Name = "AnimationClient"
client.Parent = SPS
client.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquippedChangedEvent = Remotes:WaitForChild("EquippedChangedEvent")
local AnimFolder = ReplicatedStorage:WaitForChild("CustomAnimations")

local currentTrack = nil
local isWalking = false

local function stopAnimation()
	if currentTrack then
		currentTrack:Stop(0.3)
		currentTrack = nil
	end
end

local function playAnimation(character, animId)
	if not animId or animId == "" then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	stopAnimation()

	local anim = Instance.new("Animation")
	anim.AnimationId = animId

	local success, track = pcall(function() return animator:LoadAnimation(anim) end)

	if success and track then
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		currentTrack = track
		print("🎬 Playing animation: " .. animId)
	else
		warn("🎬 Failed to load animation: " .. animId)
	end
end

local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

local currentEquipped = nil

local function updateAnimation()
	local character = player.Character
	if not character then return end
	stopAnimation()

	if not currentEquipped or currentEquipped == "" then return end
	local baseName = parseName(currentEquipped)

	-- 🌟 AUTO-DETECT: Look for an Animation object with this aura's name!
	local animObj = AnimFolder:FindFirstChild(baseName)
	
	if animObj and animObj:IsA("Animation") then
		if not isWalking then
			playAnimation(character, animObj.AnimationId)
		end
	end
end

EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	currentEquipped = auraName
	updateAnimation()
end)

-- Handle Walking vs Idle
player.CharacterAdded:Connect(function()
	task.wait(1.5)
	local character = player.Character
	if not character then return end
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Running:Connect(function(speed)
		if speed > 0.1 then
			isWalking = true
			stopAnimation()
		else
			isWalking = false
			updateAnimation()
		end
	end)

	updateAnimation()
end)

print("🎬 Auto-Detect AnimationClient loaded!")
]==]

print("✅ AUTO-DETECT ANIMATION SYSTEM INSTALLED!")
print("📁 A folder named 'CustomAnimations' was created in ReplicatedStorage.")
print("🎮 Add Animation objects there, name them after auras, and you're done!")
