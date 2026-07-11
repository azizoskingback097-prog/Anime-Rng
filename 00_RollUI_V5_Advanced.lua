-- ═══════════════════════════════════════════════════════════
-- 🎰 ROLL UI V5 (Refined Fakeout + Gradients + Auto-Skip!)
-- ═══════════════════════════════════════════════════════════
-- Paste in Command Bar → Enter
--
-- FEATURES:
--   • Refined Fake-Out: Slows down, skips Rare (or snaps back from Rare).
--   • Rarity Text: "1 in X" displayed cleanly in the center of every card.
--   • Visual Effects: Smooth color-changing gradients for standard rares.
--   • Auto-Skip (Gamepass): Skips animation for Common-Epic, but FORCES 
--     full animation for Legendary+!
--   • Top Result Text: Shows result at top center when skipped.
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local old = SPS:FindFirstChild("RollUI")
if old then old:Destroy() end

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
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

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

-- ⚙️ GAMEPASS ID: Replace 12345678 with your actual Auto-Skip Gamepass ID!
local AUTO_SKIP_GAMEPASS_ID = 12345678 
local LEGENDARY_THRESHOLD = 5000 -- Rarities this high or higher ALWAYS play the animation

local auraNames, commonAuras, rareAuras = {}, {}, {}
if AuraData then
	for _, a in ipairs(AuraData.Auras) do
		table.insert(auraNames, a)
		if a.Rarity < 100 then table.insert(commonAuras, a) end
		if a.Rarity >= 1000 and a.Rarity < LEGENDARY_THRESHOLD then table.insert(rareAuras, a) end
	end
end
if #auraNames == 0 then auraNames = { {Name="...", Color=Color3.fromRGB(255,255,255), Tier="Common", Rarity=1} } end
if #commonAuras == 0 then commonAuras = auraNames end
if #rareAuras == 0 then rareAuras = auraNames end

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

-- REEL CONTAINER
local reelContainer = Instance.new("Frame")
reelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
reelContainer.Size = UDim2.fromOffset(400, 700)
reelContainer.Position = UDim2.fromScale(0.5, 0.45)
reelContainer.BackgroundTransparency = 1
reelContainer.Visible = false
reelContainer.ZIndex = 5
reelContainer.Parent = shaker

-- Reel Window
local reelClip = Instance.new("Frame")
reelClip.Size = UDim2.fromScale(1, 1)
reelClip.Position = UDim2.fromScale(0, 0)
reelClip.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
reelClip.BackgroundTransparency = 0.3
reelClip.ClipsDescendants = true
reelClip.ZIndex = 5
local rcCorner = Instance.new("UICorner"); rcCorner.CornerRadius = UDim.new(0.05, 0); rcCorner.Parent = reelClip
reelClip.Parent = reelContainer

-- Center Line
local centerLine = Instance.new("Frame")
centerLine.AnchorPoint = Vector2.new(0.5, 0.5)
centerLine.Size = UDim2.fromOffset(420, 6)
centerLine.Position = UDim2.fromScale(0.5, 0.5)
centerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerLine.BorderSizePixel = 0
centerLine.ZIndex = 10
centerLine.Parent = reelClip

-- Center Glow
local centerGlow = Instance.new("Frame")
centerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
centerGlow.Size = UDim2.fromOffset(420, 100)
centerGlow.Position = UDim2.fromScale(0.5, 0.5)
centerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerGlow.BackgroundTransparency = 0.9
centerGlow.BorderSizePixel = 0
centerGlow.ZIndex = 9
local cgCorner = Instance.new("UICorner"); cgCorner.CornerRadius = UDim.new(1, 0); cgCorner.Parent = centerGlow
centerGlow.Parent = reelClip

-- Moving Reel
local reel = Instance.new("Frame")
reel.Size = UDim2.fromOffset(380, 0)
reel.Position = UDim2.fromScale(0, 0)
reel.BackgroundTransparency = 1
reel.Parent = reelClip

