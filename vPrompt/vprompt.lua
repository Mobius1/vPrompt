local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 19, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["UP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

vPrompt = {}
vPrompt.__index = vPrompt

function vPrompt:Create(options)
    local obj = {}

    setmetatable(obj, vPrompt)

    local defaultConfig = {
        font = 0,
        scale = 0.4,
        origin = vector2(0, 0),
        margin = 0.008,
        padding = 0.004,
        offsetY = 0.00,
        backgroundColor = { r = 0, g = 0, b = 0, a = 100 },
        labelColor = { r = 255, g = 255, b = 255, a = 255 },
        buttonColor = { r = 255, g = 255, b = 255, a = 255 },
        buttonLabelColor = { r = 0, g = 0, b = 0, a = 255 },
        drawDistance = 4.0,
        interactDistance = 2.0,
        canDraw = function() return true end,
    }

    assert(Keys[options.key] ~= nil, '^1Invalid key:'.. options.key)

    obj.label = options.label
    obj.key = Keys[options.key]
    obj.keyLabel = options.key
    obj.font = options.font or defaultConfig.font
    obj.scale = options.scale or defaultConfig.scale
    obj.origin = origin or defaultConfig.origin
    obj.margin = options.margin or defaultConfig.margin
    obj.padding = options.padding or defaultConfig.padding
    obj.offsetY = options.offsetY or defaultConfig.offsetY
    obj.labelColor = options.labelColor or defaultConfig.labelColor
    obj.backgroundColor = options.backgroundColor or defaultConfig.backgroundColor
    obj.buttonColor = options.buttonColor or defaultConfig.buttonColor
    obj.buttonLabelColor = options.buttonLabelColor or defaultConfig.buttonLabelColor
    obj.drawDistance = options.drawDistance or defaultConfig.drawDistance
    obj.interactDistance = options.interactDistance or defaultConfig.interactDistance
    obj.canDraw = options.canDraw or defaultConfig.canDraw
    obj.callbacks = {}

    if options.entity then
        assert(DoesEntityExist(options.entity), '^1Invalid entity passed to "entity" option')

        obj.entity = options.entity
    elseif options.bone then
        assert(DoesEntityExist(options.bone.entity), '^1Invalid entity passed to "bone.entity" option')

        obj.boneEntity = options.bone.entity
        obj.boneIndex = GetEntityBoneIndexByName(options.bone.entity, options.bone.name)
    else
        assert(type(options.coords) == 'vector3', '^1Invalid vector3 value passed to "coords" option')

        obj.coords = options.coords       
    end

    if obj.font == 1 then
        obj.offsetY = 0.01
    elseif obj.font == 2 then
        obj.offsetY = 0.009
    elseif obj.font == 4 or obj.font == 5 or obj.font == 6 or obj.font == 7 then
        obj.offsetY = 0.008
    end

    obj:GetDimensions()
    obj:SetButton()
    obj:SetPadding()
    obj:SetBackground()
    obj:CreateThread()

    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            obj:Destroy()
        end
    end)

   return obj
end

function vPrompt:GetDimensions()
    local sw, sh = GetActiveScreenResolution()
    
    self.keyTextWidth = self:GetTextWidth(self.keyLabel) 
    self.labelTextWidth = self:GetTextWidth(self.label)     
    self.textHeight = GetRenderedCharacterHeight(self.scale, self.font)
    self.sw = sw
    self.sh = sh 
end

function vPrompt:SetButton()
    self.button = {
        w = (math.max(0.015, self.keyTextWidth) * self.sw) / self.sw,
        h = (0.015 * self.sw) / self.sh,
        bgColor = self.buttonColor,
        fontColor = self.buttonLabelColor          
    }
end

function vPrompt:SetPadding()
    local padding = self.padding
    self.padding = {
        x = (padding * self.sw) / self.sw,
        y = (padding * self.sw) / self.sh
    }
end

function vPrompt:SetBackground()
    self.background = {
        w = self.labelTextWidth + self.button.w + (self.padding.x * 3) + (self.margin * 2),
        h = self.button.h + (self.padding.y * 2),
        bgColor = self.backgroundColor,
        fontColor = self.labelColor    
    }

    self.button.x = self.origin.x - (self.background.w / 2) + (self.button.w / 2) + self.padding.x
    self.button.y = self.origin.y - (self.background.h / 2) + (self.button.h / 2) + self.padding.y 
    
    self.button.text = {
        x = self.button.x,
        y = self.button.y - self.textHeight + self.offsetY
    }
    
    self.background.text = {
        x = self.button.x + (self.button.w / 2) + self.margin + self.padding.x,
        y = self.button.y - self.textHeight + self.offsetY
    }
end

