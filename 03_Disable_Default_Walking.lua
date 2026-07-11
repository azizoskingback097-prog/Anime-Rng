-- ═══════════════════════════════════════════════════════════
-- 🚶‍♂️ DISABLE DEFAULT WALKING MECHANICS
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- Disables the default Roblox Animate script so you can implement
-- custom movement systems later.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("DisableWalking")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "DisableWalking"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function onCharacterAdded(character)
	-- Wait for the default Roblox Animate script to be injected
	local animate = character:WaitForChild("Animate", 5)
	if animate then
		animate.Enabled = false
		print("🚫 Default walking animation disabled.")
	end
	
	-- Also reduce WalkSpeed/JumpPower prep (Optional, uncomment if you want full freeze)
	-- local humanoid = character:WaitForChild("Humanoid", 5)
	-- if humanoid then
	--     humanoid.WalkSpeed = 0
	--     humanoid.JumpPower = 0
	-- end
end

-- Connect to current character and future respawns
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

print("DisableWalking script loaded!")
]==]

print("✅ DISABLE WALKING SCRIPT APPLIED! Default Animate script will be disabled.")
