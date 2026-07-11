-- ═══════════════════════════════════════════════════════════
-- 🌪️  WEATHER SERVER (v9)  —  Script   |   PLACE IN: ServerScriptService
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
--   1. CYCLES WEATHER → picks a random weather, fires WeatherChangedEvent
--   2. DETECTS ADMIN FORCING → if an admin changes CurrentWeather,
--      the timer resets to use the new weather's duration
--   3. CHAT TIPS → posts helpful tips in the chat periodically
--
-- 🆕 v9: Now detects when admin forces a weather (via CurrentWeather value)
--   and resets the timer accordingly.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Weather frequency → edit WeatherData (weights + durations)
--   • Tip interval      → TIP_INTERVAL
--   • Tip messages      → TIPS list
--
-- 🔗 RELATED SCRIPTS:
--   • WeatherData   → weather definitions + PickRandom()
--   • WeatherClient  → listens to WeatherChangedEvent
--   • GameServer    → admin ForceWeather writes CurrentWeather value
-- ═══════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))

-- ⚙️ CUSTOMIZE
local START_DELAY    = 5
local TIP_INTERVAL   = 60
local TIPS = {
	"💡 Don't forget to LIKE and FAVORITE the game!",
	"💡 Special weather can MUTATE your auras — watch the sky!",
	"💡 Check the shop for luck potions to boost your rolls!",
	"💡 The rarer the aura, the cooler it looks — keep rolling!",
	"💡 Blood Moon weather gives CURSED mutations!",
	"💡 Sandstorm weather gives SANDY mutations!",
	"💡 Equip your best aura from the Inventory!",
	"💡 Trade with friends to complete your collection!",
}

local Remotes             = ReplicatedStorage:WaitForChild("Remotes")
local WeatherChangedEvent = Remotes:WaitForChild("WeatherChangedEvent")
local ChatTipEvent        = Remotes:WaitForChild("ChatTipEvent")
local currentWeatherValue = ReplicatedStorage:WaitForChild("CurrentWeather")

local function applyWeather(weather)
	currentWeatherValue.Value = weather.Name
	WeatherChangedEvent:FireAllClients({
		Name = weather.Name, Lighting = weather.Lighting, Particles = weather.Particles,
		BannerText = weather.BannerText, BannerColor = weather.BannerColor,
	})
	if weather.Name ~= "Clear" then print("🌪️ Weather: " .. weather.Name) end
end

-- chat tips loop
task.spawn(function()
	task.wait(START_DELAY)
	while true do
		local tip = TIPS[math.random(1, #TIPS)]
		for _, player in ipairs(Players:GetPlayers()) do
			ChatTipEvent:FireClient(player, tip)
		end
		task.wait(TIP_INTERVAL)
	end
end)

-- weather cycling loop (with admin-force detection!)
currentWeatherValue.Value = "Clear"
task.wait(START_DELAY)

while true do
	local weather = WeatherData.PickRandom()
	applyWeather(weather)

	local duration = math.random(weather.Duration[1], weather.Duration[2])
	local appliedName = weather.Name
	local elapsed = 0

	-- wait for duration, but check every second if admin changed the weather
	while elapsed < duration do
		task.wait(1)
		elapsed += 1
		if currentWeatherValue.Value ~= appliedName then
			-- 🛠️ ADMIN FORCED A WEATHER! Reset timer to use its duration
			appliedName = currentWeatherValue.Value
			local forced = WeatherData.GetByName(appliedName)
			if forced then
				duration = math.random(forced.Duration[1], forced.Duration[2])
			end
			elapsed = 0
		end
	end
end
