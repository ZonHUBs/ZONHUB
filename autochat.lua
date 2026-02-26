-- [[ ZONHUB - AUTO CHAT MODULE (GHOST TYPE SMOOTH + QUEUE BACKOFF) ]] --
local TargetPage = ...
if not TargetPage then
    warn("[AutoChat] Module harus di-load dari ZonIndex! (TargetPage nil)")
    return
end

getgenv().ScriptVersion = "AutoChat v20.2 - UI Fix + Queue Backoff"
getgenv().AutoChatEnabled = false

-- ========================================== --
-- SERVICES
-- ========================================== --
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ========================================== --
-- SAFE WRAPPER (biar UI gak hilang karena error)
-- ========================================== --
local function safe(fn)
    local ok, err = xpcall(fn, function(e)
        return debug.traceback(e, 2)
    end)
    if not ok then
        warn("[AutoChat] ERROR:\n" .. tostring(err))
    end
end

-- ========================================== --
-- FUNGSI UI UTILITY
-- ========================================== --
local Theme = {
    Item = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255),
    Purple = Color3.fromRGB(140, 80, 255)
}

local function CreateToggle(Parent, Text, Var)
    local Btn = Instance.new("TextButton")
    Btn.Parent = Parent
    Btn.BackgroundColor3 = Theme.Item
    Btn.Size = UDim2.new(1, -10, 0, 35)
    Btn.Text = ""
    Btn.AutoButtonColor = false

    local C = Instance.new("UICorner", Btn)
    C.CornerRadius = UDim.new(0, 6)

    local T = Instance.new("TextLabel", Btn)
    T.Text = Text
    T.TextColor3 = Theme.Text
    T.Font = Enum.Font.GothamSemibold
    T.TextSize = 12
    T.Size = UDim2.new(1, -40, 1, 0)
    T.Position = UDim2.new(0, 10, 0, 0)
    T.BackgroundTransparency = 1
    T.TextXAlignment = Enum.TextXAlignment.Left

    local IndBg = Instance.new("Frame", Btn)
    IndBg.Size = UDim2.new(0, 36, 0, 18)
    IndBg.Position = UDim2.new(1, -45, 0.5, -9)
    IndBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

    local IC = Instance.new("UICorner", IndBg)
    IC.CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame", IndBg)
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = UDim2.new(0, 2, 0.5, -7)
    Dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

    local DC = Instance.new("UICorner", Dot)
    DC.CornerRadius = UDim.new(1, 0)

    -- sync initial state (biar dot sesuai getgenv)
    if getgenv()[Var] then
        Dot.Position = UDim2.new(1, -16, 0.5, -7)
        Dot.BackgroundColor3 = Color3.new(1,1,1)
        IndBg.BackgroundColor3 = Theme.Purple
    end

    Btn.MouseButton1Click:Connect(function()
        getgenv()[Var] = not getgenv()[Var]
        if getgenv()[Var] then
            Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true)
            Dot.BackgroundColor3 = Color3.new(1, 1, 1)
            IndBg.BackgroundColor3 = Theme.Purple
        else
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true)
            Dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            IndBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end)
end

local function CreateTextBox(Parent, Text, Default, IsNumber)
    local Frame = Instance.new("Frame")
    Frame.Parent = Parent
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
-- BUILD MENU (INI YANG HARUS MUNCUL)
-- ========================================== --
safe(function()
    CreateToggle(TargetPage, "Start Auto Chat", "AutoChatEnabled")
    getgenv().ChatTextBoxInstance = CreateTextBox(TargetPage, "Isi Pesan Chat", "ZonHub On Top!", false)
    getgenv().DelayTextBoxInstance = CreateTextBox(TargetPage, "Delay (Detik)", "5", true)
end)

