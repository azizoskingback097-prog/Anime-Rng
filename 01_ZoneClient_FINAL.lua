-- ═══════════════════════════════════════════════════════════
-- 🌍 ZONE UI & MUSIC (Final Fix)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old = SPS:FindFirstChild("ZoneClient")
if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "ZoneClient"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🎵 ZONE DATA TABLE
local ZONE_DATA = {
	["SpawnZone"] = { DisplayName = "The Sanctuary", TextColor = Color3.fromRGB(255, 255, 255), MusicId = "rbxassetid://1837879082", MusicVolume = 0.5 },
	["ForestZone"] = { DisplayName = "Whispering Woods", TextColor = Color3.fromRGB(150, 255, 150), MusicId = "rbxassetid://1846468024", MusicVolume = 0.4 },
	["SakuraZone"] = { DisplayName = "Sakura Gardens", TextColor = Color3.fromRGB(255, 180, 200), MusicId = "rbxassetid://1838115150", MusicVolume = 0.4 }
}

local currentZone = nil
local zoneParts = {}

local gui = Instance.new("ScreenGui")
gui.Name = "ZoneUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 12
gui.Parent = playerGui

local areaFrame = Instance.new("Frame")
areaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
areaFrame.Size = UDim2.fromOffset(800, 150)
areaFrame.Position = UDim2.fromScale(0.5, 0.18)
areaFrame.BackgroundTransparency = 1
areaFrame.Parent = gui

local areaText = Instance.new("TextLabel")
areaText.Size = UDim2.fromScale(1, 1)
areaText.BackgroundTransparency = 1
areaText.Text = ""
areaText.Font = Enum.Font.Bodoni -- Elegant luxury font
areaText.TextSize = 100 
areaText.TextColor3 = Color3.fromRGB(255, 255, 255)
areaText.TextTransparency = 1
areaText.ZIndex = 10
areaText.Parent = areaFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3; stroke.Color = Color3.fromRGB(20, 10, 30); stroke.Transparency = 1; stroke.Parent = areaText

local music1 = Instance.new("Sound")
music1.Volume = 0; music1.Looped = true; music1.Parent = SoundService
local music2 = Instance.new("Sound")
music2.Volume = 0; music2.Looped = true; music2.Parent = SoundService
local activeTrack = music1
local inactiveTrack = music2

local function playZoneMusic(zoneName)
	local data = ZONE_DATA[zoneName]
	if not data or not data.MusicId or activeTrack.SoundId == data.MusicId then return end
	local newTrack = inactiveTrack
	newTrack.SoundId = data.MusicId; newTrack.Volume = 0; newTrack:Play()
	TweenService:Create(newTrack, TweenInfo.new(2), {Volume = data.MusicVolume}):Play()
	TweenService:Create(activeTrack, TweenInfo.new(2), {Volume = 0}):Play()
	inactiveTrack = activeTrack; activeTrack = newTrack
	task.delay(2.1, function() if inactiveTrack.Volume == 0 then inactiveTrack:Stop() end end)
end

local function showAreaUI(zoneName)
	local data = ZONE_DATA[zoneName]
	if not data then return end
	areaText.Text = data.DisplayName; areaText.TextColor3 = data.TextColor
	stroke.Transparency = 1; areaText.TextTransparency = 1; areaText.Rotation = -2
	TweenService:Create(areaText, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency = 0, Rotation = 0}):Play()
	TweenService:Create(stroke, TweenInfo.new(0.8), {Transparency = 0.1}):Play()
	task.delay(4, function()
		TweenService:Create(areaText, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1, Rotation = 2}):Play()
		TweenService:Create(stroke, TweenInfo.new(1.2), {Transparency = 1}):Play()
	end)
end

local function setupZones()
	local zoneFolder = Workspace:WaitForChild("MapZones", 5)
	if not zoneFolder then warn("❌ 'MapZones' folder not found in Workspace!") return end
	for _, part in ipairs(zoneFolder:GetChildren()) do
		if part:IsA("BasePart") then
			part.Transparency = 1 
			table.insert(zoneParts, part)
		end
	end
end
setupZones()

RunService.Heartbeat:Connect(function()
	local char = player.Character; if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	for _, zone in ipairs(zoneParts) do
		local localPos = zone.CFrame:PointToObjectSpace(hrp.Position)
		if math.abs(localPos.X) < zone.Size.X/2 and math.abs(localPos.Y) < zone.Size.Y/2 and math.abs(localPos.Z) < zone.Size.Z/2 then
			if currentZone ~= zone.Name then
				currentZone = zone.Name; showAreaUI(currentZone); playZoneMusic(currentZone)
			end
			return 
		end
	end
	currentZone = nil
end)

print("ZoneClient loaded successfully! (Final Version)")
]==]

print("✅ ZONE CLIENT FIXED! (Will now load properly with Bodoni font)")
