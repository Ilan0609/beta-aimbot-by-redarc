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
_G.TeamCheck = true
_G.AimPart = "Head"
_G.CircleRadius = 200
_G.AimbotMaxDistance = 350

-- FOV - Champ de vision
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

-- Fonction pour créer des cases à cocher
local function createCheckbox(parent, text, position, defaultValue, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.9, 0, 0, 30)
    Frame.Position = position
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Checkbox = Instance.new("TextButton")
    Checkbox.Size = UDim2.new(0, 20, 0, 20)
    Checkbox.Position = UDim2.new(0, 0, 0.5, -10)
    Checkbox.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    Checkbox.Text = ""
    Checkbox.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -30, 1, 0)
    Label.Position = UDim2.new(0, 30, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local isChecked = defaultValue
    Checkbox.MouseButton1Click:Connect(function()
        isChecked = not isChecked
        Checkbox.BackgroundColor3 = isChecked and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        callback(isChecked)
    end)
end

-- Fonction pour créer un bouton
local function createButton(parent, text, position, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.9, 0, 0, 30)
    Button.Position = position
    Button.Text = text
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.Parent = parent

    Button.MouseButton1Click:Connect(function()
        callback()
    end)
end

-- Création du menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Enabled = MenuVisible

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 300)
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Cheat Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Parent = Frame

-- Ajouter des cases à cocher
createCheckbox(Frame, "Enable Aimbot", UDim2.new(0, 10, 0, 40), _G.AimbotEnabled, function(value)
    _G.AimbotEnabled = value
end)

createCheckbox(Frame, "Enable ESP", UDim2.new(0, 10, 0, 80), _G.ESPEnabled, function(value)
    _G.ESPEnabled = value
end)

createCheckbox(Frame, "Team Check", UDim2.new(0, 10, 0, 120), _G.TeamCheck, function(value)
    _G.TeamCheck = value
end)

-- Ajout du FOV Radius
local FOVSlider = Instance.new("TextBox")
FOVSlider.Size = UDim2.new(0.9, 0, 0, 30)
FOVSlider.Position = UDim2.new(0, 10, 0, 160)
FOVSlider.Text = tostring(_G.CircleRadius)
FOVSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FOVSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVSlider.Font = Enum.Font.Gotham
FOVSlider.TextSize = 14
FOVSlider.TextXAlignment = Enum.TextXAlignment.Center
FOVSlider.Parent = Frame

FOVSlider.FocusLost:Connect(function()
    local newValue = tonumber(FOVSlider.Text)
    if newValue then
        _G.CircleRadius = newValue
    else
        FOVSlider.Text = tostring(_G.CircleRadius)
    end
end)

-- Ajout du bouton Aimbot Rivals
createButton(Frame, "Load Aimbot Rivals", UDim2.new(0, 10, 0, 200), function()
    -- Charger et exécuter le script Aimbot Rivals
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Ilan0609/rivals/refs/heads/main/rivals.lua"))()
    
    -- Désactiver le script actuel
    ScreenGui.Enabled = false
end)

-- Touche pour afficher/masquer le menu
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        MenuVisible = not MenuVisible
        ScreenGui.Enabled = MenuVisible
    end
end)
