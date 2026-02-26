-- [[ ZONHUB - AUTO CHAT MODULE (GHOST TYPE SMOOTH) ]] --
local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari ZonIndex!") return end

getgenv().ScriptVersion = "AutoChat v20.1 - Ghost Smooth (All Chat Systems)"

-- ========================================== --
-- SERVICES
-- ========================================== --
getgenv().AutoChatEnabled = false
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ========================================== --
-- FUNGSI UI UTILITY
-- ========================================== --
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }

local function CreateToggle(Parent, Text, Var)
    local Btn = Instance.new("TextButton", Parent)
    Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; Btn.AutoButtonColor = false
    local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6)
    local T = Instance.new("TextLabel", Btn)
    T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left
    local IndBg = Instance.new("Frame", Btn)
    IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
    local IC = Instance.new("UICorner", IndBg); IC.CornerRadius = UDim.new(1,0)
    local Dot = Instance.new("Frame", IndBg)
    Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100)
    local DC = Instance.new("UICorner", Dot); DC.CornerRadius = UDim.new(1,0)

    Btn.MouseButton1Click:Connect(function()
        getgenv()[Var] = not getgenv()[Var]
        if getgenv()[Var] then
            Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true)
            Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple
        else
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true)
            Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
        end
    end)
end

local function CreateTextBox(Parent, Text, Default, IsNumber)
    local Frame = Instance.new("Frame", Parent)
    Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35)
    local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame)
    Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.45, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left
    local InputBox = Instance.new("TextBox", Frame)
    InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.5, 0, 0.15, 0); InputBox.Size = UDim2.new(0.45, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 11; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); InputBox.ClearTextOnFocus = false; InputBox.TextXAlignment = Enum.TextXAlignment.Center
    local IC = Instance.new("UICorner", InputBox); IC.CornerRadius = UDim.new(0, 4)
    if IsNumber then
        InputBox.FocusLost:Connect(function()
            if not tonumber(InputBox.Text) then InputBox.Text = tostring(Default) end
        end)
    end
    return InputBox
end

-- ========================================== --
-- BUILD MENU
-- ========================================== --
CreateToggle(TargetPage, "Start Auto Chat", "AutoChatEnabled")
getgenv().ChatTextBoxInstance = CreateTextBox(TargetPage, "Isi Pesan Chat", "ZonHub On Top!", false)
getgenv().DelayTextBoxInstance = CreateTextBox(TargetPage, "Delay (Detik)", "5", true)

-- ========================================== --
-- GHOST TYPING (FIXED TIMING)
-- ========================================== --
local function GhostTypeSmooth(msg)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Slash, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.Slash, false, game)

        local box
        local start = os.clock()
        repeat
            box = UIS:GetFocusedTextBox()
            task.wait(0.05)
        until box or (os.clock() - start) > 5

        if box then
            box.Text = msg
            task.wait(0.03)
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end
    end)
end

-- ========================================== --
-- SMART SEND (WORKS ON TextChatService + Legacy)
-- ========================================== --
local function SendChatSmart(msg)
    msg = tostring(msg or "")
    if msg == "" then return false, "Pesan kosong" end

    -- 1) TextChatService (chat baru)
    do
        local ok, sent, err = pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = nil

                -- Target channel kalau sudah diset oleh input bar
                if TextChatService.ChatInputBarConfiguration then
                    channel = TextChatService.ChatInputBarConfiguration.TargetTextChannel
                end

                -- Fallback cari channel umum
                if not channel then
                    local channels = TextChatService:FindFirstChild("TextChannels") or TextChatService:WaitForChild("TextChannels", 2)
                    if channels then
                        channel = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel")
                    end
                end

                if not channel then
                    return false, "TextChannel tidak ketemu"
                end

                channel:SendAsync(msg)
                return true
            end

            return nil -- bukan TextChatService
        end)

        if ok and sent ~= nil then
            return sent, err
        end
    end

    -- 2) Legacy chat (DefaultChatSystem)
    do
        local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        local say = events and events:FindFirstChild("SayMessageRequest")
        if say then
            say:FireServer(msg, "All")
            return true
        end
    end

    -- 3) Fallback terakhir: ghost typing UI
    GhostTypeSmooth(msg)
    return true
end

-- ========================================== --
-- LOOPING SISTEMATIS (anti dobel kirim)
-- ========================================== --
local _sending = false

task.spawn(function()
    while true do
        task.wait(0.1)

        if getgenv().AutoChatEnabled and not _sending then
            local pesan = (getgenv().ChatTextBoxInstance and getgenv().ChatTextBoxInstance.Text) or ""
            local rawDelay = tonumber(getgenv().DelayTextBoxInstance.Text) or 5
            if rawDelay < 2 then rawDelay = 2 end

            if pesan ~= "" then
                _sending = true
                SendChatSmart(pesan)
                task.wait(rawDelay)
                _sending = false
            else
                task.wait(0.2)
            end
        else
            task.wait(0.4)
        end
    end
end)
