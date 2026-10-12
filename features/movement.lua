-- ============================================================
-- ============  MODULE: MOVEMENT  ============================
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local Movement = {}

local Config, Toggles, Hub, Elements, page
local connections = {}

-- состояние
local speedState   = { enabled = false, value = 16, bv = nil, loop = nil }
local noclipState  = { enabled = false, loop = nil }
local flyState     = { enabled = false, speed = 50, bv = nil, loop = nil, gyro = nil }
local jumpState    = { enabled = false, value = 50 }
local gravityState = { enabled = false, value = 196 }

local function track(c)
	table.insert(connections, c)
	return c
end

local function getChar()
	return player.Character
end

-- ============================================================
-- SPEED
-- ============================================================
local function cleanupSpeed()
	if speedState.loop then speedState.loop:Disconnect() speedState.loop = nil end
	if speedState.bv and speedState.bv.Parent then speedState.bv:Destroy() end
	speedState.bv = nil
	local char = getChar()
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 16 end
	end
end

local function applySpeed()
	local char = getChar()
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	hum.WalkSpeed = 16

	if not speedState.bv or not speedState.bv.Parent then
		speedState.bv = Instance.new("BodyVelocity")
		speedState.bv.MaxForce = Vector3.new(1e5, 0, 1e5)
		speedState.bv.P = 1e5
		speedState.bv.Parent = root
	end

	if not speedState.loop then
		speedState.loop = RunService.Heartbeat:Connect(function()
			if not speedState.enabled then return end
			local c = getChar()
			if not c then return end
			local h = c:FindFirstChildOfClass("Humanoid")
			if not h or not speedState.bv or not speedState.bv.Parent then return end
			local md = h.MoveDirection
			if md.Magnitude > 0 then
				speedState.bv.Velocity = md * speedState.value
			else
				speedState.bv.Velocity = Vector3.zero
			end
		end)
		track(speedState.loop)
	end
end

-- ============================================================
-- NOCLIP
-- ============================================================
local function startNoclip()
	if noclipState.loop then return end
	noclipState.loop = RunService.Stepped:Connect(function()
		if not noclipState.enabled then return end
		local char = getChar()
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end)
	track(noclipState.loop)
end

local function stopNoclip()
	if noclipState.loop then
		noclipState.loop:Disconnect()
		noclipState.loop = nil
	end
end

-- ============================================================
-- FLY
-- ============================================================
local function cleanupFly()
	if flyState.loop then flyState.loop:Disconnect() flyState.loop = nil end
	if flyState.bv and flyState.bv.Parent then flyState.bv:Destroy() end
	flyState.bv = nil
end

local function applyFly()
	local char = getChar()
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if not flyState.bv or not flyState.bv.Parent then
		flyState.bv = Instance.new("BodyVelocity")
		flyState.bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flyState.bv.P = 1e5
		flyState.bv.Parent = root
	end

	if not flyState.loop then
		flyState.loop = RunService.RenderStepped:Connect(function()
			if not flyState.enabled then return end
			local c = getChar()
			if not c then return end
			local r = c:FindFirstChild("HumanoidRootPart")
			local h = c:FindFirstChildOfClass("Humanoid")
			if not r or not h or not flyState.bv or not flyState.bv.Parent then return end

			local cam = workspace.CurrentCamera
			local md = h.MoveDirection

			if md.Magnitude > 0 then
				local lookFlat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
				local flatFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + lookFlat)
				local velocity = (cam.CFrame * CFrame.new(flatFrame:VectorToObjectSpace(md))).Position - cam.CFrame.Position
				if velocity.Magnitude > 0 then velocity = velocity.Unit end
				flyState.bv.Velocity = velocity * flyState.speed
			else
				flyState.bv.Velocity = Vector3.zero
			end
		end)
		track(flyState.loop)
	end
end

-- ============================================================
-- JUMP
-- ============================================================
local function applyJump()
	local char = getChar()
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.UseJumpPower = true
	hum.JumpPower = jumpState.value
end

-- ============================================================
-- GRAVITY
-- ============================================================
local function applyGravity()
	workspace.Gravity = gravityState.value
end

