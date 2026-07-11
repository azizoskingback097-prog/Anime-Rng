-- ═══════════════════════════════════════════════════════════
-- 🔍 SKYBOX DIAGNOSTIC — tells us EXACTLY why the skybox isn't loading
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar → Enter
-- This RUNS the skybox test directly and prints the results.
-- ═══════════════════════════════════════════════════════════

local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")

print("══════════════════════════════════════")
print("🔍 SKYBOX DIAGNOSTIC STARTING...")
print("══════════════════════════════════════")

-- STEP 1: Remove any existing Sky objects
for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("Sky") then
		print("🧹 Removed old Sky object")
		child:Destroy()
	end
end

-- STEP 2: Create a fresh Sky with YOUR IDs
local sky = Instance.new("Sky")
sky.Name = "DiagnosticSky"

-- Your IDs
local ids = {
	Bk = "rbxassetid://159005370",
	Dn = "rbxassetid://858422412",
	Ft = "rbxassetid://159005370",
	Lf = "rbxassetid://159005370",
	Rt = "rbxassetid://159006363",
	Up = "rbxassetid://159006363",
}

sky.SkyboxBk = ids.Bk
sky.SkyboxDn = ids.Dn
sky.SkyboxFt = ids.Ft
sky.SkyboxLf = ids.Lf
sky.SkyboxRt = ids.Rt
sky.SkyboxUp = ids.Up
sky.CelestialBodiesShow = true
sky.Parent = Lighting

print("✅ Sky object created in Lighting with your IDs")
print("")
print("📡 Testing if each texture loads...")

-- STEP 3: Test each ID with ContentProvider
local labels = { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }
for _, label in ipairs(labels) do
	local assetId = ids[label]
	ContentProvider:PreloadAsync({ assetId })
	print("  " .. label .. ": " .. assetId .. " → set on Sky")
end

print("")
print("══════════════════════════════════════")
print("👁️ LOOK AT YOUR GAME WINDOW NOW!")
print("══════════════════════════════════════")
print("")
print("Is the sky showing the skybox image?")
print("")
print("➡️ If YES → the code works, the WeatherClient has a bug (I'll fix it)")
print("➡️ If BLACK/DEFAULT → the IDs are DECAL IDs, not IMAGE IDs")
print("")
print("══════════════════════════════════════")
print("🔧 HOW TO FIND THE REAL IMAGE IDs:")
print("══════════════════════════════════════")
print("1. View → Toolbox → search your skybox → Insert it")
print("2. Find the Sky object that was inserted")
print("3. Click it → look at the PROPERTIES window (bottom right)")
print("4. You'll see SkyboxBk, SkyboxDn, SkyboxFt, etc.")
print("5. Each one says something like: rbxassetid://159005358")
print("6. Copy THOSE numbers — they might be DIFFERENT from 159005370!")
print("")
print("The DECAL ID (what you copied from the toolbox listing)")
print("is NOT the same as the IMAGE ID (what the Sky object uses).")
print("══════════════════════════════════════")
print("📋 Tell me what you see: is the sky BLACK or does it show an image?")
print("══════════════════════════════════════")
