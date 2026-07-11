-- ═══════════════════════════════════════════════════════════
-- 🎬 CREATE ANIMATION SYSTEM — idle animations per aura!
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- Creates:
--   • AnimationConfig (ModuleScript in ReplicatedStorage)
--   • AnimationClient (LocalScript in StarterPlayerScripts)
--
-- YOUR ANIMATION ID: rbxassetid://109686840711847
-- This is set as the DEFAULT idle animation for ALL auras.
--
-- HOW TO CUSTOMIZE:
--   Open AnimationConfig and change individual aura animations:
--     ["Nine-Tails"] = "rbxassetid://YOUR_OTHER_ID",
--     ["Genesis"] = nil,   -- nil = no animation for this aura
-- ═══════════════════════════════════════════════════════════

local RS  = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- ═══ 1) AnimationConfig ═══
local oldCfg = RS:FindFirstChild("AnimationConfig")
if oldCfg then oldCfg:Destroy() end
task.wait(0.1)

local cfg = Instance.new("ModuleScript")
cfg.Name = "AnimationConfig"
cfg.Parent = RS
cfg.Source = [==[
-- ============================================================
--  AnimationConfig — Idle animations for each aura!
--  ReplicatedStorage > AnimationConfig
-- ============================================================
--
--  HOW IT WORKS:
--    • DefaultIdle plays for ALL auras that don't have a custom one
--    • If an aura is in the Auras table, it uses THAT animation instead
--    • If an aura is set to nil, it has NO animation (just stands)
--
--  TO ADD A CUSTOM ANIMATION:
--    ["Nine-Tails"] = "rbxassetid://YOUR_ANIM_ID",
--
--  TO DISABLE ANIMATION FOR AN AURA:
--    ["Genesis"] = nil,
--
-- ============================================================

local AnimConfig = {}

-- Default idle animation (plays for ALL auras by default)
AnimConfig.DefaultIdle = "rbxassetid://109686840711847"

-- Per-aura overrides (empty for now — add your own later!)
-- Examples:
--   ["Nine-Tails"] = "rbxassetid://1111111111",
--   ["Genesis"] = "rbxassetid://2222222222",
--   ["Flicker"] = nil,  -- no animation, just stands
AnimConfig.Auras = {
	-- Add your custom animations here!
	-- If an aura isn't listed, it uses DefaultIdle
}

return AnimConfig
]==]
print("✅ AnimationConfig created!")

-- ═══ 2) AnimationClient ═══
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

-- Load AnimationConfig (safe — won't crash if missing)
local AnimConfig
pcall(function() AnimConfig = require(ReplicatedStorage:WaitForChild("AnimationConfig")) end)

print("🎬 AnimationClient loaded!")
if AnimConfig then
	print("   Default idle: " .. tostring(AnimConfig.DefaultIdle))
end

-- Track current animation
local currentTrack = nil

-- Stop current animation
local function stopAnimation()
	if currentTrack then
		currentTrack:Stop(0.5)
		currentTrack = nil
	end
end

-- Play an animation on the character
local function playAnimation(character, animId)
	if not animId or animId == "" then return end

	-- Get the Humanoid and Animator
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Stop any current animation
	stopAnimation()

	-- Create the Animation object
	local anim = Instance.new("Animation")
	anim.AnimationId = animId

	-- Load and play
	local success, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)

	if success and track then
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Idle
		track:Play()
		currentTrack = track
		print("🎬 Playing animation: " .. animId)
	else
		warn("🎬 Failed to load animation: " .. animId)
	end
end

-- Parse aura name (handles mutations like "Sandy|Nine-Tails" -> "Nine-Tails")
local function parseName(stored)
	local sep = string.find(stored, "|")
	if sep then return string.sub(stored, sep + 1) end
	return stored
end

-- Update animation based on equipped aura
local currentEquipped = nil

local function updateAnimation()
	local character = player.Character
	if not character then return end

	stopAnimation()

	if not currentEquipped or currentEquipped == "" then return end

	local baseName = parseName(currentEquipped)

	-- Look up the animation for this aura
	local animId = nil
	if AnimConfig and AnimConfig.Auras then
		-- Check if this aura has a specific animation
		if AnimConfig.Auras[baseName] ~= nil then
			animId = AnimConfig.Auras[baseName]
		else
			-- Use default
			animId = AnimConfig.DefaultIdle
		end
	elseif AnimConfig then
		animId = AnimConfig.DefaultIdle
	end

	if animId then
		playAnimation(character, animId)
	else
		print("🎬 No animation for '" .. baseName .. "'")
	end
end

-- Listen for equip changes
EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	currentEquipped = auraName
	updateAnimation()
end)

-- Re-apply on respawn
player.CharacterAdded:Connect(function()
	task.wait(1.5)
	updateAnimation()
end)

print("🎬 AnimationClient ready!")
]==]

print("✅ AnimationClient created!")
print("══════════════════════════════════════")
print("🎬 ANIMATION SYSTEM INSTALLED!")
print("══════════════════════════════════════")
print("✨ Default idle: rbxassetid://109686840711847")
print("🎯 Plays for ALL auras when equipped")
print("📝 To customize: open AnimationConfig in ReplicatedStorage")
print("══════════════════════════════════════")
