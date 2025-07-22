
local BoxLib = {}


function BoxLib:New(player)
    local box = {}

    -- Services and Properties
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = game:GetService("Players").LocalPlayer

    box.Player = player
    box.UpdateConnection = nil
    box.Color = Color3.fromRGB(255, 0, 0) -- Default color
    box.Thickness = 2

    -- Helper to create drawing lines
    local function createLine()
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = box.Color
        line.Thickness = box.Thickness
        line.Transparency = 1
        return line
    end

    -- Create all the drawing objects for the box corners
    box.Lines = {
        TL1 = createLine(), TL2 = createLine(),
        TR1 = createLine(), TR2 = createLine(),
        BL1 = createLine(), BL2 = createLine(),
        BR1 = createLine(), BR2 = createLine()
    }

    -- This part is used for calculating the screen position of the box
    local oriPart = Instance.new("Part")
    oriPart.Transparency = 1
    oriPart.CanCollide = false
    oriPart.Anchored = true
    oriPart.Size = Vector3.new(1, 1, 1)
    oriPart.Parent = Workspace

    --[[ Methods for controlling the box ]]--

    -- Cleans up all drawing objects and disconnects the update loop
    function box:Destroy()
        if box.UpdateConnection then
            box.UpdateConnection:Disconnect()
            box.UpdateConnection = nil
        end
        for _, line in pairs(box.Lines) do
            line:Remove()
        end
        oriPart:Destroy()
        -- Nil out tables to help garbage collection
        box.Player = nil
        box.Lines = nil
        print("Box ESP destroyed for:", player.Name)
    end

    -- Sets a new color for the box
    function box:SetColor(color)
        box.Color = color
        for _, line in pairs(box.Lines) do
            line.Color = color
        end
    end
    
    -- Toggles the visibility of all lines
    function box:SetVisible(state)
        for _, line in pairs(box.Lines) do
            line.Visible = state
        end
    end

    --[[ Main Update Loop ]]--
    box.UpdateConnection = RunService.RenderStepped:Connect(function()
        local char = box.Player and box.Player.Character
        local localCharHrp = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        -- Check if the target player and local player are valid
        if char and localCharHrp and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local hrp = char.HumanoidRootPart
            local _, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                box:SetVisible(true)
                
                -- Position and size the box based on the character's dimensions
                oriPart.Size = Vector3.new(hrp.Size.X, hrp.Size.Y * 1.5, hrp.Size.Z)
                oriPart.CFrame = CFrame.new(hrp.CFrame.Position, Camera.CFrame.Position)

                local SizeX, SizeY = oriPart.Size.X, oriPart.Size.Y
                local TL = Camera:WorldToViewportPoint((oriPart.CFrame * CFrame.new(SizeX, SizeY, 0)).p)
                local TR = Camera:WorldToViewportPoint((oriPart.CFrame * CFrame.new(-SizeX, SizeY, 0)).p)
                local BL = Camera:WorldToViewportPoint((oriPart.CFrame * CFrame.new(SizeX, -SizeY, 0)).p)
                local BR = Camera:WorldToViewportPoint((oriPart.CFrame * CFrame.new(-SizeX, -SizeY, 0)).p)

                local ratio = (Camera.CFrame.p - hrp.Position).magnitude
                local offset = math.clamp(1 / ratio * 750, 2, 30)

                -- Update line positions for the corner boxes
                box.Lines.TL1.From, box.Lines.TL1.To = Vector2.new(TL.X, TL.Y), Vector2.new(TL.X + offset, TL.Y)
                box.Lines.TL2.From, box.Lines.TL2.To = Vector2.new(TL.X, TL.Y), Vector2.new(TL.X, TL.Y + offset)
                box.Lines.TR1.From, box.Lines.TR1.To = Vector2.new(TR.X, TR.Y), Vector2.new(TR.X - offset, TR.Y)
                box.Lines.TR2.From, box.Lines.TR2.To = Vector2.new(TR.X, TR.Y), Vector2.new(TR.X, TR.Y + offset)
                box.Lines.BL1.From, box.Lines.BL1.To = Vector2.new(BL.X, BL.Y), Vector2.new(BL.X + offset, BL.Y)
                box.Lines.BL2.From, box.Lines.BL2.To = Vector2.new(BL.X, BL.Y), Vector2.new(BL.X, BL.Y - offset)
                box.Lines.BR1.From, box.Lines.BR1.To = Vector2.new(BR.X, BR.Y), Vector2.new(BR.X - offset, BR.Y)
                box.Lines.BR2.From, box.Lines.BR2.To = Vector2.new(BR.X, BR.Y), Vector2.new(BR.X, BR.Y - offset)

                -- Autothickness based on distance
                local distance = (localCharHrp.Position - hrp.Position).magnitude
                local thickness = math.clamp(1 / distance * 100, 1, 4)
                for _, line in pairs(box.Lines) do
                    line.Thickness = thickness
                end
            else
                box:SetVisible(false)
            end
        else
            box:SetVisible(false)
        end
    end)
    
    return box
end

return BoxLib
