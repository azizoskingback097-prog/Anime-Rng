-- ═══════════════════════════════════════════════════════════
-- 🏃‍♂️ RUN ANIMATION FIX (No more frozen poses!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- 1. Delete any broken old versions
local old = SPS:FindFirstChild("CustomWalkAnim")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "CustomWalkAnim"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ⚙️ CUSTOMIZE YOUR ANIMATION ID HERE
-- Note: Make sure the ID is a PUBLIC Animation, or it will freeze your character!
local CUSTOM_ANIM_ID = "rbxassetid://616163682" -- (Placeholder: Default Roblox Run)

local function applyCustomAnimation(character)
	-- Wait for the default Animate script to load inside the character
	local animate = character:WaitForChild("Animate", 5)
	if not animate then return end

	local function overrideAnim(name)
		local animObj = animate:FindFirstChild(name)
		if animObj then
			-- Find the Animation object inside (walk, run, idle have animations inside them)
			local anim = animObj:FindFirstChildWhichIsA("Animation", true)
			if anim then
				anim.AnimationId = CUSTOM_ANIM_ID
				print("✅ Overrode '" .. name .. "' animation.")
			end
		end
	end

	-- Override walk, run, and idle
	overrideAnim("walk")
	overrideAnim("run")
	overrideAnim("idle")
end

if player.Character then
	applyCustomAnimation(player.Character)
end

player.CharacterAdded:Connect(applyCustomAnimation)
]==]

print("✅ RUN ANIMATION FIX APPLIED! (Placeholder ID used, change it to your own!)")
