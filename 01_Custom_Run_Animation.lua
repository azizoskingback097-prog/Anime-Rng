-- ═══════════════════════════════════════════════════════════
-- 🏃‍♂️ CUSTOM WALK/RUN ANIMATION OVERRIDER
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- Replaces default walk/run with your custom animation!
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("CustomWalkAnim")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "CustomWalkAnim"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local CUSTOM_ANIM_ID = "rbxassetid://112762041387120"

local function applyCustomAnimation(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local animate = character:WaitForChild("Animate", 5)
	
	if not humanoid or not animate then return end

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
end

if player.Character then
	applyCustomAnimation(player.Character)
end

player.CharacterAdded:Connect(applyCustomAnimation)

print("✅ Custom Walk/Run Animation loaded!")
]==]

print("✅ CUSTOM ANIMATION SCRIPT APPLIED!")
