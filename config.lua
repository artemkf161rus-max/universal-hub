-- ============================================================
-- ============  UNIVERSAL HUB — CONFIG  ======================
-- ============================================================
local Config = {}

-- ============ ОБЩЕЕ ============
Config.HUB_NAME = "Universal Hub"
Config.HUB_VERSION = "1.0.0"

-- ============ ESP ============
Config.ESP_RADIUS = 500           -- максимум студов для ESP
Config.ESP_DEFAULT_COLOR = Color3.fromRGB(255, 0, 0)

-- ============ MOVEMENT ============
Config.MIN_SPEED = 16
Config.MAX_SPEED = 500
Config.DEFAULT_SPEED = 16

Config.FLY_SPEED_MIN = 10
Config.FLY_SPEED_MAX = 500
Config.FLY_SPEED_DEFAULT = 50

Config.JUMP_MIN = 50
Config.JUMP_MAX = 500
Config.JUMP_DEFAULT = 50

Config.GRAVITY_MIN = 0
Config.GRAVITY_MAX = 196
Config.GRAVITY_DEFAULT = 196

-- ============ MISC ============
Config.CHAT_SPAM_DELAY = 1        -- секунд между сообщениями
Config.CHAT_SPAM_DEFAULT = "Привет всем!"

-- ============ UI ============
Config.PAGES_COUNT = 4            -- количество страниц в меню

return Config
