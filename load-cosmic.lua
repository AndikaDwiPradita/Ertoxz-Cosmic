-- =========================================================
-- COSMIC PANEL LOGIC LOADER (REMOTE MEMORY BASED + AUTO LOGIN)
-- =========================================================

-- GANTI "USERNAME" DAN "REPO" SESUAI DENGAN GITHUB KAMU
local GITHUB_BASE = "https://raw.githubusercontent.com/AndikaDwiPradita/Ertoxz-Cosmic/main/"
local SESSION_FILE = "/sdcard/Android/media/com.rtsoft.growtopia/scripts/cosmic_session.txt"

COSMIC_PANEL_DOC = nil
COSMIC_ACTIVE_TAB = "login"
COSMIC_LOGGED_IN = false
COSMIC_USER = nil

-- Status Toggle
COSMIC_TOGGLES = {
    modfly = false,
    noclip = false,
    autofarm = false
}

-- Mengambil elemen RmlUI dari ID
local function GetEl(id)
    if not COSMIC_PANEL_DOC then return nil end
    return COSMIC_PANEL_DOC:GetElementById(id)
end

-- =========================================================
-- MANAJEMEN SESI LOKAL (AUTO-LOGIN REMINDER)
-- =========================================================

local function SaveSession(username)
    local f = io.open(SESSION_FILE, "w")
    if f then
        f:write("logged_in=1\n")
        f:write("username=" .. tostring(username) .. "\n")
        f:close()
    end
end

local function ClearSession()
    local f = io.open(SESSION_FILE, "w")
    if f then
        f:write("logged_in=0\n")
        f:close()
    end
end

local function ReadSession()
    local f = io.open(SESSION_FILE, "r")
    if not f then return nil end
    
    local session = {}
    for line in f:lines() do
        local k, v = line:match("([^=]+)=(.+)")
        if k and v then
            session[k] = v
        end
    end
    f:close()

    if session.logged_in == "1" and session.username then
        return session.username
    end
    return nil
end

-- =========================================================
-- EVENT HANDLERS / FUNGSI UI
-- =========================================================

function CosmicOnClose()
    if COSMIC_PANEL_DOC then
        COSMIC_PANEL_DOC:Hide()
        LogToConsole("`2[Cosmic] UI Closed.")
        if CosmicBridge then
            CosmicBridge.Emit("onUiAction", { action = "LOG_MESSAGE", message = "UI Closed" })
        end
    end
end

function CosmicOnMinimize()
    if COSMIC_PANEL_DOC then
        COSMIC_PANEL_DOC:Hide()
        LogToConsole("`2[Cosmic] UI Minimized.")
    end
end

function CosmicOnTab(tabName)
    -- Mencegah akses ke tab lain jika belum login
    if not COSMIC_LOGGED_IN and tabName ~= "login" then
        tabName = "login"
    end

    COSMIC_ACTIVE_TAB = tabName
    
    local tabs = {"login", "main", "scripts", "player", "settings"}
    for _, t in ipairs(tabs) do
        local pageEl = GetEl("page-" .. t)
        if pageEl then
            if t == tabName then
                pageEl:SetClass("active", true)
            else
                pageEl:SetClass("active", false)
            end
        end
    end
end

function CosmicOnLogin()
    local inputUser = GetEl("input-username")
    local inputPass = GetEl("input-password")
    local errorEl = GetEl("login-error")
    
    local userVal = inputUser and inputUser:GetAttribute("value") or ""
    local passVal = inputPass and inputPass:GetAttribute("value") or ""
    
    if userVal == "" or passVal == "" then
        if errorEl then errorEl:SetInnerRml("Username / Password kosong!") end
        return
    end
    
    -- Simpan Sesi Login
    COSMIC_LOGGED_IN = true
    COSMIC_USER = userVal
    SaveSession(userVal)
    
    if errorEl then errorEl:SetInnerRml("") end
    
    local userStatusEl = GetEl("sidebar-user")
    if userStatusEl then userStatusEl:SetInnerRml("User: " .. userVal) end
    
    local logoutBtn = GetEl("logout-btn")
    if logoutBtn then logoutBtn:SetClass("show", true) end
    
    LogToConsole("`2[Cosmic] Logged in as: " .. userVal)
    CosmicOnTab("main")
