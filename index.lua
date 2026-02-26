-- [[ ZONHUB - INDEX LOADER V.0.60 (MODERNIZED UI) ]] --

getgenv().HubVersion = "1.0.2" 

local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local LP = Players.LocalPlayer

pcall(function() if getgenv().ZonIndexUI then getgenv().ZonIndexUI:Destroy() end end)

-- [[ SETUP UI UTAMA ]] --
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "ZonHubIndex"
pcall(function() ScreenGui.Parent = CoreGui end); if not ScreenGui.Parent then ScreenGui.Parent = LP.PlayerGui end
ScreenGui.ResetOnSpawn = false; getgenv().ZonIndexUI = ScreenGui 

-- Skema Warna Modern (Deep Dark & Neon Indigo Accent)
local Theme = { 
    Bg = Color3.fromRGB(20, 22, 26), 
    Header = Color3.fromRGB(13, 15, 18), 
    Item = Color3.fromRGB(32, 35, 42), 
    Text = Color3.fromRGB(240, 245, 255), 
    SubText = Color3.fromRGB(160, 165, 175),
    Purple = Color3.fromRGB(115, 85, 255), 
    Discord = Color3.fromRGB(88, 101, 242)
}

-- Tombol Logo (Minimized)
local ZONBtn = Instance.new("TextButton", ScreenGui); ZONBtn.BackgroundColor3 = Theme.Bg; ZONBtn.Position = UDim2.new(0.1, 0, 0.1, 0); ZONBtn.Size = UDim2.new(0, 50, 0, 50); ZONBtn.Text = "ZON"; ZONBtn.TextColor3 = Theme.Purple; ZONBtn.Font = Enum.Font.GothamBlack; ZONBtn.TextSize = 18; ZONBtn.Visible = false; ZONBtn.AutoButtonColor = false
Instance.new("UICorner", ZONBtn).CornerRadius = UDim.new(1, 0)
local BtnStroke = Instance.new("UIStroke", ZONBtn); BtnStroke.Color = Theme.Purple; BtnStroke.Thickness = 2; BtnStroke.Transparency = 0.2

-- Frame Utama
local Main = Instance.new("Frame", ScreenGui); Main.BackgroundColor3 = Theme.Bg; Main.Position = UDim2.new(0.5, -250, 0.5, -160); Main.Size = UDim2.new(0, 550, 0, 340)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Theme.Purple; MainStroke.Thickness = 1.5; MainStroke.Transparency = 0.4

-- Fungsi Drag (Dipertahankan dari aslinya)
local function MakeDraggable(frame, trigger) 
    local dragging, dragInput, dragStart, startPos
    trigger.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) 
        end 
    end)
    trigger.InputChanged:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end 
    end)
    UIS.InputChanged:Connect(function(input) 
        if input == dragInput and dragging then 
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
        end 
    end) 
end
MakeDraggable(Main, Main); MakeDraggable(ZONBtn, ZONBtn)

-- Header
local Header = Instance.new("Frame", Main); Header.BackgroundColor3 = Theme.Header; Header.Size = UDim2.new(1, 0, 0, 45); Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
local HeaderHide = Instance.new("Frame", Header); HeaderHide.BackgroundColor3 = Theme.Header; HeaderHide.Size = UDim2.new(1, 0, 0.5, 0); HeaderHide.Position = UDim2.new(0, 0, 0.5, 0); HeaderHide.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header); Title.Text = "ZONHUB"; Title.TextColor3 = Theme.Text; Title.Font = Enum.Font.GothamBlack; Title.TextSize = 18; Title.Size = UDim2.new(0.4, 0, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local TitleVer = Instance.new("TextLabel", Header); TitleVer.Text = getgenv().HubVersion; TitleVer.TextColor3 = Theme.Purple; TitleVer.Font = Enum.Font.GothamBold; TitleVer.TextSize = 12; TitleVer.Size = UDim2.new(0, 50, 1, 0); TitleVer.Position = UDim2.new(0, 105, 0, 1); TitleVer.BackgroundTransparency = 1; TitleVer.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Header (Discord & Minimize)
local DiscordBtn = Instance.new("TextButton", Header); DiscordBtn.Size = UDim2.new(0, 100, 0, 28); DiscordBtn.Position = UDim2.new(1, -150, 0.5, -14); DiscordBtn.Text = "Join Discord"; DiscordBtn.BackgroundColor3 = Theme.Discord; DiscordBtn.TextColor3 = Color3.new(1,1,1); DiscordBtn.Font = Enum.Font.GothamBold; DiscordBtn.TextSize = 12; DiscordBtn.AutoButtonColor = false
Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 6)
DiscordBtn.MouseButton1Click:Connect(function() pcall(function() setclipboard("https://discord.gg/feFrHDXQBp") end) end)

