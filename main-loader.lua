-- =========================================================
-- COSMIC PANEL MAIN LOADER
-- Jalankan file ini menggunakan tombol Execute Lua di Bothax
-- =========================================================

-- GANTI "USERNAME" DAN "REPO" SESUAI DENGAN GITHUB KAMU
local RAW_LOADER_URL = "https://raw.githubusercontent.com/USERNAME/REPO/main/load-cosmic.lua"

LogToConsole("`2[Cosmic] Downloading Cosmic Panel from GitHub...")

local response = MakeRequest(RAW_LOADER_URL, "GET")

if response and response.body and response.body ~= "" then
    LogToConsole("`2[Cosmic] Download success! Compiling...")
    
    local chunk, err = load(response.body)
    
    if chunk then
        local success, runErr = pcall(chunk)
        if not success then
            LogToConsole("`4[Cosmic] Runtime Error: " .. tostring(runErr))
        end
    else
        LogToConsole("`4[Cosmic] Syntax Error: " .. tostring(err))
    end
else
    LogToConsole("`4[Cosmic] Failed to download script from GitHub!")
end