end

function CosmicOnLogout()
    COSMIC_LOGGED_IN = false
    COSMIC_USER = nil
    ClearSession()
    
    local userStatusEl = GetEl("sidebar-user")
    if userStatusEl then userStatusEl:SetInnerRml("Belum login") end
    
    local logoutBtn = GetEl("logout-btn")
    if logoutBtn then logoutBtn:SetClass("show", false) end
    
    CosmicOnTab("login")
    LogToConsole("`2[Cosmic] Logged out.")
end

function CosmicOnToggle(event, name)
    COSMIC_TOGGLES[name] = not COSMIC_TOGGLES[name]
    local state = COSMIC_TOGGLES[name]
    
    if event and event.current_target then
        event.current_target:SetClass("active", state)
    end
    
    if CosmicBridge then
        CosmicBridge.Emit("onUiAction", {
            action = "TOGGLE_FEATURE",
            feature = name,
            state = state
        })
    end
end

function CosmicOnPilihScript(scriptName)
    LogToConsole("`2[Cosmic] Selected Script: " .. scriptName)
end

function CosmicOnButton(action)
    if action == "info" then
        local infoEl = GetEl("player-info-text")
        if infoEl then
            infoEl:SetInnerRml("Posisi Player: X: 50, Y: 23 | World: EXIT")
        end
    end
end

-- =========================================================
-- INITIALIZATION / RENDER ENGINE
-- =========================================================

local function InitCosmicUI()
    -- 1. Load Cosmic Bridge Listener dari GitHub
    LogToConsole("`2[Cosmic] Loading Bridge Listener...")
    local bridgeRes = MakeRequest(GITHUB_BASE .. "cosmic_bridge_listener.lua", "GET")
    if bridgeRes and bridgeRes.body and bridgeRes.body ~= "" then
        local bridgeChunk, err = load(bridgeRes.body)
        if bridgeChunk then
            pcall(bridgeChunk)
        else
            LogToConsole("`4[Cosmic Bridge] Syntax Error: " .. tostring(err))
        end
    end

    -- 2. Download RML & RCSS dari GitHub
    local ctx = rmlui.contexts[1]
    if not ctx then
        LogToConsole("`4[Cosmic] Error: RmlUI Context not found!")
        return
    end

    LogToConsole("`2[Cosmic] Fetching RML & RCSS templates...")
    local rmlRes = MakeRequest(GITHUB_BASE .. "CosmicPanel.rml", "GET")
    local rcssRes = MakeRequest(GITHUB_BASE .. "CosmicPanel.rcss", "GET")

    if not rmlRes or not rmlRes.body or rmlRes.body == "" then
        LogToConsole("`4[Cosmic] Error loading CosmicPanel.rml!")
        return
    end

    -- Injeksi RCSS ke dalam tag <style> di RML
    local rawRml = rmlRes.body
    if rcssRes and rcssRes.body then
        rawRml = rawRml:gsub('<link type="text/rcss" href="CosmicPanel.rcss"/>', '<style>' .. rcssRes.body .. '</style>')
    end

    -- Load Document langsung dari string RAM
    COSMIC_PANEL_DOC = ctx:CreateDocumentFromString(rawRml)
    if COSMIC_PANEL_DOC then
        COSMIC_PANEL_DOC:Show()
        
        -- Cek Sesi Auto-Login
        local savedUser = ReadSession()
        if savedUser then
            COSMIC_LOGGED_IN = true
            COSMIC_USER = savedUser
            
            local userStatusEl = GetEl("sidebar-user")
            if userStatusEl then userStatusEl:SetInnerRml("User: " .. savedUser) end
            
            local logoutBtn = GetEl("logout-btn")
            if logoutBtn then logoutBtn:SetClass("show", true) end
            
            CosmicOnTab("main")
            LogToConsole("`2[Cosmic] Auto-login berhasil! Selamat datang kembali, " .. savedUser)
        else
            CosmicOnTab("login")
            LogToConsole("`2[Cosmic] Silakan login terlebih dahulu.")
        end

    else
        LogToConsole("`4[Cosmic] Failed to create RmlUI Document!")
    end
end

InitCosmicUI()
