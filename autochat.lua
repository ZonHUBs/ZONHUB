-- [[ ZONHUB - AUTO CHAT MODULE (UI MOUNT FIX + QUEUE/BACKOFF) ]] --
local TargetPage = ...
if not TargetPage then
    warn("[AutoChat] Module harus di-load dari ZonIndex! (TargetPage nil)")
    return
end

local G = getgenv()
G.ScriptVersion = "AutoChat v20.3 - UI Mount Fix + Queue Backoff"

-- =========================================================
-- GLOBAL STATE (biar kalau module di-load ulang, tidak dobel loop)
-- =========================================================
G.__ZONHUB_AUTOCHAT_STATE = G.__ZONHUB_AUTOCHAT_STATE or {}
local State = G.__ZONHUB_AUTOCHAT_STATE

-- =========================================================
-- SERVICES (hanya set sekali)
-- =========================================================
if not State._services then
    State.VIM = game:GetService("VirtualInputManager")
    State.UIS = game:GetService("UserInputService")
    State.Players = game:GetService("Players")
    State.TextChatService = game:GetService("TextChatService")
    State.ReplicatedStorage = game:GetService("ReplicatedStorage")
    State.LP = State.Players.LocalPlayer
    State._services = true
end

-- default global var
G.AutoChatEnabled = G.AutoChatEnabled or false

-- =========================================================
-- THEME + SAFE WRAPPER
-- =========================================================
local Theme = {
    Item = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255),
    Purple = Color3.fromRGB(140, 80, 255)
}

local function safe(fn)
    local ok, err = xpcall(fn, function(e)
        return debug.traceback(e, 2)
    end)
    if not ok then
        warn("[AutoChat] ERROR:\n" .. tostring(err))
    end
end

-- =========================================================
-- UI HELPERS
-- =========================================================
local function ResolveContainer(page)
    -- kalau TargetPage bukan Instance, coba ambil field umum (jaga-jaga framework)
    if typeof(page) ~= "Instance" then
        if typeof(page) == "table" then
            page = page.Content or page.Container or page.Page or page.Frame
        end
    end
    if typeof(page) ~= "Instance" then
        warn("[AutoChat] TargetPage bukan Instance, UI tidak bisa dibuat")
        return nil
    end

    -- coba cari container umum
    local content = page:FindFirstChild("Content", true)
    if content and (content:IsA("Frame") or content:IsA("ScrollingFrame")) then
        return content
    end

    local scroll = page:FindFirstChildWhichIsA("ScrollingFrame", true)
    if scroll then return scroll end

    if page:IsA("Frame") or page:IsA("ScrollingFrame") then
        return page
    end

    return page
end

local function CreateToggle(Parent, Text, Var)
    local Btn = Instance.new("TextButton")
    Btn.Parent = Parent
    Btn.BackgroundColor3 = Theme.Item
    Btn.Size = UDim2.new(1, -10, 0, 35)
    Btn.Text = ""
    Btn.AutoButtonColor = false

    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

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
    Instance.new("UICorner", IndBg).CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame", IndBg)
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = UDim2.new(0, 2, 0.5, -7)
    Dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    -- sync initial state
    if G[Var] then
        Dot.Position = UDim2.new(1, -16, 0.5, -7)
        Dot.BackgroundColor3 = Color3.new(1, 1, 1)
        IndBg.BackgroundColor3 = Theme.Purple
    end

    Btn.MouseButton1Click:Connect(function()
        G[Var] = not G[Var]
        if G[Var] then
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
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

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
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)

    if IsNumber then
        InputBox.FocusLost:Connect(function()
            if not tonumber(InputBox.Text) then
                InputBox.Text = tostring(Default)
            end
        end)
    end

    return InputBox
end

-- =========================================================
-- CHAT SENDERS
-- =========================================================
local function GhostTypeSmooth(msg)
    pcall(function()
        State.VIM:SendKeyEvent(true, Enum.KeyCode.Slash, false, game)
        State.VIM:SendKeyEvent(false, Enum.KeyCode.Slash, false, game)

        local box
        local start = os.clock()
        repeat
            box = State.UIS:GetFocusedTextBox()
            task.wait(0.05)
        until box or (os.clock() - start) > 5

        if box then
            box.Text = msg
            task.wait(0.03)
            State.VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            State.VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end
    end)
end

local function WaitChatReady(timeout)
    local t0 = os.clock()
    while (os.clock() - t0) < (timeout or 8) do
        if State.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = State.TextChatService:FindFirstChild("TextChannels")
            if channels and channels:FindFirstChildWhichIsA("TextChannel") then
                return true
            end
        else
            local events = State.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if events and events:FindFirstChild("SayMessageRequest") then
                return true
            end
        end
        task.wait(0.2)
    end
    return false
end

