-- ═══════════════════════════════════════════════════════════
-- 📊  STATS UI  —  LocalScript   |   PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- A small always-visible panel in the top-right corner showing:
--   • Total Rolls
--   • Rarest Pull (the luckiest aura you've ever gotten)
--   • Auras Found (X out of total in the game)
--   • Current Luck multiplier
-- Updates automatically after every roll and after admin actions.
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Panel position/size → PANEL_POS / PANEL_SIZE
--   • Colors              → ⚙️ UI THEME block
--   • Which stats show    → comment out a line in update()
--
-- 🔗 RELATED SCRIPTS:
--   • RollServer → answers GetStatsFunction, fires StatsUpdatedEvent
--   • AuraDatabase → total aura count (indirectly, via the server)
--
-- 💡 SUGGESTION / EXAMPLE ADDITION:
--   Animate the numbers counting UP when they change (like a slot),
--   or flash the "Rarest" line gold when you beat your record.
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local GetStatsFunction  = Remotes:WaitForChild("GetStatsFunction")
local StatsUpdatedEvent = Remotes:WaitForChild("StatsUpdatedEvent")

-- ⚙️ ─────────────────── CUSTOMIZE: UI THEME ───────────────────
local BG_COLOR     = Color3.fromRGB(25, 25, 40)
local TEXT_COLOR   = Color3.fromRGB(255, 255, 255)
local TITLE_COLOR  = Color3.fromRGB(255, 215, 0)
local VALUE_COLOR  = Color3.fromRGB(120, 200, 255)
local STROKE_COLOR = Color3.fromRGB(80, 120, 255)
-- ⚙️ ─────────────────── CUSTOMIZE: LAYOUT ─────────────────────
local PANEL_POS  = UDim2.fromScale(0.78, 0.02)   -- top-right corner
local PANEL_SIZE = UDim2.fromScale(0.20, 0.20)
-- ⚙️ ───────────────────────── END CUSTOMIZE ───────────────────

-- ────────────── build the UI ──────────────
local gui = Instance.new("ScreenGui")
gui.Name = "StatsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = PANEL_SIZE
panel.Position = PANEL_POS
panel.BackgroundColor3 = BG_COLOR
panel.BackgroundTransparency = 0.15
local pCorner = Instance.new("UICorner"); pCorner.CornerRadius = UDim.new(0.08, 0); pCorner.Parent = panel
local pStroke = Instance.new("UIStroke"); pStroke.Thickness = 2; pStroke.Color = STROKE_COLOR; pStroke.Parent = panel
panel.Parent = gui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0.04, 0)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = panel

-- helper to make a label row
local function makeLabel()
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.92, 0.18)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = TEXT_COLOR
	lbl.Parent = panel
	return lbl
end

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.fromScale(0.92, 0.2)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextScaled = true
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = TITLE_COLOR
titleLabel.Text = "📊  STATS"
titleLabel.Parent = panel

local rollsLabel   = makeLabel()
local rarestLabel  = makeLabel()
local foundLabel   = makeLabel()
local luckLabel    = makeLabel()

-- ────────────── update logic ──────────────
local function formatRarity(n)
	if n == 0 then return "—" end
	return "1 in " .. n
end

local function update(stats)
	if not stats then return end
	rollsLabel.Text  = "Rolls:  " .. tostring(stats.Rolls or 0)
	rarestLabel.Text = "Rarest: " .. tostring(stats.RarestAura or "None") .. "  (" .. formatRarity(stats.RarestRarity) .. ")"
	foundLabel.Text  = "Found:  " .. tostring(stats.Found or 0) .. "/" .. tostring(stats.Total or 0)
	luckLabel.Text   = "Luck:  ×" .. tostring(stats.Luck or 1)
end

-- request current stats on load (so the panel shows right away)
update(GetStatsFunction:InvokeServer())

-- listen for live updates from the server
StatsUpdatedEvent.OnClientEvent:Connect(update)

print("📊 StatsUI loaded!")