-- ========================================== --
-- GHOST TYPING (fallback terakhir)
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
-- SMART SEND (queue + backoff) agar gak macet di server rame
-- ========================================== --
local ChatSender = {
    Queue = {},
    Sending = false,
    MinDelay = 2,
    MaxDelay = 25,
    Backoff = 0,
    LastSendAt = 0,
    Debug = false, -- ubah true kalau mau lihat warn debug
}

local function dprint(...)
    if ChatSender.Debug then warn("[AutoChat]", ...) end
end

local function WaitChatReady(timeout)
    local t0 = os.clock()
    while (os.clock() - t0) < (timeout or 8) do
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels and channels:FindFirstChildWhichIsA("TextChannel") then
                return true
            end
        else
            local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if events and events:FindFirstChild("SayMessageRequest") then
                return true
            end
        end
        task.wait(0.2)
    end
    return false
end

local function ResolveTextChannel()
    if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
        return nil
    end

    local channel = nil
    pcall(function()
        if TextChatService.ChatInputBarConfiguration then
            channel = TextChatService.ChatInputBarConfiguration.TargetTextChannel
        end
    end)

    if not channel then
        local channels = TextChatService:FindFirstChild("TextChannels")
        if channels then
            channel = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel")
        end
    end

    return channel
end

local function TrySendOnce(msg)
    msg = tostring(msg or "")
    if msg == "" then return false, "Pesan kosong" end
    if not WaitChatReady(6) then return false, "Chat belum ready" end

    -- TextChatService
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = ResolveTextChannel()
        if not channel then return false, "TextChannel tidak ketemu" end

        local ok, err = pcall(function()
            channel:SendAsync(msg)
        end)
        if ok then return true else return false, tostring(err) end
    end

    -- Legacy
    local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local say = events and events:FindFirstChild("SayMessageRequest")
    if say then
        say:FireServer(msg, "All")
        return true
    end

    -- UI fallback
    GhostTypeSmooth(msg)
    return true
end

function ChatSender:GetBaseDelay()
    local rawDelay = tonumber(getgenv().DelayTextBoxInstance and getgenv().DelayTextBoxInstance.Text) or 5
    if rawDelay < self.MinDelay then rawDelay = self.MinDelay end
    return rawDelay
end

function ChatSender:IncreaseBackoff(reason)
    self.Backoff = (self.Backoff <= 0) and 2 or math.min(self.MaxDelay, math.floor(self.Backoff * 1.5 + 1))
    dprint("Send gagal:", reason, "| Backoff:", self.Backoff)
end

function ChatSender:DecreaseBackoff()
    if self.Backoff > 0 then
        self.Backoff = math.max(0, self.Backoff - 1)
    end
end

function ChatSender:Push(msg)
    table.insert(self.Queue, tostring(msg))
    if not self.Sending then
        task.spawn(function() self:Process() end)
    end
end

function ChatSender:Process()
    self.Sending = true

    while getgenv().AutoChatEnabled do
        local msg = table.remove(self.Queue, 1)
        if not msg then break end

        local delay = self:GetBaseDelay() + self.Backoff
        local since = os.clock() - (self.LastSendAt or 0)
        if since < delay then
            task.wait(delay - since)
        end

        local ok, reason = TrySendOnce(msg)
        self.LastSendAt = os.clock()

        if ok then
            self:DecreaseBackoff()
        else
            self:IncreaseBackoff(reason)
            table.insert(self.Queue, 1, msg) -- retry
            task.wait(math.min(self.MaxDelay, 2 + self.Backoff))
        end

        task.wait(0.05)
    end

    self.Sending = false
end

-- ========================================== --
-- LOOP AUTOCHAT
-- ========================================== --
task.spawn(function()
    while true do
        task.wait(0.25)

        if getgenv().AutoChatEnabled then
            local pesan = (getgenv().ChatTextBoxInstance and getgenv().ChatTextBoxInstance.Text) or ""
            if pesan ~= "" then
                ChatSender:Push(pesan)
                task.wait(0.9) -- jangan push terlalu cepat ke queue
            end
        else
            task.wait(0.6)
        end
    end
end)
