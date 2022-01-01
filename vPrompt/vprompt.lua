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

-- Default config for set-up
local defaultConfig = {
    debug = false,
    font = 0,
    scale = 0.4,
    origin = vector2(0, 0),
    offset = vector3(0, 0, 0),
    margin = 0.008,
    padding = 0.004,
    textOffset = 0.00,
    buttonSize = 0.015,
    backgroundColor = { r = 0, g = 0, b = 0, a = 100 },
    labelColor = { r = 255, g = 255, b = 255, a = 255 },
    buttonColor = { r = 255, g = 255, b = 255, a = 255 },
    buttonLabelColor = { r = 0, g = 0, b = 0, a = 255 },
    drawDistance = 4.0,
    interactDistance = 2.0,
    canDraw = function() return true end,
}

vPrompt = {}
vPrompt.__index = vPrompt


------
--
-- @param options   table      - User-defined options
--
-- Create new vPrompt instance
------
function vPrompt:Create(options)
    local obj = {}

    setmetatable(obj, vPrompt)

    -- Initialise
    obj:_Init(options)
    obj:Update()
    obj:_CreateThread()

    -- Make sure we destroy the instance if the resource stops
    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            obj:Destroy()
        end
    end)

   return obj
end

function vPrompt:_Init(cfg)
    -- Check for valid key
    assert(Keys[cfg.key] ~= nil, '^1Invalid key:'.. cfg.key)

    self.cfg = {}


    -- Merge user-defined options
    self.cfg.debug = cfg.debug or defaultConfig.debug
    self.cfg.label = tostring(cfg.label)
    self.cfg.key = Keys[cfg.key]
    self.cfg.keyLabel = tostring(cfg.key)
    self.cfg.font = cfg.font or defaultConfig.font
    self.cfg.scale = cfg.scale or defaultConfig.scale
    self.cfg.origin = cfg.origin or defaultConfig.origin
    self.cfg.offset = cfg.offset or defaultConfig.offset
    self.cfg.margin = cfg.margin or defaultConfig.margin
    self.cfg.padding = cfg.padding or defaultConfig.padding
    self.cfg.textOffset = cfg.textOffset or defaultConfig.textOffset
    self.cfg.buttonSize = cfg.buttonSize or defaultConfig.buttonSize
    self.cfg.labelColor = cfg.labelColor or defaultConfig.labelColor
    self.cfg.backgroundColor = cfg.backgroundColor or defaultConfig.backgroundColor
    self.cfg.buttonColor = cfg.buttonColor or defaultConfig.buttonColor
    self.cfg.buttonLabelColor = cfg.buttonLabelColor or defaultConfig.buttonLabelColor
    self.cfg.drawDistance = cfg.drawDistance or defaultConfig.drawDistance
    self.cfg.interactDistance = cfg.interactDistance or defaultConfig.interactDistance
    self.cfg.canDraw = cfg.canDraw or defaultConfig.canDraw
    self.cfg.callbacks = {}

    if cfg.entity then
        -- Check for valid entity
        assert(DoesEntityExist(cfg.entity), '^1Invalid entity passed to "entity" option')

        self.cfg.entity = cfg.entity
    elseif cfg.bone then
        -- Check for valid entity
        assert(DoesEntityExist(cfg.bone.entity), '^1Invalid entity passed to "bone.entity" option')

        self.cfg.boneEntity = cfg.bone.entity
        self.cfg.boneIndex = GetEntityBoneIndexByName(cfg.bone.entity, cfg.bone.name)
    elseif cfg.coords then
        -- Check for valid vector3 coords
        assert(type(cfg.coords) == 'vector3', '^1Invalid vector3 value passed to "coords" option')

        self.cfg.coords = cfg.coords       
        self.cfg.coords = self.cfg.coords + self.cfg.offset    
    end

    -- Handle offsets for native GTA:V fonts
    if self.cfg.font == 1 then
        self.cfg.textOffset = 0.01
    elseif self.cfg.font == 2 then
        self.cfg.textOffset = 0.009
    elseif self.cfg.font == 4 or self.cfg.font == 5 or self.cfg.font == 6 or self.cfg.font == 7 then
        self.cfg.textOffset = 0.008
    end
end

------
--
-- Updates the dimensions
--
-- @return void
--
------
function vPrompt:Update()
    self:_GetDimensions()
    self:_SetButton()
    self:_SetPadding()
    self:_SetBackground()
end

