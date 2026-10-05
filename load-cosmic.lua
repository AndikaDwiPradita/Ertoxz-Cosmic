-- =========================================================
-- COSMIC PANEL LOGIC LOADER (FIXED CONTEXT & LOGS)
-- =========================================================

local GITHUB_BASE = "https://raw.githubusercontent.com/AndikaDwiPradita/Ertoxz-Cosmic/main/"

local SCRIPTS_DIR  = GetCurrentScriptDirectory and GetCurrentScriptDirectory() or "/sdcard/Android/media/com.rtsoft.growtopia/scripts/"
local SESSION_FILE = SCRIPTS_DIR .. "cosmic_session.txt"
local TEMP_RML     = SCRIPTS_DIR .. "CosmicPanel.rml"
local TEMP_RCSS    = SCRIPTS_DIR .. "CosmicPanel.rcss"

COSMIC_PANEL_DOC = nil
COSMIC_ACTIVE_TAB = "login"
COSMIC_LOGGED_IN = false
COSMIC_USER = nil

COSMIC_TOGGLES = {
    modfly = false,
    noclip = false,
    autofarm = false
}

local function GetEl(id)
    if not COSMIC_PANEL_DOC then return nil end
    return COSMIC_PANEL_DOC:GetElementById(id)
end

local function SaveFile(path, content)
    local f = io.open(path, "wb")
    if f then
        f:write(content)
        f:close()
        return true
    end
    return false
end

-- =========================================================
-- SESSION REMINDER
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
        if k and v then session[k] = v end
    end
    f:close()

    if session.logged_in == "1" and session.username then
        return session.username
    end
    return nil
end

-- =========================================================
-- UI FUNCTIONS
-- =========================================================

function CosmicOnClose()
    if COSMIC_PANEL_DOC then
        COSMIC_PANEL_DOC:Hide()
        LogToConsole("`2[Cosmic] UI Closed.")
    end
end

function CosmicOnMinimize()
    if COSMIC_PANEL_DOC then
        COSMIC_PANEL_DOC:Hide()
        LogToConsole("`2[Cosmic] UI Minimized.")
    end
end

function CosmicOnTab(tabName)
    if not COSMIC_LOGGED_IN and tabName ~= "login" then
        tabName = "login"
    end

    COSMIC_ACTIVE_TAB = tabName
    
    local tabs = {"login", "main", "scripts", "player", "settings"}
    for _, t in ipairs(tabs) do
        local pageEl = GetEl("page-" .. t)
        if pageEl then
            pageEl:SetClass("active", t == tabName)
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
    
    LogToConsole("`2[Cosmic] Toggle " .. name .. " -> " .. tostring(state))
end

function CosmicOnPilihScript(scriptName)
    LogToConsole("`2[Cosmic] Selected Script: " .. scriptName)
end

function CosmicOnButton(action)
    if action == "info" then
        local infoEl = GetEl("player-info-text")
        if infoEl then
            infoEl:SetInnerRml("Posisi Player: Ready")
        end
    end
end

-- =========================================================
-- INITIALIZATION ENGINE (DYNAMIC CONTEXT)
-- =========================================================

local function InitCosmicUI()
    LogToConsole("`2[Cosmic] Starting UI Initialization...")

    if not rmlui or not rmlui.contexts then
        LogToConsole("`4[Cosmic Error] Object rmlui.contexts TIDAK DITEMUKAN!")
        return
    end

    -- Cari Context RmlUI yang aktif (Bisa nama string atau index angka)
    local ctx = nil
    local ctxName = nil
    for name, c in pairs(rmlui.contexts) do
        if c then
            ctx = c
            ctxName = tostring(name)
            break
        end
    end

    if not ctx then
        LogToConsole("`4[Cosmic Error] Tidak ada Context RmlUI yang aktif!")
        return
    end

    LogToConsole("`2[Cosmic] RmlUI Context terdeteksi: " .. ctxName)

    -- Download RML & RCSS dari GitHub
    LogToConsole("`2[Cosmic] Downloading RML & RCSS...")
    local rmlRes  = MakeRequest(GITHUB_BASE .. "CosmicPanel.rml", "GET")
    local rcssRes = MakeRequest(GITHUB_BASE .. "CosmicPanel.rcss", "GET")

    if not rmlRes or not rmlRes.body or rmlRes.body == "" then
        LogToConsole("`4[Cosmic Error] CosmicPanel.rml gagal di-download dari GitHub!")
        return
    end

    -- Simpan file ke folder lokal Bothax
    local wRml = SaveFile(TEMP_RML, rmlRes.body)
    if rcssRes and rcssRes.body then
        SaveFile(TEMP_RCSS, rcssRes.body)
    end

    if not wRml then
        LogToConsole("`4[Cosmic Error] Gagal menulis file RML ke folder lokal!")
        return
    end

    LogToConsole("`2[Cosmic] Template tersimpan di lokal. Loading document...")

    -- Tutup dokumen lama jika ada
    if ctx.documents and ctx.documents['CosmicPanel'] then
        ctx.documents['CosmicPanel']:Close()
    end

    -- Load Dokumen dari file lokal
    COSMIC_PANEL_DOC = ctx:LoadDocument(TEMP_RML)
    if COSMIC_PANEL_DOC then
        COSMIC_PANEL_DOC:Show()
        LogToConsole("`2[Cosmic] SUCCESS! Panel UI Berhasil Tampil!")
        
        local savedUser = ReadSession()
        if savedUser then
            COSMIC_LOGGED_IN = true
            COSMIC_USER = savedUser
            
            local userStatusEl = GetEl("sidebar-user")
            if userStatusEl then userStatusEl:SetInnerRml("User: " .. savedUser) end
            
            local logoutBtn = GetEl("logout-btn")
            if logoutBtn then logoutBtn:SetClass("show", true) end
            
            CosmicOnTab("main")
            LogToConsole("`2[Cosmic] Auto-login: " .. savedUser)
        else
            CosmicOnTab("login")
        end
    else
        LogToConsole("`4[Cosmic Error] LoadDocument() gagal! Cek penulisan syntax RML/RCSS.")
    end
end

InitCosmicUI()
