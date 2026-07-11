-- ═══════════════════════════════════════════════════════════
-- ✨ VFX DATA — ModuleScript | PLACE IN: ReplicatedStorage
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES:
-- Defines every VFX effect + maps auras to their VFX.
-- Read by VFXClient (creates the effects on your character).
--
-- 🔗 RELATED SCRIPTS:
--   • VFXClient → reads this to create effects
--   • AuraData → reads aura tiers for fallback mapping
-- ═══════════════════════════════════════════════════════════

local VFXData = {}

--[[
═══════════════════════════════════════════════════════════
📌 CUSTOMIZABLE SECTION: Aura → VFX Mapping
═══════════════════════════════════════════════════════════

HOW TO USE:
  Map each aura NAME to a VFX NAME (defined below in the VFX section).
  If an aura isn't listed here, it falls back to TierVFX.

EXAMPLE:
  ["Nine-Tails"] = "Fire Burst",  -- Nine-Tails gets fire effect
  ["Genesis"] = "Divine Wind",    -- Genesis gets the tornado effect

TO CHANGE AN AURA'S VFX:
  Just change the VFX name on the right side.
  Example: ["Surge"] = "Crystal Aura"  →  ["Surge"] = "Fire Burst"
────────────────────────────────────────────────────────────
]]
VFXData.AuraMap = {
	["Flicker"]         = "Smoke Mist",
	["Spark"]           = "Smoke Mist",
	["Glow"]            = "Stardust",
	["Ember"]           = "Fire Burst",
	["Surge"]           = "Crystal Aura",
	["Bloom"]           = "Stardust",
	["Spirit Bomb"]     = "Fire Burst",
	["Tempest"]         = "Crystal Aura",
	["Nine-Tails"]      = "Fire Burst",
	["Eclipse"]         = "Shadow Flame",
	["Conqueror Haki"]  = "Holy Burst",
	["Cursed Energy"]   = "Shadow Flame",
	["Hollow Mask"]     = "Shadow Flame",
	["Genesis"]         = "Divine Wind",
}

--[[
────────────────────────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Tier → VFX Fallback
HOW TO USE: If an aura isn't in AuraMap, it uses its TIER's VFX.
────────────────────────────────────────────────────────────
]]
VFXData.TierVFX = {
	Common    = "Smoke Mist",
	Uncommon  = "Stardust",
	Rare      = "Fire Burst",
	Epic      = "Crystal Aura",
	Legendary = "Holy Burst",
	Mythic    = "Divine Wind",
}

-- ═══════════════════════════════════════════════════════════
-- 🎨 VFX DEFINITIONS
-- ═══════════════════════════════════════════════════════════
VFXData.VFX = {}

--[[
═══════════════════════════════════════════════════════════
📌 VFX GUIDE: Smoke Mist
═══════════════════════════════════════════════════════════
🔰 WHAT THIS DOES:
  Soft grey smoke swirling around the player's body.
  Perfect for Common auras (subtle, not flashy).

🎨 HOW TO CUSTOMIZE:
  • Change Color → make it darker/lighter
  • Change Rate → more/less smoke (20 = gentle, 50 = thick)
  • Change Size → bigger/smaller puffs
  • Change Speed → faster/slower drift

➕ HOW TO ADD YOUR OWN:
  Copy this entire block, rename it, change the properties.

⚙️ PROPERTIES EXPLAINED:
  Part = where it attaches (HumanoidRootPart = body center)
  Color = particle color (ColorSequence for color over time)
  Size = particle size (NumberSequence for grow/shrink)
  Transparency = 0=opaque, 1=invisible
  Lifetime = how long each particle lives (seconds)
  Rate = particles per second
  Speed = how fast they drift outward
  SpreadAngle = how wide they spread (degrees)
  Acceleration = gravity/wind (Y negative = floating down)

❌ COMMON MISTAKES:
  • Don't set Rate above 100 — causes lag
  • Don't use Size bigger than 5 — looks glitchy
  • Make sure Part name is exact (case-sensitive!)
═══════════════════════════════════════════════════════════
]]
VFXData.VFX["Smoke Mist"] = {
	Name = "Smoke Mist",
	Effects = {
		{
			Type = "Smoke",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(150, 150, 150),
			Size = 1.2,
			Opacity = 0.4,
			RiseAcceleration = 1.5,
		},
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new(Color3.fromRGB(160, 160, 160)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 4) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(3, 5),
			Rate = 15,
			Speed = NumberRange.new(1, 2),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 1, 0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-20, 20),
		},
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 VFX GUIDE: Stardust
═══════════════════════════════════════════════════════════
🔰 WHAT THIS DOES:
  Small white sparkles floating upward around the body.
  Great for Uncommon auras — magical but subtle.

