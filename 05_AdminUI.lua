-- ═══════════════════════════════════════════════════════════
-- 🛠️  ADMIN UI (v9)  —  LocalScript   |   PLACE IN: StarterPlayerScripts
-- ═══════════════════════════════════════════════════════════
-- 📝 WHAT IT DOES (simple words):
-- Admin testing panel. Sections:
--   • 🌪️ WEATHER CONTROL → force any weather instantly
--   • 🧬 GIVE MUTATED AURA → pick a mutation + aura, get it
--   • GIVE AURA → normal auras
--   • LUCK SETTER, GIVE RARE, CLEAR, RESET
--
-- 🆕 v9 NEW SECTIONS:
--   • Weather control (reads all weathers from WeatherData automatically)
--   • Give mutated aura (pick mutation type + base aura)
--
-- 🎨 HOW TO CUSTOMIZE:
--   • Button pos → OPEN_BUTTON_POS
--   • Colors     → ⚙️ UI THEME block
--
-- 🔗 RELATED SCRIPTS:
--   • GameServer  → answers AdminFunction (ForceWeather, GiveMutated, etc.)
--   • AuraData    → fills the "give aura" list
--   • WeatherData → fills the weather + mutation lists
-- ═══════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local AdminFunction = Remotes:WaitForChild("AdminFunction")
local AdminStatusEvent = Remotes:WaitForChild("AdminStatusEvent")
local AuraData    = require(ReplicatedStorage:WaitForChild("AuraData"))
local WeatherData = require(ReplicatedStorage:WaitForChild("WeatherData"))

