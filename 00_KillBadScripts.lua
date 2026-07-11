-- ═══════════════════════════════════════════════════════════
-- 🧹 FIX #2: Kill bad VFX scripts (SukunaVFX crash!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")
local dangerNames = {
	"qPerfectionWeld", "qWeld", "AutoWeld", "WeldAll", "PerfectionWeld",
	"CoreTextureSystem", "CoreViewSystem", "TextureUtility", "Animation",
	"changeMesh", "changeColor", "PoseTexture",
}
local killed = 0
for _, child in ipairs(Workspace:GetDescendants()) do
	if child:IsA("Script") or child:IsA("LocalScript") then
		for _, dangerName in ipairs(dangerNames) do
			if child.Name == dangerName or string.find(child.Name, dangerName) then
				print("Killed: " .. child:GetFullName())
				child:Destroy()
				killed = killed + 1
				break
			end
		end
	end
end
print("✅ Killed " .. killed .. " bad scripts! (SukunaVFX crash fixed!)")