🎨 HOW TO CUSTOMIZE:
  • Change Color → gold, blue, pink sparkles
  • Change Rate → more/less sparkles
  • Change Lifetime → longer/shorter trails
  • Add LightEmission → makes them glow in the dark
═══════════════════════════════════════════════════════════
]]
VFXData.VFX["Stardust"] = {
	Name = "Stardust",
	Effects = {
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 220)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 0.1) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1.5, 3),
			Rate = 40,
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(45, 45),
			Acceleration = Vector3.new(0, 3, 0),
			LightEmission = 1,
			Texture = "rbxassetid://243660364", -- default sparkle texture
		},
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(255, 255, 200),
			Brightness = 1,
			Range = 8,
		},
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 VFX GUIDE: Fire Burst
═══════════════════════════════════════════════════════════
🔰 WHAT THIS DOES:
  Red/orange flames rising from the body + hands.
  Perfect for fire-type auras (Ember, Nine-Tails, Spirit Bomb).

🎨 HOW TO CUSTOMIZE:
  • Change Fire Color → blue fire, green fire, etc.
  • Change Fire Size → bigger/smaller flames
  • Add more particles for extra embers
  • Add a PointLight for glow
═══════════════════════════════════════════════════════════
]]
VFXData.VFX["Fire Burst"] = {
	Name = "Fire Burst",
	Effects = {
		{
			Type = "Fire",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(255, 100, 30),
			SecondaryColor = Color3.fromRGB(255, 200, 50),
			Size = 2.5,
			Heat = 15,
		},
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new({
				NumberSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
				NumberSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 30)),
				NumberSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 0)),
			}),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0.2) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.8, 1.5),
			Rate = 50,
			Speed = NumberRange.new(5, 10),
			SpreadAngle = Vector2.new(15, 15),
			Acceleration = Vector3.new(0, 10, 0),
			LightEmission = 0.8,
		},
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(255, 120, 30),
			Brightness = 2,
			Range = 12,
		},
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 VFX GUIDE: Crystal Aura
═══════════════════════════════════════════════════════════
🔰 WHAT THIS DOES:
  Blue shimmering crystal-like particles orbiting the chest.
  Great for Epic auras (Surge, Tempest).

🎨 HOW TO CUSTOMIZE:
  • Change Color → purple crystals, green crystals
  • Change Size → bigger/smaller shards
  • Add more emitters for denser effect
═══════════════════════════════════════════════════════════
]]
VFXData.VFX["Crystal Aura"] = {
	Name = "Crystal Aura",
	Effects = {
		{
			Type = "Particle",
			Part = "UpperTorso",
			Color = ColorSequence.new(Color3.fromRGB(100, 180, 255)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 2), NumberSequenceKeypoint.new(1, 0.5) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.8) }),
			Lifetime = NumberRange.new(1.5, 2.5),
			Rate = 35,
			Speed = NumberRange.new(3, 6),
			SpreadAngle = Vector2.new(360, 360),
			Acceleration = Vector3.new(0, 1, 0),
			LightEmission = 0.8,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-180, 180),
		},
		{
			Type = "Light",
			Part = "UpperTorso",
			Color = Color3.fromRGB(100, 180, 255),
			Brightness = 1.5,
			Range = 10,
		},
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 VFX GUIDE: Shadow Flame
═══════════════════════════════════════════════════════════
🔰 WHAT THIS DOES:
  Dark purple fire wisps + smoke rising from the body.
  Great for dark/cursed auras (Eclipse, Cursed Energy, Hollow Mask).

🎨 HOW TO CUSTOMIZE:
  • Change Color → dark red, dark green shadows
  • Add more smoke for thicker darkness
