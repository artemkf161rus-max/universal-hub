-- ============================================================
-- ============  MODULE: ESP  =================================
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local ESP = {}

local Config, Toggles, Hub, Elements, page
local connections = {}

local espObjects = {}  -- [Player] = {highlight, billboard, nameLabel, distLabel}

local espState = {
	enabled = false,
	showName = true,
	showDistance = true,
	showHealth = false,
	maxDist = 500,
	color = Color3.fromRGB(255, 0, 0),
}

local function track(c)
	table.insert(connections, c)
	return c
end

local function getMyPos()
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

-- ============================================================
-- CREATE / REMOVE
-- ============================================================
local function createESP(targetPlayer)
	if targetPlayer == player or espObjects[targetPlayer] then return end
	local char = targetPlayer.Character
	if not char then return end

	-- Highlight
	local hl = Instance.new("Highlight")
	hl.Name = "ESP_HL"
	hl.FillColor = espState.color
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = char
	hl.Parent = char

	-- Billboard (имя + дистанция)
	local bb = Instance.new("BillboardGui")
	bb.Name = "ESP_BB"
	bb.Size = UDim2.new(0, 200, 0, 44)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
	bb.Parent = char

	-- Имя
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = targetPlayer.Name
	nameLabel.TextColor3 = espState.color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = bb

	-- Дистанция
	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0, 16)
	distLabel.Position = UDim2.new(0, 0, 0, 20)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "[0]"
	distLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
	distLabel.TextStrokeTransparency = 0
	distLabel.Font = Enum.Font.GothamBold
	distLabel.TextSize = 12
	distLabel.Parent = bb

	-- Health
	local healthLabel = Instance.new("TextLabel")
	healthLabel.Size = UDim2.new(1, 0, 0, 14)
	healthLabel.Position = UDim2.new(0, 0, 0, 30)
	healthLabel.BackgroundTransparency = 1
	healthLabel.Text = "HP: 100"
	healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	healthLabel.TextStrokeTransparency = 0
	healthLabel.Font = Enum.Font.GothamBold
	healthLabel.TextSize = 10
	healthLabel.Parent = bb

	espObjects[targetPlayer] = {
		highlight = hl,
		billboard = bb,
		nameLabel = nameLabel,
		distLabel = distLabel,
		healthLabel = healthLabel,
	}
end

local function removeESP(targetPlayer)
	local d = espObjects[targetPlayer]
	if d then
		if d.highlight then d.highlight:Destroy() end
		if d.billboard then d.billboard:Destroy() end
		espObjects[targetPlayer] = nil
	end
end

local function clearAll()
	for p in pairs(espObjects) do removeESP(p) end
end

-- ============================================================
-- UPDATE LOOP
-- ============================================================
local function updateLoop()
	if not espState.enabled then return end
	local myPos = getMyPos()

	for tp, data in pairs(espObjects) do
		local char = tp.Character
		if char and data.highlight then
			local hp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			local charPos = hp and hp.Position

			local inRange = true
			if myPos and charPos then
				inRange = (charPos - myPos).Magnitude <= espState.maxDist
			end

			-- Highlight
			data.highlight.Enabled = inRange
			data.highlight.FillColor = espState.color
			data.highlight.Adornee = char

			-- Billboard
			if data.billboard then
				data.billboard.Enabled = inRange
				data.billboard.Adornee = char:FindFirstChild("Head")
					or char:FindFirstChildWhichIsA("BasePart")
			end

			-- Имя
			if data.nameLabel then
				data.nameLabel.Visible = espState.showName and inRange
				data.nameLabel.TextColor3 = espState.color
			end

			-- Дистанция
			if data.distLabel then
				data.distLabel.Visible = espState.showDistance and inRange
				if myPos and charPos then
					data.distLabel.Text = "[" .. math.floor((charPos - myPos).Magnitude) .. "]"
				end
			end

			-- Health
			if data.healthLabel then
				data.healthLabel.Visible = espState.showHealth and inRange
				if hum then
					local hpPercent = math.floor((hum.Health / hum.MaxHealth) * 100)
					data.healthLabel.Text = "HP: " .. hpPercent
					if hpPercent > 60 then
						data.healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					elseif hpPercent > 30 then
						data.healthLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
					else
						data.healthLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
					end
				end
			end
		end
	end
end

