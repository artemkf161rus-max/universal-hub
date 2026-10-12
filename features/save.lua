-- ============================================================
-- ============  MODULE: SAVE CONFIG  =========================
-- ============================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local Save = {}

local Config, Toggles, Hub, Elements, page
local connections = {}

local CONFIG_FILE = "universal_hub_config.json"

local saveState = {
	enabled = true,
	loaded = false,
	lastSave = 0,
	saveDelay = 3,
	subscriptions = {},
}

-- ============================================================
-- FS HELPERS
-- ============================================================
local function hasFs()
	return writefile and readfile and isfile
end

local function fileExists(name)
	if isfile then
		local ok, r = pcall(isfile, name)
		return ok and r
	end
	return false
end

-- ============================================================
-- REGISTER
-- ============================================================
function Save.register(key, getter, setter)
	saveState.subscriptions[key] = { get = getter, set = setter }
end

function Save.unregister(key)
	saveState.subscriptions[key] = nil
end

-- ============================================================
-- SAVE
-- ============================================================
local function collectValues()
	local data = {}
	for key, sub in pairs(saveState.subscriptions) do
		if sub and sub.get then
			local ok, value = pcall(sub.get)
			if ok then data[key] = value end
		end
	end
	return data
end

function Save.save()
	if not hasFs() then
		warn("[SAVE] Executor не поддерживает writefile")
		return false
	end

	local data = collectValues()
	data._version = 1
	data._savedAt = os.time()

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then
		warn("[SAVE] Ошибка кодирования")
		return false
	end

	local writeOk = pcall(function()
		writefile(CONFIG_FILE, encoded)
	end)
	if not writeOk then
		warn("[SAVE] Ошибка записи")
		return false
	end

	saveState.lastSave = tick()
	print("[SAVE] Сохранено: " .. CONFIG_FILE .. " (" .. tostring(#encoded) .. " байт)")
	return true
end

-- ============================================================
-- LOAD
-- ============================================================
function Save.load()
	if not hasFs() then
		warn("[SAVE] Executor не поддерживает readfile")
		return false
	end

	if not fileExists(CONFIG_FILE) then
		print("[SAVE] Файл не найден — используется дефолт")
		return false
	end

	local readOk, content = pcall(function()
		return readfile(CONFIG_FILE)
	end)
	if not readOk or not content then
		warn("[SAVE] Ошибка чтения")
		return false
	end

	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not decodeOk or type(data) ~= "table" then
		warn("[SAVE] Ошибка декодирования JSON")
		return false
	end

	local applied, skipped = 0, 0
	for key, sub in pairs(saveState.subscriptions) do
		if sub and sub.set and data[key] ~= nil then
			local ok = pcall(sub.set, data[key])
			if ok then
				applied = applied + 1
			else
				skipped = skipped + 1
			end
		end
	end

	saveState.loaded = true
	print("[SAVE] Загружено: " .. applied .. " / " .. (applied + skipped))
	return true
end

-- ============================================================
-- RESET
-- ============================================================
function Save.reset()
	if hasFs() and fileExists(CONFIG_FILE) then
		pcall(function()
			writefile(CONFIG_FILE, "{}")
		end)
		print("[SAVE] Файл сброшен")
	end
end

-- ============================================================
-- AUTO-SAVE LOOP
-- ============================================================
local function startAutoSave()
	if not hasFs() then return end

	local lastSnapshot = ""

	task.spawn(function()
		while true do
			task.wait(saveState.saveDelay)

			if saveState.enabled and saveState.loaded then
				local data = collectValues()
				local ok, encoded = pcall(function()
					return HttpService:JSONEncode(data)
				end)

				if ok and encoded ~= lastSnapshot then
					lastSnapshot = encoded
					Save.save()
				end
			end
		end
	end)
end

-- ============================================================
-- UI (page 4 — под playerlist)
-- ============================================================
local function buildUI()
	page = Hub.Page(4)
	if not page then
		warn("[save] page 4 не найдена")
		return
	end

	-- разделитель
	local divider = Instance.new("Frame")
	divider.Name = "SaveDivider"
	divider.Size = UDim2.new(1, -16, 0, 1)
	divider.Position = UDim2.new(0, 8, 0, 195)
	divider.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
	divider.BorderSizePixel = 0
	divider.Parent = page

	local statusText = hasFs() and "Ready" or "NO FS"
	local statusColor = hasFs() and Color3.fromRGB(100, 255, 100)
		or Color3.fromRGB(255, 100, 100)

	-- заголовок
	Elements.label(page, "═══ SAVE CONFIG ═══", 202,
		{ color = Color3.fromRGB(255, 200, 0), size = 10,
		  font = Enum.Font.GothamBold })

	-- статус
	local statusLabel = Elements.label(page, "Status: " .. statusText, 218,
		{ color = statusColor, size = 9,
		  font = Enum.Font.GothamBold })

	-- Auto Save
	Elements.label(page, "Auto Save", 236)
	Hub.Toggles.autoSave = Elements.switch(page, 234, function(on)
		saveState.enabled = on
		print("[SAVE] Auto-save " .. (on and "ON" or "OFF"))
	end)

	-- Кнопки
	local btnHolder = Instance.new("Frame")
	btnHolder.Size = UDim2.new(1, -16, 0, 22)
	btnHolder.Position = UDim2.new(0, 8, 0, 254)
	btnHolder.BackgroundTransparency = 1
	btnHolder.Parent = page

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.Padding = UDim.new(0, 4)
	btnLayout.Parent = btnHolder

	-- SAVE
	local saveBtn = Elements.button(btnHolder, "Save", 1,
		Color3.fromRGB(0, 130, 0), 60)
	saveBtn.Size = UDim2.new(0, 60, 0, 22)
	saveBtn.TextSize = 10
	saveBtn.MouseButton1Click:Connect(function()
		if Save.save() then
			statusLabel.Text = "Status: Saved ✓"
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			task.delay(2, function()
				statusLabel.Text = "Status: " .. statusText
				statusLabel.TextColor3 = statusColor
			end)
		else
			statusLabel.Text = "Status: FAILED"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end)

	-- LOAD
	local loadBtn = Elements.button(btnHolder, "Load", 2,
		Color3.fromRGB(0, 100, 180), 60)
	loadBtn.Size = UDim2.new(0, 60, 0, 22)
	loadBtn.TextSize = 10
	loadBtn.MouseButton1Click:Connect(function()
		if Save.load() then
			statusLabel.Text = "Status: Loaded ✓"
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			task.delay(2, function()
				statusLabel.Text = "Status: " .. statusText
				statusLabel.TextColor3 = statusColor
			end)
		else
			statusLabel.Text = "Status: No file"
			statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		end
	end)

	-- RESET
	local resetBtn = Elements.button(btnHolder, "Reset", 3,
		Color3.fromRGB(150, 0, 0), 60)
	resetBtn.Size = UDim2.new(0, 60, 0, 22)
	resetBtn.TextSize = 10
	resetBtn.MouseButton1Click:Connect(function()
		Save.reset()
		statusLabel.Text = "Status: Reset (restart)"
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	end)

	-- файл
	Elements.label(page, "File: " .. CONFIG_FILE, 280,
		{ color = Color3.fromRGB(120, 120, 140), size = 8,
		  font = Enum.Font.Gotham })
end

-- ============================================================
-- INIT
-- ============================================================
function Save.init(hub)
	Hub = hub
	Config = hub.Config
	Toggles = hub.Toggles
	Elements = hub.Elements or (hub.Objects and hub.Objects.Elements)

	if not Elements then
		warn("[save] Elements не найдены")
		return
	end

	buildUI()
	Hub.Modules.save = Save

	task.defer(function()
		task.wait(3)  -- ждём загрузки всех модулей

		-- регистрация тумблеров
		local function reg(key, toggleObj)
			if toggleObj and toggleObj.get and toggleObj.set then
				Save.register(key, toggleObj.get, toggleObj.set)
			end
		end

		reg("movement.speed",   Hub.Toggles.speed)
		reg("movement.noclip",  Hub.Toggles.noclip)
		reg("movement.fly",     Hub.Toggles.fly)
		reg("movement.jump",    Hub.Toggles.jump)
		reg("movement.gravity", Hub.Toggles.gravity)

		reg("esp.enabled",     Hub.Toggles.esp)
		reg("esp.name",        Hub.Toggles.espName)
		reg("esp.distance",    Hub.Toggles.espDist)
		reg("esp.health",      Hub.Toggles.espHP)

		reg("misc.antiAfk",    Hub.Toggles.antiAfk)
		reg("misc.chatSpam",   Hub.Toggles.chatSpam)
		reg("misc.fpsBoost",   Hub.Toggles.fpsBoost)

		local count = 0
		for _ in pairs(saveState.subscriptions) do count = count + 1 end
		print("[SAVE] Зарегистрировано: " .. count .. " настроек")

		task.wait(0.5)
		Save.load()
		startAutoSave()
	end)

	function Save.cleanup()
		if saveState.enabled then
			pcall(Save.save)
		end
		saveState.enabled = false
		saveState.subscriptions = {}
		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		connections = {}
	end

	print("[SAVE] Модуль инициализирован")
	return Save
end

return Save
