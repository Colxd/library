

local NameEspLibrary = {}
NameEspLibrary.__index = NameEspLibrary

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

--// Creates a new Name ESP object for a player
function NameEspLibrary:New(player, settings)
    local esp = setmetatable({}, NameEspLibrary)

    esp.Player = player
    esp.Settings = {
        Color = (settings and settings.Color) or Color3.fromRGB(255, 255, 255),
        AutoScale = (settings and settings.AutoScale ~= nil) and settings.AutoScale or true,
        MinSize = (settings and settings.MinSize) or 10,
        MaxSize = (settings and settings.MaxSize) or 22,
        YOffset = (settings and settings.YOffset) or 2
    }

    esp.TextObject = Drawing.new("Text")
    esp.TextObject.Visible = false
    esp.TextObject.Center = true
    esp.TextObject.Outline = true
    esp.TextObject.Font = Drawing.Fonts.UI
    esp.TextObject.Color = esp.Settings.Color
    esp.TextObject.Size = 15 -- Initial size

    esp.Connection = RunService.RenderStepped:Connect(function()
        if not esp.Player or not esp.Player.Character or not esp.Player.Character:FindFirstChild("Head") or not esp.Player.Character:FindFirstChildOfClass("Humanoid") or esp.Player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            esp.TextObject.Visible = false
            return
        end

        local head = esp.Player.Character.Head
        local worldPosition = head.Position + Vector3.new(0, esp.Settings.YOffset, 0)
        local screenPosition, onScreen = Camera:WorldToViewportPoint(worldPosition)

        if onScreen then
            esp.TextObject.Visible = true
            esp.TextObject.Position = Vector2.new(screenPosition.X, screenPosition.Y)
            esp.TextObject.Text = esp.Player.Name

            if esp.Settings.AutoScale then
                local distance = (Camera.CFrame.Position - worldPosition).Magnitude
                local size = math.clamp(1 / distance * 1000, esp.Settings.MinSize, esp.Settings.MaxSize)
                esp.TextObject.Size = size
            end
        else
            esp.TextObject.Visible = false
        end
    end)

    return esp
end

--// Updates the color of the text
function NameEspLibrary:SetColor(color)
    if self.TextObject then
        self.TextObject.Color = color
    end
end

--// Destroys the ESP object and cleans up connections
function NameEspLibrary:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.TextObject then
        self.TextObject:Remove()
        self.TextObject = nil
    end
    
    --// Clear table for garbage collection
    for k, _ in pairs(self) do
        self[k] = nil
    end
end

return NameEspLibrary
