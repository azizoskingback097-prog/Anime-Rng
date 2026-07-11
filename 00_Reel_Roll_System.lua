-- ═══════════════════════════════════════════════════════════
-- 🎰 CASE OPENING REEL SYSTEM (Complete Rework)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- FEATURES:
--   • Horizontal sliding reel (like CS:GO / Simulator games).
--   • Decelerates smoothly and lands EXACTLY in the center.
--   • Rare Teasing System (Every 3-5 rolls, fake a rare passing by).
--   • Blur background while spinning.
--   • Auto Roll waits completely for animation to finish.
--   • Cutscene Framework ready for Mythic/Legendary rarities.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Lighting = game:GetService("Lighting")
local old = SPS:FindFirstChild("RollUI")
if old then old:Destroy() end

-- Ensure Blur exists
local blur = Lighting:FindFirstChild("RollBlur")
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Name = "RollBlur"
	blur.Size = 0
	blur.Parent = Lighting
end

task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "RollUI"
s.Parent = SPS
s.Source = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollFunction = Remotes:WaitForChild("RollFunction")
local AnnounceEvent = Remotes:WaitForChild("AnnounceEvent")

local SFX
pcall(function() SFX = require(ReplicatedStorage:WaitForChild("SFXConfig")) end)
local AuraData
pcall(function() AuraData = require(ReplicatedStorage:WaitForChild("AuraData")) end)

local blur = Lighting:WaitForChild("RollBlur")

local auraNames, commonAuras, rareAuras = {}, {}, {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		table.insert(auraNames, a)
		if a.Rarity < 100 then table.insert(commonAuras, a) end
		if a.Rarity >= 5000 then table.insert(rareAuras, a) end
	end
end
if #auraNames == 0 then auraNames = { {Name="...", Color=Color3.fromRGB(255,255,255), Tier="Common", Rarity=1} } end
if #commonAuras == 0 then commonAuras = auraNames end
if #rareAuras == 0 then rareAuras = auraNames end

-- Clean old GUI
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "RollGui" then c:Destroy() end
end

-- Build UI
local gui = Instance.new("ScreenGui")
gui.Name = "RollGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 10
gui.Parent = playerGui

local shaker = Instance.new("Frame")
shaker.Size = UDim2.fromScale(1, 1); shaker.Position = UDim2.fromScale(0, 0)
shaker.BackgroundTransparency = 1; shaker.Parent = gui

-- Reel Container (The window you see through)
local reelClip = Instance.new("Frame")
reelClip.AnchorPoint = Vector2.new(0.5, 0.5)
reelClip.Size = UDim2.fromOffset(900, 250)
reelClip.Position = UDim2.fromScale(0.5, 0.4)
reelClip.BackgroundTransparency = 1
reelClip.ClipsDescendants = true
reelClip.ZIndex = 5
reelClip.Parent = shaker

-- Center Line (Shows where the winner lands)
local centerLine = Instance.new("Frame")
centerLine.AnchorPoint = Vector2.new(0.5, 0.5)
centerLine.Size = UDim2.fromOffset(6, 260)
centerLine.Position = UDim2.fromScale(0.5, 0.5)
centerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerLine.BorderSizePixel = 0
centerLine.ZIndex = 10
centerLine.Parent = reelClip

-- The Moving Reel
local reel = Instance.new("Frame")
reel.Size = UDim2.fromOffset(0, 250) -- Size X will grow as cards are added
reel.Position = UDim2.fromScale(0, 0)
reel.BackgroundTransparency = 1
reel.Parent = reelClip

-- Result Text (For cutscenes / final display)
local resultText = Instance.new("TextLabel")
resultText.AnchorPoint = Vector2.new(0.5, 0.5)
resultText.Size = UDim2.fromOffset(500, 100)
resultText.Position = UDim2.fromScale(0.5, 0.7)
resultText.Text = ""
resultText.Font = Enum.Font.GothamBlack
resultText.TextScaled = true
resultText.BackgroundTransparency = 1
resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
resultText.TextTransparency = 1
resultText.ZIndex = 20
resultText.Parent = shaker

-- Buttons
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Size = UDim2.fromScale(0.16, 0.09)
button.Position = UDim2.fromScale(0.5, 0.85)
button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
button.TextColor3 = Color3.fromRGB(255,255,255)
button.ZIndex = 20
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12, 0); bCorner.Parent = button
button.Parent = gui