-- Top Result Text (For Auto-Skip)
local topResultText = Instance.new("TextLabel")
topResultText.AnchorPoint = Vector2.new(0.5, 0.5)
topResultText.Size = UDim2.fromOffset(600, 80)
topResultText.Position = UDim2.fromScale(0.5, 0.15)
topResultText.Text = ""
topResultText.Font = Enum.Font.GothamBlack
topResultText.TextScaled = true
topResultText.BackgroundTransparency = 1
topResultText.TextColor3 = Color3.fromRGB(255, 255, 255)
topResultText.TextTransparency = 1
topResultText.ZIndex = 20
topResultText.Parent = shaker

-- Buttons
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Size = UDim2.fromScale(0.16, 0.09)
button.Position = UDim2.fromScale(0.5, 0.92)
button.Text = "ROLL"
button.Font = Enum.Font.GothamBlack; button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(80, 120, 255); button.TextColor3 = Color3.fromRGB(255,255,255)
button.ZIndex = 20
local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0.12, 0); bCorner.Parent = button
button.Parent = gui

local autoBtn = Instance.new("TextButton")
autoBtn.AnchorPoint = Vector2.new(0.5, 0.5)
autoBtn.Size = UDim2.fromScale(0.10, 0.06)
autoBtn.Position = UDim2.fromScale(0.5, 0.85)
autoBtn.Text = "AUTO: OFF"
autoBtn.Font = Enum.Font.GothamBold; autoBtn.TextScaled = true
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); autoBtn.TextColor3 = Color3.fromRGB(255,255,255)
autoBtn.ZIndex = 20
local abCorner = Instance.new("UICorner"); abCorner.CornerRadius = UDim.new(0.15, 0); abCorner.Parent = autoBtn
autoBtn.Parent = gui

local skipBtn = Instance.new("TextButton")
skipBtn.AnchorPoint = Vector2.new(0.5, 0.5)
skipBtn.Size = UDim2.fromScale(0.10, 0.06)
skipBtn.Position = UDim2.fromScale(0.62, 0.85)
skipBtn.Text = "SKIP (OFF)"
skipBtn.Font = Enum.Font.GothamBold; skipBtn.TextScaled = true
skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); skipBtn.TextColor3 = Color3.fromRGB(200,200,200)
skipBtn.ZIndex = 20
local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0.15, 0); sbCorner.Parent = skipBtn
skipBtn.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromScale(0.7, 0.1); banner.Position = UDim2.fromScale(0.15, 0.1)
banner.Text = ""; banner.Font = Enum.Font.GothamBlack; banner.TextScaled = true
banner.BackgroundColor3 = Color3.fromRGB(30,30,45); banner.TextColor3 = Color3.fromRGB(255,215,0)
banner.BackgroundTransparency = 1; banner.Visible = false; banner.ZIndex = 30
local bnCorner = Instance.new("UICorner"); bnCorner.CornerRadius = UDim.new(0.2, 0); bnCorner.Parent = banner
banner.Parent = gui

-- ═══════════════════════════════════════════════════════════
-- CARD VISUAL EFFECTS (Gradients & Rarity Text)
-- ═══════════════════════════════════════════════════════════
local CARD_HEIGHT = 130
local CARD_WIDTH = 360
local CARD_GAP = 20
local STEP = CARD_HEIGHT + CARD_GAP

local activeGradients = {}

