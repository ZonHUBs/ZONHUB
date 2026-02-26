-- [[ ZONHUB - AUTO CHAT MODULE (ANTI-BLINK & ALL CHAT SYSTEMS) ]] --
local TargetPage = ... 
if not TargetPage then warn("Module harus di-load dari ZonIndex!") return end

getgenv().ScriptVersion = "AutoChat v2.1 - Anti Blink Fix" 

-- ========================================== --
-- VARIABEL GLOBAL 
-- ========================================== --
getgenv().AutoChatEnabled = false
getgenv().AutoChatMessage = "ZonHub On Top!" 
getgenv().AutoChatDelay = 5                  
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ========================================== --
-- FUNGSI UI UTILITY (MOBILE FRIENDLY)
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

local function CreateTextBox(Parent, Text, Default, Var, IsNumber) 
    local Frame = Instance.new("Frame", Parent)
    Frame.BackgroundColor3 = Theme.Item
    Frame.Size = UDim2.new(1, -10, 0, 35)
    local C = Instance.new("UICorner", Frame)
    C.CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Text = Text
    Label.TextColor3 = Theme.Text
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(0.45, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local InputBox = Instance.new("TextBox", Frame)
    InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    InputBox.Position = UDim2.new(0.5, 0, 0.15, 0)
    InputBox.Size = UDim2.new(0.45, 0, 0.7, 0)
    InputBox.Font = Enum.Font.GothamSemibold
    InputBox.TextSize = 11
    InputBox.TextColor3 = Theme.Text
    InputBox.Text = tostring(Default)
    InputBox.ClearTextOnFocus = false
    InputBox.TextXAlignment = Enum.TextXAlignment.Center
    local IC = Instance.new("UICorner", InputBox)
    IC.CornerRadius = UDim.new(0, 4)
    
    InputBox:GetPropertyChangedSignal("Text"):Connect(function()
        if IsNumber then
            local val = tonumber(InputBox.Text)
            if val then getgenv()[Var] = val end
        else
            getgenv()[Var] = InputBox.Text
        end
    end)

    InputBox.FocusLost:Connect(function()
        if IsNumber and not tonumber(InputBox.Text) then
            InputBox.Text = tostring(getgenv()[Var]) 
        end
    end)
end

-- ========================================== --
-- MEMBANGUN MENU UI 
-- ========================================== --
CreateToggle(TargetPage, "Start Auto Chat", "AutoChatEnabled")
CreateTextBox(TargetPage, "Isi Pesan Chat", getgenv().AutoChatMessage, "AutoChatMessage", false)
CreateTextBox(TargetPage, "Delay (Detik)", getgenv().AutoChatDelay, "AutoChatDelay", true)

-- ========================================== --
-- FUNGSI MENGIRIM PESAN (BRUTE-FORCE SYSTEM)
-- ========================================== --
local function SendChatMessage(msg)
    -- 1. Coba Kirim Lewat TextChatService (Sistem Baru Roblox)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local sent = false
            -- Cari channel utama (RBXGeneral)
            local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if generalChannel then
                generalChannel:SendAsync(msg)
                sent = true
            end
            
            -- Jika RBXGeneral tidak ada, paksa kirim ke SEMUA channel yang ada
            if not sent then
                for _, channel in ipairs(TextChatService.TextChannels:GetChildren()) do
                    if channel:IsA("TextChannel") then
                        channel:SendAsync(msg)
                    end
                end
            end
        end
    end)

    -- 2. Coba Kirim Lewat Legacy Chat (Sistem Lama Roblox)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(msg, "All")
            else
                -- Deep search jika disembunyikan oleh dev game
                local remote = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
                if remote and remote:IsA("RemoteEvent") then
                    remote:FireServer(msg, "All")
                end
            end
        end
    end)

    -- 3. Fallback Darurat: Paksa munculkan Chat Bubble di atas kepala karakter
    pcall(function()
        Players:Chat(msg)
    end)
end

-- ========================================== --
-- LOGIKA LOOPING AUTO CHAT
-- ========================================== --
task.spawn(function()
    while true do
        if getgenv().AutoChatEnabled then
            local pesan = getgenv().AutoChatMessage
            local jeda = getgenv().AutoChatDelay
            
            -- PENTING: Batas aman Anti-Spam Roblox adalah minimal 3 detik. 
            -- Jika di bawah itu, Roblox akan nge-bug / berkedip ikonnya.
            if type(jeda) ~= "number" or jeda < 3 then 
                jeda = 3 
            end 
            
            if pesan and pesan ~= "" then
                SendChatMessage(pesan)
                task.wait(jeda)
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end)
