-- ═══════════════════════════════════════════════════════════
-- 🛠️  COMMAND BAR SETUP
-- HOW TO USE: View > Command Bar  →  paste ALL of this  →  Enter
-- It creates the Remotes folder and the two remote objects.
-- Safe to run again — it won't create duplicates.
-- ═══════════════════════════════════════════════════════════

local RS = game:GetService("ReplicatedStorage")

-- 1) Remotes folder
local Remotes = RS:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = RS
end

-- 2) RollFunction (client → server, returns the rolled aura)
local rf = Remotes:FindFirstChild("RollFunction")
if not rf then
	rf = Instance.new("RemoteFunction")
	rf.Name = "RollFunction"
	rf.Parent = Remotes
end

-- 3) AnnounceEvent (server → all clients, rare-pull announcements)
local re = Remotes:FindFirstChild("AnnounceEvent")
if not re then
	re = Instance.new("RemoteEvent")
	re.Name = "AnnounceEvent"
	re.Parent = Remotes
end

print("✅ Setup done! Remotes folder is in ReplicatedStorage.")
