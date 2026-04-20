local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"

local Library     = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Azoxx's Lua | Full Suite",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    UnlockMouseWhileOpen = true,
    Size = UDim2.new(0, 590, 0, 520),
})

Library:SetWatermark("Azoxx-Lua")
Library:SetWatermarkVisibility(true)

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyTheme("Purple")

local Tabs = {
    Main  = Window:AddTab("Combat & Movement"),
    Orbit = Window:AddTab("Orbit Settings"),
    Misc  = Window:AddTab("Misc"),
}

local player = game:GetService("Players").LocalPlayer
local character, root, humanoid
local tickCounter = 0
local voidEnabled = false
local voidStrength = 50000 

local orbitEnabled = false
local orbitMode = "Closest Enemy"
local orbitSpeed = 15000
local orbitDistance = 18

local bulletTPEnabled = false
local hitRate = 100

local function setupChar()
    character = player.Character or player.CharacterAdded:Wait()
    root = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            part.CanCollide = false
        end
    end
end
setupChar()
player.CharacterAdded:Connect(setupChar)

-- [ MAIN TAB ] --
local Movement = Tabs.Main:AddLeftGroupbox("Anti-Aim / Void")
Movement:AddToggle("VoidToggle", { Text = "Void Spam", Default = false }):OnChanged(function(v) voidEnabled = v end)
Movement:AddSlider("VoidSlider", { Text = "Desync Strength", Default = 50000, Min = 500, Max = 1000000, Rounding = 0 })

local Combat = Tabs.Main:AddRightGroupbox("Combat")
Combat:AddToggle("BulletTP", { Text = "Silent Aim (Bullet TP)", Default = false }):OnChanged(function(v) bulletTPEnabled = v end)
Combat:AddSlider("HitRate", { Text = "Hit Rate %", Default = 100, Min = 0, Max = 100, Rounding = 0 })

-- [ ORBIT TAB ] --
local OrbitBox = Tabs.Orbit:AddLeftGroupbox("Orbit Control")
OrbitBox:AddToggle("OrbitToggle", { Text = "Enable Orbit", Default = false }):OnChanged(function(v) orbitEnabled = v end)
OrbitBox:AddSlider("OrbitSpeed", { Text = "Speed", Default = 15000, Min = 0, Max = 50000, Rounding = 0 })
OrbitBox:AddSlider("OrbitDistance", { Text = "Distance", Default = 18, Min = 5, Max = 50, Rounding = 1 })

-- [ MISC TAB ] --
local function applyAntiReload()
    pcall(function()
        local ItemLibrary = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary)
        local Items = rawget(ItemLibrary, "Items")
        if Items then
            for _, item in pairs(Items) do
                local name = (item.Name or ""):lower()
                if name == "bow" or name == "daggers" or name == "slingshot" then
                    if item.ReloadLength then item.ReloadLength = (name == "daggers" and 0.09 or 0) end
                end
            end
        end
    end)
end

local MiscBox = Tabs.Misc:AddLeftGroupbox("Weapon Tweaks")
MiscBox:AddToggle("AntiReload", { Text = "Instant Reload", Default = false }):OnChanged(function(v) if v then applyAntiReload() end end)
MiscBox:AddToggle("FastFire", { Text = "Fast Fire Rate", Default = false })

-- [ CORE LOGIC ] --
local RunService = game:GetService("RunService")
local angle = 0

RunService.Heartbeat:Connect(function(dt)
    if not root or not root.Parent then return end
    tickCounter = (tickCounter + 1) % 10

    if orbitEnabled or voidEnabled then
        root.Velocity = Vector3.new(0, -Options.VoidSlider.Value, 0)
        root.RotVelocity = Vector3.new(5000, 5000, 5000)
        if humanoid then
            humanoid.PlatformStand = true
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end

    local targetPos = nil

    if orbitEnabled then
        local targetRoot = nil
        local closestDist = math.huge
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if not (player.Team and p.Team and player.Team == p.Team) then
                    local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        targetRoot = p.Character.HumanoidRootPart
                    end
                end
            end
        end

        if targetRoot then
            angle = angle + (Options.OrbitSpeed.Value / 650) * dt
            local jitter = (math.random() - 0.5) * 3 -- Anti-prediction jitter
            local ox = (Options.OrbitDistance.Value + jitter) * math.cos(angle)
            local oz = (Options.OrbitDistance.Value + jitter) * math.sin(angle)
            targetPos = targetRoot.Position + Vector3.new(ox, 8, oz)
        end
    elseif voidEnabled then
        targetPos = root.Position + Vector3.new(math.random(-25,25), -math.random(400, 1000), math.random(-25,25))
    end

    if targetPos then
        if tickCounter % 2 == 0 then
            root.CFrame = CFrame.new(0, 9e12, 0)
        else
            root.CFrame = CFrame.new(targetPos)
        end
    end

    -- Bullet TP Logic
    if bulletTPEnabled then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") and obj.Velocity.Magnitude > 5 then
                local n = obj.Name:lower()
                if n:find("arrow") or n:find("bullet") or n:find("projectile") then
                    -- Simple target check
                    for _, p in ipairs(game.Players:GetPlayers()) do
                        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            if math.random(1, 100) <= Options.HitRate.Value then
                                obj.CFrame = p.Character.HumanoidRootPart.CFrame
                            end
                        end
                    end
                end
            end
        end
    end
end)

Library:Notify("Azoxx-Lua")
