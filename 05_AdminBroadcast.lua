-- ═══════════════════════════════════════════════════════════
-- 📣  SYS2 #5 — ADMIN BROADCAST  (avatar + ✓ + fade in/out)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:
--   • ServerScriptService ▸ AdminBroadcastServer   (Script)  — validates + relays
--   • StarterPlayerScripts ▸ AdminBroadcastUI       (LocalScript) — the panel + admin input
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   • ONLY admins (UserIds/usernames in AnnouncementService) can broadcast.
--   • Admins send a message via a small input box OR chat command /bc <msg>.
--   • All players see a panel: [admin avatar] ✓ AdminName: message
--     that fades in, holds, and fades out.
--   • Server-authoritative: the client never decides who's an admin.
-- ═══════════════════════════════════════════════════════════

local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

-- ═══ 1. SERVER: validate + relay ═══
local oldSrv = SSS:FindFirstChild("AdminBroadcastServer"); if oldSrv then oldSrv:Destroy() end
task.wait(0.1)
local srv = Instance.new("Script")
srv.Name = "AdminBroadcastServer"
srv.Parent = SSS
srv.Source = [====[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- 🔌 ensure remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local function ensureRF(name)
	local r = remotes:FindFirstChild(name)
	if not r then r = Instance.new("RemoteFunction"); r.Name = name; r.Parent = remotes end
	return r
end
local RequestBroadcast = ensureRF("RequestAdminBroadcast")   -- client -> server
local AdminBroadcastEvent = remotes:FindFirstChild("AdminBroadcastEvent")
	if not AdminBroadcastEvent then AdminBroadcastEvent = Instance.new("RemoteEvent"); AdminBroadcastEvent.Name = "AdminBroadcastEvent"; AdminBroadcastEvent.Parent = remotes end

-- 📣 use AnnouncementService for the admin list + broadcast logic (single source of truth)
local AnnouncementService
pcall(function() AnnouncementService = require(script.Parent:WaitForChild("AnnouncementService")) end)

-- client asks to broadcast -> validate admin -> fire to everyone
RequestBroadcast.OnServerInvoke = function(player, text)
	-- prefer AnnouncementService; fall back to a hard check if module missing
	local ok = false
	if AnnouncementService then
		ok = AnnouncementService.AdminBroadcast(player, text)
	else
		-- hard fallback admin list
		local ADMINS = { ["Twix79i"] = true }
		if ADMINS[player.Name] then
			AdminBroadcastEvent:FireAllClients({ AdminName = player.Name, AdminId = player.UserId, Message = tostring(text or ""):sub(1,200) })
			ok = true
		end
	end
	return ok
end

-- chat command:  /bc hello everyone   (or /broadcast)
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		msg = msg or ""
		local cmd, rest = msg:match("^%s*/(%a+)%s*(.*)$")
		if not cmd then return end
		cmd = cmd:lower()
		if (cmd == "bc" or cmd == "broadcast") and rest and #rest > 0 then
			RequestBroadcast.OnServerInvoke(player, rest)
		end
	end)
end)

print("✅ AdminBroadcastServer ready. Admins: /bc <message>  or use the input box.")
]====]

