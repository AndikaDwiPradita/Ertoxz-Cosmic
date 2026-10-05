-- =========================================================
-- COSMIC BRIDGE LISTENER
-- Menangani event-event khusus dari RmlUI ke Bothax/Game Engine
-- =========================================================

CosmicBridge = {
    listeners = {}
}

-- Fungsi untuk mendaftarkan event listener baru
function CosmicBridge.Register(eventName, callback)
    if not CosmicBridge.listeners[eventName] then
        CosmicBridge.listeners[eventName] = {}
    end
    table.insert(CosmicBridge.listeners[eventName], callback)
    LogToConsole("`2[Cosmic Bridge] Listener registered for event: " .. tostring(eventName))
end

-- Fungsi untuk memicu event dari RmlUI atau Lua
function CosmicBridge.Emit(eventName, data)
    local handlers = CosmicBridge.listeners[eventName]
    if handlers then
        for _, handler in ipairs(handlers) do
            local status, err = pcall(handler, data)
            if not status then
                LogToConsole("`4[Cosmic Bridge Error] " .. tostring(err))
            end
        end
    end
end

-- =========================================================
-- DEFAULT EVENT HANDLERS / HOOKS
-- =========================================================

-- Listener untuk menangkap perintah / UI Actions
CosmicBridge.Register("onUiAction", function(data)
    if not data then return end
    
    if data.action == "LOG_MESSAGE" then
        LogToConsole("`2[Cosmic Bridge] UI Says: " .. tostring(data.message))
    elseif data.action == "TOGGLE_FEATURE" then
        LogToConsole("`2[Cosmic Bridge] Feature " .. tostring(data.feature) .. " set to " .. tostring(data.state))
    end
end)

-- Listener untuk komunikasi jaringan / game packet (jika diperlukan)
CosmicBridge.Register("onPacketReceive", function(packet)
    -- Contoh penanganan packet game di masa mendatang
end)

LogToConsole("`2[Cosmic Bridge] Bridge Listener fully initialized!")
