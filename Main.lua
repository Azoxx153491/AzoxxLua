local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Azoxx-Lua",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    Size = UDim2.new(0, 550, 0, 600),
})

local MobileButton = Instance.new("ScreenGui")
local Button = Instance.new("TextButton")
local Corner = Instance.new("UICorner")
MobileButton.Name = "UniversalToggle"
MobileButton.Parent = game:GetService("CoreGui")
Button.Parent = MobileButton
Button.BackgroundColor3 = Color3.fromRGB(125, 0, 255)
Button.Position = UDim2.new(0, 10, 0.5, -25)
Button.Size = UDim2.new(0, 50, 0, 50)
Button.Text = "A"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextSize = 25
Button.Draggable = true
Button.Active = true
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Button
Button.MouseButton1Click:Connect(function() Library:Toggle() end)

local Tabs = {
    Main = Window:AddTab("Combat"),
    Movement = Window:AddTab("Movement"),
    Misc = Window:AddTab("Misc"),
}

local Combat = Tabs.Main:AddLeftGroupbox("Aimbot")
Combat:AddToggle("BulletTP", { Text = "Bullet TP", Default = false })
Combat:AddSlider("HitRate", { Text = "Accuracy %", Default = 100, Min = 0, Max = 100, Rounding = 0 })

local VoidBox = Tabs.Movement:AddLeftGroupbox("VoidSpam")
VoidBox:AddToggle("VoidToggle", { Text = "Enable VoidSpam", Default = false })
VoidBox:AddSlider("VoidX", { Text = "X Depth", Default = 25, Min = 0, Max = 100000000, Rounding = 0 })
VoidBox:AddSlider("VoidNX", { Text = "-X Depth", Default = 25, Min = 0, Max = 100000000, Rounding = 0 })
VoidBox:AddSlider("VoidY", { Text = "Y Depth", Default = 5000, Min = 0, Max = 100000000, Rounding = 0 })
VoidBox:AddSlider("VoidNY", { Text = "-Y Depth", Default = 5000, Min = 0, Max = 100000000, Rounding = 0 })

local OrbitBox = Tabs.Movement:AddRightGroupbox("Orbit")
OrbitBox:AddToggle("OrbitToggle", { Text = "Enable Orbit", Default = false })
OrbitBox:AddSlider("OrbitSpeed", { Text = "Speed", Default = 25000, Min = 0, Max = 100000, Rounding = 0 })
OrbitBox:AddSlider("OrbitDistance", { Text = "Distance", Default = 15, Min = 5, Max = 500, Rounding = 1 })

local MiscBox = Tabs.Misc:AddLeftGroupbox("Weapons")
MiscBox:AddToggle("AntiReload", { Text = "Instant Reload", Default = false })
MiscBox:AddToggle("FastShoot", { Text = "Fast Fire Rate", Default = false })

local SettingsBox = Tabs.Misc:AddRightGroupbox("Settings")
SettingsBox:AddLabel("Menu Bind"):AddKeyPicker("MenuKey", { Default = "F3", NoUI = true, Text = "Menu Keybind" })
Library.ToggleKeybind = Library.Options.MenuKey

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:ApplyTheme("Purple")
SaveManager:SetFolder('AzoxxLua')
SaveManager:BuildConfigSection(Tabs.Misc)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character, root, humanoid
local angle, tickCounter = 0, 0
local isReturning = false

local function setupChar(char)
    character = char or player.Character or player.CharacterAdded:Wait()
    root = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
end
setupChar()
player.CharacterAdded:Connect(setupChar)

local function GetClosestTarget()
    local closest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (p.Character.Head.Position - root.Position).Magnitude
                if d < dist then dist = d closest = p.Character.Head end
            end
        end
    end
    return closest
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local ItemLib = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary)
            local Items = rawget(ItemLib, "Items")
            if Items then
                for _, item in pairs(Items) do
                    local n = (item.Name or ""):lower()
                    local isFast = n:find("dagger") or n:find("sword") or n:find("knife")
                    local isProjectile = n:find("bow") or n:find("sling") or n:find("sniper") or n:find("gun")
                    
                    if Library.Toggles.AntiReload.Value then
                        item.ReloadLength = 0
                        item.ReloadTime = 0
                        item.ReloadSpeed = 1000
                        item.ChargeTime = 0
                        item.WindUp = 0
                        item.DrawTime = 0 
                    end
                    
                    if Library.Toggles.FastShoot.Value then
                        item.AttackInterval = (isFast and 0.1 or 0)
                        item.FireRate = 5000
                        item.Cooldown = (isFast and 0.1 or 0)
                        if isProjectile then item.ShotDelay = 0 end
                    end
                end
            end
        end)
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not root or isReturning then return end
    tickCounter = (tickCounter + 1) % 10
    local target = GetClosestTarget()
    local targetPos = nil

    if Library.Toggles.BulletTP.Value and target then
        for _, proj in ipairs(workspace:GetChildren()) do
            if proj:IsA("BasePart") then
                local n = proj.Name:lower()
                if n:find("bullet") or n:find("arrow") or n:find("projectile") or n:find("bolt") then
                    if math.random(1, 100) <= Library.Options.HitRate.Value then
                        proj.CFrame = target.CFrame
                        proj.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end
    end

    if Library.Toggles.OrbitToggle.Value and target then
        angle = angle + (Library.Options.OrbitSpeed.Value / 650) * dt
        local d = math.clamp(Library.Options.OrbitDistance.Value, 5, 500)
        targetPos = target.Position + Vector3.new(d * math.cos(angle), 10, d * math.sin(angle))
    elseif Library.Toggles.VoidToggle.Value then
        local x = math.random(-Library.Options.VoidNX.Value, Library.Options.VoidX.Value)
        local y = math.random(-Library.Options.VoidNY.Value, Library.Options.VoidY.Value)
        targetPos = root.Position + Vector3.new(x, y, math.random(-25, 25))
    end

    if Library.Toggles.OrbitToggle.Value or Library.Toggles.VoidToggle.Value then
        for _, v in ipairs(character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        root.Velocity = Vector3.new(0, 0, 0)
        if humanoid then humanoid.PlatformStand = true end
        if tickCounter % 2 == 0 then
            root.CFrame = CFrame.new(root.Position.X, 5000, root.Position.Z) 
        elseif targetPos then
            root.CFrame = CFrame.new(targetPos)
        end
    end
end)

Library:Notify("Azoxx-Lua")
