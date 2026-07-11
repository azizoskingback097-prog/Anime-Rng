-- ═══════════════════════════════════════════════════════════
-- 🎬 FIX ANIMATION CONFIG (Akaza only + others null)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local oldCfg = RS:FindFirstChild("AnimationConfig")
if oldCfg then oldCfg:Destroy() end
task.wait(0.1)

local cfg = Instance.new("ModuleScript")
cfg.Name = "AnimationConfig"
cfg.Parent = RS
cfg.Source = [==[
local AnimConfig = {}

-- Default idle (set to nil so other auras have NO animation)
AnimConfig.DefaultIdle = nil

-- Custom animations per aura!
AnimConfig.Auras = {
	["Akaza"] = "rbxassetid://109686840711847",
	
	-- Example: add more here later!
	-- ["Nine-Tails"] = "rbxassetid://YOUR_ANIM_ID",
	-- ["Genesis"] = "rbxassetid://YOUR_ANIM_ID",
}

return AnimConfig
]==]

-- Also update AnimationClient to pause when walking
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
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

local AnimConfig
pcall(function() AnimConfig = require(ReplicatedStorage:WaitForChild("AnimationConfig")) end)

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
		-- Priority Action so it overrides default animations
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		currentTrack = track
		print("Playing animation: " .. animId)
	else
		warn("Failed to load animation: " .. animId)
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

	local animId = nil
	if AnimConfig and AnimConfig.Auras then
		if AnimConfig.Auras[baseName] ~= nil then
			animId = AnimConfig.Auras[baseName]
		else
			animId = AnimConfig.DefaultIdle
		end
	elseif AnimConfig then
		animId = AnimConfig.DefaultIdle
	end

	if animId and not isWalking then
		playAnimation(character, animId)
	end
end

EquippedChangedEvent.OnClientEvent:Connect(function(auraName)
	currentEquipped = auraName
	updateAnimation()
end)

-- Handle Walking vs Idle (so the animation pauses when you walk!)
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
]==]
print("✅ Animation fixed! (Plays only for Akaza, pauses when walking)")
