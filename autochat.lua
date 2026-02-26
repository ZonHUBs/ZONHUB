-- ========================================== --
-- SMART SEND v2 (Queue + Backoff + Re-resolve)
-- ========================================== --

local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChatSender = {
    Queue = {},
    Sending = false,
    MinDelay = 2,        -- delay minimum aman
    MaxDelay = 25,       -- batas backoff
    Backoff = 0,         -- tambahan delay dinamis saat gagal
    LastSendAt = 0,
    Debug = true,
}

local function dprint(...)
    if ChatSender.Debug then
        warn("[AutoChat]", ...)
    end
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
    -- selalu resolve ulang (biar aman setelah pindah world / rame)
    if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
        return nil
    end

    local channel = nil

    local ok = pcall(function()
        if TextChatService.ChatInputBarConfiguration then
            channel = TextChatService.ChatInputBarConfiguration.TargetTextChannel
        end
    end)

    if not ok then channel = nil end

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

    -- Pastikan chat sudah siap (sering kejadian pas masuk world rame)
    if not WaitChatReady(6) then
        return false, "Chat belum ready"
    end

    -- 1) TextChatService (chat baru)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = ResolveTextChannel()
        if not channel then
            return false, "TextChannel tidak ketemu"
        end

        local ok, err = pcall(function()
            channel:SendAsync(msg)
        end)

        if ok then
            return true
        else
            return false, tostring(err)
        end
    end

    -- 2) Legacy chat
    local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local say = events and events:FindFirstChild("SayMessageRequest")
    if say then
        say:FireServer(msg, "All")
        return true
    end

    -- 3) Fallback terakhir: ghost typing UI
    GhostTypeSmooth(msg)
    return true
end

function ChatSender:Push(msg)
    table.insert(self.Queue, tostring(msg))
    if not self.Sending then
        task.spawn(function()
            self:Process()
        end)
    end
end

function ChatSender:GetBaseDelay()
    local rawDelay = tonumber(getgenv().DelayTextBoxInstance and getgenv().DelayTextBoxInstance.Text) or 5
    if rawDelay < self.MinDelay then rawDelay = self.MinDelay end
    return rawDelay
end

function ChatSender:IncreaseBackoff(reason)
    -- backoff naik kalau gagal (anti macet di server rame / floodcheck)
    if self.Backoff <= 0 then
        self.Backoff = 2
    else
        self.Backoff = math.min(self.MaxDelay, math.floor(self.Backoff * 1.5 + 1))
    end
    dprint("Send gagal:", reason, "| Backoff jadi:", self.Backoff)
end

function ChatSender:DecreaseBackoff()
    -- kalau sukses, backoff turun pelan-pelan
    if self.Backoff > 0 then
        self.Backoff = math.max(0, self.Backoff - 1)
    end
end

function ChatSender:Process()
    self.Sending = true

    while getgenv().AutoChatEnabled do
        local msg = table.remove(self.Queue, 1)
        if not msg then break end

        -- delay = user delay + backoff
        local delay = self:GetBaseDelay() + self.Backoff

        -- jaga jarak antar kirim (biar gak ketabrak throttle)
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
            -- kalau gagal, masukin lagi ke depan queue biar dicoba lagi
            table.insert(self.Queue, 1, msg)
            task.wait(math.min(self.MaxDelay, 2 + self.Backoff))
        end

        task.wait(0.05)
    end

    self.Sending = false
end

-- ========================================== --
-- LOOP BARU (lebih stabil)
-- ========================================== --
task.spawn(function()
    while true do
        task.wait(0.2)

        if getgenv().AutoChatEnabled then
            local pesan = (getgenv().ChatTextBoxInstance and getgenv().ChatTextBoxInstance.Text) or ""
            if pesan ~= "" then
                -- push ke queue, biar pengiriman diatur sistem backoff
                ChatSender:Push(pesan)

                -- jangan push terlalu sering ke queue
                task.wait(0.8)
            end
        else
            task.wait(0.6)
        end
    end
end)