------
--
-- Updates the key
--
-- @param label     string        - the new key
--
-- @return void
--
------
function vPrompt:SetKey(key)
    -- Check for valid key
    assert(Keys[key] ~= nil, '^1Invalid key:'.. key)

    if key ~= self.cfg.keyLabel then
        self.cfg.key        = Keys[key]
        self.cfg.keyLabel   = tostring(key)
    end
end

------
--
-- Updates the label
--
-- @param label     string        - the new label
--
-- @return void
--
------
function vPrompt:SetLabel(label)
    if label ~= self.cfg.label then
        self.cfg.label = label
        self:Update()
    end
end

------
--
-- Updates the label
--
-- @param label     string        - the new label
--
-- @return void
--
------
function vPrompt:SetBackgroundColor(r, g, b, a)
    self.cfg.backgroundColor.r = r
    self.cfg.backgroundColor.g = g
    self.cfg.backgroundColor.b = b
    self.cfg.backgroundColor.a = a
end

------
--
-- Destroys the instance
--
-- @return void
--
------
function vPrompt:Destroy()
    -- Kill the thread
    self.stop = true

    -- Remove callbacks
    self.cfg.callbacks = {}
end

------
--
-- Add event listener
--
-- @param event     string        - event name
-- @param cb        function      - event callback
--
-- @return void
--
------
function vPrompt:On(event, cb)
    -- Check event name is a string
    assert(type(event) == 'string', string.format("^1Invalid type for param: 'event' | Expected 'string', got %s ", type(event)))

    -- Check if event is already registered
    assert(self.cfg.callbacks[event] == nil, string.format("^1Event '%s' already registered", event))

    self.cfg.callbacks[event] = cb
end

function vPrompt:_GetDimensions()
    local sw, sh = GetActiveScreenResolution()
    
    -- Get width of button
    self.keyTextWidth = self:_GetTextWidth(self.cfg.keyLabel) 

    -- Get width of background box
    self.labelTextWidth = self:_GetTextWidth(self.cfg.label) 
    
    -- Get the font height
    self.textHeight = GetRenderedCharacterHeight(self.cfg.scale, self.cfg.font)

    self.sw = sw
    self.sh = sh 
end

function vPrompt:_SetButton()
    self.button = {
        w = (math.max(self.cfg.buttonSize, self.keyTextWidth) * self.sw) / self.sw,
        h = (self.cfg.buttonSize * self.sw) / self.sh,
        bgColor = self.cfg.buttonColor,
        fontColor = self.cfg.buttonLabelColor          
    }
end

function vPrompt:_SetPadding()
    local padding = self.cfg.padding

    self.boxPadding = {
        x = (padding * self.sw) / self.sw,
        y = (padding * self.sw) / self.sh
    }
end

function vPrompt:_SetBackground()
    self.minWidth = self.button.w + (self.boxPadding.x * 2)
    self.maxWidth = self.labelTextWidth + self.button.w + (self.boxPadding.x * 3) + (self.cfg.margin * 2)

    self.background = {
        w = self.maxWidth,
        h = self.button.h + (self.boxPadding.y * 2),
        bgColor = self.cfg.backgroundColor,
        fontColor = self.cfg.labelColor    
    }

    self.button.x = self.cfg.origin.x - (self.background.w / 2) + (self.button.w / 2) + self.boxPadding.x
    self.button.y = self.cfg.origin.y - (self.background.h / 2) + (self.button.h / 2) + self.boxPadding.y 
    
    self.button.text = {
        x = self.button.x,
        y = self.button.y - self.textHeight + self.cfg.textOffset
    }
    
    self.background.text = {
        x = self.button.x + (self.button.w / 2) + self.cfg.margin + self.boxPadding.x,
        y = self.button.y - self.textHeight + self.cfg.textOffset
    }
end

function vPrompt:_Draw()
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

    self.button.x = self.cfg.origin.x - (self.background.w / 2) + (self.button.w / 2) + self.boxPadding.x
    self.button.text.x = self.button.x

    -- Render the boxes and text
    self:_RenderElement(self.cfg.label, self.background)
    self:_RenderElement(self.cfg.keyLabel, self.button, true)

    -- Draw keypress effect
    if self.pressed then
        self.highlight.w = self.highlight.w + (0.0005 * self.sw) / self.sw
        self.highlight.h = self.highlight.h + (0.0005 * self.sw) / self.sh
        self.highlight.a = self.highlight.a - 18

        SetDrawOrigin(self.cfg.coords.x, self.cfg.coords.y, self.cfg.coords.z, 0)
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

