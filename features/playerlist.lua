-- ============================================================
-- ============  MODULE: PLAYER LIST  =========================
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local PlayerList = {}

local Config, Toggles, Hub, Elements, page
local connections = {}

local entries = {}  -- [Player] = {frame, nameLabel, distLabel, tpBtn}

local function track(c)
	table.insert(connections, c)
	return c
end

local function getPos(p)
	local char = p.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

-- ============================================================
-- TELEPORT
-- ============================================================
local function teleportTo(targetPlayer)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local targetChar = targetPlayer.Character
	if not targetChar then return end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end

	-- телепорт на 3 студа впереди цели
	root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
	print("[TP] Телепорт к " .. targetPlayer.Name)
end

-- ============================================================
-- REFRESH LIST
-- ============================================================
local function refreshList()
	if not page then return end

	-- очищаем старые entries (кроме заголовка)
	for _, entry in pairs(entries) do
		if entry.frame and entry.frame.Parent then
			entry.frame:Destroy()
		end
	end
	entries = {}

	local y = 24  -- отступ от заголовка

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local frame = Instance.new("Frame")
			frame.Name = p.Name
			frame.Size = UDim2.new(1, -16, 0, 24)
			frame.Position = UDim2.new(0, 8, 0, y)
			frame.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
			frame.BorderSizePixel = 0
			frame.Parent = page

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 4)
			c.Parent = frame

			-- имя
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -75, 1, 0)
			nameLabel.Position = UDim2.new(0, 6, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = p.Name
			nameLabel.TextColor3 = Color3.fromRGB(230, 220, 255)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 10
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			nameLabel.Parent = frame

			-- дистанция
			local distLabel = Instance.new("TextLabel")
			distLabel.Size = UDim2.new(0, 30, 1, 0)
			distLabel.Position = UDim2.new(1, -70, 0, 0)
			distLabel.BackgroundTransparency = 1
			distLabel.Text = "[--]"
			distLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			distLabel.Font = Enum.Font.GothamBold
			distLabel.TextSize = 9
			distLabel.TextXAlignment = Enum.TextXAlignment.Right
			distLabel.Parent = frame

			-- кнопка TP
			local tpBtn = Instance.new("TextButton")
			tpBtn.Size = UDim2.new(0, 34, 1, -6)
			tpBtn.Position = UDim2.new(1, -38, 0, 3)
			tpBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 0)
			tpBtn.BorderSizePixel = 0
			tpBtn.Text = "TP"
			tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tpBtn.Font = Enum.Font.GothamBold
			tpBtn.TextSize = 10
			tpBtn.AutoButtonColor = false
			tpBtn.Parent = frame

			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 3)
			bc.Parent = tpBtn

			tpBtn.MouseButton1Click:Connect(function()
				teleportTo(p)
			end)

			entries[p] = {
				frame = frame,
				nameLabel = nameLabel,
				distLabel = distLabel,
			}

			y = y + 28
		end
	end
end

-- ============================================================
-- UPDATE DISTANCES
-- ============================================================
local function updateDistances()
	local myPos = getPos(player)
	if not myPos then return end

	for p, entry in pairs(entries) do
		local pos = getPos(p)
		if entry.distLabel then
			if pos then
				local dist = math.floor((pos - myPos).Magnitude)
				entry.distLabel.Text = "[" .. dist .. "]"
			else
				entry.distLabel.Text = "[dead]"
			end
		end
	end
end

-- ============================================================
-- UI (page 4)
-- ============================================================
local function buildUI()
	page = Hub.Page(4)
	if not page then
		warn("[playerlist] page 4 не найдена")
		return
	end

	-- заголовок
	Elements.label(page, "PLAYER LIST", 2,
		{ color = Color3.fromRGB(200, 150, 255), size = 12,
		  font = Enum.Font.GothamBold })

	-- кнопка Refresh
	local refreshBtn = Elements.button(page, "Refresh", 1,
		Color3.fromRGB(80, 30, 160), 70)
	refreshBtn.Position = UDim2.new(1, -78, 0, 2)
	refreshBtn.Size = UDim2.new(0, 70, 0, 16)
	refreshBtn.TextSize = 9
	refreshBtn.MouseButton1Click:Connect(function()
		refreshList()
		print("[PLAYERLIST] Обновлён")
	end)

	-- счётчик
	local countLabel = Elements.label(page, "Online: 0", 18,
		{ color = Color3.fromRGB(150, 150, 180), size = 9,
		  font = Enum.Font.Gotham })

	local function updateCount()
		local n = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then n = n + 1 end
		end
		countLabel.Text = "Online: " .. n
	end
	updateCount()

	-- список
	refreshList()

	-- авто-обновление
	track(Players.PlayerAdded:Connect(function()
		task.wait(0.5)
		refreshList()
		updateCount()
	end))
	track(Players.PlayerRemoving:Connect(function()
		task.wait(0.5)
		refreshList()
		updateCount()
	end))

	-- обновление дистанций
	track(RunService.Heartbeat:Connect(updateDistances))
end

-- ============================================================
-- INIT
-- ============================================================
function PlayerList.init(hub)
	Hub = hub
	Config = hub.Config
	Toggles = hub.Toggles
	Elements = hub.Elements or (hub.Objects and hub.Objects.Elements)

	if not Elements then
		warn("[playerlist] Elements не найдены")
		return
	end

	buildUI()

	function PlayerList.cleanup()
		for _, entry in pairs(entries) do
			if entry.frame and entry.frame.Parent then
				entry.frame:Destroy()
			end
		end
		entries = {}
		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		connections = {}
	end

	print("[PLAYERLIST] Модуль инициализирован")
	return PlayerList
end

return PlayerList
