-- ============================================================
-- ============  MODULE: MISC  ================================
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local Misc = {}

local Config, Toggles, Hub, Elements, page
local connections = {}

local miscState = {
	antiAfk = false,
	chatSpam = false,
	chatMessage = "Hello!",
	chatDelay = 1,
	fpsBoost = false,
}

local function track(c)
	table.insert(connections, c)
	return c
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
local function setupAntiAfk()
	track(player.Idled:Connect(function()
		if not miscState.antiAfk then return end
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
		print("[MISC] Anti-AFK сработал")
	end))
end

-- ============================================================
-- CHAT SPAM
-- ============================================================
local function startChatSpam()
	task.spawn(function()
		while miscState.chatSpam do
			local sendChat = nil

			-- пробуем найти чат-эвент
			local ReplicatedStorageEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemEvents")
			if ReplicatedStorageEvents then
				sendChat = ReplicatedStorageEvents:FindFirstChild("SayMessageRequest")
			end

			-- новый чат
			if not sendChat then
				local TextChatService = game:GetService("TextChatService")
				local channels = TextChatService:FindFirstChild("TextChannels")
				if channels then
					local general = channels:FindFirstChild("RBXGeneral")
					if general then
						pcall(function()
							general:SendAsync(miscState.chatMessage)
						end)
					end
				end
			else
				pcall(function()
					sendChat:FireServer(miscState.chatMessage, "All")
				end)
			end

			task.wait(miscState.chatDelay)
		end
	end)
end

-- ============================================================
-- FPS BOOST
-- ============================================================
local savedLighting = {}

local function applyFpsBoost()
	if not savedLighting.saved then
		savedLighting.Ambient = Lighting.Ambient
		savedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
		savedLighting.Brightness = Lighting.Brightness
		savedLighting.ClockTime = Lighting.ClockTime
		savedLighting.GlobalShadows = Lighting.GlobalShadows
		savedLighting.FogEnd = Lighting.FogEnd
		savedLighting.saved = true
	end

	Lighting.Ambient = Color3.fromRGB(178, 178, 178)
	Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	Lighting.Brightness = 3
	Lighting.ClockTime = 12
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 100000

	-- убираем партиклы и звуки (для FPS)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter")
			or obj:IsA("Smoke")
			or obj:IsA("Fire")
			or obj:IsA("Sparkles") then
			obj.Enabled = false
		end
	end

	print("[MISC] FPS Boost применён")
end

local function restoreFpsBoost()
	if savedLighting.saved then
		Lighting.Ambient = savedLighting.Ambient
		Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
		Lighting.Brightness = savedLighting.Brightness
		Lighting.ClockTime = savedLighting.ClockTime
		Lighting.GlobalShadows = savedLighting.GlobalShadows
		Lighting.FogEnd = savedLighting.FogEnd
		savedLighting = {}
	end
end

-- ============================================================
-- RESET CHARACTER
-- ============================================================
local function resetCharacter()
	local char = player.Character
	if not char then return end

	-- безопасный способ
	pcall(function()
		char:BreakJoints()
	end)

	-- резервный
	pcall(function()
		player.Character:FindFirstChildOfClass("Humanoid").Health = 0
	end)

	print("[MISC] Character reset")
end

-- ============================================================
-- REJOIN
-- ============================================================
local function rejoinServer()
	local TeleportService = game:GetService("TeleportService")
	pcall(function()
		TeleportService:TeleportToPlaceInstance(
			game.PlaceId,
			game.JobId,
			player
		)
	end)
end

-- ============================================================
-- SERVER HOP
-- ============================================================
local function serverHop()
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")

	local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

	local ok, response = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(url))
	end)

	if not ok or not response then
		warn("[MISC] Не удалось получить список серверов")
		return
	end

	for _, server in ipairs(response.data) do
		if server.playing < server.maxPlayers and server.id ~= game.JobId then
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
			end)
			print("[MISC] Server Hop → " .. server.id)
			return
		end
	end

	warn("[MISC] Свободных серверов не найдено")
end

