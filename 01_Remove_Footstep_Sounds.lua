-- ═══════════════════════════════════════════════════════════
-- 🔇 REMOVE DEFAULT FOOTSTEP SOUNDS (Keep Animation!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This removes the default Roblox walking/running footstep sounds
-- so they don't interrupt your background music vibe.
-- The walking ANIMATION stays perfectly intact!
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("RemoveFootsteps")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "RemoveFootsteps"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function silenceFootsteps(character)
	-- Wait for the Humanoid to load
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	
	-- Method 1: Silence the Running sound inside the Humanoid
	local runningSound = humanoid:FindFirstChild("Running")
	if runningSound then
		runningSound.Volume = 0
		runningSound.SoundId = ""
		print("🔇 Silenced Humanoid Running sound!")
	end
	
	-- Method 2: Walk through ALL descendants and silence any footstep sounds
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("Sound") then
			local name = string.lower(obj.Name)
			-- Check for footstep-related sounds
			if name == "running" or name == "walk" or name == "footstep" or name == "footsteps" or name == "step" then
				obj.Volume = 0
				obj.SoundId = ""
				print("🔇 Silenced: " .. obj.Name)
			end
		end
	end
	
	-- Method 3: Override the Running sound when the Humanoid moves
	-- (This catches any sounds Roblox tries to inject later)
	humanoid.Running:Connect(function(speed)
		if speed > 0.1 then
			local runSound = humanoid:FindFirstChild("Running")
			if runSound and runSound.Volume > 0 then
				runSound.Volume = 0
			end
		end
	end)
end

-- Connect to current character and future respawns
if player.Character then
	silenceFootsteps(player.Character)
end
player.CharacterAdded:Connect(function(char)
	task.wait(0.5) -- Wait for character to fully load
	silenceFootsteps(char)
end)

print("✅ Footstep Sound Removal loaded! (Walking animation preserved)")
]==]

print("✅ FOOTSTEP SOUND REMOVAL APPLIED!")
print("🔇 Default walking sounds are silenced.")
print("🚶‍♂️ Walking animation is preserved!")
print("🎵 Your background music will play without interruption!")
