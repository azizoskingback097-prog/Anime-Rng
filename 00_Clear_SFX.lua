-- ═══════════════════════════════════════════════════════════
-- 🔊 FIX SFXCONFIG (Clears broken IDs)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This removes the broken sound IDs that were spamming your output.
-- It leaves the script structure intact so you can easily add your own!
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("SFXConfig")
if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "SFXConfig"
m.Parent = RS
m.Source = [==[
local SFX = {}

-- To add a sound, put your ID between the quotes!
-- Example: id = "rbxassetid://1234567890"
SFX.Sounds = {
	["roll"]       = { id = "", volume = 0.5 },
	["tick"]       = { id = "", volume = 0.3 },
	["reveal"]     = { id = "", volume = 0.6 },
	["rare"]       = { id = "", volume = 0.8 },
	["legendary"]  = { id = "", volume = 1.0 },
	["mythic"]     = { id = "", volume = 1.0 },
	["click"]      = { id = "", volume = 0.4 },
	["open"]       = { id = "", volume = 0.4 },
	["close"]      = { id = "", volume = 0.3 },
	["equip"]      = { id = "", volume = 0.6 },
}

function SFX.Play(parent, soundName, volumeOverride)
	local cfg = SFX.Sounds[soundName]
	if not cfg or cfg.id == "" then return end -- Don't play if no ID
	
	local sound = Instance.new("Sound")
	sound.SoundId = cfg.id
	sound.Volume = volumeOverride or cfg.volume or 1
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
	task.delay(10, function() if sound and sound.Parent then sound:Destroy() end end)
	return sound
end
return SFX
]==]

print("✅ SFXConfig CLEARED! No more spam errors in your output.")
print("💡 To add sounds: Open SFXConfig in ReplicatedStorage and paste your IDs inside the quotes!")
