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

local function mergeTables(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                mergeTables(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

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

    return obj
end

function vPrompt:_Init(cfg)
    -- Check for valid key
    assert(Keys[cfg.key] ~= nil, string.format('^1Invalid key: %s', cfg.key))

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
        keyColor = { r = 0, g = 0, b = 0, a = 255 },
        drawDistance = 4.0,
        interactDistance = 2.0,
        canDraw = function() return true end,
        canInteract = function() return true end,
        drawMarker = false
    }

    local defaultMarker = {
        drawDistance = 20.0,
        type = 1,
        dirX = 0.0, dirY = 0.0, dirZ = 0.0, 
        rotX = 0.0, rotY = 0.0, rotZ = 0.0, 
        scaleX = 1.0, scaleY = 1.0, scaleZ = 1.0, 
        color = { r = 255, g = 255, b = 255, a = 150 },
        bobUpAndDown = false, 
        faceCamera = false, 
        rotate = false,
        textureDict = nil,
        textureName = nil,
        drawOnEnts = false
    }

    -- Merge user-defined options
    self.cfg = mergeTables(defaultConfig, cfg)   

    self.cfg.key = Keys[cfg.key]
    self.cfg.keyLabel = tostring(cfg.key)
    self.cfg.label = tostring(cfg.label)
    self.cfg.callbacks = {}

    if self.cfg.entity then
        -- Check for valid entity
        assert(DoesEntityExist(self.cfg.entity), '^1Invalid entity passed to "entity" option')
    elseif self.cfg.bone then
        -- Check for valid entity
        assert(DoesEntityExist(self.cfg.bone.entity), '^1Invalid entity passed to "bone.entity" option')

        self.cfg.boneEntity = self.cfg.bone.entity
        self.cfg.boneIndex = GetEntityBoneIndexByName(self.cfg.bone.entity, self.cfg.bone.name)
    elseif self.cfg.coords then
        -- Check for valid vector3 coords
        assert(type(self.cfg.coords) == 'vector3', '^1Invalid vector3 value passed to "coords" option')
    
        -- Apply the offset here otherwise if we do it in the main loop it'll move by the offset every iteration
        self.cfg.coords = self.cfg.coords + self.cfg.offset    
    end

    -- 
    if self.cfg.drawMarker ~= false then
        assert(type(self.cfg.drawMarker) == 'table', '^1Option "drawMarker" must be table of options')

        self.cfg.marker = mergeTables(defaultMarker, self.cfg.drawMarker)   
    end

    -- Handle offsets for native GTA:V fonts
    if self.cfg.font == 1 then
        self.cfg.textOffset = 0.01
    elseif self.cfg.font == 2 then
        self.cfg.textOffset = 0.009
    elseif self.cfg.font == 4 or self.cfg.font == 5 or self.cfg.font == 6 or self.cfg.font == 7 then
        self.cfg.textOffset = 0.008
    end

    self:_CreateThread()
    
    -- Make sure we destroy the instance if the resource stops
    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            self:Destroy()
        end
    end)    
end

------
--
-- Updates the dimensions and positions
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

    if tostring(key) ~= self.cfg.keyLabel then
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
-- Updates the background box color
--
-- @param r     integer        - the new red value
-- @param g     integer        - the new green value
-- @param b     integer        - the new blue value
-- @param a     integer        - the new alpha value
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
-- Updates the label text color
--
-- @param r     integer        - the new red value
-- @param g     integer        - the new green value
-- @param b     integer        - the new blue value
-- @param a     integer        - the new alpha value
--
-- @return void
--
------
function vPrompt:SetLabelColor(r, g, b, a)
    self.cfg.labelColor.r = r
    self.cfg.labelColor.g = g
    self.cfg.labelColor.b = b
    self.cfg.labelColor.a = a
end

------
--
-- Updates the key text color
--
-- @param r     integer        - the new red value
-- @param g     integer        - the new green value
-- @param b     integer        - the new blue value
-- @param a     integer        - the new alpha value
--
-- @return void
--
------
function vPrompt:SetKeyColor(r, g, b, a)
    self.cfg.keyColor.r = r
    self.cfg.keyColor.g = g
    self.cfg.keyColor.b = b
    self.cfg.keyColor.a = a
end

------
--
-- Updates the button color
--
-- @param r     integer        - the new red value
-- @param g     integer        - the new green value
-- @param b     integer        - the new blue value
-- @param a     integer        - the new alpha value
--
-- @return void
--
------
function vPrompt:SetButtonColor(r, g, b, a)
    self.cfg.buttonColor.r = r
    self.cfg.buttonColor.g = g
    self.cfg.buttonColor.b = b
    self.cfg.buttonColor.a = a
