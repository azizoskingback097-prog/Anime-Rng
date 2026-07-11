-- ═══════════════════════════════════════════════════════════
-- 📦 AUTO-CREATE ZONES FOLDER (Keeps Workspace organized!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This creates a neat "MapZones" folder at the top of your Workspace
-- and generates 3 example zone parts so you don't have to make them!
-- ═══════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")

-- Create a clean folder so it's easy to find!
local folder = Workspace:FindFirstChild("MapZones")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "MapZones"
	folder.Parent = Workspace
	print("✅ Created 'MapZones' folder in Workspace!")
end

-- Function to create a zone part
local function createZone(name, size, position, color)
	local part = folder:FindFirstChild(name)
	if not part then
		part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Anchored = true
		part.CanCollide = false -- Players can walk through it
		part.Transparency = 0.8 -- Slightly visible so you can see it while editing
		part.Color = color
		part.Material = Enum.Material.ForceField
		part.Parent = folder
		print("✅ Created zone part: " .. name)
	else
		print("ℹ️ Zone part '" .. name .. "' already exists.")
	end
end

-- Create 3 Example Zones (You can resize/move these in Studio!)
createZone("SpawnZone", Vector3.new(50, 10, 50), Vector3.new(0, 5, 0), Color3.fromRGB(200, 200, 200))
createZone("ForestZone", Vector3.new(50, 10, 50), Vector3.new(100, 5, 0), Color3.fromRGB(50, 200, 50))
createZone("SakuraZone", Vector3.new(50, 10, 50), Vector3.new(200, 5, 0), Color3.fromRGB(200, 100, 150))

print("🎯 Done! Look for the 'MapZones' folder at the top of your Workspace.")
print("👉 Move and resize the parts to cover your map areas!")
