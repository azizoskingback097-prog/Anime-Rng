-- ═══════════════════════════════════════════════════════════
-- 🔊 FIX SFX SOUNDS (Replaces broken IDs with working ones!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
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

SFX.Sounds = {
	-- Rolling sounds
	["roll"]       = { id = "rbxassetid://6042053626",  volume = 0.5 },  -- whoosh
	["tick"]       = { id = "rbxassetid://9119729776",  volume = 0.3 },  -- tick

	-- Reveal sounds (when the result shows)
	["reveal"]     = { id = "rbxassetid://10999632586", volume = 0.6 },  -- normal reveal
	["rare"]       = { id = "rbxassetid://10999632586", volume = 0.8 },  -- rare pull
	["legendary"]  = { id = "rbxassetid://10999632586", volume = 1.0 },  -- legendary pull
	["mythic"]     = { id = "rbxassetid://10999632586", volume = 1.0 },  -- mythic pull

	-- UI sounds
	["click"]      = { id = "rbxassetid://9119729776",  volume = 0.4 },  -- button click
	["open"]       = { id = "rbxassetid://9119729776",  volume = 0.4 },  -- inventory open
	["close"]      = { id = "rbxassetid://9119729776",  volume = 0.3 },  -- inventory close
	["equip"]      = { id = "rbxassetid://6042053626",  volume = 0.6 },  -- equip aura
	["hover"]      = { id = "rbxassetid://9119729776",  volume = 0.2 },  -- hover
}

function SFX.Play(parent, soundName, volumeOverride)
	local cfg = SFX.Sounds[soundName]
	if not cfg then return end
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
print("✅ SFX Sounds fixed! (Using valid Audio IDs)")
