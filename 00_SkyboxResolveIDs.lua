-- ═══════════════════════════════════════════════════════════
-- 🔧 SKYBOX ID RESOLVER — converts Decal IDs to Image IDs automatically
-- ═══════════════════════════════════════════════════════════
-- ONLY run this if the diagnostic showed a BLACK sky!
-- It tries to load each asset and find the real image ID behind it.
-- ═══════════════════════════════════════════════════════════

local InsertService = game:GetService("InsertService")

print("══════════════════════════════════════")
print("🔧 SKYBOX ID RESOLVER")
print("══════════════════════════════════════")

-- Your current IDs (just the numbers, no prefix)
local idsToResolve = {
	{ label = "Bk", id = 159005370 },
	{ label = "Dn", id = 858422412 },
	{ label = "Ft", id = 159005370 },
	{ label = "Lf", id = 159005370 },
	{ label = "Rt", id = 159006363 },
	{ label = "Up", id = 159006363 },
}

local resolved = {}

for _, entry in ipairs(idsToResolve) do
	local success, asset = pcall(function()
		return InsertService:LoadAsset(entry.id)
	end)

	if success and asset then
		-- Look for a Decal or Texture inside the loaded asset
		local decal = asset:FindFirstChildOfClass("Decal")
		local texture = asset:FindFirstChildOfClass("Texture")
		local imagePart = asset:FindFirstChildOfClass("ImageLabel")

		if decal then
			local imgId = decal.Texture
			print("✅ " .. entry.label .. ": Decal " .. entry.id .. " → Image ID: " .. imgId)
			table.insert(resolved, { label = entry.label, imageId = imgId })
		elseif texture then
			local imgId = texture.Texture
			print("✅ " .. entry.label .. ": Texture " .. entry.id .. " → Image ID: " .. imgId)
			table.insert(resolved, { label = entry.label, imageId = imgId })
		else
			print("⚠️ " .. entry.label .. ": ID " .. entry.id .. " loaded but no Decal/Texture found")
			print("   → This might already be an image ID, or it's a different asset type")
			table.insert(resolved, { label = entry.label, imageId = "rbxassetid://" .. entry.id })
		end
		asset:Destroy()
	else
		print("❌ " .. entry.label .. ": Could not load ID " .. entry.id .. " (not owned or wrong type)")
		print("   → Try inserting from Toolbox manually and reading the properties")
		table.insert(resolved, { label = entry.label, imageId = "rbxassetid://" .. entry.id })
	end
end

print("")
print("══════════════════════════════════════")
print("📋 RESOLVED IMAGE IDS — copy these into WeatherData:")
print("══════════════════════════════════════")
print("")
print("Skybox = {")
for _, r in ipairs(resolved) do
	print("    \"" .. r.imageId .. "\",  -- " .. r.label)
end
print("},")
print("")
print("══════════════════════════════════════")
print("📋 Copy the output above and send it to me!")
print("I'll update WeatherData with the correct IDs.")
print("══════════════════════════════════════")