local function createCard(auraData, index)
	local card = Instance.new("Frame")
	card.Name = "Card" .. index
	card.Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromOffset(190, index * STEP + (CARD_HEIGHT / 2))
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	card.BorderSizePixel = 0
	card.ZIndex = 5
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.08, 0)
	corner.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Thickness = 4
	stroke.Color = auraData.Color or Color3.fromRGB(150, 150, 150)
	stroke.Parent = card
	
	-- Gradient Effect for Standard Rares (Color Changing)
	if auraData.Rarity >= 1000 and auraData.Rarity < LEGENDARY_THRESHOLD then
		local grad = Instance.new("UIGradient")
		grad.Name = "ColorGradient"
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, auraData.Color),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, auraData.Color)
		})
		grad.Rotation = 45
		grad.Parent = stroke
		table.insert(activeGradients, grad)
	end
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.9)
	label.Position = UDim2.fromScale(0.05, 0.05)
	label.BackgroundTransparency = 1
	-- RARITY TEXT ADDED HERE!
	label.Text = auraData.Name .. "\n1 in " .. auraData.Rarity
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.ZIndex = 6
	label.Parent = card
	
	card:SetAttribute("BaseWidth", CARD_WIDTH)
	card:SetAttribute("BaseHeight", CARD_HEIGHT)
	return card
end

