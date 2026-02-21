-- [[ ZONHUB - PABRIK MODULE (INJECTED) ]] --
local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari ZonIndex!") return end

getgenv().ScriptVersion = "Pabrik v0.50-SweepFix" 

-- ========================================== --
-- [[ SETTING KECEPATAN ]]
getgenv().PlaceDelay = 0.05 
getgenv().BreakDelay = 0.05 
getgenv().DropDelay = 0.5     
getgenv().StepDelay = 0.1   
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser") 

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

-- [[ VARIABEL GLOBAL ]] --
getgenv().GridSize = 4.5; getgenv().HitCount = 4    
getgenv().EnablePabrik = false
getgenv().PabrikStartX = 0; getgenv().PabrikEndX = 10; getgenv().PabrikYPos = 37
getgenv().GrowthTime = 30
getgenv().BreakPosX = 0; getgenv().BreakPosY = 0
getgenv().DropPosX = 0; getgenv().DropPosY = 0

getgenv().BlockThreshold = 0 
getgenv().KeepSeedAmt = 20    

getgenv().SelectedSeed = ""; getgenv().SelectedBlock = "" 

-- Modul Game Internal --
local InventoryMod
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)

local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

local function GetSlotByItemID(targetID)
    if not InventoryMod or not InventoryMod.Stacks then return nil end
    for slotIndex, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            if not data.Amount or data.Amount > 0 then return slotIndex end
        end
    end
    return nil
end

local function GetItemAmountByID(targetID)
    local total = 0
    if not InventoryMod or not InventoryMod.Stacks then return total end
    for _, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            total = total + (data.Amount or 1)
        end
    end
    return total
end

local function ScanAvailableItems()
    local items = {}; local dict = {}
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for _, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and data.Id then
                    local itemID = tostring(data.Id)
                    if not dict[itemID] then dict[itemID] = true; table.insert(items, itemID) end
                end
            end
        end
    end)
    if #items == 0 then items = {"Kosong"} end
    return items
end

-- SISTEM DROP 
local function DropItemLogic(targetID, dropAmount)
    local slot = GetSlotByItemID(targetID)
    if not slot then return false end
    local dropRemote = RS:WaitForChild("Remotes"):FindFirstChild("PlayerDrop") or RS:WaitForChild("Remotes"):FindFirstChild("PlayerDropItem")
    local promptRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):FindFirstChild("UIPromptEvent")
    
    if dropRemote and promptRemote then
        pcall(function() dropRemote:FireServer(slot) end)
        task.wait(0.2) 
        pcall(function() promptRemote:FireServer({ ButtonAction = "drp", Inputs = { amt = tostring(dropAmount) } }) end)
        task.wait(0.1)
        
        pcall(function()
            for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
                if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then
                    gui.Visible = false
                end
            end
        end)
        return true
    end
    return false
end

-- Fix UI Global 
local function ForceRestoreUI()
    pcall(function()
        if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
        end
    end)
    task.wait(0.1)
    pcall(function()
        if UIManager then
            if type(UIManager.ShowHUD) == "function" then UIManager:ShowHUD() end
            if type(UIManager.ShowUI) == "function" then UIManager:ShowUI() end
        end
    end)
    pcall(function()
        local targetUIs = { "topbar", "gems", "playerui", "hotbar", "crosshair", "mainhud", "stats", "inventory", "backpack", "menu", "bottombar", "buttons" }
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") or gui:IsA("ScreenGui") or gui:IsA("ImageLabel") then
                local gName = string.lower(gui.Name)
                for _, tName in ipairs(targetUIs) do
                    if string.find(gName, tName) and not string.find(gName, "prompt") then
                        if gui:IsA("ScreenGui") then gui.Enabled = true else gui.Visible = true end
                    end
                end
            end
        end
    end)
    pcall(function()
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") and string.find(string.lower(gui.Text), "drop") then
                if gui.Parent then gui.Parent.Visible = true end
            end
        end
    end)
end

local function WalkToGrid(tX, tY, isPabrik)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    if not MyHitbox then return end

    local startZ = MyHitbox.Position.Z
    local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
    local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)

    while (currentX ~= tX or currentY ~= tY) do
        if isPabrik and not getgenv().EnablePabrik then break end
        if currentX ~= tX then currentX = currentX + (tX > currentX and 1 or -1)
        elseif currentY ~= tY then currentY = currentY + (tY > currentY and 1 or -1) end
        
        local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ)
        MyHitbox.CFrame = CFrame.new(newWorldPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end
        task.wait(getgenv().StepDelay)
    end
end

-- [[ UI SETUP (INJECTED KE TARGET PAGE) ]] --
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }

