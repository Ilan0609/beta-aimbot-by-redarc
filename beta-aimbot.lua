local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Holding = false
local MenuVisible = true

-- Paramètres globaux
_G.AimbotEnabled = true
_G.ESPEnabled = true
_G.TeamCheck = true -- Activer la vérification des alliés
_G.AimPart = "Head" -- Cibler la tête
_G.Sensitivity = 0.1
_G.AimbotMaxDistance = 350

-- FOV - Champ de vision
_G.CircleRadius = 200
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

-- Initialisation du cercle FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

-- Fonction pour calculer la distance entre deux points
local function GetDistanceInMeters(p1, p2)
    return (p1 - p2).Magnitude
end

-- Trouver le joueur le plus proche dans le cercle FOV
local function GetClosestPlayer()
    local ClosestDistance = _G.AimbotMaxDistance
    local Target = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck and player.Team == LocalPlayer.Team then
                continue -- Ignorer les alliés si TeamCheck est activé
            end
            local Humanoid = player.Character:FindFirstChild("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                local ScreenPosition, OnScreen = Camera:WorldToScreenPoint(player.Character.HumanoidRootPart.Position)
                if OnScreen then
                    local MousePosition = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
                    local DistanceFromFOVCenter = (MousePosition - Vector2.new(ScreenPosition.X, ScreenPosition.Y)).Magnitude

                    if DistanceFromFOVCenter <= _G.CircleRadius then
                        local DistanceToPlayer = GetDistanceInMeters(LocalPlayer.Character.HumanoidRootPart.Position, player.Character.HumanoidRootPart.Position)
                        if DistanceToPlayer <= ClosestDistance then
                            ClosestDistance = DistanceToPlayer
                            Target = player
                        end
                    end
                end
            end
        end
    end
    return Target
end

-- Détecter le clic droit pour activer l'aimbot
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

-- Aimbot principal
RunService.RenderStepped:Connect(function()
    -- Mettre à jour le cercle FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    if Holding and _G.AimbotEnabled then
        local Target = GetClosestPlayer()
        if Target and Target.Character:FindFirstChild(_G.AimPart) then
            local TargetPosition = Target.Character[_G.AimPart].Position
            local CameraPosition = Camera.CFrame.Position

            local NewCFrame = CFrame.lookAt(CameraPosition, TargetPosition)
            Camera.CFrame = NewCFrame
        end
    end
end)

-- ESP (affichage des ennemis)
local function createHighlight(target)
    if target:FindFirstChild("Highlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight"
    highlight.Adornee = target
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = target
end

local function highlightPlayers()
    if not _G.ESPEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createHighlight(player.Character)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if _G.ESPEnabled then
            createHighlight(character)
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if _G.ESPEnabled then
        highlightPlayers()
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Highlight") then
                player.Character.Highlight:Destroy()
            end
        end
    end
end)

-- Création du menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Enabled = MenuVisible

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true

local AimbotButton = Instance.new("TextButton")
AimbotButton.Size = UDim2.new(1, 0, 0, 30)
AimbotButton.Position = UDim2.new(0, 0, 0, 0)
AimbotButton.Text = "Toggle Aimbot"
AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimbotButton.TextColor3 = Color3.new(1, 1, 1)
AimbotButton.Parent = Frame

local ESPButton = Instance.new("TextButton")
ESPButton.Size = UDim2.new(1, 0, 0, 30)
ESPButton.Position = UDim2.new(0, 0, 0, 40)
ESPButton.Text = "Toggle ESP"
ESPButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ESPButton.TextColor3 = Color3.new(1, 1, 1)
ESPButton.Parent = Frame

local AimbotRivalsButton = Instance.new("TextButton")
AimbotRivalsButton.Size = UDim2.new(1, 0, 0, 30)
AimbotRivalsButton.Position = UDim2.new(0, 0, 0, 80)
AimbotRivalsButton.Text = "Load Aimbot Rivals"
AimbotRivalsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimbotRivalsButton.TextColor3 = Color3.new(1, 1, 1)
AimbotRivalsButton.Parent = Frame

local FOVSlider = Instance.new("TextBox")
FOVSlider.Size = UDim2.new(1, 0, 0, 30)
FOVSlider.Position = UDim2.new(0, 0, 0, 120)
FOVSlider.Text = tostring(_G.CircleRadius)
FOVSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FOVSlider.TextColor3 = Color3.new(1, 1, 1)
FOVSlider.Parent = Frame

-- Actions des boutons
AimbotButton.MouseButton1Click:Connect(function()
    _G.AimbotEnabled = not _G.AimbotEnabled
    AimbotButton.Text = "Toggle Aimbot (" .. tostring(_G.AimbotEnabled) .. ")"
end)

ESPButton.MouseButton1Click:Connect(function()
    _G.ESPEnabled = not _G.ESPEnabled
    ESPButton.Text = "Toggle ESP (" .. tostring(_G.ESPEnabled) .. ")"
end)

AimbotRivalsButton.MouseButton1Click:Connect(function()
    -- Charger et exécuter le script Aimbot Rivals
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Ilan0609/rivals/refs/heads/main/rivals.lua"))()
    
    -- Désactiver le script actuel
    ScreenGui.Enabled = false
    -- Supprimer le bouton Load Aimbot Rivals
    AimbotRivalsButton:Destroy()
end)

FOVSlider.FocusLost:Connect(function()
    local newValue = tonumber(FOVSlider.Text)
    if newValue then
        _G.CircleRadius = newValue
    else
        FOVSlider.Text = tostring(_G.CircleRadius)
    end
end)

-- Touche pour afficher/masquer le menu
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        MenuVisible = not MenuVisible
        ScreenGui.Enabled = MenuVisible
    end
end)
