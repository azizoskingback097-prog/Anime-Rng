-- ═══════════════════════════════════════════════════════════
-- 🔧 FIX SOUND ID PREFIX (Adds rbxassetid:// automatically!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This fixes the "Temp read failed" error by checking every sound
-- ID in SFXConfig. If it's missing "rbxassetid://", it adds it!
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")
local cfg = RS:FindFirstChild("SFXConfig")

if not cfg then
	warn("❌ SFXConfig not found!")
	return
end

local source = cfg.Source
local fixed = 0

-- Find all id = "..." patterns and fix them
source = source:gsub('id%s*=%s*"([^"]*)"', function(id)
	-- Skip empty strings
	if id == "" then return 'id = ""' end
	
	-- Check if it already has the prefix
	if string.find(id, "rbxassetid://") then
		return 'id = "' .. id .. '"'
	end
	
	-- If it's just numbers, add the prefix!
	if tonumber(id) then
		fixed = fixed + 1
		print("🔧 Fixed sound ID: " .. id .. " → rbxassetid://" .. id)
		return 'id = "rbxassetid://' .. id .. '"'
	end
	
	-- If it has "rbxassetid://" without the numbers, skip
	return 'id = "' .. id .. '"'
end)

cfg.Source = source

print("══════════════════════════════════════")
print("✅ SOUND ID PREFIX FIX COMPLETE!")
print("🔧 Fixed " .. fixed .. " sound IDs (added rbxassetid://)")
print("══════════════════════════════════════")
print("🎮 Press Play and test your sounds now!")
print("══════════════════════════════════════")
print("💡 REMEMBER: Sound IDs MUST start with rbxassetid://")
print("   Example: id = 'rbxassetid://92597737835973'")
print("   NOT:     id = '92597737835973'")
print("══════════════════════════════════════")
