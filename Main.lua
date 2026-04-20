local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"

local Library     = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Azoxx's Lua",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    UnlockMouseWhileOpen = true,
    Size = UDim2.new(0, 590, 0, 520),
})

Library:SetWatermark("Azoxx's Lua")
Library:SetWatermarkVisibility(true)

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyTheme("Purple")

local Tabs = {
    Main  = Window:AddTab("Main"),
    Orbit = Window:AddTab("Orbit"),
    Misc  = Window:AddTab("Misc"),
}

local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local character, root, humanoid
local isShooting = false
local tickCounter = 0

local voidEnabled = false
local voidStrength = 2000000000

local orbitEnabled = false
local orbitMode = "Closest Enemy"
local selectedTarget = nil
local orbitSpeed = 15000
local orbitDistance = 18
local orbitHeight = 7.5
local useCustomHeight = false

local bulletTPEnabled = false
local hitRate = 100

local function setupChar()
    character = player.Character or player.CharacterAdded:Wait()
    root = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        end
    end
end
setupChar()
player.CharacterAdded:Connect(setupChar)

mouse.Button1Down:Connect(function() isShooting = true end)
mouse.Button1Up:Connect(function() isShooting = false end)

local Main = Tabs.Main:AddLeftGroupbox("Anti-Ragebot Movement")

Main:AddToggle("VoidToggle", { 
    Text = "Void Spam", 
    Default = false 
}):OnChanged(function(v) voidEnabled = v end)

Main:AddSlider("VoidSlider", {
    Text = "Void Spam Strength",
    Default = 2000000000,
    Min = 100,
    Max = 1e32,
    Rounding = 0,
    Compact = false,
}):OnChanged(function(v) 
    voidStrength = v 
    if v >= 1e32 then
        Options.VoidSlider:SetTitle("Void Spam Strength: INF")
    else
        Options.VoidSlider:SetTitle("Void Spam Strength")
    end
end)

local OrbitTab = Tabs.Orbit:AddLeftGroupbox("Orbit Control")

OrbitTab:AddDropdown("OrbitMode", {
    Text = "Orbit Mode",
    Values = {"Closest Enemy", "Specific Player"},
    Default = "Closest Enemy",
}):OnChanged(function(mode) orbitMode = mode end)

local playerNames = {}
local function updatePlayers()
    playerNames = {}
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(playerNames, p.Name)
        end
    end
    if #playerNames == 0 then table.insert(playerNames, "No players") end
end

updatePlayers()

local targetDropdown = OrbitTab:AddDropdown("SpecificTarget", {
    Text = "Choose Player to Orbit",
    Values = playerNames,
    Default = playerNames[1] or "No players",
})

targetDropdown:OnChanged(function(name)
    if orbitMode == "Specific Player" and name and name ~= "No players" then
        selectedTarget = game:GetService("Players"):FindFirstChild(name)
    end
end)

OrbitTab:AddToggle("OrbitToggle", { Text = "Enable Orbit", Default = false })
    :OnChanged(function(v) orbitEnabled = v end)

OrbitTab:AddSlider("OrbitSpeed", {
    Text = "Orbit Speed",
    Default = 15000,
    Min = 0,
    Max = 100000,
    Rounding = 0,
}):OnChanged(function(v) orbitSpeed = v end)

OrbitTab:AddSlider("OrbitDistance", {
    Text = "Orbit Distance",
    Default = 18,
    Min = 5,
    Max = 100,
    Rounding = 1,
}):OnChanged(function(v) orbitDistance = v end)

OrbitTab:AddToggle("UseCustomHeight", { 
    Text = "Custom Orbit Height", 
    Default = false 
}):OnChanged(function(v) useCustomHeight = v end)

OrbitTab:AddSlider("OrbitHeight", {
    Text = "Orbit Height",
    Default = 7.5,
    Min = -20,
    Max = 60,
    Rounding = 1,
}):OnChanged(function(v) orbitHeight = v end)

OrbitTab:AddButton("Refresh Player List", function()
    updatePlayers()
    targetDropdown:SetValues(playerNames)
end)

local Misc = Tabs.Misc:AddLeftGroupbox("Combat & Misc")

Misc:AddToggle("BulletTP", { 
    Text = "Silent Aim (Bullet TP)", 
    Default = false 
}):OnChanged(function(v) bulletTPEnabled = v end)

Misc:AddSlider("HitRate", {
    Text = "Hit Rate %",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
}):OnChanged(function(v) hitRate = v end)

