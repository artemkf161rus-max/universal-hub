-- ============================================================
-- ============  UNIVERSAL HUB — MAIN  ========================
-- ============================================================
local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Правильный BASE — БЕЗ двойного universal-hub
local BASE = "https://raw.githubusercontent.com/artemkf161rus-max/universal-hub/refs/heads/main/"

-- ============================================================
-- ============  PRE-CLEANUP  =================================
-- ============================================================
do
	print("[MAIN] ========== PRE-CLEANUP ==========")

	local oldHub = getgenv().Hub
	if oldHub then
		if oldHub.Modules then
			for name, mod in pairs(oldHub.Modules) do
				if type(mod) == "table" and mod.cleanup then
					local ok = pcall(mod.cleanup)
					if ok then
						print("[MAIN] cleanup: " .. name)
					end
				end
			end
		end

		if oldHub.Connections then
			for _, c in ipairs(oldHub.Connections) do
				pcall(function() c:Disconnect() end)
			end
			oldHub.Connections = {}
		end

		if oldHub.Toggles then
			for _, sw in pairs(oldHub.Toggles) do
				if type(sw) == "table" and sw.set then
					pcall(function() sw.set(false) end)
				end
			end
			oldHub.Toggles = {}
		end
	end
	getgenv().Hub = nil

	local removeNames = {
		MenuUI = true,
		HubNotifications = true,
		EntityNotifier = true,
	}
	for _, obj in ipairs(playerGui:GetChildren()) do
		if obj:IsA("ScreenGui") and removeNames[obj.Name] then
			obj:Destroy()
			print("[MAIN] Удалён старый GUI: " .. obj.Name)
		end
	end

	print("[MAIN] PRE-CLEANUP завершён")
end

-- ============================================================
-- ============  LOADER  ======================================
-- ============================================================
local function load(path, addTimestamp)
	local url = BASE .. path
	if addTimestamp then
		url = url .. "?t=" .. tostring(os.time())
	end

	local ok, result = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)

	if not ok then
		warn("[MAIN] ❌ Ошибка загрузки " .. path .. ": " .. tostring(result))
		return nil
	end
	return result
end

-- ============================================================
-- ============  CONFIG  ======================================
-- ============================================================
local Config = load("config.lua", false)
if not Config then
	warn("[MAIN] Config не загружен — выход")
	return
end
print("[MAIN] Config загружен: " .. Config.HUB_NAME .. " v" .. Config.HUB_VERSION)

-- ============================================================
-- ============  HUB  =========================================
-- ============================================================
local Hub = {}
Hub.Config = Config
Hub.Toggles = {}
Hub.Connections = {}
Hub.Modules = {}
Hub.Objects = {
	ESP = {},
	Windows = {},
}

getgenv().Hub = Hub
print("[MAIN] Hub создан")

-- ============================================================
-- ============  UI + МОДУЛИ  =================================
-- ============================================================
local UI = load("features/ui.lua", true)
if UI and type(UI) == "table" and UI.init then
	local ok, err = pcall(UI.init, Hub)
	if ok then
		print("[MAIN] UI и модули загружены")
	else
		warn("[MAIN] ❌ UI упал: " .. tostring(err))
	end
else
	warn("[MAIN] ❌ ui.lua не вернул init()")
end

print("[MAIN] ========== ГОТОВО ==========")
