local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 19, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["UP"] = 27, ["DOWN"] = 173
}

vPrompt = {}
vPrompt.__index = vPrompt

------
--
-- @param options      - table of options
--
-- Create new vPrompt instance
------
function vPrompt:Create(options)
    local obj = {}

    setmetatable(obj, vPrompt)

    -- Default config for set-up
    local defaultConfig = {
        font = 0,
        scale = 0.4,
        origin = vector2(0, 0),
        offset = vector3(0, 0, 0),
        margin = 0.008,
        padding = 0.004,
        fontOffset = 0.00,
        buttonSize = 0.015,
        backgroundColor = { r = 0, g = 0, b = 0, a = 100 },
        labelColor = { r = 255, g = 255, b = 255, a = 255 },
        buttonColor = { r = 255, g = 255, b = 255, a = 255 },
        buttonLabelColor = { r = 0, g = 0, b = 0, a = 255 },
        drawDistance = 4.0,
        interactDistance = 2.0,
        canDraw = function() return true end,
    }

    -- Check for valid key
    assert(Keys[options.key] ~= nil, '^1Invalid key:'.. options.key)

    -- Merge user-defined options
    obj.label = options.label
    obj.key = Keys[options.key]
    obj.keyLabel = options.key
    obj.font = options.font or defaultConfig.font
    obj.scale = options.scale or defaultConfig.scale
    obj.origin = options.origin or defaultConfig.origin
    obj.offset = options.offset or defaultConfig.offset
    obj.margin = options.margin or defaultConfig.margin
    obj.padding = options.padding or defaultConfig.padding
    obj.fontOffset = options.fontOffset or defaultConfig.fontOffset
    obj.buttonSize = options.buttonSize or defaultConfig.buttonSize
    obj.labelColor = options.labelColor or defaultConfig.labelColor
    obj.backgroundColor = options.backgroundColor or defaultConfig.backgroundColor
    obj.buttonColor = options.buttonColor or defaultConfig.buttonColor
    obj.buttonLabelColor = options.buttonLabelColor or defaultConfig.buttonLabelColor
    obj.drawDistance = options.drawDistance or defaultConfig.drawDistance
    obj.interactDistance = options.interactDistance or defaultConfig.interactDistance
    obj.canDraw = options.canDraw or defaultConfig.canDraw
    obj.callbacks = {}

    if options.entity then
        -- Check for valid entity
        assert(DoesEntityExist(options.entity), '^1Invalid entity passed to "entity" option')

        obj.entity = options.entity
    elseif options.bone then
        -- Check for valid entity
        assert(DoesEntityExist(options.bone.entity), '^1Invalid entity passed to "bone.entity" option')

        obj.boneEntity = options.bone.entity
        obj.boneIndex = GetEntityBoneIndexByName(options.bone.entity, options.bone.name)
    else
        -- Check for valid vector3 coords
        assert(type(options.coords) == 'vector3', '^1Invalid vector3 value passed to "coords" option')

        obj.coords = options.coords       
        obj.coords = obj.coords + obj.offset    
    end

    -- Handle offsets for native GTA:V fonts
    if obj.font == 1 then
        obj.fontOffset = 0.01
    elseif obj.font == 2 then
        obj.fontOffset = 0.009
    elseif obj.font == 4 or obj.font == 5 or obj.font == 6 or obj.font == 7 then
        obj.fontOffset = 0.008
    end

    -- Initialise
    obj:GetDimensions()
    obj:SetButton()
    obj:SetPadding()
    obj:SetBackground()
    obj:CreateThread()

    -- Make sure we destroy the instance if the resource stops
    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            obj:Destroy()
        end
    end)

   return obj
end

function vPrompt:GetDimensions()
    local sw, sh = GetActiveScreenResolution()
    
    -- Get width of button
    self.keyTextWidth = self:GetTextWidth(self.keyLabel) 

    -- Get width of background box
    self.labelTextWidth = self:GetTextWidth(self.label) 
    
    -- Get the font height
    self.textHeight = GetRenderedCharacterHeight(self.scale, self.font)

    self.sw = sw
    self.sh = sh 
end