function CreateToggle(Parent, Text, Var) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); local T = Instance.new("TextLabel", Btn); T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); local IC = Instance.new("UICorner", IndBg); IC.CornerRadius = UDim.new(1,0); local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); local DC = Instance.new("UICorner", Dot); DC.CornerRadius = UDim.new(1,0); Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end end) end
function CreateTextBox(Parent, Text, Default, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6); local Label = Instance.new("TextLabel", Frame); Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local InputBox = Instance.new("TextBox", Frame); InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); local IC = Instance.new("UICorner", InputBox); IC.CornerRadius = UDim.new(0, 4); InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end end); return InputBox end
function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); Btn.MouseButton1Click:Connect(Callback) end
function CreateDropdown(Parent, Text, DefaultOptions, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Frame.ClipsDescendants = true; local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6); local TopBtn = Instance.new("TextButton", Frame); TopBtn.Size = UDim2.new(1, 0, 0, 35); TopBtn.BackgroundTransparency = 1; TopBtn.Text = ""; local Label = Instance.new("TextLabel", TopBtn); Label.Text = Text .. ": Not Selected"; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 11; Label.Size = UDim2.new(1, -20, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left; local Icon = Instance.new("TextLabel", TopBtn); Icon.Text = "v"; Icon.TextColor3 = Theme.Purple; Icon.Font = Enum.Font.GothamBold; Icon.TextSize = 12; Icon.Size = UDim2.new(0, 20, 1, 0); Icon.Position = UDim2.new(1, -25, 0, 0); Icon.BackgroundTransparency = 1; local Scroll = Instance.new("ScrollingFrame", Frame); Scroll.Position = UDim2.new(0,0,0,35); Scroll.Size = UDim2.new(1,0,1,-35); Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = Theme.Purple; local List = Instance.new("UIListLayout", Scroll); local isOpen = false; TopBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; if isOpen then Frame:TweenSize(UDim2.new(1, -10, 0, 110), "Out", "Quad", 0.2, true); Icon.Text = "^" else Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end end); local function RefreshOptions(Options) for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end; for _, opt in ipairs(Options) do local OptBtn = Instance.new("TextButton", Scroll); OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); OptBtn.TextColor3 = Theme.Text; OptBtn.Text = tostring(opt); OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 11; OptBtn.MouseButton1Click:Connect(function() getgenv()[Var] = opt; Label.Text = Text .. ": " .. tostring(opt); isOpen = false; Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end) end; Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 25) end; RefreshOptions(DefaultOptions); return RefreshOptions end

-- [[ INJECT MENU KE TARGET PAGE ]] --
local RefreshSeedDropdown = CreateDropdown(TargetPage, "Pilih Seed", ScanAvailableItems(), "SelectedSeed")
local RefreshBlockDropdown = CreateDropdown(TargetPage, "Pilih Block", ScanAvailableItems(), "SelectedBlock")
CreateButton(TargetPage, "🔄 Refresh Tas", function() local newItems = ScanAvailableItems(); RefreshSeedDropdown(newItems); RefreshBlockDropdown(newItems) end)

CreateTextBox(TargetPage, "Start X", getgenv().PabrikStartX, "PabrikStartX")
CreateTextBox(TargetPage, "End X", getgenv().PabrikEndX, "PabrikEndX")
CreateTextBox(TargetPage, "Y Pos", getgenv().PabrikYPos, "PabrikYPos")

CreateTextBox(TargetPage, "Block Threshold", getgenv().BlockThreshold, "BlockThreshold")
CreateTextBox(TargetPage, "Keep Seed Amt", getgenv().KeepSeedAmt, "KeepSeedAmt")

CreateButton(TargetPage, "Set Break Pos", function() local H = workspace.Hitbox:FindFirstChild(LP.Name) if H then getgenv().BreakPosX = math.floor(H.Position.X/4.5+0.5); getgenv().BreakPosY = math.floor(H.Position.Y/4.5+0.5) end end)
CreateButton(TargetPage, "Set Drop Pos", function() local H = workspace.Hitbox:FindFirstChild(LP.Name) if H then getgenv().DropPosX = math.floor(H.Position.X/4.5+0.5); getgenv().DropPosY = math.floor(H.Position.Y/4.5+0.5) end end)
CreateToggle(TargetPage, "START BALANCED PABRIK", "EnablePabrik")

-- [[ LOGIC BALANCED TURBO + SMART DROP/REFILL ]] --
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")
local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

