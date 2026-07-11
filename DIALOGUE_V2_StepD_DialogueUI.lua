-- ═══════════════════════════════════════════════════════════
-- 💬  STEP D — DIALOGUE UI  (Grow a Garden 2 style + Overhead Bubble)
-- Paste in:  View ▸ Command Bar   →   Enter
-- Creates:  StarterPlayerScripts ▸ DialogueUI  (LocalScript)
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT THIS DOES:
--   • Auto-scans for the NPC (Heartbeat distance check — bulletproof).
--   • Shows a "Grow a Garden 2" dialogue box: dark, rounded, typewriter,
--     bouncy pop-in, hover effects, BRANCHING options.
--   • Pops a chat bubble ABOVE the NPC's head when he answers (+ bounce).
--   • Reads DialogueData (words/options) + ShopData (potions) → fully
--     data-driven, just like the VFX system. Edit the modules, not this!
-- ═══════════════════════════════════════════════════════════

local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local RS  = game:GetService("ReplicatedStorage")

local old = SPS:FindFirstChild("DialogueUI"); if old then old:Destroy() end
task.wait(0.1)

local s = Instance.new("LocalScript")
s.Name = "DialogueUI"
s.Parent = SPS
s.Source = [====[
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

print("💬 DialogueUI V2 started — loading data modules...")

-- 📚 Load our customizable data (edit THOSE, not this script)
local DialogueData = require(ReplicatedStorage:WaitForChild("DialogueData"))
local ShopData     = require(ReplicatedStorage:WaitForChild("ShopData"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local ShopOpenEvent        = Remotes:WaitForChild("ShopOpenEvent")
local PurchaseItemFunction = Remotes:WaitForChild("PurchaseItemFunction")

local OH = DialogueData.Overhead or {}

-- ── tiny helpers ─────────────────────────────────────────
local function pick(t)
	if type(t) == "string" then return t end
	if not t or #t == 0 then return "..." end
	return t[math.random(1, #t)]
end

local function fmt(n) -- 100000 -> "100,000"
	n = math.floor(tonumber(n) or 0)
	local s = tostring(n); local out = {}
	while #s > 3 do table.insert(out, 1, s:sub(-3)); s = s:sub(1, -4) end
	if #s > 0 then table.insert(out, 1, s) end
	return table.concat(out, ",")
end

do
	local c = 0; for _ in pairs(ShopData.Items) do c = c + 1 end
	print("✅ Data loaded! NPC: " .. DialogueData.NPCName .. " | Shop items: " .. c)
end

-- ═══════════════════════════════════════════════════════════
-- 💬 OVERHEAD BUBBLE (text above NPC head + bounce pop)
-- ═══════════════════════════════════════════════════════════
local bubbleFrame, bubbleText
local bubbleToken = 0

local function buildBubble(head)
	local bb = Instance.new("BillboardGui")
	bb.Name = "NPCDialogueBubble"
	bb.Adornee = head
	bb.Size = UDim2.new(0, 320, 0, 96)
	bb.StudsOffset = Vector3.new(0, OH.OffsetY or 2.4, 0)
	bb.MaxDistance = OH.MaxDistance or 70
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = head

	local frame = Instance.new("Frame")
	frame.Name = "Bubble"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, 0)
	frame.Size = UDim2.new(0, 0, 0, 0)           -- starts at 0 for the POP
	frame.BackgroundColor3 = OH.BubbleColor or Color3.fromRGB(22, 22, 28)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.Parent = bb
	Instance.new("UIPadding", frame).PaddingTop    = UDim.new(0, 10)
	frame.UIPadding.PaddingBottom = UDim.new(0, 10)
	frame.UIPadding.PaddingLeft   = UDim.new(0, 14)
	frame.UIPadding.PaddingRight  = UDim.new(0, 14)
	local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", frame); stroke.Thickness = 2
	stroke.Color = OH.NameColor or Color3.fromRGB(255, 215, 0); stroke.Transparency = 0.5
	local layout = Instance.new("UIListLayout", frame); layout.Padding = UDim.new(0, 3)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0, 18); nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 15
	nameLbl.TextColor3 = OH.NameColor or Color3.fromRGB(255, 215, 0)
	nameLbl.Text = DialogueData.NPCName
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = frame

	local textLbl = Instance.new("TextLabel")
	textLbl.Size = UDim2.new(1, 0, 0, 50); textLbl.BackgroundTransparency = 1
	textLbl.Font = Enum.Font.Gotham; textLbl.TextSize = OH.TextSize or 19
	textLbl.TextColor3 = OH.TextColor or Color3.fromRGB(245, 245, 250)
	textLbl.TextWrapped = true
	textLbl.TextXAlignment = Enum.TextXAlignment.Left
	textLbl.TextYAlignment = Enum.TextYAlignment.Top
	textLbl.Text = ""
	textLbl.Parent = frame

	bubbleFrame = frame; bubbleText = textLbl
	print("✅ Overhead bubble attached to NPC!")
end

local function showBubble(text)
	if OH.Enabled == false or not bubbleFrame then return end
	bubbleToken = bubbleToken + 1
	local myToken = bubbleToken
	bubbleText.Text = text
	bubbleFrame.Size = UDim2.new(0, 0, 0, 0)
	bubbleFrame.BackgroundTransparency = 1
	TweenService:Create(bubbleFrame,
		TweenInfo.new(OH.PopTime or 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0.12 }):Play()
	task.delay(OH.AutoClearTime or 6, function()
		if myToken ~= bubbleToken then return end
		TweenService:Create(bubbleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }):Play()
	end)
end

-- ═══════════════════════════════════════════════════════════
-- 🪟 DIALOGUE BOX (Grow a Garden 2 style)
-- ═══════════════════════════════════════════════════════════
for _, c in ipairs(playerGui:GetChildren()) do
	if c.Name == "DialogueGui" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "DialogueGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 30
gui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 0.93, 0)
container.Size = UDim2.new(0.42, 0, 0, 0)
container.AutomaticSize = Enum.AutomaticSize.Y
container.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
container.BackgroundTransparency = 0.08
container.BorderSizePixel = 0
container.Visible = false
container.Parent = gui
local cCorner = Instance.new("UICorner", container); cCorner.CornerRadius = UDim.new(0, 14)
local cStroke = Instance.new("UIStroke", container); cStroke.Thickness = 2
cStroke.Color = Color3.fromRGB(255, 215, 0); cStroke.Transparency = 0.6
local cPad = Instance.new("UIPadding", container)
cPad.PaddingTop = UDim.new(0, 16); cPad.PaddingBottom = UDim.new(0, 16)
cPad.PaddingLeft = UDim.new(0, 20); cPad.PaddingRight = UDim.new(0, 20)
local cLayout = Instance.new("UIListLayout", container); cLayout.Padding = UDim.new(0, 10)
local cScale = Instance.new("UIScale", container); cScale.Scale = 0   -- for the pop-in

local nameplate = Instance.new("TextLabel")
nameplate.Size = UDim2.new(1, 0, 0, 26); nameplate.BackgroundTransparency = 1
nameplate.Font = Enum.Font.GothamBold; nameplate.TextSize = 22
nameplate.TextColor3 = Color3.fromRGB(255, 215, 0)
nameplate.TextXAlignment = Enum.TextXAlignment.Left
nameplate.Text = DialogueData.NPCName; nameplate.TextStrokeTransparency = 0.6
nameplate.Parent = container

local bodyText = Instance.new("TextLabel")
bodyText.Size = UDim2.new(1, 0, 0, 0); bodyText.AutomaticSize = Enum.AutomaticSize.Y
bodyText.BackgroundTransparency = 1
bodyText.Font = Enum.Font.Gotham; bodyText.TextSize = 19
bodyText.TextColor3 = Color3.fromRGB(240, 240, 240)
bodyText.TextXAlignment = Enum.TextXAlignment.Left
bodyText.TextYAlignment = Enum.TextYAlignment.Top
bodyText.TextWrapped = true; bodyText.RichText = true
bodyText.TextStrokeTransparency = 0.5; bodyText.Text = ""
bodyText.Parent = container

local optionsFrame = Instance.new("Frame")
optionsFrame.Name = "Options"
optionsFrame.Size = UDim2.new(1, 0, 0, 0); optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
optionsFrame.BackgroundTransparency = 1; optionsFrame.Parent = container
local oLayout = Instance.new("UIListLayout", optionsFrame); oLayout.Padding = UDim.new(0, 6)

-- ═══════════════════════════════════════════════════════════
-- 🧠 LOGIC  (forward-declared so functions can reference each other)
-- ═══════════════════════════════════════════════════════════
local gotoNode, openShop, closeMenu, buyItem

local isTyping = false
local typingThread
local nodeHistory = {}

local function typeText(text)
	if typingThread then task.cancel(typingThread) end
	isTyping = true
	bodyText.Text = text
	bodyText.MaxVisibleGraphemes = 0
	typingThread = task.spawn(function()
		local len = utf8.len(text)
		for i = 1, len do
			if not isTyping then break end
			bodyText.MaxVisibleGraphemes = i
			task.wait(0.02)
		end
		isTyping = false
	end)
end

local function showLine(line)
	typeText(line)
	showBubble(line)
end

local function clearOptions()
	for _, c in ipairs(optionsFrame:GetChildren()) do
		if c:IsA("GuiButton") then c:Destroy() end
	end
end

local function makeButton(label, baseColor, order, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = baseColor or Color3.fromRGB(40, 40, 48)
	btn.BackgroundTransparency = 0.2
	btn.Text = "  ›  " .. label
	btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 18
	btn.TextColor3 = Color3.fromRGB(245, 245, 245)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextStrokeTransparency = 0.5
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.Parent = optionsFrame

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12),
			{ BackgroundColor3 = (baseColor or Color3.fromRGB(40,40,48)):Lerp(Color3.new(1,1,1), 0.20), TextSize = 20 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12),
			{ BackgroundColor3 = baseColor or Color3.fromRGB(40, 40, 48), TextSize = 18 }):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		if isTyping then                -- click once to skip the typewriter
			isTyping = false
			bodyText.MaxVisibleGraphemes = -1
			return
		end
		onClick()
	end)
	return btn
