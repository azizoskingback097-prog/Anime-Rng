-- ═══════════════════════════════════════════════════════════
-- 🌌 CLEAN WEATHER DATA — fixes corrupted code + skybox on all + new weather
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar → Enter
-- This replaces WeatherData with a CLEAN, working version.
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local function ensure(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName ~= className then inst:Destroy(); inst = nil end
	if not inst then inst = Instance.new(className); inst.Name = name; inst.Parent = parent end
	return inst
end

ensure("ModuleScript", "WeatherData", RS).Source = [==[
local WeatherData = {}

WeatherData.TimeCycle = {
	Enabled = true,
	DayDurationMinutes = 10,
	StartTime = 6,
	DaySkybox = nil,
	NightSkybox = nil,
}

WeatherData.Weathers = {

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
]==]

print("══════════════════════════════════════")
print("✅ CLEAN WEATHER DATA INSTALLED!")
print("══════════════════════════════════════")
print("🔧 Fixed: all corrupted markdown links removed")
print("🌌 Skybox on: Sandstorm, Blood Moon, Cosmic Rift")
print("🆕 New weather: Cosmic Rift (15% Cosmic mutation)")
print("══════════════════════════════════════")
print("🧪 TEST: Admin → Force Sandstorm → look at sky!")