local function buildAdminUI()
	for _, child in ipairs(playerGui:GetChildren()) do
		if child.Name == "AdminPanelGui" then child:Destroy() end
	end

	local BG_COLOR     = Color3.fromRGB(40,25,30)
	local TEXT_COLOR   = Color3.fromRGB(255,255,255)
	local BUTTON_COLOR = Color3.fromRGB(200,60,80)
	local FIELD_COLOR  = Color3.fromRGB(60,60,75)
	local SECTION_COLOR = Color3.fromRGB(80,120,255)
	local WEATHER_COLOR = Color3.fromRGB(80,160,255)
	local MUTATION_COLOR = Color3.fromRGB(180,100,255)

	-- collect mutation names + colors from WeatherData
	local mutations = {}
	for _, w in ipairs(WeatherData.Weathers) do
		if w.Mutation and w.Mutation.Name then
			table.insert(mutations, { Name = w.Mutation.Name, Color = w.Mutation.Color })
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminPanelGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Parent = playerGui

	-- bigger window to fit new sections
	local window = Instance.new("Frame")
	window.Size = UDim2.fromScale(0.30, 0.85); window.Position = UDim2.fromScale(0.35, 0.075)
	window.BackgroundColor3 = BG_COLOR; window.Visible = false
	local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0.04,0); wCorner.Parent = window
	local wStroke = Instance.new("UIStroke"); wStroke.Thickness = 2; wStroke.Color = BUTTON_COLOR; wStroke.Parent = window
	window.Parent = gui

	-- open button (separate from window)
	local openBtn = Instance.new("TextButton")
	openBtn.Size = UDim2.fromScale(0.16,0.06); openBtn.Position = UDim2.fromScale(0.81,0.68)
	openBtn.Text = "🛠️  Admin"; openBtn.Font = Enum.Font.GothamBold; openBtn.TextScaled = true
	openBtn.BackgroundColor3 = BUTTON_COLOR; openBtn.TextColor3 = TEXT_COLOR
	local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(0.15,0); obCorner.Parent = openBtn
	openBtn.Parent = gui

	-- scrollable content
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(0.92, 0.88); scroll.Position = UDim2.fromScale(0.04, 0.08)
	scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.fromScale(0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = window

	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0.012,0); list.Parent = scroll

	-- helper to make a section header
	local function makeSection(text, color)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 0.035); lbl.Text = text
		lbl.Font = Enum.Font.GothamBlack; lbl.TextScaled = true
		lbl.BackgroundColor3 = color or SECTION_COLOR; lbl.TextColor3 = TEXT_COLOR
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.1,0); c.Parent = lbl
		lbl.Parent = scroll
		return lbl
	end

	-- helper to make a button
	local function makeBtn(text, color, onClick)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(1, 0.04); btn.Text = text
		btn.Font = Enum.Font.GothamMedium; btn.TextScaled = true
		btn.BackgroundColor3 = color or FIELD_COLOR; btn.TextColor3 = TEXT_COLOR
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0.1,0); c.Parent = btn
		btn.Parent = scroll
		if onClick then btn.MouseButton1Click:Connect(onClick) end
		return btn
	end

	-- title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.04); title.Text = "🛠️  Admin Panel"
	title.Font = Enum.Font.GothamBlack; title.TextScaled = true
	title.BackgroundTransparency = 1; title.TextColor3 = TEXT_COLOR; title.Parent = scroll

	-- close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromScale(0.12, 0.035); closeBtn.Position = UDim2.fromScale(0.85, 0.01)
	closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true
	closeBtn.BackgroundColor3 = Color3.fromRGB(80,30,40); closeBtn.TextColor3 = TEXT_COLOR
	closeBtn.ZIndex = 10
	local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0.2,0); cbCorner.Parent = closeBtn
	closeBtn.Parent = window

	-- ═════ 🌪️ WEATHER CONTROL SECTION ═════
	makeSection("🌪️  WEATHER CONTROL", WEATHER_COLOR)
	for _, weather in ipairs(WeatherData.Weathers) do
		local btn = makeBtn("Set Weather: " .. weather.Name, FIELD_COLOR)
		btn.MouseButton1Click:Connect(function()
			local ok = AdminFunction:InvokeServer("ForceWeather", weather.Name)
			if ok then btn.Text = "✓ " .. weather.Name; task.wait(1); btn.Text = "Set Weather: " .. weather.Name end
		end)
	end

	-- ═════ 🧬 GIVE MUTATED AURA SECTION ═════
	makeSection("🧬  GIVE MUTATED AURA", MUTATION_COLOR)
	if #mutations > 0 then
		-- mutation dropdown (textbox for now — type or pick)
		local mutLabel = Instance.new("TextLabel")
		mutLabel.Size = UDim2.fromScale(1, 0.025); mutLabel.Text = "Mutation: " .. mutations[1].Name
		mutLabel.Font = Enum.Font.GothamBold; mutLabel.TextScaled = true
		mutLabel.BackgroundTransparency = 1; mutLabel.TextColor3 = TEXT_COLOR; mutLabel.Parent = scroll

		local currentMutIndex = 1
		local mutSwitch = makeBtn("← Switch Mutation →", FIELD_COLOR)
		mutSwitch.MouseButton1Click:Connect(function()
			currentMutIndex = currentMutIndex + 1
			if currentMutIndex > #mutations then currentMutIndex = 1 end
			mutLabel.Text = "Mutation: " .. mutations[currentMutIndex].Name
			mutLabel.TextColor3 = mutations[currentMutIndex].Color or TEXT_COLOR
		end)
		mutLabel.TextColor3 = mutations[1].Color or TEXT_COLOR

		-- list of auras to combine with the mutation
		local sortedAuras = {}
		for _, a in ipairs(AuraData.Auras) do table.insert(sortedAuras, a) end
		table.sort(sortedAuras, function(a,b) return a.Rarity > b.Rarity end)

		for _, aura in ipairs(sortedAuras) do
			local btn = makeBtn("🧬 " .. mutations[1].Name .. " " .. aura.Name, MUTATION_COLOR)
			btn.MouseButton1Click:Connect(function()
				local mutName = mutations[currentMutIndex].Name
				local stored = mutName .. "|" .. aura.Name
				local ok = AdminFunction:InvokeServer("GiveMutated", stored)
				if ok then btn.Text = "✓ Given!"; task.wait(0.8)
					btn.Text = "🧬 " .. mutName .. " " .. aura.Name
				end
			end)
		end
	else
		makeBtn("(No mutations available — add weathers with mutations!)", FIELD_COLOR)
	end

	-- ═════ GIVE NORMAL AURA SECTION ═════
	makeSection("✨  GIVE AURA", SECTION_COLOR)
	local sortedAuras2 = {}
	for _, a in ipairs(AuraData.Auras) do table.insert(sortedAuras2, a) end
	table.sort(sortedAuras2, function(a,b) return a.Rarity > b.Rarity end)
	for _, aura in ipairs(sortedAuras2) do
		local btn = makeBtn(aura.Name .. "  (1 in " .. aura.Rarity .. ")", FIELD_COLOR)
		btn.TextColor3 = aura.Color
		btn.MouseButton1Click:Connect(function()
			local ok = AdminFunction:InvokeServer("GiveAura", aura.Name)
			if ok then btn.Text = "✓ Given: " .. aura.Name; task.wait(0.8); btn.Text = aura.Name .. "  (1 in " .. aura.Rarity .. ")" end
		end)
	end

	-- ═════ LUCK SECTION ═════
	makeSection("🍀  LUCK", SECTION_COLOR)
	local luckBox = Instance.new("TextBox")
	luckBox.Size = UDim2.fromScale(0.6, 0.04); luckBox.Text = "1"
	luckBox.Font = Enum.Font.GothamMedium; luckBox.TextScaled = true
	luckBox.BackgroundColor3 = FIELD_COLOR; luckBox.TextColor3 = TEXT_COLOR; luckBox.ClearTextOnFocus = false
	local lbCorner = Instance.new("UICorner"); lbCorner.CornerRadius = UDim.new(0.1,0); lbCorner.Parent = luckBox; luckBox.Parent = scroll
	makeBtn("Set Luck", BUTTON_COLOR, function()
		local val = tonumber(luckBox.Text) or 1
		local result = AdminFunction:InvokeServer("SetLuck", val)
		if result then luckBox.Text = tostring(result) end
	end)

	-- ═════ QUICK ACTIONS SECTION ═════
	makeSection("⚡  QUICK ACTIONS", SECTION_COLOR)
	makeBtn("🎲 Give Rare", Color3.fromRGB(150,80,200), function()
		local got = AdminFunction:InvokeServer("GiveRare")
		-- could show feedback
	end)
	makeBtn("🗑️ Clear Inventory", Color3.fromRGB(200,60,60), function()
		AdminFunction:InvokeServer("ClearInventory")
	end)
	makeBtn("♻️ Reset ALL Data", Color3.fromRGB(180,40,40), function()
		AdminFunction:InvokeServer("ResetData")
	end)

	-- open/close
	local isOpen = false
	openBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; window.Visible = isOpen end)
	closeBtn.MouseButton1Click:Connect(function() isOpen = false; window.Visible = false end)
	print("🛠️ AdminUI v9 built — weather + mutations control ready!")
end

AdminStatusEvent.OnClientEvent:Connect(function(isAdmin)
	if isAdmin then buildAdminUI() end
end)
