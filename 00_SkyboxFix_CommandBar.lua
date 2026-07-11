-- ═══════════════════════════════════════════════════════════
-- 🌌 SKYBOX FIX — adds your real skybox IDs to Sandstorm as a WORKING EXAMPLE
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar → Enter
-- This ONLY updates WeatherData (adds your skybox to Sandstorm weather)
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local WeatherData = RS:FindFirstChild("WeatherData")

if not WeatherData then
	warn("❌ WeatherData not found! Run the v10 update first.")
	return
end

-- ═══════════════════════════════════════════════════════════
-- HERE IS EXACTLY HOW THE SKYBOX WORKS:
--
-- Your IDs:
--   All sides EXCEPT Dn = 159005370
--   Dn (Down/floor)     = 858422412
--
-- The Skybox field needs 6 IDs in THIS EXACT ORDER:
--   [1] = Bk (Back)      → 159005370
--   [2] = Dn (Down/floor)→ 858422412  ← the different one!
--   [3] = Ft (Front)     → 159005370
--   [4] = Lf (Left)      → 159005370
--   [5] = Rt (Right)     → 159005370
--   [6] = Up (Sky/ceiling)→ 159005370
--
-- Each ID needs "rbxassetid://" in front of it.
-- ═══════════════════════════════════════════════════════════

WeatherData.Source = [==[
local WeatherData = {}

--[[
────────────────────────────────────────
📌 CUSTOMIZABLE SECTION: Day/Night Cycle
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
HOW TO USE: Copy a { } block to add new weather.

🌌 HOW TO ADD A SKYBOX (STEP BY STEP):
  1. Get your 6 image IDs from a Sky object (Toolbox or uploaded)
  2. Put them in the Skybox field in THIS order:
     { Bk, Dn, Ft, Lf, Rt, Up }
  3. Each one needs "rbxassetid://" prefix

  Skybox = {
      "rbxassetid://159005370",  -- [1] Bk = Back wall
      "rbxassetid://858422412",  -- [2] Dn = Down (floor/ground)
      "rbxassetid://159005370",  -- [3] Ft = Front wall
      "rbxassetid://159005370",  -- [4] Lf = Left wall
      "rbxassetid://159005370",  -- [5] Rt = Right wall
      "rbxassetid://159005370",  -- [6] Up = Up (sky ceiling)
  },

  ⚠️ If the skybox looks wrong (stretched, rotated, black):
     → You might have the IMAGE ID instead of the ASSET ID
     → In Studio, insert the Sky → look at each property → copy what's there
     → The toolbox sometimes gives a MODEL ID, not the image ID!

  💡 To use the SAME skybox for a different weather, just copy the block!
────────────────────────────────────────
]]
WeatherData.Weathers = {

	-- ────── CLEAR ──────
	{
		Name = "Clear", Weight = 50, Duration = { 90, 180 },
		Mutation = { Chance = 0, Name = nil, Color = nil },
		Lighting = {
			ClockTime = 14, FogColor = Color3.fromRGB(199,217,240), FogEnd = 100000,
			Ambient = Color3.fromRGB(128,128,128), OutdoorAmbient = Color3.fromRGB(128,128,128),
			Brightness = 2, ColorShift_Top = Color3.fromRGB(0,0,0), ColorShift_Bottom = Color3.fromRGB(0,0,0),
		},
		Skybox = nil,  -- Clear keeps default sky
		Particles = {},
		BannerText = "",
		BannerColor = Color3.fromRGB(255,255,255),
	},

	-- ────── SANDSTORM (NOW HAS YOUR SKYBOX!) ──────
	{
		Name = "Sandstorm", Weight = 25, Duration = { 60, 120 },
		Mutation = { Chance = 0.10, Name = "Sandy", Color = Color3.fromRGB(220,190,140) },
		Lighting = {
			ClockTime = 12, FogColor = Color3.fromRGB(200,170,120), FogEnd = 150,
			Ambient = Color3.fromRGB(180,150,100), OutdoorAmbient = Color3.fromRGB(200,170,120),
			Brightness = 1.5, ColorShift_Top = Color3.fromRGB(40,30,10), ColorShift_Bottom = Color3.fromRGB(40,30,10),
		},

		-- ✅ YOUR SKYBOX IS HERE! This is what makes the sky change.
		-- Order: Bk, Dn, Ft, Lf, Rt, Up
		Skybox = {
			"rbxassetid://159005370",  -- [1] Bk = Back
			"rbxassetid://858422412",  -- [2] Dn = Down (the different one!)
			"rbxassetid://159005370",  -- [3] Ft = Front
			"rbxassetid://159005370",  -- [4] Lf = Left
			"rbxassetid://159005370",  -- [5] Rt = Right
			"rbxassetid://159005370",  -- [6] Up = Up
		},

		Particles = {
			{
				Color = Color3.fromRGB(210,180,140),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0,4), NumberSequenceKeypoint.new(1,1) }),
				Transparency = NumberSequence.new(0.4), Lifetime = NumberRange.new(4,7), Rate = 300,
				Speed = NumberRange.new(15,30), SpreadAngle = Vector2.new(45,45),
				Acceleration = Vector3.new(30,0,0), Texture = "",
			},
		},
		BannerText = "🌪️  SANDSTORM!  10% chance for SANDY mutations!",
		BannerColor = Color3.fromRGB(220,190,140),
	},

	-- ────── BLOOD MOON ──────
	{
		Name = "Blood Moon", Weight = 15, Duration = { 45, 90 },
		Mutation = { Chance = 0.08, Name = "Cursed", Color = Color3.fromRGB(150,0,30) },
		Lighting = {
			ClockTime = 0, FogColor = Color3.fromRGB(40,0,10), FogEnd = 300,
			Ambient = Color3.fromRGB(80,10,20), OutdoorAmbient = Color3.fromRGB(60,0,15),
			Brightness = 1, ColorShift_Top = Color3.fromRGB(60,0,0), ColorShift_Bottom = Color3.fromRGB(40,0,0),
		},
		Skybox = nil,  -- ⚙️ add your own red skybox here if you have one!
		Particles = {
			{
				Color = Color3.fromRGB(200,30,30),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,3) }),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(1,0) }),
				Lifetime = NumberRange.new(5,10), Rate = 100, Speed = NumberRange.new(2,5),
				SpreadAngle = Vector2.new(180,180), Acceleration = Vector3.new(0,-2,0), Texture = "",
			},
		},
		BannerText = "🔴  BLOOD MOON!  8% chance for CURSED mutations!",
		BannerColor = Color3.fromRGB(200,30,30),
	},
}

function WeatherData.GetByName(name)
	for _, w in ipairs(WeatherData.Weathers) do if w.Name == name then return w end end
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
print("✅ SKYBOX ADDED!")
print("══════════════════════════════════════")
print("🌌 Your skybox is now on the Sandstorm weather")
print("🧪 TEST: Open Admin → Force Sandstorm → look at the sky!")
print("══════════════════════════════════════")
print("⚠️ If the sky is BLACK or looks wrong:")
print("   The ID might be an ASSET ID, not an IMAGE ID.")
print("   Fix: In Studio, insert your skybox from toolbox,")
print("   click the Sky object, and copy each SkyboxBk/Dn/Ft/Lf/Rt/Up")
print("   property value — THAT's the correct image ID.")
print("══════════════════════════════════════")