-- ============================================================
-- UI (page 2)
-- ============================================================
local function buildUI()
	page = Hub.Page(2)
	if not page then
		warn("[esp] page 2 не найдена")
		return
	end

	-- ============ COLOR PICKER ============
	local colorLabel = Elements.label(page,
		"ESP Color", 2,
		{ color = Color3.fromRGB(255, 255, 255), size = 10 })

	-- RGB preview box
	local previewBox = Instance.new("Frame")
	previewBox.Size = UDim2.new(0, 30, 0, 18)
	previewBox.Position = UDim2.new(1, -40, 0, 0)
	previewBox.BackgroundColor3 = espState.color
	previewBox.BorderSizePixel = 0
	previewBox.Parent = page

	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 4)
	pc.Parent = previewBox

	local ps = Instance.new("UIStroke")
	ps.Color = Color3.fromRGB(255, 255, 255)
	ps.Thickness = 1
	ps.Parent = previewBox

	-- R
	Elements.label(page, "R (0-255)", 24)
	Elements.slider(page, 40, 0, 255, 255, function(v)
		espState.color = Color3.fromRGB(
			math.floor(v),
			math.floor(espState.color.G * 255),
			math.floor(espState.color.B * 255)
		)
		previewBox.BackgroundColor3 = espState.color
		colorLabel.TextColor3 = espState.color
	end)

	-- G
	Elements.label(page, "G (0-255)", 58)
	Elements.slider(page, 74, 0, 255, 0, function(v)
		espState.color = Color3.fromRGB(
			math.floor(espState.color.R * 255),
			math.floor(v),
			math.floor(espState.color.B * 255)
		)
		previewBox.BackgroundColor3 = espState.color
		colorLabel.TextColor3 = espState.color
	end)

	-- B
	Elements.label(page, "B (0-255)", 92)
	Elements.slider(page, 108, 0, 255, 0, function(v)
		espState.color = Color3.fromRGB(
			math.floor(espState.color.R * 255),
			math.floor(espState.color.G * 255),
			math.floor(v)
		)
		previewBox.BackgroundColor3 = espState.color
		colorLabel.TextColor3 = espState.color
	end)

	-- ============ DISTANCE ============
	Elements.label(page, "MAX DISTANCE (50-2000)", 130)
	local distVal = Elements.label(page, "Value: 500", 146,
		{ color = Color3.fromRGB(255, 255, 255), size = 10 })

	Elements.slider(page, 162, 50, 2000, 500, function(v)
		espState.maxDist = math.floor(v)
		distVal.Text = "Value: " .. espState.maxDist
	end)

	-- ============ SETTINGS ============
	Elements.label(page, "Show Name", 182)
	Hub.Toggles.espName = Elements.switch(page, 180, function(on)
		espState.showName = on
	end)

	Elements.label(page, "Show Distance", 200)
	Hub.Toggles.espDist = Elements.switch(page, 198, function(on)
		espState.showDistance = on
	end)

	Elements.label(page, "Show Health", 218)
	Hub.Toggles.espHP = Elements.switch(page, 216, function(on)
		espState.showHealth = on
	end)

	-- ============ MAIN ENABLE ============
	Elements.label(page, "ESP ENABLED", 240,
		{ color = Color3.fromRGB(150, 255, 150), size = 11 })

	Hub.Toggles.esp = Elements.switch(page, 238, function(on)
		espState.enabled = on
		if on then
			for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
		else
			clearAll()
		end
	end)
end

-- ============================================================
-- INIT
-- ============================================================
function ESP.init(hub)
	Hub = hub
	Config = hub.Config
	Toggles = hub.Toggles
	Elements = hub.Elements or (hub.Objects and hub.Objects.Elements)

	if not Elements then
		warn("[esp] Elements не найдены")
		return
	end

	buildUI()

	-- следим за игроками
	for _, p in ipairs(Players:GetPlayers()) do
		track(p.CharacterAdded:Connect(function()
			if espState.enabled then
				task.wait(0.5)
				removeESP(p)
				createESP(p)
			end
		end))
	end

	track(Players.PlayerAdded:Connect(function(p)
		track(p.CharacterAdded:Connect(function()
			if espState.enabled then
				task.wait(0.5)
				createESP(p)
			end
		end))
	end))

	track(Players.PlayerRemoving:Connect(removeESP))

	-- update loop
	track(RunService.RenderStepped:Connect(updateLoop))

	function ESP.cleanup()
		espState.enabled = false
		clearAll()
		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		connections = {}
	end

	print("[ESP] Модуль инициализирован")
	return ESP
end

return ESP