═══════════════════════════════════════════════════════════
]]
VFXData.VFX["Shadow Flame"] = {
	Name = "Shadow Flame",
	Effects = {
		{
			Type = "Fire",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(80, 0, 120),
			SecondaryColor = Color3.fromRGB(40, 0, 60),
			Size = 3,
			Heat = 10,
		},
		{
			Type = "Smoke",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(40, 0, 60),
			Size = 2,
			Opacity = 0.5,
			RiseAcceleration = 2,
		},
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new({
				NumberSequenceKeypoint.new(0, Color3.fromRGB(100, 0, 150)),
				NumberSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 40)),
			}),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0.5) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1.5, 3),
			Rate = 30,
			Speed = NumberRange.new(2, 5),
			SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(0, 5, 0),
			LightEmission = 0.3,
		},
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(100, 0, 150),
			Brightness = 1,
			Range = 10,
		},
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 VFX GUIDE: Holy Burst
═══════════════════════════════════════════════════════════
🔰 WHAT THIS DOES:
  Giant white light explosion + sparkles + a glowing halo.
  Perfect for Legendary auras (Conqueror Haki, Genesis).

🎨 HOW TO CUSTOMIZE:
  • Change Color → gold holy, blue divine
  • Change Light Range → bigger glow
  • Add more sparkles for extra divinity
═══════════════════════════════════════════════════════════
]]
VFXData.VFX["Holy Burst"] = {
	Name = "Holy Burst",
	Effects = {
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(255, 255, 220),
			Brightness = 3,
			Range = 18,
		},
		{
			Type = "Particle",
			Part = "UpperTorso",
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 240)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 3), NumberSequenceKeypoint.new(1, 0.5) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1, 2),
			Rate = 60,
			Speed = NumberRange.new(8, 15),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 2, 0),
			LightEmission = 1,
			Texture = "rbxassetid://243660364",
		},
		{
			Type = "Particle",
			Part = "Head",
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 200)),
			Size = NumberSequence.new(0.5),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(2, 4),
			Rate = 20,
			Speed = NumberRange.new(0, 1),
			SpreadAngle = Vector2.new(45, 45),
			LightEmission = 1,
			Texture = "rbxassetid://243660364",
		},
		{
			Type = "Light",
			Part = "Head",
			Color = Color3.fromRGB(255, 255, 180),
			Brightness = 2,
			Range = 8,
		},
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 VFX GUIDE: Divine Wind
═══════════════════════════════════════════════════════════
🔰 WHAT THIS DOES:
  Teal/cyan swirling energy tornado around the whole body.
  The ultimate effect for Mythic auras (Genesis, rarest pulls).

🎨 HOW TO CUSTOMIZE:
  • Change Color → red tornado, gold tornado
  • Add more emitters for a denser tornado
  • Increase Rate for more particles
═══════════════════════════════════════════════════════════
]]
VFXData.VFX["Divine Wind"] = {
	Name = "Divine Wind",
	Effects = {
		-- swirling particles (the tornado)
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new({
				NumberSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 200)),
				NumberSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
				NumberSequenceKeypoint.new(1, Color3.fromRGB(100, 255, 255)),
			}),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(0.5, 4), NumberSequenceKeypoint.new(1, 1) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.9) }),
			Lifetime = NumberRange.new(1, 2),
			Rate = 80,
			Speed = NumberRange.new(10, 20),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 15, 0),
			LightEmission = 1,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(180, 360),
		},
		-- ground particles (sparks)
		{
			Type = "Particle",
			Part = "HumanoidRootPart",
			Color = ColorSequence.new(Color3.fromRGB(0, 255, 220)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.5, 1),
			Rate = 40,
			Speed = NumberRange.new(15, 25),
			SpreadAngle = Vector2.new(45, 45),
			Acceleration = Vector3.new(0, 5, 0),
			LightEmission = 1,
		},
		-- big glow
		{
			Type = "Light",
			Part = "HumanoidRootPart",
			Color = Color3.fromRGB(0, 255, 200),
			Brightness = 3,
			Range = 20,
		},
	},
}

--[[
═══════════════════════════════════════════════════════════
📌 HELPER: Look up which VFX to use for an aura
═══════════════════════════════════════════════════════════
HOW THIS WORKS:
  1. Check AuraMap for the exact aura name
  2. If not found, check the aura's Tier in TierVFX
  3. If still not found, return nil (no VFX)
═══════════════════════════════════════════════════════════
]]
function VFXData.GetVFXForAura(auraName, tier)
	-- direct map
	if VFXData.AuraMap[auraName] then
		return VFXData.VFX[VFXData.AuraMap[auraName]]
	end
	-- tier fallback
	if tier and VFXData.TierVFX[tier] then
		return VFXData.VFX[VFXData.TierVFX[tier]]
	end
	return nil
end

return VFXData
