-- ═══════════════════════════════════════════════════════════
-- 💣 STEP 1: SUPER NUKE — run this FIRST, read the output, tell me what it says
-- ═══════════════════════════════════════════════════════════
-- Paste into Command Bar (EDIT MODE, not Play mode!) → Enter
-- It searches EVERY location recursively and destroys ALL rng stuff.
-- ═══════════════════════════════════════════════════════════

local nukeNames = {}
for _, name in ipairs({
	"AuraData", "AuraDatabase", "RNGManager", "RollServer", "GameServer",
	"RollClient", "RollUI", "InventoryUI", "StatsUI", "AdminPanel", "AdminUI",
	"RollGui", "InventoryGui", "StatsGui", "AdminPanelGui",
	"Remotes",
	"RollFunction", "AnnounceEvent", "GetInventoryFunction", "EquipFunction",
	"AdminFunction", "GetStatsFunction", "StatsUpdatedEvent",
}) do
	nukeNames[name] = true
end

local destroyed = 0

local function deepNuke(parent, label)
	for _, child in ipairs(parent:GetChildren()) do
		if nukeNames[child.Name] then
			print("💥 [" .. label .. "] Destroyed: " .. child.Name .. " (" .. child.ClassName .. ")")
			child:Destroy()
			destroyed = destroyed + 1
		else
			deepNuke(child, label)
		end
	end
end

-- search EVERYWHERE (recursive)
deepNuke(game:GetService("ReplicatedStorage"),  "ReplicatedStorage")
deepNuke(game:GetService("ServerScriptService"), "ServerScriptService")
deepNuke(game:GetService("StarterGui"),         "StarterGui")
deepNuke(game:GetService("StarterPlayer"),      "StarterPlayer")
deepNuke(game:GetService("StarterPack"),        "StarterPack")

-- also check Workspace top-level (don't recurse into the map)
for _, child in ipairs(game:GetService("Workspace"):GetChildren()) do
	if nukeNames[child.Name] then
		print("💥 [Workspace] Destroyed: " .. child.Name)
		child:Destroy()
		destroyed = destroyed + 1
	end
end

print("══════════════════════════════════════")
print("💣 SUPER NUKE COMPLETE — destroyed " .. destroyed .. " items.")
print("══════════════════════════════════════")
if destroyed == 0 then
	print("ℹ️ Nothing found to destroy — everything was already clean!")
end
print("➡️ Now paste the REBUILD command bar (00b) to recreate everything.")