function vPrompt:SetButton()
    self.button = {
        w = (math.max(self.buttonSize, self.keyTextWidth) * self.sw) / self.sw,
        h = (self.buttonSize * self.sw) / self.sh,
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
    self.minWidth = self.button.w + (self.padding.x * 2)
    self.maxWidth = self.labelTextWidth + self.button.w + (self.padding.x * 3) + (self.margin * 2)

    self.background = {
        w = self.maxWidth,
        h = self.button.h + (self.padding.y * 2),
        bgColor = self.backgroundColor,
        fontColor = self.labelColor    
    }

    self.button.x = self.origin.x - (self.background.w / 2) + (self.button.w / 2) + self.padding.x
    self.button.y = self.origin.y - (self.background.h / 2) + (self.button.h / 2) + self.padding.y 
    
    self.button.text = {
        x = self.button.x,
        y = self.button.y - self.textHeight + self.fontOffset
    }
    
    self.background.text = {
        x = self.button.x + (self.button.w / 2) + self.margin + self.padding.x,
        y = self.button.y - self.textHeight + self.fontOffset
    }
end

function vPrompt:Draw()
    if self.canInteract then
        if self.background.w < self.maxWidth then
            self.background.w = self.background.w + 0.008
        end

        self.background.fontColor.a = 255
    else
        if self.background.w > self.minWidth then
            self.background.w = self.background.w - 0.008
        else
            self.background.w = self.minWidth
        end

        self.background.fontColor.a = 0
    end

    self.button.x = self.origin.x - (self.background.w / 2) + (self.button.w / 2) + self.padding.x
    self.button.text.x = self.button.x

    -- Render the boxes and text
    self:RenderElement(self.label, self.background)
    self:RenderElement(self.keyLabel, self.button, true)

    -- Draw keypress effect
    if self.pressed then
        self.highlight.w = self.highlight.w + (0.0005 * self.sw) / self.sw
        self.highlight.h = self.highlight.h + (0.0005 * self.sw) / self.sh
        self.highlight.a = self.highlight.a - 18

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

            if self.entity then -- Entity was set in the options so track it's coords
                self.coords = GetEntityCoords(self.entity)

                self.coords = self.coords + self.offset
            elseif self.boneEntity then -- Entity bone was set in the options so track it's coords
                self.coords = GetWorldPositionOfEntityBone(self.boneEntity, self.boneIndex)

                self.coords = self.coords + self.offset
            else
                -- Coordinates were set in the options so we don't have to do anything     
            end
            
            -- Check distance between player and coords
            -- There's a place in hell for people that use the Vdist() or GetDistanceBetweenCoords() natives!!!!
            local dist = #(self.coords - pcoords)
    
            -- Check player is within draw distance
            if dist < self.drawDistance then
                local canDraw = self.canDraw()

                -- Can we draw?
                if canDraw then
                    letSleep = false

                    -- Render the elements
                    self:Draw()
                    
                    -- Instance was previously hidden, but isn't now
                    if not self.visible then
                        self.visible = true

                        -- Fire the 'show' event
                        if self.callbacks.show then
                            self.callbacks.show()
                        end
                    end
                    
                    -- Check player is within interact distance
                    if dist < self.interactDistance then

                        -- We weren't within the interact distance previously, but have now entered
                        if not self.InInteractionArea then
                            self.InInteractionArea = true

                            -- Fire 'enterInteractZone' event
                            if self.callbacks.enterInteractZone then
                                self.callbacks.enterInteractZone()
                            end
                        end

                        self.canInteract = true

                        -- Detect keypress
                        if IsControlJustPressed(0, self.key) then
                            self.pressed = true

                            -- Fire 'interact' event
                            if self.callbacks.interact then
                                self.callbacks.interact()
                            end
                        end
                    else
                        self.canInteract = false

                        -- We were within the interact distance previously, but have now left
                        if self.InInteractionArea then
                            self.InInteractionArea = false
        
                            -- Fire 'exitInteractZone' event
                            if self.callbacks.exitInteractZone then
                                self.callbacks.exitInteractZone()
                            end
                        end                         
                    end
                end
            else
                -- We were within the draw distance previously, but have now left
                if self.visible then
                    self.visible = false

                    -- Fire 'hide' event
                    if self.callbacks.hide then
                        self.callbacks.hide()
                    end
                end               
            end
    
            -- Let the thread sleep
            if letSleep then
                Citizen.Wait(1000)
            end
    
            Citizen.Wait(0)

            -- For killing the thread when the instance is destroyed
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
    -- Kill the thread
    self.stop = true

    -- Remove callbacks
    self.callbacks = {}
end

function vPrompt:On(event, cb)
    -- Check event name is a string
    assert(type(event) == 'string', string.format("^1Invalid type for param: 'event' | Expected 'string', got %s ", type(event)))

    -- Check if event is already registered
    assert(self.callbacks[event] == nil, string.format("^1Event '%s' already registered", event))

    self.callbacks[event] = cb
end
