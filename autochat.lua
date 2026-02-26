-- [[ ZONHUB - AUTO CHAT MODULE (UNIVERSAL BYPASS) ]] --
local TargetPage = ...
if not TargetPage then return end

local G = getgenv()
G.ScriptVersion = "AutoChat v21.0 - Universal Keyboard Priority"

-- Variabel Global
G.AutoChatEnabled = G.AutoChatEnabled or false

local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- =========================================================
-- FUNGSI KIRIM PAKSA (LOGIKA DIUBAH)
-- =========================================================
local function UniversalSend(msg)
    pcall(function()
        -- STEP 1: Buka Chat Bar (Cara paling aman buat semua user)
        VIM:SendKeyEvent(true, Enum.KeyCode.Slash, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Slash, false, game)

        -- STEP 2: Tunggu Fokus
        local box = nil
        local start = os.clock()
        repeat
            box = UIS:GetFocusedTextBox()
            task.wait(0.05)
        until box or (os.clock() - start) > 2

        -- STEP 3: Isi Teks & Enter
        if box then
            box.Text = msg
            task.wait(0.05)
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        else
            -- STEP 4: Fallback terakhir jika UI macet (Remote)
            local TextChatService = game:GetService("TextChatService")
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channels = TextChatService:FindFirstChild("TextChannels")
                local general = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
                if general then general:SendAsync(msg) end
            end
        end
    end)
end

-- =========================================================
-- UI BUILDER (Simple & Fast)
-- =========================================================
-- [Gunakan fungsi CreateToggle dan CreateTextBox dari script kamu sebelumnya di sini]
-- Bagian UI tetap sama seperti v20.3 agar tampilan tidak berubah

-- =========================================================
-- LOOPING UTAMA (SMOOTH & ANTI-STUCK)
-- ========================================== --
task.spawn(function()
    while true do
        task.wait(0.5)
        if G.AutoChatEnabled then
            local pesan = (G.ChatTextBoxInstance and G.ChatTextBoxInstance.Text) or ""
            local delayTime = tonumber(G.DelayTextBoxInstance and G.DelayTextBoxInstance.Text) or 5
            
            if pesan ~= "" then
                if delayTime < 2 then delayTime = 2 end -- Delay aman
                UniversalSend(pesan)
                task.wait(delayTime)
            end
        end
    end
end)