-- ═══ 2. CLIENT: the panel + admin input ═══
local oldUI = SPS:FindFirstChild("AdminBroadcastUI"); if oldUI then oldUI:Destroy() end
task.wait(0.1)
local ui = Instance.new("LocalScript")
ui.Name = "AdminBroadcastUI"
ui.Parent = SPS
ui.Source = [====[
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local AdminBroadcastEvent = Remotes:WaitForChild("AdminBroadcastEvent")
local RequestAdminBroadcast = Remotes:WaitForChild("RequestAdminBroadcast")

-- 📌 PANEL LOOK (tweak freely)
local Panel = {
	Width  = 420, Height = 70,
	Anchor = UDim2.new(0.5, 0, 0.16, 0),     -- top-center, below the coin HUD
	Bg     = Color3.fromRGB(18, 18, 26),
	Accent = Color3.fromRGB(80, 180, 255),   -- verified-blue
	HoldSec = 5,                             -- how long it stays fully visible
}

for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "AdminBroadcastGui" then c:Destroy() end
end
local gui = Instance.new("ScreenGui")
gui.Name = "AdminBroadcastGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 40
gui.Parent = playerGui

-- the broadcast panel (hidden until a message arrives)
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = Panel.Anchor
panel.Size = UDim2.fromOffset(Panel.Width, Panel.Height)
panel.BackgroundColor3 = Panel.Bg
panel.BackgroundTransparency = 1
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", panel); stroke.Thickness = 2
stroke.Color = Panel.Accent; stroke.Transparency = 1
local pad = Instance.new("UIPadding", panel)
pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.fromOffset(48, 48)
avatar.Position = UDim2.fromScale(0, 0.5)
avatar.AnchorPoint = Vector2.new(0, 0.5)
avatar.BackgroundColor3 = Color3.fromRGB(40,40,50)
avatar.Image = ""
avatar.Parent = panel
Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

local badge = Instance.new("ImageLabel")  -- the ✓ verified checkmark
badge.Size = UDim2.fromOffset(20, 20)
badge.AnchorPoint = Vector2.new(1, 1)
badge.Position = UDim2.new(0, 0 + 48, 0, 0 + 48)  -- bottom-right of avatar
badge.BackgroundColor3 = Panel.Accent
badge.Image = "rbxassetid://6690464379"  -- white check
badge.ScaleType = Enum.ScaleType.Fit
badge.Parent = panel
Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

local nameText = Instance.new("TextLabel")
nameText.Size = UDim2.new(1, -70, 0, 22)
nameText.Position = UDim2.fromOffset(60, 8)
nameText.BackgroundTransparency = 1
nameText.Font = Enum.Font.GothamBold; nameText.TextSize = 16
nameText.TextColor3 = Panel.Accent
nameText.TextXAlignment = Enum.TextXAlignment.Left
nameText.Text = ""
nameText.Parent = panel

local msgText = Instance.new("TextLabel")
msgText.Size = UDim2.new(1, -70, 1, -30)
msgText.Position = UDim2.fromOffset(60, 30)
msgText.BackgroundTransparency = 1
msgText.Font = Enum.Font.Gotham; msgText.TextSize = 15
msgText.TextColor3 = Color3.fromRGB(240, 240, 245)
msgText.TextXAlignment = Enum.TextXAlignment.Left
msgText.TextYAlignment = Enum.TextYAlignment.Top
msgText.TextWrapped = true; msgText.RichText = true
msgText.Text = ""
msgText.Parent = panel

local fadeToken = 0
local function show(info)
	fadeToken = fadeToken + 1
	local myToken = fadeToken

	-- fetch the admin's avatar thumbnail (client-side, harmless)
	task.spawn(function()
		local ok, thumb = pcall(function()
			local t = Players:GetUserThumbnailAsync(info.AdminId, Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size48x48)
			return t
		end)
		if ok and thumb and myToken == fadeToken then avatar.Image = thumb end
	end)

	nameText.Text = (info.AdminName or "Admin") .. ":"
	msgText.Text = info.Message or ""
	panel.Visible = true
	panel.BackgroundTransparency = 1
	stroke.Transparency = 1
	nameText.TextTransparency = 1
	msgText.TextTransparency = 1
	avatar.ImageTransparency = 1
	badge.ImageTransparency = 1

	-- fade in
	local ti = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(panel, ti, { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(stroke, ti, { Transparency = 0.25 }):Play()
	TweenService:Create(nameText, ti, { TextTransparency = 0 }):Play()
	TweenService:Create(msgText, ti, { TextTransparency = 0 }):Play()
	TweenService:Create(avatar, ti, { ImageTransparency = 0 }):Play()
	TweenService:Create(badge, ti, { ImageTransparency = 0 }):Play()

	-- hold, then fade out
	task.delay(Panel.HoldSec, function()
		if myToken ~= fadeToken then return end
		local to = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(panel, to, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, to, { Transparency = 1 }):Play()
		TweenService:Create(nameText, to, { TextTransparency = 1 }):Play()
		TweenService:Create(msgText, to, { TextTransparency = 1 }):Play()
		TweenService:Create(avatar, to, { ImageTransparency = 1 }):Play()
		TweenService:Create(badge, to, { ImageTransparency = 1 }):Play()
		task.wait(0.65)
		if myToken == fadeToken then panel.Visible = false end
	end)
end

AdminBroadcastEvent.OnClientEvent:Connect(show)

-- ═══ ADMIN INPUT BOX (only shown to admins) ═══
local function buildAdminInput()
	-- ask server "am I admin?" via the existing AdminStatusEvent if present
	local AdminStatusEvent = Remotes:FindFirstChild("AdminStatusEvent")
	if not AdminStatusEvent then return end

	local function reveal()
		local box = Instance.new("Frame")
		box.AnchorPoint = Vector2.new(1, 1)
		box.Size = UDim2.fromOffset(300, 38)
		box.Position = UDim2.new(0.98, 0, 0.98, 0)
		box.BackgroundColor3 = Color3.fromRGB(20,20,30)
		box.BackgroundTransparency = 0.15
		box.Parent = gui
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

		local input = Instance.new("TextBox")
		input.Size = UDim2.new(1, -80, 1, -8)
		input.Position = UDim2.fromOffset(6, 4)
		input.BackgroundColor3 = Color3.fromRGB(30,30,42)
		input.Text = ""
		input.PlaceholderText = "Broadcast to all players..."
		input.Font = Enum.Font.Gotham; input.TextSize = 14
		input.TextColor3 = Color3.fromRGB(240,240,245)
		input.ClearTextOnFocus = false
		input.Parent = box
		Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

		local send = Instance.new("TextButton")
		send.Size = UDim2.fromOffset(68, 30)
		send.Position = UDim2.new(1, -74, 0, 4)
		send.Text = "📣 Send"
		send.Font = Enum.Font.GothamBold; send.TextSize = 14
		send.BackgroundColor3 = Panel.Accent; send.TextColor3 = Color3.fromRGB(255,255,255)
		send.Parent = box
		Instance.new("UICorner", send).CornerRadius = UDim.new(0, 6)

		local function doSend()
			local t = input.Text
			if t and #t:gsub("%s+", "") > 0 then
				RequestAdminBroadcast:InvokeServer(t)
				input.Text = ""
			end
		end
		send.MouseButton1Click:Connect(doSend)
		input.FocusLost:Connect(function(enter) if enter then doSend() end end)
	end

	-- server pushes admin status to us on join; if we already are admin, reveal
	AdminStatusEvent.OnClientEvent:Connect(function(isAdmin)
		if isAdmin then reveal() end
	end)
	-- also nudge the server to re-send status in case we joined early
	task.spawn(function()
		task.wait(2)
		local AdminFunction = Remotes:FindFirstChild("AdminFunction")
		if AdminFunction then
			pcall(function()
				local isAdm = AdminFunction:InvokeServer("IsAdmin")
				if isAdm then reveal() end
			end)
		end
	end)
end
buildAdminInput()

print("✅ AdminBroadcastUI loaded! (panel + admin input box)")
]====]

print("✅ AdminBroadcast created (server + client). Admins: /bc <msg> or the input box.")