local function ResolveTextChannel()
    if State.TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
        return nil
    end

    local channel = nil
    pcall(function()
        if State.TextChatService.ChatInputBarConfiguration then
            channel = State.TextChatService.ChatInputBarConfiguration.TargetTextChannel
        end
    end)

    if not channel then
        local channels = State.TextChatService:FindFirstChild("TextChannels")
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

    -- 1) TextChatService
    if State.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = ResolveTextChannel()
        if not channel then return false, "TextChannel tidak ketemu" end

        local ok, err = pcall(function()
            channel:SendAsync(msg)
        end)
        if ok then return true else return false, tostring(err) end
    end

    -- 2) Legacy
    local events = State.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local say = events and events:FindFirstChild("SayMessageRequest")
    if say then
        say:FireServer(msg, "All")
        return true
    end

    -- 3) UI fallback
    GhostTypeSmooth(msg)
    return true
end

-- =========================================================
-- QUEUE + BACKOFF (anti macet di world rame)
-- =========================================================
if not State.ChatSender then
    State.ChatSender = {
        Queue = {},
        Sending = false,
        MinDelay = 2,
        MaxDelay = 25,
        Backoff = 0,
        LastSendAt = 0,
        Debug = false, -- set true kalau mau lihat warn debug
    }
end

local ChatSender = State.ChatSender

local function dprint(...)
    if ChatSender.Debug then warn("[AutoChat]", ...) end
end

function ChatSender:GetBaseDelay()
    local raw = tonumber(G.DelayTextBoxInstance and G.DelayTextBoxInstance.Text) or 5
    if raw < self.MinDelay then raw = self.MinDelay end
    return raw
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

    while G.AutoChatEnabled do
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
            table.insert(self.Queue, 1, msg) -- retry message yang sama
            task.wait(math.min(self.MaxDelay, 2 + self.Backoff))
        end

        task.wait(0.05)
    end

    self.Sending = false
end

-- =========================================================
-- UI MOUNT (anti di-clear / anti tidak muncul)
-- =========================================================
State.UI_MOUNT_NAME = "ZonHub_AutoChatControls"
State.CurrentPage = TargetPage

function State:Mount(page)
    self.CurrentPage = page
    local container = ResolveContainer(page)
    if not container or not container.Parent then
        return false
    end

    -- kalau sudah ada holder, jangan bikin dobel
    if container:FindFirstChild(self.UI_MOUNT_NAME) then
        return true
    end

    -- holder biar aman dari rebuild/clear internal
    local Holder = Instance.new("Frame")
    Holder.Name = self.UI_MOUNT_NAME
    Holder.Parent = container
    Holder.BackgroundTransparency = 1
    Holder.Size = UDim2.new(1, 0, 0, 0)
    Holder.AutomaticSize = Enum.AutomaticSize.Y

    local List = Instance.new("UIListLayout", Holder)
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 8)

    local Pad = Instance.new("UIPadding", Holder)
    Pad.PaddingTop = UDim.new(0, 8)
    Pad.PaddingLeft = UDim.new(0, 5)
    Pad.PaddingRight = UDim.new(0, 5)

    -- build controls
    CreateToggle(Holder, "Start Auto Chat", "AutoChatEnabled")
    G.ChatTextBoxInstance = CreateTextBox(Holder, "Isi Pesan Chat", "ZonHub On Top!", false)
    G.DelayTextBoxInstance = CreateTextBox(Holder, "Delay (Detik)", "5", true)

    return true
end

-- mount cepat tapi aman (biar tidak kalah sama UI builder ZonHub)
safe(function()
    task.defer(function()
        for i = 1, 40 do
            if State:Mount(TargetPage) then break end
            task.wait(0.1)
        end
    end)
end)

-- watchdog UI (kalau tab/page di-refresh, kontrol muncul lagi)
if not State._ui_watchdog then
    State._ui_watchdog = true
    task.spawn(function()
        while task.wait(1) do
            local page = State.CurrentPage
            if page then
                local container = ResolveContainer(page)
                if container and container.Parent then
                    if not container:FindFirstChild(State.UI_MOUNT_NAME) then
                        safe(function()
                            State:Mount(page)
                        end)
                    end
                end
            end
        end
    end)
end

-- =========================================================
-- MAIN LOOP (tidak numpuk queue)
-- =========================================================
if not State._main_loop then
    State._main_loop = true
    task.spawn(function()
        while task.wait(0.25) do
            if G.AutoChatEnabled then
                local pesan = (G.ChatTextBoxInstance and G.ChatTextBoxInstance.Text) or ""
                if pesan ~= "" then
                    -- biar tidak numpuk: push hanya kalau queue kosong
                    if #ChatSender.Queue == 0 and not ChatSender.Sending then
                        ChatSender:Push(pesan)
                    elseif #ChatSender.Queue == 0 and ChatSender.Sending then
                        -- sender lagi jalan tapi queue kosong (boleh push 1)
                        ChatSender:Push(pesan)
                    end
                end
            end
        end
    end)
end