task.spawn(function()
    while true do
        if getgenv().EnablePabrik then
            if getgenv().SelectedSeed == "" or getgenv().SelectedBlock == "" then task.wait(2); continue end

            -- FASE 1: PLANTING
            WalkToGrid(getgenv().PabrikStartX, getgenv().PabrikYPos, true); task.wait(0.5)
            for x = getgenv().PabrikStartX, getgenv().PabrikEndX do
                if not getgenv().EnablePabrik then break end
                local seedSlot = GetSlotByItemID(getgenv().SelectedSeed)
                if not seedSlot then break end
                
                WalkToGrid(x, getgenv().PabrikYPos, true); task.wait(0.1) 
                RemotePlace:FireServer(Vector2.new(x, getgenv().PabrikYPos), seedSlot); task.wait(getgenv().PlaceDelay)
            end

            -- FASE 2: WAITING
            if getgenv().EnablePabrik then for w = 1, getgenv().GrowthTime do if not getgenv().EnablePabrik then break end; task.wait(1) end end

            -- FASE 3: HARVESTING (DENGAN AUTO-COLLECT SWEEP)
            if getgenv().EnablePabrik then
                WalkToGrid(getgenv().PabrikStartX, getgenv().PabrikYPos, true); task.wait(0.5)
                for x = getgenv().PabrikStartX, getgenv().PabrikEndX do
                    if not getgenv().EnablePabrik then break end
                    WalkToGrid(x, getgenv().PabrikYPos, true); task.wait(0.1) 
                    local TGrid = Vector2.new(x, getgenv().PabrikYPos)
                    for hit = 1, getgenv().HitCount do RemoteBreak:FireServer(TGrid); task.wait(getgenv().BreakDelay) end
                    task.wait(0.1) 
                end
                
                -- [[ LOGIKA SAPU BERSIH TAMBAHAN ]]
                if getgenv().EnablePabrik then
                    -- Nentuin arah: kalau start lebih kecil dari end, maju ke depan. Kalau sebaliknya, maju ke belakang.
                    local moveDirection = (getgenv().PabrikEndX >= getgenv().PabrikStartX) and 1 or -1
                    local sweepPosX = getgenv().PabrikEndX + moveDirection
                    
                    -- Jalan 1 langkah ke depan buat ambil sisa block/seed
                    WalkToGrid(sweepPosX, getgenv().PabrikYPos, true)
                    task.wait(0.6) -- Nunggu sebentar biar magnet karakter nyedot semua drop
                end
            end

            -- FASE 4: TURBO BREAK & PLACE (STACKING)
            if getgenv().EnablePabrik then
                WalkToGrid(getgenv().BreakPosX, getgenv().BreakPosY, true); task.wait(0.5)
                local BreakTarget = Vector2.new(getgenv().BreakPosX - 1, getgenv().BreakPosY)
                local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name)

                local Breaking = true
                task.spawn(function()
                    while Breaking and getgenv().EnablePabrik do
                        RemoteBreak:FireServer(BreakTarget)
                        task.wait(0.05) 
                    end
                end)

                while getgenv().EnablePabrik do
                    local currentAmt = GetItemAmountByID(getgenv().SelectedBlock)
                    if currentAmt <= getgenv().BlockThreshold then break end
                    
                    local blockSlot = GetSlotByItemID(getgenv().SelectedBlock)
                    if blockSlot then RemotePlace:FireServer(BreakTarget, blockSlot) end
                    
                    task.wait(0.25)
                    
                    if MyHitbox then
                        local oldCF = MyHitbox.CFrame
                        MyHitbox.CanCollide = false
                        MyHitbox.CFrame = CFrame.new((getgenv().BreakPosX - 1) * 4.5, getgenv().BreakPosY * 4.5, oldCF.Position.Z)
                        task.wait(0.05)
                        MyHitbox.CFrame = oldCF
                        MyHitbox.CanCollide = true
                    end
                    task.wait(0.05)
                end
                
                if getgenv().EnablePabrik then task.wait(2.5) end
                Breaking = false 
                
                task.wait(0.2)
                if MyHitbox then
                    local oldCF = MyHitbox.CFrame
                    MyHitbox.CanCollide = false
                    MyHitbox.CFrame = CFrame.new((getgenv().BreakPosX - 1) * 4.5, getgenv().BreakPosY * 4.5, oldCF.Position.Z)
                    task.wait(0.2)
                    MyHitbox.CFrame = oldCF
                    MyHitbox.CanCollide = true
                end
            end

            -- FASE 5: AUTO DROP & REFILL (SMART STORAGE)
            if getgenv().EnablePabrik then 
                local currentSeedAmt = GetItemAmountByID(getgenv().SelectedSeed)
                
                if currentSeedAmt ~= getgenv().KeepSeedAmt then
                    WalkToGrid(getgenv().DropPosX, getgenv().DropPosY, true)
                    task.wait(1.5) 
                    
                    while getgenv().EnablePabrik do
                        local current = GetItemAmountByID(getgenv().SelectedSeed)
                        local toDrop = current - getgenv().KeepSeedAmt
                        
                        if toDrop <= 0 then break end
                        
                        local dropNow = math.min(toDrop, 200)
                        local success = DropItemLogic(getgenv().SelectedSeed, dropNow)
                        
                        if success then
                            task.wait(getgenv().DropDelay + 0.3) 
                        else
                            break 
                        end
                    end
                    
                    ForceRestoreUI()
                end
            end
        end
        task.wait(1)
    end
end)
