-- ═══════════════════════════════════════════════════════════
-- 🌪️  WEATHER DATA  —  ModuleScript   |   PLACE IN: ReplicatedStorage
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- Defines every weather + the day/night cycle settings.
-- Read by WeatherServer (picks random weather), WeatherClient
-- (shows visuals + skybox), and GameServer (applies mutations).
--
-- ⚠️ IMPORTANT: Never copy-paste this from chat! Chat turns
-- function names into clickable links that break the code.
-- Always use the command bar file to deploy this.
-- ═══════════════════════════════════════════════════════════

local WeatherData = {}

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Day/Night Cycle
HOW TO USE: Controls the continuous day/night transition.
  • Enabled = true/false to toggle the cycle
  • DayDurationMinutes = real minutes per full 24h cycle
  • StartTime = hour to start (0=midnight, 6=dawn, 12=noon, 18=dusk)
  • DaySkybox/NightSkybox = optional {6 IDs} for sky textures
────────────────────────────────────────
]]
WeatherData.TimeCycle = {
	Enabled = true,
	DayDurationMinutes = 10,
	StartTime = 6,
	DaySkybox = nil,
	NightSkybox = nil,
}

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Weather List
HOW TO USE: Each { } block is one weather. Copy one to add new.

🌌 HOW TO ADD A SKYBOX:
  Skybox = {
      "rbxassetid://111",  -- Bk (Back)
      "rbxassetid://222",  -- Dn (Down/floor)
      "rbxassetid://333",  -- Ft (Front)
      "rbxassetid://444",  -- Lf (Left)
      "rbxassetid://555",  -- Rt (Right)
      "rbxassetid://666",  -- Up (Up/sky)
  },
  Set Skybox = nil to keep default sky.

⚠️ If sky is BLACK: you have an ASSET ID, not an IMAGE ID.
   Insert the Sky in Studio → read the SkyboxBk/Dn/Ft/Lf/Rt/Up
   property values → THOSE are the correct image IDs.

EXAMPLE — new weather (already added as "Cosmic Rift" below!):
  {
      Name = "Foggy Swamp", Weight = 15, Duration = { 60, 90 },
      Mutation = { Chance = 0.15, Name = "Swamp", Color = Color3.fromRGB(80,120,60) },
      Lighting = { ClockTime = 7, FogColor = Color3.fromRGB(80,100,70), FogEnd = 80, ... },
      Skybox = { "rbxassetid://111", "rbxassetid://222", ... },
      Particles = { { Color = ..., Rate = 50, ... } },
      BannerText = "🟢 FOGGY SWAMP! 15% chance for SWAMP mutations!",
      BannerColor = Color3.fromRGB(80,120,60),
  },