function vPrompt:_CreateThread()
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

            if self.cfg.entity then -- Entity was set in the options so track it's coords
                self.cfg.coords = GetEntityCoords(self.cfg.entity)

                self.cfg.coords = self.cfg.coords + self.cfg.offset
            elseif self.cfg.boneEntity then -- Entity bone was set in the options so track it's coords
                self.cfg.coords = GetWorldPositionOfEntityBone(self.cfg.boneEntity, self.cfg.boneIndex)

                self.cfg.coords = self.cfg.coords + self.cfg.offset
            else
                -- Coordinates were set in the options so we don't have to do anything     
            end
            
            -- Check distance between player and coords
            -- There's a place in hell for people that use the Vdist() or GetDistanceBetweenCoords() natives!!!!
            local dist = #(self.cfg.coords - pcoords)
    
            -- Check player is within draw distance
            if dist < self.cfg.drawDistance then
                local canDraw = self.cfg.canDraw()

                -- Can we draw?
                if canDraw then
                    letSleep = false

                    -- Render the elements
                    self:_Draw()
                    
                    -- Instance was previously hidden, but isn't now
                    if not self.visible then
                        self.visible = true

                        -- Fire the 'show' event
                        if self.cfg.callbacks.show then
                            self.cfg.callbacks.show()
                        end
                    end
                    
                    -- Check player is within interact distance
                    if dist < self.cfg.interactDistance then

                        -- We weren't within the interact distance previously, but have now entered
                        if not self.InInteractionArea then
                            self.InInteractionArea = true

                            -- Fire 'enterInteractZone' event
                            if self.cfg.callbacks.enterInteractZone then
                                self.cfg.callbacks.enterInteractZone()
                            end
                        end

                        self.canInteract = true

                        -- Detect keypress
                        if IsControlJustPressed(0, self.cfg.key) then
                            self.pressed = true

                            -- Fire 'interact' event
                            if self.cfg.callbacks.interact then
                                self.cfg.callbacks.interact(dist, pcoords)
                            end
                        end
                    else
                        self.canInteract = false

                        -- We were within the interact distance previously, but have now left
                        if self.InInteractionArea then
                            self.InInteractionArea = false
        
                            -- Fire 'exitInteractZone' event
                            if self.cfg.callbacks.exitInteractZone then
                                self.cfg.callbacks.exitInteractZone()
                            end
                        end                         
                    end
                end
            else
                -- We were within the draw distance previously, but have now left
                if self.visible then
                    self.visible = false

                    -- Fire 'hide' event
                    if self.cfg.callbacks.hide then
                        self.cfg.callbacks.hide()
                    end
                end               
            end

            if self.cfg.debug then
                letSleep = false

                local found, groundZ = GetGroundZFor_3dCoord(self.cfg.coords.x, self.cfg.coords.y, self.cfg.coords.z, false)
                DrawMarker(1, self.cfg.coords.x, self.cfg.coords.y, groundZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, self.cfg.interactDistance * 2, self.cfg.interactDistance * 2, 1.0, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                DrawMarker(1, self.cfg.coords.x, self.cfg.coords.y, groundZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, self.cfg.drawDistance * 2, self.cfg.drawDistance * 2, 1.0, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)                
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

function vPrompt:_GetTextWidth(text)
    BeginTextCommandGetWidth("STRING");
    SetTextScale(self.cfg.scale, self.cfg.scale)
    SetTextFont(self.cfg.font)
    SetTextEntry("STRING")    
    AddTextComponentString(text)
    return EndTextCommandGetWidth(1)    
end

function vPrompt:_RenderElement(text, box, centered)
    SetTextScale(self.cfg.scale, self.cfg.scale)
    SetTextFont(self.cfg.font)
    SetTextColour(box.fontColor.r, box.fontColor.g, box.fontColor.b, box.fontColor.a)
    SetTextEntry("STRING")
    SetTextCentre(centered ~= nil)
    AddTextComponentString(text)
    SetDrawOrigin(self.cfg.coords.x, self.cfg.coords.y, self.cfg.coords.z, 0)
    EndTextCommandDisplayText(box.text.x, box.text.y)
    DrawRect(box.x, box.y, box.w, box.h, box.bgColor.r, box.bgColor.g, box.bgColor.b, box.bgColor.a)
    ClearDrawOrigin()
end
