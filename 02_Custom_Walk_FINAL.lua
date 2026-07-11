-- ═══════════════════════════════════════════════════════════
-- 🏃‍♂️ CUSTOM WALK/RUN ANIMATION (Fixes DisableWalking Conflict)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- 1. DELETE the DisableWalking script so it stops blocking animations!
local disableScript = SPS:FindFirstChild("DisableWalking")
if disableScript then
	disableScript:Destroy()
	print("🗑️ Deleted 'DisableWalking' to restore animation capabilities.")
end

-- 2. Recreate the CustomWalkAnim script
local old = SPS:FindFirstChild("CustomWalkAnim")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "CustomWalkAnim"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local CUSTOM_ANIM_ID = "rbxassetid://1852625856"

local function applyCustomAnimation(character)
	-- Wait for the default Animate script to load
	local animate = character:WaitForChild("Animate", 5)
	if not animate then return end

	local function overrideAnim(name)
		local animObj = animate:FindFirstChild(name)
		if animObj then
			local anim = animObj:FindFirstChildWhichIsA("Animation")
			if anim then
				anim.AnimationId = CUSTOM_ANIM_ID
			end
		end
	end

	-- Override walk, run, and idle so it feels cohesive
	overrideAnim("walk")
	overrideAnim("run")
	overrideAnim("idle")
end

if player.Character then
	applyCustomAnimation(player.Character)
end

player.CharacterAdded:Connect(applyCustomAnimation)

print("✅ Custom Walk/Run Animation loaded! (ID: 1852625856)")
]==]

print("✅ CUSTOM WALK ANIMATION APPLIED! (DisableWalking conflict resolved)")