-- ============================================================
-- UI (page 1)
-- ============================================================
local function buildUI()
	page = Hub.Page(1)
	if not page then
		warn("[movement] page 1 не найдена")
		return
	end

	-- ============ SPEED ============
	Elements.label(page, "SPEED (16-500)", 2)
	local speedVal = Elements.label(page, "Value: 16", 18,
		{ color = Color3.fromRGB(255, 255, 255), size = 10 })

	Elements.slider(page, 34, Config.MIN_SPEED, Config.MAX_SPEED,
		Config.DEFAULT_SPEED, function(v)
			speedState.value = math.floor(v)
			speedVal.Text = "Value: " .. speedState.value
		end)

	Elements.label(page, "Enable Speed", 52)
	Hub.Toggles.speed = Elements.switch(page, 50, function(on)
		speedState.enabled = on
		if on then applySpeed() else cleanupSpeed() end
	end)

	-- ============ NOCLIP ============
	Elements.label(page, "Noclip", 72)
	Hub.Toggles.noclip = Elements.switch(page, 70, function(on)
		noclipState.enabled = on
		if on then startNoclip() else stopNoclip() end
	end)

	-- ============ FLY ============
	Elements.label(page, "FLY SPEED (10-500)", 92)
	local flyVal = Elements.label(page, "Value: 50", 108,
		{ color = Color3.fromRGB(255, 255, 255), size = 10 })

	Elements.slider(page, 124, Config.FLY_SPEED_MIN, Config.FLY_SPEED_MAX,
		Config.FLY_SPEED_DEFAULT, function(v)
			flyState.speed = math.floor(v)
			flyVal.Text = "Value: " .. flyState.speed
		end)

	Elements.label(page, "Fly [RightShift]", 142)
	Hub.Toggles.fly = Elements.switch(page, 140, function(on)
		flyState.enabled = on
		if on then applyFly() else cleanupFly() end
	end)

	-- ============ JUMP ============
	Elements.label(page, "JUMP POWER (50-500)", 162)
	local jumpVal = Elements.label(page, "Value: 50", 178,
		{ color = Color3.fromRGB(255, 255, 255), size = 10 })

	Elements.slider(page, 194, Config.JUMP_MIN, Config.JUMP_MAX,
		Config.JUMP_DEFAULT, function(v)
			jumpState.value = math.floor(v)
			jumpVal.Text = "Value: " .. jumpState.value
			if jumpState.enabled then applyJump() end
		end)

	Elements.label(page, "Jump Boost", 212)
	Hub.Toggles.jump = Elements.switch(page, 210, function(on)
		jumpState.enabled = on
		if on then applyJump() end
	end)

	-- ============ GRAVITY ============
	Elements.label(page, "GRAVITY (0-196)", 232)
	local gravVal = Elements.label(page, "Value: 196", 248,
		{ color = Color3.fromRGB(255, 255, 255), size = 10 })

	Elements.slider(page, 264, Config.GRAVITY_MIN, Config.GRAVITY_MAX,
		Config.GRAVITY_DEFAULT, function(v)
			gravityState.value = math.floor(v)
			gravVal.Text = "Value: " .. gravityState.value
			if gravityState.enabled then applyGravity() end
		end)

	Elements.label(page, "Low Gravity", 282)
	Hub.Toggles.gravity = Elements.switch(page, 280, function(on)
		gravityState.enabled = on
		if on then applyGravity() else workspace.Gravity = 196 end
	end)
end

-- ============================================================
-- INIT
-- ============================================================
function Movement.init(hub)
	Hub = hub
	Config = hub.Config
	Toggles = hub.Toggles
	Elements = hub.Elements or (hub.Objects and hub.Objects.Elements)

	if not Elements then
		warn("[movement] Elements не найдены")
		return
	end

	buildUI()

	-- keybind для Fly (RightShift)
	track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			if Hub.Toggles.fly then
				local state = Hub.Toggles.fly.get()
				Hub.Toggles.fly.set(not state)
			end
		end
	end))

	-- respawn — переприменить
	track(player.CharacterAdded:Connect(function()
		task.wait(1)
		if speedState.enabled then cleanupSpeed() applySpeed() end
		if flyState.enabled then cleanupFly() applyFly() end
		if jumpState.enabled then applyJump() end
		if gravityState.enabled then applyGravity() end
	end))

	function Movement.cleanup()
		speedState.enabled = false
		noclipState.enabled = false
		flyState.enabled = false
		jumpState.enabled = false
		gravityState.enabled = false

		cleanupSpeed()
		stopNoclip()
		cleanupFly()

		workspace.Gravity = 196

		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		connections = {}
	end

	print("[MOVEMENT] Модуль инициализирован")
	return Movement
end

return Movement