end

------
--
-- Updates the coords
--
-- @param coords     table | vec3        - the new coords
--
-- @return void
--
------
function vPrompt:SetCoords(coords)
    self.cfg.coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
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


------
-- PRIVATE METHODS
------

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
        bc = self.cfg.buttonColor,
        fc = self.cfg.keyColor          
    }

    self.fx = { w = self.button.w, h = self.button.h, a = 255 }
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
        bc = self.cfg.backgroundColor,
        fc = self.cfg.labelColor    
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

    -- Default to collapsed
    if self.cfg.drawDistance > self.cfg.interactDistance then
        self.background.w = self.minWidth
    end
end

function vPrompt:_Draw()
    local bg    = self.background
    local btn   = self.button

    if self.canInteract then
        if bg.w < self.maxWidth then
            bg.w = bg.w + 0.008
        end

        bg.fc.a = 255
    else
        if bg.w > self.minWidth then
            bg.w = bg.w - 0.008
        else
            bg.w = self.minWidth
        end

        bg.fc.a = 0
    end

    btn.x = self.cfg.origin.x - (bg.w / 2) + (btn.w / 2) + self.boxPadding.x
    btn.text.x = btn.x

    -- Render the boxes and text
    self:_RenderElement(self.cfg.label, bg)
    self:_RenderElement(self.cfg.keyLabel, btn, true)

    -- Draw keypress effect
    if self.pressed then
        self.fx.w = self.fx.w + (0.0005 * self.sw) / self.sw
        self.fx.h = self.fx.h + (0.0005 * self.sw) / self.sh
        self.fx.a = self.fx.a - 18

        SetDrawOrigin(self.cfg.coords.x, self.cfg.coords.y, self.cfg.coords.z, 0)
        DrawRect(btn.x, btn.y, self.fx.w, self.fx.h, btn.bc.r, btn.bc.g, btn.bc.b, self.fx.a)
        ClearDrawOrigin()  

        if self.fx.a <= 0 then
            self.pressed = false
            self.fx = { w = btn.w, h = btn.h, a = 255 }            
        end
    end
end

function vPrompt:_CreateThread()
    Citizen.CreateThread(function()
        self:Update()

        while true do
            local letSleep = true
            local player = PlayerPedId()
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

                            local canInteract = self.cfg.canInteract()

                            if canInteract then
                                -- Fire 'interact' event
                                if self.cfg.callbacks.interact then
                                    self.cfg.callbacks.interact(dist, pcoords)
                                end
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

            if self.cfg.marker or self.cfg.debug then
                letSleep = false

                local found, groundZ = GetGroundZFor_3dCoord(self.cfg.coords.x, self.cfg.coords.y, self.cfg.coords.z, false)

                -- Draw marker
                if self.cfg.marker then
                    if dist < self.cfg.marker.drawDistance then
                        local m = self.cfg.marker
                        DrawMarker(m.type, self.cfg.coords.x, self.cfg.coords.y, groundZ, m.dirX, m.dirY, m.dirZ, m.rotX, m.rotY, m.rotZ, m.scaleX, m.scaleY, m.scaleZ, m.color.r, m.color.g, m.color.b, m.color.a, m.bobUpAndDown, m.faceCamera, 2, m.rotate, m.textureDict, m.textureName, m.drawOnEnts)
                    end
                end

                -- Draw debug markers
                if self.cfg.debug then
                    DrawMarker(1, self.cfg.coords.x, self.cfg.coords.y, groundZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, self.cfg.interactDistance * 2, self.cfg.interactDistance * 2, 1.0, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                    DrawMarker(1, self.cfg.coords.x, self.cfg.coords.y, groundZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, self.cfg.drawDistance * 2, self.cfg.drawDistance * 2, 1.0, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)                
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
    SetTextColour(box.fc.r, box.fc.g, box.fc.b, box.fc.a)
    SetTextEntry("STRING")
    SetTextCentre(centered ~= nil)
    AddTextComponentString(text)
    SetDrawOrigin(self.cfg.coords.x, self.cfg.coords.y, self.cfg.coords.z, 0)
    EndTextCommandDisplayText(box.text.x, box.text.y)
    DrawRect(box.x, box.y, box.w, box.h, box.bc.r, box.bc.g, box.bc.b, box.bc.a)
    ClearDrawOrigin()
end