local function applyAntiReload()
    pcall(function()
        local ItemLibrary = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary)
        local Items = rawget(ItemLibrary, "Items")
        if Items then
            for _, item in pairs(Items) do
                local name = (item.Name or ""):lower()
                if name == "bow" or name == "daggers" or name == "slingshot" then
                    if item.ReloadLength then
                        item.ReloadLength = (name == "daggers" and 0.09 or 0)
                    end
                end
            end
        end
    end)
end

Misc:AddToggle("AntiReload", { Text = "Anti Reload", Default = false })
    :OnChanged(function(v) if v then applyAntiReload() end end)

Misc:AddToggle("AntiOOB", { Text = "Anti Out of Bounds", Default = true })
Misc:AddToggle("FastFireRate", { Text = "Extremely Fast Fire Rate", Default = false })

local angle = 0
local RunService = game:GetService("RunService")
local voidPhase = 0

RunService.Heartbeat:Connect(function(dt)
    if not root or not root.Parent then return end
    tickCounter = tickCounter + 1

    local activeOrbit = orbitEnabled and (not voidEnabled or (voidEnabled and isShooting))
    local activeVoid = voidEnabled and (not orbitEnabled or (orbitEnabled and not isShooting))

    if activeOrbit or activeVoid then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Massless = true
                -- Critical: Set high velocity to break server-side lag compensation
                part.Velocity = Vector3.new(0, -5000, 0)
                part.AssemblyLinearVelocity = Vector3.new(0, -5000, 0)
                part.RotVelocity = Vector3.new(5000, 5000, 5000)
            end
        end
        if humanoid then
            humanoid.PlatformStand = true
            humanoid:ChangeState(Enum.HumanoidStateType.NoClip)
        end
    else
        if humanoid then humanoid.PlatformStand = false end
    end

    local finalCFrame = nil

    if activeOrbit then
        local targetRoot = nil
        if orbitMode == "Closest Enemy" then
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
        else
            if selectedTarget and selectedTarget.Character and selectedTarget.Character:FindFirstChild("HumanoidRootPart") then
                targetRoot = selectedTarget.Character.HumanoidRootPart
            end
        end

        if targetRoot then
            angle = angle + (orbitSpeed / 650) * dt
            
            -- Anti-Prediction Jitter
            local jitterX = (math.random() - 0.5) * 4
            local jitterZ = (math.random() - 0.5) * 4
            
            local ox = (orbitDistance + jitterX) * math.cos(angle)
            local oz = (orbitDistance + jitterZ) * math.sin(angle)
            local height = useCustomHeight and orbitHeight or 7.5
            
            finalCFrame = CFrame.new(targetRoot.Position + Vector3.new(ox, height, oz), targetRoot.Position)
        end

    elseif activeVoid then
        voidPhase = voidPhase + dt * 25
        local base = root.Position
        local s = voidStrength / 100000
        local yDrop = -s * 340 * (math.sin(voidPhase * 3.5) + 1.9)
        local spikeX = (math.random() - 0.5) * s * 260
        local spikeZ = (math.random() - 0.5) * s * 260
        finalCFrame = CFrame.new(base.X + spikeX, base.Y + yDrop, base.Z + spikeZ)
    end

    if finalCFrame then
        -- Advanced Flip-Flop Desync
        if tickCounter % 2 == 0 then
            -- Server sees you millions of studs away on even frames
            root.CFrame = CFrame.new(0, 9e15, 0)
        else
            -- Server sees you at target on odd frames (too fast for raycasts to lock)
            root.CFrame = finalCFrame
        end
    end

    if bulletTPEnabled then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") and obj.Velocity.Magnitude > 2 then
                local nameLower = obj.Name:lower()
                if nameLower:find("arrow") or nameLower:find("bolt") or nameLower:find("dagger") or 
                   nameLower:find("bullet") or nameLower:find("projectile") then

                    local closestEnemy = nil
                    local closestDist = math.huge
                    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            if not (player.Team and p.Team and player.Team == p.Team) then
                                local dist = (p.Character.HumanoidRootPart.Position - obj.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closestEnemy = p.Character.HumanoidRootPart
                                end
                            end
                        end
                    end

                    if closestEnemy and math.random(1, 100) <= hitRate then
                        obj.CFrame = CFrame.new(closestEnemy.Position)
                        obj.Velocity = (closestEnemy.Position - obj.Position).Unit * 1000
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(5) do
        updatePlayers()
        targetDropdown:SetValues(playerNames)
    end
end)

Library:Notify("Azoxx's Lua - Orbit Jitter & Anti-Prediction Loaded")