────────────────────────────────────────
]]
WeatherData.Weathers = {

	-- ────── CLEAR (default — no skybox, day/night cycle runs) ──────
	{
		Name = "Clear", Weight = 50, Duration = { 90, 180 },
		Mutation = { Chance = 0, Name = nil, Color = nil },
		Lighting = {
			ClockTime = 14, FogColor = Color3.fromRGB(199, 217, 240), FogEnd = 100000,
			Ambient = Color3.fromRGB(128, 128, 128), OutdoorAmbient = Color3.fromRGB(128, 128, 128),
			Brightness = 2, ColorShift_Top = Color3.fromRGB(0, 0, 0), ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		},
		Skybox = nil,
		Particles = {},
		BannerText = "",
		BannerColor = Color3.fromRGB(255, 255, 255),
	},

	-- ────── SANDSTORM (with your skybox!) ──────
	{
		Name = "Sandstorm", Weight = 25, Duration = { 60, 120 },
		Mutation = { Chance = 0.10, Name = "Sandy", Color = Color3.fromRGB(220, 190, 140) },
		Lighting = {
			ClockTime = 12, FogColor = Color3.fromRGB(200, 170, 120), FogEnd = 150,
			Ambient = Color3.fromRGB(180, 150, 100), OutdoorAmbient = Color3.fromRGB(200, 170, 120),
			Brightness = 1.5, ColorShift_Top = Color3.fromRGB(40, 30, 10), ColorShift_Bottom = Color3.fromRGB(40, 30, 10),
		},
		Skybox = {
			"rbxassetid://159005370",
			"rbxassetid://858422412",
			"rbxassetid://159005370",
			"rbxassetid://159005370",
			"rbxassetid://159006363",
			"rbxassetid://159006363",
		},
		Particles = {
			{
				Color = Color3.fromRGB(210, 180, 140),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 1) }),
				Transparency = NumberSequence.new(0.4),
				Lifetime = NumberRange.new(4, 7),
				Rate = 300,
				Speed = NumberRange.new(15, 30),
				SpreadAngle = Vector2.new(45, 45),
				Acceleration = Vector3.new(30, 0, 0),
				Texture = "",
			},
		},
		BannerText = "🌪️  SANDSTORM!  10% chance for SANDY mutations!",
		BannerColor = Color3.fromRGB(220, 190, 140),
	},

	-- ────── BLOOD MOON (with your skybox!) ──────
	{
		Name = "Blood Moon", Weight = 15, Duration = { 45, 90 },
		Mutation = { Chance = 0.08, Name = "Cursed", Color = Color3.fromRGB(150, 0, 30) },
		Lighting = {
			ClockTime = 0, FogColor = Color3.fromRGB(40, 0, 10), FogEnd = 300,
			Ambient = Color3.fromRGB(80, 10, 20), OutdoorAmbient = Color3.fromRGB(60, 0, 15),
			Brightness = 1, ColorShift_Top = Color3.fromRGB(60, 0, 0), ColorShift_Bottom = Color3.fromRGB(40, 0, 0),
		},
		Skybox = {
			"rbxassetid://159005370",
			"rbxassetid://858422412",
			"rbxassetid://159005370",
			"rbxassetid://159005370",
			"rbxassetid://159006363",
			"rbxassetid://159006363",
		},
		Particles = {
			{
				Color = Color3.fromRGB(200, 30, 30),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3) }),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(5, 10),
				Rate = 100,
				Speed = NumberRange.new(2, 5),
				SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -2, 0),
				Texture = "",
			},
		},
		BannerText = "🔴  BLOOD MOON!  8% chance for CURSED mutations!",
		BannerColor = Color3.fromRGB(200, 30, 30),
	},

	-- ────── COSMIC RIFT (NEW! example weather + suggestion!) ──────
	-- This is an EXAMPLE of how to add a new weather:
	-- • Name = "Cosmic Rift" → unique name, shows in banner + admin
	-- • Weight = 10 → rarer than others (lower number = less common)
	-- • Mutation = 15% chance for "Cosmic" mutations (purple color)
	-- • Lighting = dark night with purple fog
	-- • Skybox = same skybox as others (replace with a purple space one!)
	-- • Particles = floating purple sparkles rising upward
	-- • BannerText/BannerColor = announcement when it starts
	{
		Name = "Cosmic Rift", Weight = 10, Duration = { 60, 100 },
		Mutation = { Chance = 0.15, Name = "Cosmic", Color = Color3.fromRGB(180, 100, 255) },
		Lighting = {
			ClockTime = 2, FogColor = Color3.fromRGB(30, 10, 50), FogEnd = 400,
			Ambient = Color3.fromRGB(60, 30, 90), OutdoorAmbient = Color3.fromRGB(50, 20, 80),
			Brightness = 0.8, ColorShift_Top = Color3.fromRGB(30, 0, 60), ColorShift_Bottom = Color3.fromRGB(20, 0, 40),
		},
		Skybox = {
			"rbxassetid://159005370",
			"rbxassetid://858422412",
			"rbxassetid://159005370",
			"rbxassetid://159005370",
			"rbxassetid://159006363",
			"rbxassetid://159006363",
		},
		Particles = {
			{
				Color = Color3.fromRGB(180, 100, 255),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2) }),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
				Lifetime = NumberRange.new(6, 12),
				Rate = 80,
				Speed = NumberRange.new(1, 3),
				SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, 3, 0),
				Texture = "",
			},
		},
		BannerText = "🌌  COSMIC RIFT!  15% chance for COSMIC mutations!",
		BannerColor = Color3.fromRGB(180, 100, 255),
	},
}


-- ═══════════════════════════════════════════════════════════
-- 🧠 HELPER FUNCTIONS (don't edit unless you know what you're doing)
-- ═══════════════════════════════════════════════════════════
function WeatherData.GetByName(name)
	for _, w in ipairs(WeatherData.Weathers) do
		if w.Name == name then return w end
	end
	return nil
end

function WeatherData.GetByMutation(mutationName)
	for _, w in ipairs(WeatherData.Weathers) do
		if w.Mutation and w.Mutation.Name == mutationName then return w end
	end
	return nil
end

function WeatherData.PickRandom()
	local totalWeight = 0
	for _, w in ipairs(WeatherData.Weathers) do totalWeight = totalWeight + w.Weight end
	local r = math.random() * totalWeight
	local cumulative = 0
	for _, w in ipairs(WeatherData.Weathers) do
		cumulative = cumulative + w.Weight
		if r <= cumulative then return w end
	end
	return WeatherData.Weathers[1]
end

return WeatherData
