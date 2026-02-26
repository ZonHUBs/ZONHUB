-- [[ ZONHUB - AUTO CHAT MODULE (SISTEMATIS BYPASS) ]] --
local TargetPage = ... 
if not TargetPage then warn("Module harus di-load dari ZonIndex!") return end

getgenv().ScriptVersion = "AutoChat v10.0 - Ultimate Systematic" 

-- ========================================== --
-- VARIABEL & SERVICES
-- ========================================== --
getgenv().AutoChatEnabled = false
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- ========================================== --
-- FUNGSI UI UTILITY (Tampilan Menu)
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
-- LOGIKA SISTEMATIS (SEARCH & TYPE)
-- ========================================== --
local function SystematicChat(msg)
    pcall(function()
        -- Cari Chat Bar asli di PlayerGui secara mendalam
        local chatBar = nil
        for _, v in pairs(LP.PlayerGui:GetDescendants()) do
            if v:IsA("TextBox") and (v.Name == "TextBox" or v.Name == "ChatBar") then
                -- Memastikan ini benar-benar kotak input chat
                if v.Visible and v.Parent.Name:lower():find("bar") or v.Parent.Name:lower():find("input") then
                    chatBar = v
                    break
                end
            end
        end

        if chatBar then
            -- Langkah 1: Fokuskan kamera/game agar input masuk
            VirtualUser:ClickButton1(Vector2.new(0,0)) 
            
            -- Langkah 2: Paksa buka chat (Tombol '/')
            VirtualUser:TypeKey(Enum.KeyCode.Slash)
            task.wait(0.2)
            
            -- Langkah 3: Masukkan teks langsung ke properti UI
            chatBar.Text = msg
            task.wait(0.1)
            
            -- Langkah 4: Tekan Enter secara virtual melalui VirtualUser
            VirtualUser:TypeKey(Enum.KeyCode.Return)
        else
            -- Jika UI Chat tidak terdeteksi (Fallback ke Remote)
            local SayMessageRequest = game:GetService("ReplicatedStorage"):FindFirstChild("SayMessageRequest", true)
            if SayMessageRequest then
                SayMessageRequest:FireServer(msg, "All")
            end
        end
    end)
end

-- ========================================== --
-- LOOPING UTAMA
-- ========================================== --
task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().AutoChatEnabled then
            local pesan = getgenv().ChatTextBoxInstance and getgenv().ChatTextBoxInstance.Text or ""
            local rawDelay = tonumber(getgenv().DelayTextBoxInstance.Text) or 5
            
            if pesan ~= "" then
                if rawDelay < 2 then rawDelay = 2 end
                SystematicChat(pesan)
                task.wait(rawDelay)
            end
        else
            task.wait(0.5)
        end
    end
end)