-- ============================================================
-- UI (page 3)
-- ============================================================
local function buildUI()
	page = Hub.Page(3)
	if not page then
		warn("[misc] page 3 не найдена")
		return
	end

	-- ============ ANTI-AFK ============
	Elements.label(page, "Anti-AFK", 2)
	Hub.Toggles.antiAfk = Elements.switch(page, 0, function(on)
		miscState.antiAfk = on
		print("[MISC] Anti-AFK " .. (on and "ON" or "OFF"))
	end)

	-- ============ CHAT SPAM ============
	Elements.label(page, "Chat Spam", 22)
	Hub.Toggles.chatSpam = Elements.switch(page, 20, function(on)
		miscState.chatSpam = on
		if on then startChatSpam() end
	end)

	-- Сообщение
	Elements.label(page, "Message: " .. miscState.chatMessage, 42,
		{ color = Color3.fromRGB(200, 200, 200), size = 9,
		  font = Enum.Font.Gotham })

	-- Быстрые варианты
	local msgHolder = Instance.new("Frame")
	msgHolder.Size = UDim2.new(1, -16, 0, 20)
	msgHolder.Position = UDim2.new(0, 8, 0, 58)
	msgHolder.BackgroundTransparency = 1
	msgHolder.Parent = page

	local msgLayout = Instance.new("UIListLayout")
	msgLayout.FillDirection = Enum.FillDirection.Horizontal
	msgLayout.Padding = UDim.new(0, 4)
	msgLayout.Parent = msgHolder

	local msgInput = Instance.new("TextBox")
	msgInput.Size = UDim2.new(1, -70, 1, 0)
	msgInput.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
	msgInput.BorderSizePixel = 0
	msgInput.Text = miscState.chatMessage
	msgInput.PlaceholderText = "Введи сообщение"
	msgInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	msgInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
	msgInput.Font = Enum.Font.Gotham
	msgInput.TextSize = 10
	msgInput.ClearTextOnFocus = false
	msgInput.Parent = msgHolder

	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(0, 4)
	mc.Parent = msgInput

	msgInput.FocusLost:Connect(function()
		miscState.chatMessage = msgInput.Text
		print("[MISC] Сообщение: " .. miscState.chatMessage)
	end)

	local applyBtn = Elements.button(msgHolder, "OK", 1,
		Color3.fromRGB(80, 30, 160), 40)
	applyBtn.Size = UDim2.new(0, 40, 1, 0)
	applyBtn.TextSize = 10
	applyBtn.MouseButton1Click:Connect(function()
		miscState.chatMessage = msgInput.Text
		print("[MISC] Сообщение: " .. miscState.chatMessage)
	end)

	-- ============ FPS BOOST ============
	Elements.label(page, "FPS Boost", 90)
	Hub.Toggles.fpsBoost = Elements.switch(page, 88, function(on)
		miscState.fpsBoost = on
		if on then applyFpsBoost() else restoreFpsBoost() end
	end)

	Elements.label(page, "Убирает партиклы и тени", 110,
		{ color = Color3.fromRGB(150, 150, 150), size = 9,
		  font = Enum.Font.Gotham })

	-- ============ ACTIONS ============
	Elements.label(page, "═══ ACTIONS ═══", 132,
		{ color = Color3.fromRGB(255, 200, 0), size = 10,
		  font = Enum.Font.GothamBold })

	-- Reset Character
	local resetBtn = Elements.button(page, "Reset Character", 1,
		Color3.fromRGB(150, 30, 30), 130)
	resetBtn.Position = UDim2.new(0, 8, 0, 152)
	resetBtn.Size = UDim2.new(1, -16, 0, 24)
	resetBtn.TextSize = 11
	resetBtn.MouseButton1Click:Connect(function()
		resetCharacter()
	end)

	-- Rejoin
	local rejoinBtn = Elements.button(page, "Rejoin Server", 2,
		Color3.fromRGB(30, 100, 200), 130)
	rejoinBtn.Position = UDim2.new(0, 8, 0, 180)
	rejoinBtn.Size = UDim2.new(1, -16, 0, 24)
	rejoinBtn.TextSize = 11
	rejoinBtn.MouseButton1Click:Connect(function()
		rejoinServer()
	end)

	-- Server Hop
	local hopBtn = Elements.button(page, "Server Hop", 3,
		Color3.fromRGB(150, 80, 200), 130)
	hopBtn.Position = UDim2.new(0, 8, 0, 208)
	hopBtn.Size = UDim2.new(1, -16, 0, 24)
	hopBtn.TextSize = 11
	hopBtn.MouseButton1Click:Connect(function()
		serverHop()
	end)

	-- ============ INFO ============
	Elements.label(page, "JobId: " .. string.sub(game.JobId, 1, 8) .. "...", 240,
		{ color = Color3.fromRGB(150, 150, 150), size = 9,
		  font = Enum.Font.Gotham })
end

-- ============================================================
-- INIT
-- ============================================================
function Misc.init(hub)
	Hub = hub
	Config = hub.Config
	Toggles = hub.Toggles
	Elements = hub.Elements or (hub.Objects and hub.Objects.Elements)

	if not Elements then
		warn("[misc] Elements не найдены")
		return
	end

	buildUI()
	setupAntiAfk()

	function Misc.cleanup()
		miscState.antiAfk = false
		miscState.chatSpam = false
		miscState.fpsBoost = false

		restoreFpsBoost()

		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		connections = {}
	end

	print("[MISC] Модуль инициализирован")
	return Misc
end

return Misc
