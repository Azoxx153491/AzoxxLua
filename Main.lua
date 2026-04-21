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

RunService.Heartbeat:Connect(function(dt)
    if not root or isReturning then return end
    tickCounter = (tickCounter + 1) % 10
    local target = GetClosestTarget()
    local targetPos = nil

    if Library.Toggles.BulletTP.Value and target then
        for _, proj in ipairs(workspace:GetChildren()) do
            if proj:IsA("BasePart") then
                local n = proj.Name:lower()
                if n:find("bullet") or n:find("arrow") or n:find("projectile") then
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
