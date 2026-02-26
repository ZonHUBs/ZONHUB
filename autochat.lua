-- [[ ZONHUB - AUTO CHAT MODULE v22.0 - ULTIMATE UI FIX ]] --
local TargetPage = ...
if not TargetPage then return end

local G = getgenv()
G.AutoChatEnabled = false

local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")

-- ========================================== --
-- FUNGSI UNTUK MEMBUAT UI (DIJAMIN MUNCUL)
-- ========================================== --
local function BuildControls(parent)
    if parent:FindFirstChild("AutoChat_Controls") then return end
    
    local container = Instance.new("Frame", parent)
    container.Name = "AutoChat_Controls"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Buat UI secara manual di sini agar tidak tergantung fungsi luar
    local function CreateToggle(txt, var)
        local b = Instance.new("TextButton", container)
        b.Size = UDim2.new(0.9, 0, 0, 35)
        b.Text = txt .. ": OFF"
        b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        b.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", b)
        
        b.MouseButton1Click:Connect(function()
            G[var] = not G[var]
            b.Text = txt .. (G[var] and ": ON" or ": OFF")
            b.BackgroundColor3 = G[var] and Color3.fromRGB(140, 80, 255) or Color3.fromRGB(60, 60, 60)
        end)
    end

    local function CreateInput(txt, def)
        local f = Instance.new("Frame", container)
        f.Size = UDim2.new(0.9, 0, 0, 40)
        f.BackgroundTransparency = 1
        local l = Instance.new("TextLabel", f)
        l.Text = txt; l.Size = UDim2.new(0.4, 0, 1, 0); l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1
        local i = Instance.new("TextBox", f)
        i.Size = UDim2.new(0.5, 0, 0.8, 0); i.Position = UDim2.new(0.45, 0, 0.1, 0); i.Text = def; i.BackgroundColor3 = Color3.fromRGB(30,30,30); i.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", i)
        return i
    end

    CreateToggle("Start Auto Chat", "AutoChatEnabled")
    G.ChatTextBoxInstance = CreateInput("Pesan:", "ZonHub On Top!")
    G.DelayTextBoxInstance = CreateInput("Delay:", "5")
end

-- ========================================== --
-- LOGIKA PENGIRIMAN (BYPASS SEMUA VERSI)
-- ========================================== --
local function SendAction(msg)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Slash, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.Slash, false, game)
        task.wait(0.3)
        
        local box = UIS:GetFocusedTextBox()
        if box then
            box.Text = msg
            task.wait(0.1)
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end
    end)
end

-- ========================================== --
-- STARTING SCRIPT
-- ========================================== --
-- Mencoba mount UI berkali-kali sampai muncul
task.spawn(function()
    for i = 1, 20 do
        BuildControls(TargetPage)
        task.wait(0.5)
    end
end)

-- Loop Utama
task.spawn(function()
    while true do
        task.wait(0.5)
        if G.AutoChatEnabled then
            local p = G.ChatTextBoxInstance and G.ChatTextBoxInstance.Text or ""
            local d = tonumber(G.DelayTextBoxInstance.Text) or 5
            if p ~= "" then
                SendAction(p)
                task.wait(d)
            end
        end
    end
end)
