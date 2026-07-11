-- ═══════════════════════════════════════════════════════════
-- 💬  SYS2 #4 — ANNOUNCEMENT FEED UI  (read-only, chat-like)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  StarterPlayerScripts ▸ AnnouncementFeed  (LocalScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 A "Slime RNG style" feed (top-left): when someone rolls
--    something rare, a line slides in:
--       ✨ [Player] got AuraName (1 in 70K)
--    Players CANNOT type into it (system-only). Lines fade by age.
--    Tier colors come FROM THE SERVER (in the message), so this UI
--    needs no config of its own — just visuals.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("AnnouncementFeed"); if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "AnnouncementFeed"
s.Parent = SPS
s.Source = [====[
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")

-- 📌 FEED LOOK (tweak freely)
local CFG = {
	VisibleLines = 6,                           -- max lines shown at once
	Anchor       = UDim2.new(0.02, 0, 0.30, 0), -- top-left-ish (below HUD)
	Width        = 380,
	LineHeight   = 26,
	TextSize     = 16,
	Font         = Enum.Font.GothamMedium,
	BgColor      = Color3.fromRGB(15, 15, 20),
	BgTransparency = 0.15,
	MaxAgeSec    = 14,                          -- line lives this long
	FadeStartSec = 9,                           -- starts fading at this age
}

local GlobalAnnounceEvent = Remotes:WaitForChild("GlobalAnnounceEvent")

-- build the container (transparent; lines are individual frames)
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "AnnounceFeedGui" then c:Destroy() end
end
local gui = Instance.new("ScreenGui")
gui.Name = "AnnounceFeedGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 12
gui.Parent = playerGui

local list = Instance.new("Frame")
list.AnchorPoint = Vector2.new(0, 0)
list.Position = CFG.Anchor
list.Size = UDim2.fromOffset(CFG.Width, CFG.LineHeight * CFG.VisibleLines + 10)
list.BackgroundTransparency = 1
list.Parent = gui
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

-- a small "global drops" header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 18)
header.BackgroundTransparency = 1
header.Text = "🌍  GLOBAL DROPS"
header.Font = Enum.Font.GothamBold; header.TextSize = 14
header.TextColor3 = Color3.fromRGB(150, 150, 160)
header.TextXAlignment = Enum.TextXAlignment.Left
header.LayoutOrder = 0
header.Parent = list

local order = 1   -- increments forever so newest is on top (lowest LayoutOrder among lines)

local function addLine(msg)
	order = order - 1   -- newer = smaller LayoutOrder = appears above older
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, CFG.LineHeight)
	line.BackgroundColor3 = CFG.BgColor
	line.BackgroundTransparency = CFG.BgTransparency
	line.LayoutOrder = order
	line.Parent = list
	Instance.new("UICorner", line).CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", line)
	stroke.Thickness = 1; stroke.Color = msg.Color or Color3.fromRGB(255,255,255)
	stroke.Transparency = 0.35

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Font = CFG.Font; txt.TextSize = CFG.TextSize
	txt.TextColor3 = Color3.fromRGB(235, 235, 240)
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.RichText = true
	local pad = Instance.new("UIPadding", txt)
	pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
	txt.Parent = line

	-- build the message text
	local icon = "✨"
	if msg.Style == "legendary" then icon = "🌟"
	elseif msg.Style == "mythic" then icon = "💠"
	elseif msg.Style == "epic" then icon = "💜"
	elseif msg.Style == "rare" then icon = "🔵" end
	local hex = string.format("#%02X%02X%02X",
		math.floor((msg.Color.R)*255), math.floor((msg.Color.G)*255), math.floor((msg.Color.B)*255))
	local mutTag = msg.Mutated and " <font color='#b46cff'>(MUTATED!)</font>" or ""
	txt.Text = string.format('%s <font color="%s"><b>%s</b></font> got <font color="%s"><b>%s</b></font> <font color="#9aa0aa">(1 in %s)</font>%s',
		icon, "#c8d0e0", msg.Player or "?", hex, msg.Name or "?", msg.Odds or "?", mutTag)

	-- slide-in animation (from the left)
	line.Position = UDim2.fromOffset(-CFG.Width, 0)
	TweenService:Create(line, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(0, 0) }):Play()

	-- fade by age
	task.spawn(function()
		task.wait(CFG.FadeStartSec)
		local age = 0
		while age < (CFG.MaxAgeSec - CFG.FadeStartSec) do
			local dt = 0.1
			line.BackgroundTransparency = math.clamp(line.BackgroundTransparency + 0.02, 0, 1)
			stroke.Transparency = math.clamp(stroke.Transparency + 0.02, 0, 1)
			txt.TextTransparency = math.clamp(txt.TextTransparency + 0.03, 0, 1)
			txt.TextStrokeTransparency = math.clamp((txt.TextStrokeTransparency or 1) + 0.03, 0, 1)
			task.wait(dt); age = age + dt
		end
		line:Destroy()
	end)
end

GlobalAnnounceEvent.OnClientEvent:Connect(addLine)

print("✅ Announcement Feed loaded! (read-only, chat-style)")
]====]

print("✅ AnnouncementFeed created in StarterPlayerScripts.")