function vPrompt:Draw()

    if self.canInteract then
        if self.background.w < (self.labelTextWidth + self.button.w + (self.padding.x * 3) + (self.margin * 2)) then
            self.background.w = self.background.w + 0.008
        else
            -- self.background.w = self.labelTextWidth + self.button.w + (self.padding.x * 3) + (self.margin * 2)
        end

        self.background.fontColor.a = 255
    else
        if self.background.w > (self.button.w + (self.padding.x * 2)) then
            self.background.w = self.background.w - 0.008
        else
            self.background.w = self.button.w + (self.padding.x * 2)
        end

        self.background.fontColor.a = 0
    end

    self.button.x = self.origin.x - (self.background.w / 2) + (self.button.w / 2) + self.padding.x
    self.button.text.x = self.button.x

    self:RenderElement(self.label, self.background)
    self:RenderElement(self.keyLabel, self.button, true)

    if self.pressed then
        self.highlight.w = self.highlight.w + (0.0005 * self.sw) / self.sw
        self.highlight.h = self.highlight.h + (0.0005 * self.sw) / self.sh
        self.highlight.a = self.highlight.a - 20

        SetDrawOrigin(self.coords.x, self.coords.y, self.coords.z, 0)
        DrawRect(self.highlight.x, self.highlight.y, self.highlight.w, self.highlight.h, self.button.bgColor.r, self.button.bgColor.g, self.button.bgColor.b, self.highlight.a)
        ClearDrawOrigin()  

        if self.highlight.a <= 0 then
            self.pressed = false

            self.highlight = {
                x = self.button.x,
                y = self.button.y,
                w = self.button.w,
                h = self.button.h,
                a = 255
            }            
        end
    end
end

function vPrompt:CreateThread()
    Citizen.CreateThread(function()
        local player = PlayerPedId()

        self.highlight = {
            x = self.button.x,
            y = self.button.y,
            w = self.button.w,
            h = self.button.h,
            a = 255
        }

        while true do
            local letSleep = true
            local pcoords = GetEntityCoords(player)

            if self.entity then
                self.coords = GetEntityCoords(self.entity)
            elseif self.boneEntity then
                self.coords = GetWorldPositionOfEntityBone(self.boneEntity, self.boneIndex)            
            end
            
            local dist = #(self.coords - pcoords)
    
            if dist < self.drawDistance then
                if self.canDraw() then
                    letSleep = false
                    self:Draw()
                    
                    if not self.visible then
                        self.visible = true

                        if self.callbacks.show then
                            self.callbacks.show()
                        end
                    end
                    
                    if dist < self.interactDistance then

                        if not self.InInteractionArea then
                            self.InInteractionArea = true

                            if self.callbacks.enterInteractZone then
                                self.callbacks.enterInteractZone()
                            end
                        end

                        self.canInteract = true
                        if IsControlJustPressed(0, self.key) then
                            self.pressed = true

                            if self.callbacks.interact then
                                self.callbacks.interact()
                            end
                        end
                    else
                        self.canInteract = false

                        if self.InInteractionArea then
                            self.InInteractionArea = false
        
                            if self.callbacks.exitInteractZone then
                                self.callbacks.exitInteractZone()
                            end
                        end                         
                    end
                end
            else
                if self.visible then
                    self.visible = false
                    if self.callbacks.hide then
                        self.callbacks.hide()
                    end
                end               
            end
    
            if letSleep then
                Citizen.Wait(1000)
            end
    
            Citizen.Wait(0)

            if self.stop then return end
        end
    end)
end

function vPrompt:GetTextWidth(text)
    BeginTextCommandGetWidth("STRING");
    SetTextScale(self.scale, self.scale)
    SetTextFont(self.font)
    SetTextEntry("STRING")    
    AddTextComponentString(text)
    return EndTextCommandGetWidth(1)    
end

function vPrompt:RenderElement(text, box, centered)
    SetTextScale(self.scale, self.scale)
    SetTextFont(self.font)
    SetTextColour(box.fontColor.r, box.fontColor.g, box.fontColor.b, box.fontColor.a)
    SetTextEntry("STRING")
    SetTextCentre(centered ~= nil)
    AddTextComponentString(text)
    SetDrawOrigin(self.coords.x, self.coords.y, self.coords.z, 0)
    EndTextCommandDisplayText(box.text.x, box.text.y)
    DrawRect(box.x, box.y, box.w, box.h, box.bgColor.r, box.bgColor.g, box.bgColor.b, box.bgColor.a)
    ClearDrawOrigin()
end

function vPrompt:Destroy(event, cb)
    self.stop = true
    self.callbacks = {}
end

function vPrompt:On(event, cb)
    self.callbacks[event] = cb
end
