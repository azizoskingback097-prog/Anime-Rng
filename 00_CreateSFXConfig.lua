-- ═══════════════════════════════════════════════════════════
-- 🔊 CREATE SFXCONFIG — the sound database!
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This creates a module where you put your sound IDs.
-- To change a sound, just replace the ID number!
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")

local old = RS:FindFirstChild("SFXConfig")
if old then old:Destroy() end
task.wait(0.1)

local m = Instance.new("ModuleScript")
m.Name = "SFXConfig"
m.Parent = RS
m.Source = [==[
-- ============================================================
--  SFXConfig — Your sound database!
--  ReplicatedStorage > SFXConfig
-- ============================================================
--  HOW TO CHANGE A SOUND:
--    1. Find a sound you like (Toolbox or uploaded)
--    2. Get its Sound ID (right-click > Copy ID, or from properties)
--    3. Replace the number below!
--
--  HOW TO FIND SOUNDS:
--    • Toolbox > search "sound" or "sfx"
--    • Or upload your own audio (Create tab on roblox.com)
--    • The ID looks like: rbxassetid://1234567890
--
--  VOLUME:
--    Each sound has a volume (0 = silent, 1 = normal, 2 = loud)
-- ============================================================

local SFX = {}

SFX.Sounds = {
	-- Rolling sounds
	["roll"]       = { id = "rbxassetid://611472248",   volume = 0.5 },  -- whoosh when you click ROLL
	["tick"]       = { id = "rbxassetid://6895056282",  volume = 0.3 },  -- ticking during flicker

	-- Reveal sounds (when the result shows)
	["reveal"]     = { id = "rbxassetid://2868117459",  volume = 0.6 },  -- normal reveal
	["rare"]       = { id = "rbxassetid://2583352817",  volume = 0.8 },  -- rare pull (Epic+)
	["legendary"]  = { id = "rbxassetid://3120830953",  volume = 1.0 },  -- legendary pull
	["mythic"]     = { id = "rbxassetid://3120830953",  volume = 1.0 },  -- mythic pull (same as legendary for now)

	-- UI sounds
	["click"]      = { id = "rbxassetid://6895056282",  volume = 0.4 },  -- button click
	["open"]       = { id = "rbxassetid://6895056282",  volume = 0.4 },  -- inventory open
	["close"]      = { id = "rbxassetid://6895056282",  volume = 0.3 },  -- inventory close
	["equip"]      = { id = "rbxassetid://2868117459",  volume = 0.6 },  -- equip aura
	["hover"]      = { id = "rbxassetid://6895056282",  volume = 0.2 },  -- hover over item
}

-- PLAY FUNCTION — creates a sound and plays it, then cleans up
-- Usage: SFX.Play(parent, "roll") or SFX.Play(parent, "rare", 0.8)
function SFX.Play(parent, soundName, volumeOverride)
	local cfg = SFX.Sounds[soundName]
	if not cfg then return end

	local sound = Instance.new("Sound")
	sound.SoundId = cfg.id
	sound.Volume = volumeOverride or cfg.volume or 1
	sound.Parent = parent

	sound:Play()

	-- Clean up after the sound finishes
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	-- Safety: destroy after 10 seconds even if Ended doesn't fire
	task.delay(10, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)

	return sound
end

return SFX
]==]

print("✅ SFXConfig CREATED!")
print("🔊 Sounds defined: roll, tick, reveal, rare, legendary, mythic, click, open, close, equip, hover")
print("💡 To change a sound: open SFXConfig and replace the rbxassetid:// number!")
print("🎮 Next: paste the RollUI SFX update and InventoryUI SFX update!")
