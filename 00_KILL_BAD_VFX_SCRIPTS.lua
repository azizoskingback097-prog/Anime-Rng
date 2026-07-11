-- ═══════════════════════════════════════════════════════════
-- 🧹 KILL BAD VFX SCRIPTS — removes crashing scripts from Toolbox models
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- This scans your entire Workspace and deletes DANGEROUS scripts
-- that come hidden inside Toolbox VFX packs. These scripts cause
-- your game to freeze and crash.
-- ═══════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")

-- List of known DANGEROUS script names from Toolbox VFX packs
local dangerNames = {
	"qPerfectionWeld", "qWeld", "AutoWeld", "WeldAll", "PerfectionWeld",
	"CoreTextureSystem", "CoreViewSystem", "TextureUtility", "Animation",
	"changeMesh", "changeColor", "PoseTexture",
}

local killed = 0

local function killScripts(parent)
	for _, child in ipairs(parent:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			for _, dangerName in ipairs(dangerNames) do
				if child.Name == dangerName or string.find(child.Name, dangerName) then
					print("💥 Killed dangerous script: " .. child:GetFullName())
					child:Destroy()
					killed = killed + 1
					break
				end
			end
		end
	end
end

killScripts(Workspace)

print("══════════════════════════════════════")
print("✅ CLEANUP COMPLETE! Killed " .. killed .. " dangerous scripts.")
print("══════════════════════════════════════")
print("⚠️ REMEMBER: When you insert ANY VFX from the Toolbox:")
print("   1. Look inside it in the Explorer")
print("   2. DELETE any Script or LocalScript inside it")
print("   3. Keep ONLY the Parts, Attachments, and ParticleEmitters!")
print("══════════════════════════════════════")