local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5)
autoBtn.Size = UDim2.fromScale(0.10, 0.06)
autoBtn.Position = UDim2.fromScale(0.5, 0.78)
autoBtn.Text = "AUTO: OFF"
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextScaled = true
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
autoBtn.TextColor3 = Color3.fromRGB(255,255,255)
autoBtn.ZIndex = 20
local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0.15, 0); abCorner.Parent = autoBtn
autoBtn.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.1)
banner.Position = UDim2.fromScale(0.15, 0.12)
banner.Text = ""
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(30,30,45)
banner.TextColor3 = Color3.fromRGB(255,215,0)
banner.BackgroundTransparency = 1
banner.Visible = false
banner.ZIndex = 30
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2, 0); bnCorner.Parent = banner
banner.Parent = gui

-- ═══════════════════════════════════════════════════════════
-- CARD LOGIC
-- ═══════════════════════════════════════════════════════════
local CARD_WIDTH = 180
local CARD_GAP = 20
local STEP = CARD_WIDTH + CARD_GAP

local function createCard(auraData, index)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(CARD_WIDTH, 230)
	card.Position = UDim2.fromOffset(index * STEP, 10)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	card.BorderSizePixel = 0
	card.ZIndex = 5
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = auraData.Color or Color3.fromRGB(150, 150, 150)
	stroke.Parent = card
	
	local glow = Instance.new("UIStroke")
	glow.Thickness = 8
	glow.Color = auraData.Color or Color3.fromRGB(150, 150, 150)
	glow.Transparency = 0.5
	glow.Parent = card
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.9)
	label.Position = UDim2.fromScale(0.05, 0.05)
	label.BackgroundTransparency = 1
	label.Text = auraData.Name .. "\n\n" .. (auraData.Tier or "Common")
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.ZIndex = 6
	label.Parent = card
	
	return card
end