end

local function pickNodeLine(node)
	if node.WeatherLines then
		local w = ReplicatedStorage:FindFirstChild("CurrentWeather")
		local key = w and w.Value
		local pool = (key and node.WeatherLines[key]) or node.Fallback or node.Lines
		return pick(pool)
	end
	return pick(node.Lines)
end

local function buildNodeOptions(node)
	clearOptions()
	for i, opt in ipairs(node.Options or {}) do
		local color = opt.Color
		if opt.Action == "Close" then color = color or Color3.fromRGB(120, 45, 45) end
		makeButton(opt.Text or "?", color, i, function()
			if opt.Goto then
				table.insert(nodeHistory, require(ReplicatedStorage).DialogueData and currentNode or currentNode)
				gotoNode(opt.Goto)
			elseif opt.Action == "OpenShop" then
				openShop()
			elseif opt.Action == "Back" then
				gotoNode(table.remove(nodeHistory) or "Root")
			elseif opt.Action == "Close" then
				closeMenu()
			end
		end)
	end
end

function gotoNode(key)
	currentNode = key
	if DialogueData.AutoShop and DialogueData.AutoShop.Enabled ~= false
		and key == (DialogueData.AutoShop.NodeKey or "Shop") then
		-- 🔮 AUTO-SHOP: build potion buttons straight from ShopData
		showLine(pick(DialogueData.AutoShop.BrowseLine or { "Here's what I've got:" }))
		clearOptions()
		local i = 1
		for id, item in pairs(ShopData.Items) do
			local label = (item.Icon or "🧪") .. "  " .. (item.DisplayName or id)
				.. "   —   " .. fmt(item.Price) .. " 🪙"
			makeButton(label, item.Color or Color3.fromRGB(40,40,48), i, function()
				buyItem(id, item)
			end)
			i = i + 1
		end
		makeButton("◀ Back", Color3.fromRGB(50, 50, 60), i, function()
			gotoNode(table.remove(nodeHistory) or "Root")
		end)
		return
	end

	local node = DialogueData.Nodes[key]
	if not node then
		warn("❌ Dialogue node not found: " .. tostring(key))
		return
	end
	showLine(pickNodeLine(node))
	buildNodeOptions(node)
