-- [[ ZONHUB - AUTO CHAT MODULE (FORCE ALL CHANNELS) ]] --
local TargetPage = ... 
if not TargetPage then warn("Module harus di-load dari ZonIndex!") return end

getgenv().ScriptVersion = "AutoChat v5.0 - Ultimate Engine" 

-- ========================================== --
-- VARIABEL GLOBAL 
-- ========================================== --
getgenv().AutoChatEnabled = false
getgenv().AutoChatDelay = 5                  
getgenv().ChatTextBoxInstance = nil 
getgenv().DelayTextBoxInstance = nil 
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

    if IsNumber then
        InputBox.FocusLost:Connect(function()
            if not tonumber(InputBox.Text) then
                InputBox.Text = tostring(Default) 
            end
        end)
    end
    
    return InputBox 
end

-- ========================================== --
-- MEMBANGUN MENU UI 
-- ========================================== --
CreateToggle(TargetPage, "Start Auto Chat", "AutoChatEnabled")
getgenv().ChatTextBoxInstance = CreateTextBox(TargetPage, "Isi Pesan Chat", "ZonHub On Top!", false)
getgenv().DelayTextBoxInstance = CreateTextBox(TargetPage, "Delay (Detik)", "5", true)

-- ========================================== --
-- FUNGSI MENGIRIM PESAN (FORCE ALL CHANNELS)
-- ========================================== --
local function ForceSendChat(msg)
    -- SISTEM BARU (TextChatService)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local success = false
        pcall(function()
            local rbxGeneral = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if rbxGeneral then
                rbxGeneral:SendAsync(msg)
                success = true
            end
        end)
        
        -- Jika gagal di RBXGeneral (biasa terjadi pada akun Non-VC / <13), 
        -- kita paksa broadcast ke seluruh channel yang ada!
        if not success then
            pcall(function()
                for _, channel in pairs(TextChatService:GetDescendants()) do
                    if channel:IsA("TextChannel") then
                        pcall(function() channel:SendAsync(msg) end)
                    end
                end
            end)
        end
    
    -- SISTEM LAMA (LegacyChatService)
    else
        pcall(function()
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end)
    end
    
    -- FALLBACK UNIVERSAL (Memunculkan chat di atas kepala karakter)
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
            -- Ambil teks terbaru langsung dari UI
            local pesan = getgenv().ChatTextBoxInstance and getgenv().ChatTextBoxInstance.Text or "ZonHub On Top!"
            local rawDelay = getgenv().DelayTextBoxInstance and tonumber(getgenv().DelayTextBoxInstance.Text) or 5
            
            -- Cegah spam terlalu cepat yang membuat chat error/delay
            if rawDelay < 3 then rawDelay = 3 end 
            
            if pesan and pesan:match("%S") then 
                ForceSendChat(pesan)
                task.wait(rawDelay)
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end)