local MinBtn = Instance.new("TextButton", Header); MinBtn.Size = UDim2.new(0, 32, 0, 28); MinBtn.Position = UDim2.new(1, -42, 0.5, -14); MinBtn.Text = "—"; MinBtn.BackgroundColor3 = Theme.Item; MinBtn.TextColor3 = Theme.Text; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 12; MinBtn.AutoButtonColor = false
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Efek Hover untuk Tombol Header
local function ApplyHover(button, originalColor, hoverColor)
    button.MouseEnter:Connect(function() TS:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play() end)
    button.MouseLeave:Connect(function() TS:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play() end)
end
ApplyHover(DiscordBtn, Theme.Discord, Color3.fromRGB(105, 118, 255))
ApplyHover(MinBtn, Theme.Item, Color3.fromRGB(45, 48, 55))

-- Fungsi Toggle UI
local function ToggleUI() 
    Main.Visible = not Main.Visible; ZONBtn.Visible = not Main.Visible
    if ZONBtn.Visible then ZONBtn.Position = UDim2.new(0, Main.AbsolutePosition.X, 0, Main.AbsolutePosition.Y) else Main.Position = UDim2.new(0, ZONBtn.AbsolutePosition.X, 0, ZONBtn.AbsolutePosition.Y) end 
end
MinBtn.MouseButton1Click:Connect(ToggleUI); ZONBtn.MouseButton1Click:Connect(ToggleUI)

-- [[ SISTEM TAB & INJECTION ]] --
local TabContainer = Instance.new("ScrollingFrame", Main); TabContainer.Size = UDim2.new(0, 140, 1, -45); TabContainer.Position = UDim2.new(0, 0, 0, 45); TabContainer.BackgroundColor3 = Theme.Header; TabContainer.BorderSizePixel = 0; TabContainer.ScrollBarThickness = 0
local TabPadding = Instance.new("UIPadding", TabContainer); TabPadding.PaddingTop = UDim.new(0, 10); TabPadding.PaddingBottom = UDim.new(0, 10)
local TabListLayout = Instance.new("UIListLayout", TabContainer); TabListLayout.Padding = UDim.new(0, 8); TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local PageContainer = Instance.new("Frame", Main); PageContainer.Size = UDim2.new(1, -150, 1, -55); PageContainer.Position = UDim2.new(0, 145, 0, 50); PageContainer.BackgroundTransparency = 1

local Tabs = {}; local Pages = {}