end

function buyItem(id, item)
	showLine("Let me grab that " .. (item.DisplayName or id) .. " for you...")
	task.spawn(function()
		local ok, _msg = PurchaseItemFunction:InvokeServer(id)
		if ok then
			showLine(pick(item.BuyLine or { "Pleasure doing business!" }))
		else
			showLine("You haven't got enough coins for that yet, traveler! (" .. fmt(item.Price) .. " needed)")
		end
	end)
end

function openShop()
	pcall(function() ShopOpenEvent:FireServer() end)   -- server relay opens ShopUI
	local function tryToggle()
		local shopGui = playerGui:FindFirstChild("ShopGui")
		if shopGui then
			for _, child in ipairs(shopGui:GetChildren()) do
				if child:IsA("Frame") then child.Visible = true; return end
			end
		end
	end
	tryToggle()
	task.delay(0.4, tryToggle)   -- retry in case ShopUI loaded a bit late
end

function closeMenu()
	isTyping = false
	local wasOpen = container.Visible
	TweenService:Create(cScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = 0 }):Play()
	task.delay(0.24, function() container.Visible = false end)
	if wasOpen then
		task.delay(0.1, function() showBubble(pick(DialogueData.Farewells or { "See you around!" })) end)
	end
end

local function openMenu()
	if container.Visible then return end
	nodeHistory = {}
	container.Visible = true
	cScale.Scale = 0
	TweenService:Create(cScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }):Play()
	task.delay(0.12, function() gotoNode("Root") end)
end

-- ═══════════════════════════════════════════════════════════
-- 🔎 AUTO-SCAN (Heartbeat distance check — bulletproof, no prompt)
-- ═══════════════════════════════════════════════════════════
local npcHead
RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if not npcHead then
		for _, name in ipairs(DialogueData.NPCSearchNames or { "ShopDealler" }) do
			local map = Workspace:FindFirstChild("Map")
			local npc = (map and map:FindFirstChild(name, true)) or Workspace:FindFirstChild(name, true)
			if npc then
				npcHead = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
				if npcHead then
					print("✅ Found NPC: " .. npc:GetFullName())
					if OH.Enabled ~= false then buildBubble(npcHead) end
				end
				break
			end
		end
		return
	end

	local dist = (hrp.Position - npcHead.Position).Magnitude
	local talkD = DialogueData.TalkDistance or 12
	if dist < talkD then
		if not container.Visible then openMenu() end
	elseif dist > talkD + 5 then
		if container.Visible then closeMenu() end
	end
end)

print("✅ DialogueUI V2 fully loaded! Walk near " .. DialogueData.NPCName .. " to talk.")
]====]

print("✅ STEP D done! DialogueUI created in StarterPlayerScripts.")
print("   🎮 Press Play and walk near the NPC to test!")