local function clearReel()
	for _, child in ipairs(reel:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	reel.Size = UDim2.fromOffset(0, 250)
end

-- ═══════════════════════════════════════════════════════════
-- CUTSCENE MANAGER (For Future Use!)
-- ═══════════════════════════════════════════════════════════
local CutsceneManager = {}

function CutsceneManager.Play(res)
	-- Framework ready: Add custom 3D/UI cutscenes for Mythic/Divine here!
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 15
	overlay.Parent = gui
	
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
	resultText.Text = res.DisplayName or res.Name
	resultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
	resultText.TextTransparency = 0
	
	task.wait(3) -- Pause to show off the rarity
	
	TweenService:Create(overlay, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(resultText, TweenInfo.new(1), {TextTransparency = 1}):Play()
	task.wait(1)
	overlay:Destroy()
end

-- ═══════════════════════════════════════════════════════════
-- MAIN REEL ANIMATION
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local autoRollEnabled = false
local teaseCounter = math.random(3, 5)
local rollCount = 0

local function playReel(res)
	button.Active = false
	button.Text = "..."
	clearReel()
	
	rollCount += 1
	local isTeaseRoll = (rollCount % teaseCounter == 0)
	if isTeaseRoll then
		teaseCounter = math.random(3, 5) -- Reset counter
	end
	
	-- Generate 40 cards
	local totalCards = 40
	for i = 0, totalCards - 1 do
		local cardData
		
		if i == totalCards - 1 then
			-- The Actual Winner!
			cardData = res
		elseif isTeaseRoll and (i == 25 or i == 30) then
			-- The Fake Rare Tease!
			cardData = rareAuras[math.random(1, #rareAuras)]
		else
			-- Random common filler
			cardData = commonAuras[math.random(1, #commonAuras)]
		end
		
		local card = createCard(cardData, i)
		card.Parent = reel
	end
	
	reel.Size = UDim2.fromOffset(totalCards * STEP, 250)
	
	-- Wait for UI to calculate sizes
	task.wait(0.1)
	
	-- Start Position (Off-screen right)
	local startX = reelClip.AbsoluteSize.X
	reel.Position = UDim2.fromOffset(startX, 0)
	
	-- End Position (Winner exactly in center)
	local winnerIndex = totalCards - 1
	local winnerCenterX = winnerIndex * STEP + (CARD_WIDTH / 2)
	local reelClipCenterX = reelClip.AbsoluteSize.X / 2
	local endX = reelClipCenterX - winnerCenterX
	
	-- Trigger Blur & Tick sounds
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 15}):Play()
	if SFX then SFX.Play(gui, "roll") end
	
	-- Tick loop while spinning
	task.spawn(function()
		local tickTime = os.clock()
		while reel.Position.X.Offset > endX + 50 do
			if os.clock() - tickTime > 0.1 then
				if SFX then SFX.Play(gui, "tick", 0.3) end
				tickTime = os.clock()
			end
			task.wait()
		end
	end)
	
	-- Start Spin Tween (5 seconds, smooth deceleration)
	local spinInfo = TweenInfo.new(5.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local spinTween = TweenService:Create(reel, spinInfo, {
		Position = UDim2.fromOffset(endX, 0)
	})
	spinTween:Play()
	
	spinTween.Completed:Wait()
	
	-- Remove Blur
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	
	-- Impact Effect!
	if SFX then 
		if res.Rarity >= 1000 then SFX.Play(gui, "legendary")
		elseif res.Rarity >= 100 then SFX.Play(gui, "rare")
		else SFX.Play(gui, "reveal") end
	end
	
	-- Shake Screen
	local shakeIntensity = res.Rarity >= 1000 and 8 or 3
	local t0 = os.clock()
	while os.clock() - t0 < 0.4 do
		local ox = (math.random() - 0.5) * shakeIntensity * 2
		local oy = (math.random() - 0.5) * shakeIntensity * 2
		shaker.Position = UDim2.fromOffset(ox, oy)
		task.wait()
	end
	shaker.Position = UDim2.fromScale(0, 0)
	
	button.Text = "ROLL"
	button.Active = true
	
	-- Check if this rarity requires a Cutscene (Framework Call)
	if res.Rarity >= 50000 then -- Mythic+
		CutsceneManager.Play(res)
	end
	
	-- Wait before clearing the reel so player can see result
	task.wait(2)
end

-- ═══════════════════════════════════════════════════════════
-- ROLL ORCHESTRATOR
-- ═══════════════════════════════════════════════════════════
local function doRoll()
	if isRolling then return end
	isRolling = true
	
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)
	
	-- Wait for server result BEFORE starting animation
	while not gotResult do task.wait(0.02) end
	
	if not res then
		isRolling = false; return
	end

	-- Play the full reel animation (yields until done)
	playReel(res)
	
	isRolling = false
end

button.MouseButton1Click:Connect(doRoll)

autoBtn.MouseButton1Click:Connect(function()
	autoRollEnabled = not autoRollEnabled
	if autoRollEnabled then
		autoBtn.Text = "AUTO: ON"
		autoBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	else
		autoBtn.Text = "AUTO: OFF"
		autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
	if SFX then SFX.Play(gui, "click") end
end)

-- Auto Roll Loop (Respects animation time perfectly)
task.spawn(function()
	while true do
		task.wait(0.1)
		if autoRollEnabled and not isRolling then 
			doRoll() 
		end
	end
end)

-- Announcements
AnnounceEvent.OnClientEvent:Connect(function(info)
	local prefix = info.Mutated and "MUTATED " or ""
	banner.Text = "🎉  " .. info.Player .. " pulled " .. prefix .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.TextColor3 = info.Color or Color3.fromRGB(255, 215, 0)
	banner.Visible = true
	banner.BackgroundTransparency = 0.3
	banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.12)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)

print("RollUI loaded! (Case Opening Reel System)")
]==]

print("✅ CASE OPENING REEL SYSTEM INSTALLED!")
print("🎰 Horizontal reel, teasing system, blur, and cutscene framework active!")