local function CreateAutoLoadTab(TabName, DescText, LoadLink)
    local TBtn = Instance.new("TextButton", TabContainer); TBtn.Size = UDim2.new(0.85, 0, 0, 36); TBtn.BackgroundColor3 = Theme.Item; TBtn.Text = TabName; TBtn.TextColor3 = Theme.SubText; TBtn.Font = Enum.Font.GothamMedium; TBtn.TextSize = 13; TBtn.AutoButtonColor = false
    Instance.new("UICorner", TBtn).CornerRadius = UDim.new(0, 6)
    
    local Page = Instance.new("ScrollingFrame", PageContainer); Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.BorderSizePixel = 0; Page.ScrollBarThickness = 4; Page.ScrollBarImageColor3 = Theme.Purple
    local PagePadding = Instance.new("UIPadding", Page); PagePadding.PaddingRight = UDim.new(0, 5)
    local PageLayout = Instance.new("UIListLayout", Page); PageLayout.Padding = UDim.new(0, 8); PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local LTitle = Instance.new("TextLabel", Page); LTitle.Size = UDim2.new(1,0,0,28); LTitle.BackgroundTransparency = 1; LTitle.Text = TabName .. " Module"; LTitle.TextColor3 = Theme.Purple; LTitle.Font = Enum.Font.GothamBold; LTitle.TextSize = 18; LTitle.TextXAlignment = Enum.TextXAlignment.Left
    local LDesc = Instance.new("TextLabel", Page); LDesc.Size = UDim2.new(1,0,0,30); LDesc.BackgroundTransparency = 1; LDesc.Text = DescText; LDesc.TextColor3 = Theme.SubText; LDesc.Font = Enum.Font.Gotham; LDesc.TextSize = 12; LDesc.TextWrapped = true; LDesc.TextXAlignment = Enum.TextXAlignment.Left; LDesc.TextYAlignment = Enum.TextYAlignment.Top
    
    local Div = Instance.new("Frame", Page); Div.Size = UDim2.new(1,0,0,1); Div.BackgroundColor3 = Theme.Item; Div.BorderSizePixel = 0
    
    local StatusLabel = Instance.new("TextLabel", Page); StatusLabel.Size = UDim2.new(1,0,0,35); StatusLabel.BackgroundTransparency = 1; StatusLabel.Text = "Klik tab di samping untuk memuat module..."; StatusLabel.TextColor3 = Theme.Text; StatusLabel.Font = Enum.Font.GothamMedium; StatusLabel.TextSize = 13
    
    local isLoaded = false 
    
    TBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, t in pairs(Tabs) do 
            TS:Create(t, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Item}):Play()
            t.TextColor3 = Theme.SubText 
            t.Font = Enum.Font.GothamMedium
        end
        Page.Visible = true
        TS:Create(TBtn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Purple}):Play()
        TBtn.TextColor3 = Color3.new(1,1,1)
        TBtn.Font = Enum.Font.GothamBold
        
        if not isLoaded and LoadLink ~= "" then
            StatusLabel.Text = "⏳ Sedang mengambil script..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
            isLoaded = true 
            
            task.spawn(function()
                local scriptCode = game:HttpGet(LoadLink)
                local func, compileErr = loadstring(scriptCode)
                
                if func then
                    local success, runErr = pcall(function()
                        func(Page) 
                    end)
                    
                    if success then
                        StatusLabel:Destroy() 
                    else
                        StatusLabel.Text = "❌ Gagal Jalan: " .. tostring(runErr)
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                    end
                else
                    StatusLabel.Text = "❌ Gagal Load Link Raw!"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
                end
            end)
        end
    end)
    table.insert(Tabs, TBtn); table.insert(Pages, Page); return Page, TBtn
end

CreateAutoLoadTab("Pabrik", "Memuat otomatis sistem Pabrik.", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Pabrik.lua")
CreateAutoLoadTab("Auto Farm", "Sistem farming resource (Kayu, Batu).", "https://raw.githubusercontent.com/Koziz/CAW-SCRIPT/refs/heads/main/Autofarm.lua") 
CreateAutoLoadTab("Manager", "Sistem Inventory & Sortir Barang.", "https://raw.githubusercontent.com/ZonHUBs/ZONHUB/refs/heads/main/manager.lua")
CreateAutoLoadTab("Auto Chat", "Auto Chat.", "https://raw.githubusercontent.com/ZonHUBs/ZONHUB/refs/heads/main/autochat.lua")
