-- ═══════════════════════════════════════════════════════════
-- 💎 PREMIUM VFX PACK — adds 3 high-quality scripted VFX
-- ═══════════════════════════════════════════════════════════
-- HOW TO USE: View > Command Bar → paste ALL of this → Enter
--
-- Adds these NEW VFX to VFXData:
--   1. Inferno Storm    — epic fire tornado with embers
--   2. Celestial Aura   — golden divine rings + stars + glow
--   3. Void Rift        — dark energy crackling with purple lightning
--
-- Each is FULLY scripted (no external assets needed).
-- They auto-appear in the Admin panel for testing!
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local VFXData = RS:FindFirstChild("VFXData")

if not VFXData then
	warn("❌ VFXData not found! Run the VFX Update command bar first.")
	return
end

-- Read the existing source and append new VFX before the helper function
local currentSource = VFXData.Source

-- The new VFX definitions (inserted before the GetVFXForAura function)
local newVFX = [[

-- ═══════════════════════════════════════════════════════════
-- 💎 PREMIUM VFX PACK (3 new high-quality effects!)
-- ═══════════════════════════════════════════════════════════

-- 1. INFERNO STORM — epic fire tornado with rising embers + glow
VFXData.VFX["Inferno Storm"] = {
	Name = "Inferno Storm",
	Effects = {
		-- Fire tornado particles (swirling upward)
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 50)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 120, 0)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 50, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 0)),
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 4),
				NumberSequenceKeypoint.new(0.7, 3),
				NumberSequenceKeypoint.new(1, 0.5),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.8, 0.4),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(1.5, 2.5),
			Rate = 100,
			Speed = NumberRange.new(8, 15),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 20, 0),
			LightEmission = 1,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(180, 360),
		},
		-- Rising embers (small fast sparks)
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0)),
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0.1),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(2, 4),
			Rate = 60,
			Speed = NumberRange.new(5, 12),
			SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(0, 8, 0),
			LightEmission = 1,
			Texture = "rbxassetid://243660364",
		},
		-- Ground ring (expanding circle of fire)
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 3),
				NumberSequenceKeypoint.new(1, 0.5),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.5, 1),
			Rate = 50,
			Speed = NumberRange.new(15, 25),
			SpreadAngle = Vector2.new(0, 0),
			Acceleration = Vector3.new(0, -2, 0),
			LightEmission = 1,
		},
		-- Big fire glow
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(255, 100, 0),
			Brightness = 3,
			Range = 20,
		},
	},
}

-- 2. CELESTIAL AURA — golden divine rings + floating stars + heavenly glow
VFXData.VFX["Celestial Aura"] = {
	Name = "Celestial Aura",
	Effects = {
		-- Golden divine particles (slow, majestic, floating up)
		{
			Type = "Particle",
			Part = "UpperTorso",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 220)),
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.5),
				NumberSequenceKeypoint.new(0.5, 3),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.7, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(2, 4),
			Rate = 50,
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 5, 0),
			LightEmission = 1,
			Texture = "rbxassetid://243660364",
		},
		-- Expanding golden ring (pulses outward)
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.5, 2),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(1, 1.5),
			Rate = 30,
			Speed = NumberRange.new(1, 2),
			SpreadAngle = Vector2.new(0, 0),
			Acceleration = Vector3.new(0, 0, 0),
			LightEmission = 1,
		},
		-- Floating stars (small twinkles around the body)
		{
			Type = "Particle",
			Part = "Head",
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 180)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.8),
				NumberSequenceKeypoint.new(1, 0.2),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(3, 5),
			Rate = 25,
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 1, 0),
			LightEmission = 1,
			Texture = "rbxassetid://243660364",
		},
		-- Heavenly body glow
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(255, 230, 150),
			Brightness = 3,
			Range = 18,
		},
		-- Head halo glow
		{
			Type = "Light",
			Part = "Head",
			Color = Color3.fromRGB(255, 255, 200),
			Brightness = 2.5,
			Range = 10,
		},
	},
}

-- 3. VOID RIFT — dark energy with purple lightning + shadow particles
VFXData.VFX["Void Rift"] = {
	Name = "Void Rift",
	Effects = {
		-- Dark purple energy particles (swirling, menacing)
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 255)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(120, 0, 180)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 0, 100)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 0, 20)),
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.5, 3),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(0.8, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(1.5, 3),
			Rate = 70,
			Speed = NumberRange.new(5, 12),
			SpreadAngle = Vector2.new(360, 360),
			Acceleration = Vector3.new(0, -3, 0),
			LightEmission = 0.7,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-360, 360),
		},
		-- Purple lightning sparks (fast, erratic)
		{
			Type = "Particle",
			Part = "UpperTorso",
			Color = ColorSequence.new(Color3.fromRGB(200, 100, 255)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.1, 1.5),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.1, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.2, 0.5),
			Rate = 40,
			Speed = NumberRange.new(10, 20),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 0, 0),
			LightEmission = 1,
		},
		-- Dark shadow smoke (rising ominous cloud)
		{
			Type = "Smoke",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(20, 0, 40),
			Size = 3,
			Opacity = 0.6,
			RiseAcceleration = 3,
		},
		-- Void glow (dark purple light)
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(120, 0, 200),
			Brightness = 2,
			Range = 15,
		},
	},
}

]]

-- Insert the new VFX before the GetVFXForAura function
local marker = "function VFXData.GetVFXForAura"
local insertPos = string.find(currentSource, marker)

if insertPos then
	local newSource = string.sub(currentSource, 1, insertPos - 1) .. newVFX .. "\n" .. string.sub(currentSource, insertPos)
	VFXData.Source = newSource
else
	-- fallback: append at the end
	VFXData.Source = currentSource .. newVFX
end

print("══════════════════════════════════════")
print("💎 PREMIUM VFX PACK ADDED!")
print("══════════════════════════════════════")
print("🔥 Inferno Storm  — epic fire tornado + embers + ring")
print("✨ Celestial Aura — golden divine rings + stars + halo")
print("🌌 Void Rift      — dark energy + purple lightning + shadow")
print("══════════════════════════════════════")
print("🎮 To use them, map them to auras in VFXData.AuraMap:")
print('   ["Nine-Tails"] = "Inferno Storm",')
print('   ["Genesis"] = "Celestial Aura",')
print('   ["Cursed Energy"] = "Void Rift",')
print("══════════════════════════════════════")
print("💡 Or test them NOW via Admin panel! They appear automatically.")
print("══════════════════════════════════════")