local function clearReel()
	activeGradients = {}
	for _, child in ipairs(reel:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	reel.Size = UDim2.fromOffset(380, 0)
end

-- Animate gradients continuously
task.spawn(function()
	while true do
		for _, grad in ipairs(activeGradients) do
			if grad.Parent then
				grad.Offset = Vector2.new(os.clock() % 1, 0)
			end
		end
		task.wait(0.03)
	end
end)

-- CARD POP EFFECT
local popConnection = nil
local function startCardPopTracker()
	if popConnection then popConnection:Disconnect() end
	local lastPoppedIndex = -1
	popConnection = RunService.RenderStepped:Connect(function()
		if not reelContainer.Visible then return end
		local reelY = reel.Position.Y.Offset
		local centerLineY = reelClip.AbsoluteSize.Y / 2
		local centerInReel = centerLineY - reelY
		local closestIndex = math.floor(centerInReel / STEP + 0.5)
		if closestIndex ~= lastPoppedIndex and closestIndex >= 0 then
			if lastPoppedIndex >= 0 then
				local oldCard = reel:FindFirstChild("Card" .. lastPoppedIndex)
				if oldCard then
					local bw = oldCard:GetAttribute("BaseWidth"); local bh = oldCard:GetAttribute("BaseHeight")
					TweenService:Create(oldCard, TweenInfo.new(0.15), {Size = UDim2.fromOffset(bw, bh)}):Play()
				end
			end
			local newCard = reel:FindFirstChild("Card" .. closestIndex)
			if newCard then
				local bw = newCard:GetAttribute("BaseWidth"); local bh = newCard:GetAttribute("BaseHeight")
				TweenService:Create(newCard, TweenInfo.new(0.1), {Size = UDim2.fromOffset(bw + 20, bh + 20)}):Play()
				if SFX and closestIndex > lastPoppedIndex + 0 then SFX.Play(gui, "tick", 0.15) end
			end
			lastPoppedIndex = closestIndex
		end
	end)
end

-- CUTSCENE MANAGER (Top Tier Auras)
local CutsceneManager = {}
function CutsceneManager.Play(res)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1; overlay.ZIndex = 15; overlay.Parent = gui
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
	topResultText.Text = res.DisplayName or res.Name
	topResultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
	topResultText.TextTransparency = 0
	task.wait(3)
	TweenService:Create(overlay, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(topResultText, TweenInfo.new(1), {TextTransparency = 1}):Play()
	task.wait(1); overlay:Destroy()
end

-- ═══════════════════════════════════════════════════════════
-- REFINED FAKE-OUT LOGIC (V5)
-- ═══════════════════════════════════════════════════════════
local isRolling = false
local autoRollEnabled = false
local teaseCounter = math.random(3, 5)
local rollCount = 0

local function playReel(res, isSkipped)
	button.Active = false; button.Text = "..."
	clearReel()
	reelContainer.Visible = true
	rollCount += 1
	local isTeaseRoll = (rollCount % teaseCounter == 0) and not isSkipped
	if isTeaseRoll then teaseCounter = math.random(3, 5) end
	
	local totalCards = 60
	local winnerIndex = 54
	local teaseIndex = winnerIndex - 2 
	local isTeaseBefore = true
	
	if isTeaseRoll then
		isTeaseBefore = math.random() > 0.5
		teaseIndex = isTeaseBefore and (winnerIndex - 2) or (winnerIndex + 2)
	end
	
	for i = 0, totalCards - 1 do
		local cardData
		if i == winnerIndex then cardData = res
		elseif isTeaseRoll and i == teaseIndex then cardData = rareAuras[math.random(1, #rareAuras)]
		else cardData = commonAuras[math.random(1, #commonAuras)] end
		createCard(cardData, i).Parent = reel
	end
	
	reel.Size = UDim2.fromOffset(380, totalCards * STEP)
	task.wait(0.1)
	
	local reelClipCenterY = reelClip.AbsoluteSize.Y / 2
	local getTargetY = function(index) return reelClipCenterY - (index * STEP + (CARD_HEIGHT / 2)) end
	local finalEndY = getTargetY(winnerIndex)
	reel.Position = UDim2.fromOffset(0, 0)
	
	if isSkipped then
		-- AUTO-SKIP PATH: Fast spin, show result at top, maintain background look
		TweenService:Create(blur, TweenInfo.new(0.1), {Size = 10}):Play()
		local fastSpin = TweenService:Create(reel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
		fastSpin:Play()
		
		topResultText.Text = (res.DisplayName or res.Name) .. " (1 in " .. res.Rarity .. ")"
		topResultText.TextColor3 = res.Color or Color3.fromRGB(255, 255, 255)
		topResultText.TextTransparency = 0
		if SFX then SFX.Play(gui, "reveal") end
		
		fastSpin.Completed:Wait()
		task.wait(1.5) -- Cooldown for stability
		TweenService:Create(blur, TweenInfo.new(0.3), {Size = 0}):Play()
		TweenService:Create(topResultText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(reelClip, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		reelContainer.Visible = false
		button.Text = "ROLL"; button.Active = true
		return
	end
	
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 15}):Play()
	TweenService:Create(reelClip, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
	if SFX then SFX.Play(gui, "roll") end
	startCardPopTracker()
	
	if isTeaseRoll then
		if isTeaseBefore then
			-- SCENARIO 1: Slow down to Rare, then SKIP past it to Actual
			local t1 = TweenService:Create(reel, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, getTargetY(teaseIndex - 0.2))})
			t1:Play(); t1.Completed:Wait()
			task.wait(0.6) -- Hold to build tension
			local t2 = TweenService:Create(reel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
			t2:Play(); t2.Completed:Wait()
		else
			-- SCENARIO 2: Stop on Actual, creep towards Rare, then SNAP BACK
			local t1 = TweenService:Create(reel, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
			t1:Play(); t1.Completed:Wait()
			task.wait(0.6) 
			local t2 = TweenService:Create(reel, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, getTargetY(winnerIndex + 0.8))})
			t2:Play(); t2.Completed:Wait()
			task.wait(0.3)
			local t3 = TweenService:Create(reel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
			t3:Play(); t3.Completed:Wait()
		end
	else
		-- NORMAL SPIN
		local spin = TweenService:Create(reel, TweenInfo.new(4.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, finalEndY)})
		spin:Play(); spin.Completed:Wait()
	end
	
	if popConnection then popConnection:Disconnect(); popConnection = nil end
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	if SFX then 
		if res.Rarity >= 5000 then SFX.Play(gui, "legendary")
		elseif res.Rarity >= 1000 then SFX.Play(gui, "rare")
		else SFX.Play(gui, "reveal") end
	end
	
	local shakeIntensity = res.Rarity >= 1000 and 6 or 2
	local t0 = os.clock()
	while os.clock() - t0 < 0.3 do
		shaker.Position = UDim2.fromOffset((math.random() - 0.5) * shakeIntensity * 2, (math.random() - 0.5) * shakeIntensity * 2)
		task.wait()
	end
	shaker.Position = UDim2.fromScale(0, 0)
	
	button.Text = "ROLL"; button.Active = true
	if res.Rarity >= 50000 then CutsceneManager.Play(res) end
	task.wait(2)
	
	TweenService:Create(reelClip, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	for _, card in ipairs(reel:GetChildren()) do
		if card:IsA("GuiObject") then
			TweenService:Create(card, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			for _, child in ipairs(card:GetDescendants()) do
				if child:IsA("TextLabel") then TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
				elseif child:IsA("UIStroke") then TweenService:Create(child, TweenInfo.new(0.5), {Transparency = 1}):Play() end
			end
		end
	end
	TweenService:Create(centerLine, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(centerGlow, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	task.wait(0.6); reelContainer.Visible = false
end

-- ═══════════════════════════════════════════════════════════
-- ORCHESTRATOR & AUTO-SKIP LOGIC
-- ═══════════════════════════════════════════════════════════
local hasSkipGamepass = false
local autoSkipEnabled = false

local function checkGamepass()
	pcall(function()
		hasSkipGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_SKIP_GAMEPASS_ID)
	end)
	if hasSkipGamepass then
		skipBtn.Text = "SKIP (ON)"
		skipBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		autoSkipEnabled = true
	end
end
task.spawn(checkGamepass)

local function doRoll()
	if isRolling then return end
	isRolling = true
	local gotResult = false; local res
	task.spawn(function() res = RollFunction:InvokeServer(); gotResult = true end)
	while not gotResult do task.wait(0.02) end
	if not res then isRolling = false; return end

	-- If Auto-Skip is ON, and rarity is below Legendary threshold, SKIP IT!
	local shouldSkip = autoSkipEnabled and (res.Rarity < LEGENDARY_THRESHOLD)
	playReel(res, shouldSkip)
	isRolling = false
end

button.MouseButton1Click:Connect(doRoll)

autoBtn.MouseButton1Click:Connect(function()
	autoRollEnabled = not autoRollEnabled
	if autoRollEnabled then autoBtn.Text = "AUTO: ON"; autoBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	else autoBtn.Text = "AUTO: OFF"; autoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end
	if SFX then SFX.Play(gui, "click") end
end)

skipBtn.MouseButton1Click:Connect(function()
	if hasSkipGamepass then
		autoSkipEnabled = not autoSkipEnabled
		if autoSkipEnabled then skipBtn.Text = "SKIP (ON)"; skipBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		else skipBtn.Text = "SKIP (OFF)"; skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end
		if SFX then SFX.Play(gui, "click") end
	else
		-- Prompt Purchase
		MarketplaceService:PromptGamePassPurchase(player, AUTO_SKIP_GAMEPASS_ID)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if autoRollEnabled and not isRolling then doRoll() end
	end
end)

AnnounceEvent.OnClientEvent:Connect(function(info)
	local prefix = info.Mutated and "MUTATED " or ""
	banner.Text = "🎉  " .. info.Player .. " pulled " .. prefix .. info.Name .. "  (1 in " .. info.Rarity .. ")!"
	banner.TextColor3 = info.Color or Color3.fromRGB(255, 215, 0)
	banner.Visible = true; banner.BackgroundTransparency = 0.3; banner.Position = UDim2.fromScale(0.15,-0.15)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.15,0.1)}):Play()
	task.delay(5, function() banner.Visible = false end)
end)

print("RollUI loaded! (V5 - Refined Fakeout + Auto-Skip System)")
]==]

print("✅ ROLL UI V5 APPLIED!")
print("🎨 Added Rarity Text & Color Gradients to cards.")
print("🪝 Refined the Fakeout to skip exactly one card.")
print("⚡ Auto-Skip button added (Configured for Legendary+ protection).")
