-- ============================================================
-- ============  UNIVERSAL HUB — UI (MINI)  ===================
-- ============================================================
local UI = {}

function UI.init(Hub)
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local BASE = "https://raw.githubusercontent.com/artemkf161rus-max/universal-hub/refs/heads/main/"

	-- ==================== ЦВЕТА ====================
	local COLORS = {
		Background    = Color3.fromRGB(15, 12, 25),
		Background2   = Color3.fromRGB(25, 20, 40),
		Background3   = Color3.fromRGB(35, 28, 55),
		Accent        = Color3.fromRGB(150, 80, 255),
		AccentDark    = Color3.fromRGB(80, 30, 160),
		AccentLight   = Color3.fromRGB(200, 150, 255),
		Stroke        = Color3.fromRGB(180, 120, 255),
		Text          = Color3.fromRGB(230, 220, 255),
		TextBright    = Color3.fromRGB(255, 255, 255),
		TextDim       = Color3.fromRGB(160, 150, 180),
		DangerDark    = Color3.fromRGB(120, 20, 20),
		SuccessDark   = Color3.fromRGB(20, 130, 60),
		SwitchOff     = Color3.fromRGB(45, 40, 60),
		SwitchOn      = Color3.fromRGB(150, 80, 255),
		Divider       = Color3.fromRGB(70, 60, 100),
		ScrollBar     = Color3.fromRGB(150, 80, 255),
	}
	local FONT_BOLD = Enum.Font.GothamBold
	local FONT = Enum.Font.Gotham

	-- ==================== ROOT GUI ====================
	local gui = Instance.new("ScreenGui")
	gui.Name = "MenuUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	Hub.Objects.MainGui = gui

	local isLocked = false
	Hub.IsLocked = function() return isLocked end

	local function corner(parent, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r or 5)
		c.Parent = parent
		return c
	end

	local function stroke(parent, color, thickness, transparency)
		local s = Instance.new("UIStroke")
		s.Color = color or COLORS.Stroke
		s.Thickness = thickness or 1
		s.Transparency = transparency or 0
		s.Parent = parent
		return s
	end

	local function gradient(parent, color1, color2, rotation)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(color1, color2)
		g.Rotation = rotation or 90
		g.Parent = parent
		return g
	end

	local function makeDraggable(frame, dragTarget)
		local dragging, dragStart, startPos, dragInput
		local target = dragTarget or frame
		target.InputBegan:Connect(function(input)
			if isLocked then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		target.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if isLocked then dragging = false return end
			if input == dragInput then
				local delta = input.Position - dragStart
				frame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	-- ============================================================
	-- ELEMENTS (очень маленькие)
	-- ============================================================
	local Elements = {}

	function Elements.label(parent, text, y, cfg)
		cfg = cfg or {}
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -12, 0, 12)
		l.Position = UDim2.new(0, 6, 0, y)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = cfg.color or COLORS.Text
		l.Font = cfg.font or FONT_BOLD
		l.TextSize = cfg.size or 8
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = parent
		return l
	end

	function Elements.divider(parent, y)
		local d = Instance.new("Frame")
		d.Name = "Divider"
		d.Size = UDim2.new(1, -12, 0, 1)
		d.Position = UDim2.new(0, 6, 0, y)
		d.BackgroundColor3 = COLORS.Divider
		d.BorderSizePixel = 0
		d.Parent = parent
		gradient(d, Color3.fromRGB(70, 60, 100), COLORS.Accent, 0)
		return d
	end

	function Elements.switch(parent, y, callback)
		local bg = Instance.new("TextButton")
		bg.Size = UDim2.new(0, 28, 0, 14)
		bg.Position = UDim2.new(1, -34, 0, y)
		bg.BackgroundColor3 = COLORS.SwitchOff
		bg.BorderSizePixel = 0
		bg.Text = ""
		bg.AutoButtonColor = false
		bg.Parent = parent
		corner(bg, 999)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 9, 0, 9)
		knob.Position = UDim2.new(0, 2, 0.5, -4.5)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.Parent = bg
		corner(knob, 999)

		local state = false
		local function update()
			TweenService:Create(bg, TweenInfo.new(0.2),
				{BackgroundColor3 = state and COLORS.SwitchOn or COLORS.SwitchOff}):Play()
			TweenService:Create(knob, TweenInfo.new(0.2),
				{Position = state and UDim2.new(0, 17, 0.5, -4.5) or UDim2.new(0, 2, 0.5, -4.5)}):Play()
			if callback then callback(state) end
		end

		bg.MouseButton1Click:Connect(function()
			state = not state
			update()
		end)

		return {
			instance = bg,
			knob = knob,
			get = function() return state end,
			set = function(v) state = v update() end,
		}
	end

	function Elements.slider(parent, y, min, max, default, callback)
		local sb = Instance.new("Frame")
		sb.Size = UDim2.new(1, -12, 0, 4)
		sb.Position = UDim2.new(0, 6, 0, y)
		sb.BackgroundColor3 = COLORS.Background2
		sb.BorderSizePixel = 0
		sb.Active = true
		sb.Parent = parent
		corner(sb, 999)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
		fill.BackgroundColor3 = COLORS.Accent
		fill.BorderSizePixel = 0
		fill.Parent = sb
		corner(fill, 999)
		gradient(fill, COLORS.AccentDark, COLORS.Accent, 0)

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 9, 0, 9)
		knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
		knob.AnchorPoint = Vector2.new(0, 0.5)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.ZIndex = 2
		knob.Parent = sb
		corner(knob, 999)

		local dragging = false
		local value = default
		local function setV(v)
			v = math.clamp(v, min, max)
			value = v
			local a = (v - min) / (max - min)
			fill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
			if callback then callback(v) end
		end

		sb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				local p = input.Position.X - sb.AbsolutePosition.X
				setV(min + math.clamp(p / sb.AbsoluteSize.X, 0, 1) * (max - min))
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
				local p = input.Position.X - sb.AbsolutePosition.X
				setV(min + math.clamp(p / sb.AbsoluteSize.X, 0, 1) * (max - min))
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		return {
			instance = sb,
			get = function() return value end,
			set = setV,
		}
	end

	function Elements.button(parent, text, order, color, width, callback)
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("TextButton") and child.Text == text then
				return child
			end
		end

		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, width or 50, 0, 18)
		b.BackgroundColor3 = color or COLORS.AccentDark
		b.BorderSizePixel = 0
		b.Text = text
		b.TextColor3 = COLORS.TextBright
		b.Font = FONT_BOLD
		b.TextSize = 9
		b.LayoutOrder = order or 0
		b.AutoButtonColor = false
		b.Active = true
		b.Parent = parent
		corner(b, 4)
		stroke(b, COLORS.Stroke, 1, 0.3)
		if callback then b.MouseButton1Click:Connect(callback) end
		return b
	end

	-- ============================================================
	-- BUTTON HOLDER (минимальный)
	-- ============================================================
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, 160, 0, 20)
	holder.Position = UDim2.new(0, 10, 0, 10)
	holder.BackgroundTransparency = 1
	holder.Active = true
	holder.Parent = gui

	local holderLayout = Instance.new("UIListLayout")
	holderLayout.FillDirection = Enum.FillDirection.Horizontal
	holderLayout.Padding = UDim.new(0, 4)
	holderLayout.Parent = holder

	local toggleBtn = Elements.button(holder, "Menu", 1, COLORS.AccentDark, 48)
	local lockBtn   = Elements.button(holder, "Lock", 2, COLORS.AccentDark, 45)
	local unloadBtn = Elements.button(holder, "Exit", 3, COLORS.DangerDark, 45)

	-- ============================================================
	-- MENU FRAME (200×250)
	-- ============================================================
	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(0, 200, 0, 250)
	menu.Position = UDim2.new(0, 10, 0, 35)
	menu.BackgroundColor3 = COLORS.Background
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.Active = true
	menu.ClipsDescendants = true
	menu.Parent = gui
	corner(menu, 6)
	stroke(menu, COLORS.Accent, 1, 0)
	gradient(menu, COLORS.Background, COLORS.Background2, 90)

	local topGlow = Instance.new("Frame")
	topGlow.Size = UDim2.new(1, -12, 0, 1.5)
	topGlow.Position = UDim2.new(0, 6, 0, 3)
	topGlow.BackgroundColor3 = COLORS.Accent
	topGlow.BorderSizePixel = 0
	topGlow.ZIndex = 2
	topGlow.Parent = menu
	corner(topGlow, 999)
	gradient(topGlow, COLORS.AccentDark, COLORS.AccentLight, 0)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0, 14)
	title.Position = UDim2.new(0, 6, 0, 7)
	title.BackgroundTransparency = 1
	title.Text = "✦ Universal ✦"
	title.TextColor3 = COLORS.TextBright
	title.Font = FONT_BOLD
	title.TextSize = 9
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = menu

	local versionLabel = Instance.new("TextLabel")
	versionLabel.Size = UDim2.new(0, 40, 0, 10)
	versionLabel.Position = UDim2.new(1, -46, 0, 8)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "v" .. (Hub.Config.HUB_VERSION or "1.0.0")
	versionLabel.TextColor3 = COLORS.TextDim
	versionLabel.Font = FONT
	versionLabel.TextSize = 8
	versionLabel.TextXAlignment = Enum.TextXAlignment.Right
	versionLabel.Parent = menu

	-- ============================================================
	-- PAGES
	-- ============================================================
	local pages = {}
	local pagesCount = Hub.Config.PAGES_COUNT or 4
	local pageNames = { "Move", "ESP", "Misc", "Play" }

	local CANVAS_HEIGHT = 450

	for i = 1, pagesCount do
		local pageFrame = Instance.new("Frame")
		pageFrame.Name = "Page" .. i
		pageFrame.Size = UDim2.new(1, 0, 1, -46)
		pageFrame.Position = UDim2.new(0, 0, 0, 23)
		pageFrame.BackgroundTransparency = 1
		pageFrame.Visible = false
		pageFrame.ClipsDescendants = false
		pageFrame.Parent = menu

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Scroll"
		scroll.Size = UDim2.new(1, 0, 1, 0)
		scroll.Position = UDim2.new(0, 0, 0, 0)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = COLORS.ScrollBar
		scroll.ScrollBarImageTransparency = 0
		scroll.CanvasSize = UDim2.new(0, 0, 0, CANVAS_HEIGHT)
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
		scroll.Active = true
		scroll.Selectable = true
		scroll.ScrollingEnabled = true
		scroll.Parent = pageFrame

		pages[i] = scroll
	end

	-- ============================================================
	-- НАВИГАЦИЯ
	-- ============================================================
	local nav = Instance.new("Frame")
	nav.Size = UDim2.new(1, -10, 0, 18)
	nav.Position = UDim2.new(0, 5, 1, -21)
	nav.BackgroundColor3 = COLORS.Background3
	nav.BorderSizePixel = 0
	nav.Parent = menu
	corner(nav, 4)

	local prev = Instance.new("TextButton")
	prev.Size = UDim2.new(0, 28, 1, 0)
	prev.BackgroundTransparency = 1
	prev.Text = "◀"
	prev.TextColor3 = COLORS.AccentLight
	prev.Font = FONT_BOLD
	prev.TextSize = 10
	prev.AutoButtonColor = false
	prev.Parent = nav

	local next_ = Instance.new("TextButton")
	next_.Size = UDim2.new(0, 28, 1, 0)
	next_.Position = UDim2.new(1, -28, 0, 0)
	next_.BackgroundTransparency = 1
	next_.Text = "▶"
	next_.TextColor3 = COLORS.AccentLight
	next_.Font = FONT_BOLD
	next_.TextSize = 10
	next_.AutoButtonColor = false
	next_.Parent = nav

	local pageLabel = Instance.new("TextLabel")
	pageLabel.Size = UDim2.new(1, -56, 1, 0)
	pageLabel.Position = UDim2.new(0, 28, 0, 0)
	pageLabel.BackgroundTransparency = 1
	pageLabel.TextColor3 = COLORS.Text
	pageLabel.Font = FONT_BOLD
	pageLabel.TextSize = 9
	pageLabel.Parent = nav

	local currentPage = 1
	local function showPage(n)
		if n < 1 then n = pagesCount end
		if n > pagesCount then n = 1 end
		currentPage = n
		for i, scroll in ipairs(pages) do
			scroll.Parent.Visible = (i == n)
			scroll.CanvasPosition = Vector2.new(0, 0)
		end
		pageLabel.Text = pageNames[n] .. "  " .. n .. "/" .. pagesCount
	end

	prev.MouseButton1Click:Connect(function() showPage(currentPage - 1) end)
	next_.MouseButton1Click:Connect(function() showPage(currentPage + 1) end)

	local touchStart = nil
	nav.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			touchStart = input.Position.X
		end
	end)
	nav.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and touchStart then
			local delta = input.Position.X - touchStart
			if delta > 40 then
				showPage(currentPage - 1)
			elseif delta < -40 then
				showPage(currentPage + 1)
			end
			touchStart = nil
		end
	end)

	showPage(1)

	-- ============================================================
	-- ПУБЛИЧНОЕ API
	-- ============================================================
	Hub.Page = function(n) return pages[n] end
	Hub.Elements = Elements
	Hub.Objects.Elements = Elements
	Hub.MenuGui = gui
	Hub.MenuFrame = menu
	Hub.Pages = pages
	Hub.ShowPage = showPage

	-- ============================================================
	-- DRAG & BUTTONS
	-- ============================================================
	makeDraggable(holder, toggleBtn)
	makeDraggable(holder, lockBtn)
	makeDraggable(holder, unloadBtn)
	makeDraggable(menu, menu)

	local open = false
	toggleBtn.MouseButton1Click:Connect(function()
		open = not open
		menu.Visible = open
		if open then
			menu.Position = UDim2.new(
				holder.Position.X.Scale, holder.Position.X.Offset,
				holder.Position.Y.Scale, holder.Position.Y.Offset + 26
			)
		end
	end)

	lockBtn.MouseButton1Click:Connect(function()
		isLocked = not isLocked
		lockBtn.Text = isLocked and "Lckd" or "Lock"
		lockBtn.BackgroundColor3 = isLocked and COLORS.SuccessDark or COLORS.AccentDark
	end)

	-- ============================================================
	-- ЗАГРУЗКА МОДУЛЕЙ
	-- ============================================================
	local function loadModule(path)
		local url = BASE .. path .. "?t=" .. tostring(os.time())
		local ok, result = pcall(function()
			return loadstring(game:HttpGet(url))()
		end)
		if not ok then
			warn("[UI] ❌ " .. path .. ": " .. tostring(result))
			return nil
		end
		return result
	end

	local modules = {
		"features/movement.lua",
		"features/esp.lua",
		"features/misc.lua",
		"features/playerlist.lua",
		"features/save.lua",
	}

	print("[UI] ========== ЗАГРУЗКА МОДУЛЕЙ ==========")

	for _, path in ipairs(modules) do
		local mod = loadModule(path)
		if not mod or type(mod) ~= "table" or not mod.init then
			warn("[UI] ❌ " .. path)
			continue
		end

		local name = path:match("features/(%w+)%.lua")
		Hub.Modules[name] = mod

		local ok, err = pcall(mod.init, Hub)
		if ok then
			print("[UI] ✅ " .. name)
		else
			warn("[UI] ❌ " .. name .. ": " .. tostring(err))
		end
	end

	print("[UI] =========================================")

	-- ============================================================
	-- UNLOAD
	-- ============================================================
	unloadBtn.MouseButton1Click:Connect(function()
		print("[UI] Unloading...")

		if Hub.Modules.save and Hub.Modules.save.cleanup then
			pcall(Hub.Modules.save.cleanup)
		end

		for name, mod in pairs(Hub.Modules) do
			if name ~= "save" and type(mod) == "table" and mod.cleanup then
				pcall(mod.cleanup)
			end
		end

		for _, sw in pairs(Hub.Toggles) do
			pcall(function() sw.set(false) end)
		end

		for _, c in pairs(Hub.Connections) do
			pcall(function() c:Disconnect() end)
		end
		Hub.Connections = {}

		if gui and gui.Parent then gui:Destroy() end
		print("[HUB] Unloaded")
	end)

	print("[UI] Готово")
	return Hub
end

return UI
