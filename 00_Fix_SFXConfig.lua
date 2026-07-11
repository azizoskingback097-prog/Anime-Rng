-- ═══════════════════════════════════════════════════════════
-- 🔧 FIX #1: Recreate SFXConfig (fixes missing buttons!)
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
	["roll"] = { id = "rbxassetid://611472248", volume = 0.5 },
	["tick"] = { id = "rbxassetid://6895056282", volume = 0.3 },
	["reveal"] = { id = "rbxassetid://2868117459", volume = 0.6 },
	["rare"] = { id = "rbxassetid://2583352817", volume = 0.8 },
	["legendary"] = { id = "rbxassetid://3120830953", volume = 1.0 },
	["mythic"] = { id = "rbxassetid://3120830953", volume = 1.0 },
	["click"] = { id = "rbxassetid://6895056282", volume = 0.4 },
	["open"] = { id = "rbxassetid://6895056282", volume = 0.4 },
	["close"] = { id = "rbxassetid://6895056282", volume = 0.3 },
	["equip"] = { id = "rbxassetid://2868117459", volume = 0.6 },
	["hover"] = { id = "rbxassetid://6895056282", volume = 0.2 },
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
print("✅ SFXConfig RECREATED! Buttons should work now!")
