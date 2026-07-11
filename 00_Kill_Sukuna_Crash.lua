-- KILL SUKUNAVFX CRASH
local Workspace = game:GetService("Workspace")
local killed = 0

for _, child in ipairs(Workspace:GetDescendants()) do
	if child:IsA("Script") or child:IsA("LocalScript") then
		-- Delete ALL scripts inside VFX packs in workspace
		if string.find(child:GetFullName(), "VFX") or string.find(child:GetFullName(), "Particles") or string.find(child:GetFullName(), "Mage") then
			print("Killed: " .. child:GetFullName())
			child:Destroy()
			killed = killed + 1
		end
	end
end

print("Killed " .. killed .. " bad VFX scripts!")
