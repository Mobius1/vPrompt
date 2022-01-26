# vPrompt
 3D Interactive Prompts for FiveM

vPrompt draws floating prompt elements like seen in ESX's `DrawText3D()` method, but with an added button element and background. vPrompt automatically detects when a player is within interaction range and listens for when the defined key is pressed. This removes the need to write extra logic in your resource for calculating the player's proximty to the coords / entity / bone and also removes the need for extra keypress logic.


 ### Features
 * Customisable appearance and positioning
 * Event emitter for easy listening of events
 * Detects keypress when in interact range
 * Proximity system - no need for extra logic in your code for calculating distances
 * Animated reveal / hide
 * Animated keypress effect
 * Resmon: 
    * `0.00ms` when not in draw range
    * `0.07ms` when drawn / in draw / interact range (uses scaleform so can't reduce it any more)


![vPrompt](https://i.imgur.com/a7QwgLD.gif)

---


- [Demos](#demos)
- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
- [Methods](#methods)
- [Events](#events)
---

## Demos
- [Video](https://streamable.com/q4zhuc)

---

## Installation
* Drop the `vPrompt` directory into you `resources` directory
* Add `ensure vPrompt` to your `server.cfg` file
* Add `'@vPrompt/vprompt.lua'` to the `client_scripts` table in the `fxmanifest.lua`:

```lua
client_scripts {
    '@vPrompt/vprompt.lua',
    ...
}
```

---

## Usage
Create prompt for coords:
```lua
local myPrompt = vPrompt:Create({
    key = "E",
    label = "Search Bin",
    coords = vector3(-311.05, -1535.51, 27.90)
})
```

Create prompt for entity:
```lua
local player = PlayerPedId()
local coords = GetEntityCoords(player)
local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.00, 0, 70)

local myPrompt = vPrompt:Create({
    key = "E",
    label = "Open Boot",
    entity = vehicle,
    canDraw = function()
        -- Only draw the prompt if the player is not in a vehicle
        return not IsPedInAnyVehicle(player)
    end 
})
```

Create prompt for entity bone:
```lua
local player = PlayerPedId()
local coords = GetEntityCoords(player)
local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.00, 0, 70)

local myPrompt = vPrompt:Create({
    key = "E",
    label = "Pick Doorlock",
    bone = {
        entity = vehicle, -- the entity
        name = 'door_dside_f' -- the bone name
    },
    canDraw = function()
        -- Only draw the prompt if the player is not in a vehicle
        return not IsPedInAnyVehicle(player)
    end,
    canInteract = function()
        -- Only allow interaction if player has the lockpick item
        local hasLockPick = QBCore.Functions.HasItem('lockpick')

        return hasLockPick
    end    
})
```

---

## Options
```lua
local myPrompt = vPrompt:Create({
    key = 'E',                  -- the key to be pressed
    label = 'Press Me',         -- the label
    drawDistance = 4.0,         -- The distance from the coords / entity / bone before the prompt is drawn
    interactDistance = 2.0,     -- The distance from the coords / entity / bone before the player can interact    
    font = 0,                   -- the font to be used
    scale = 0.4,                -- the font scale
    margin = 0.008,             -- The left / right margin for the label text  (percentage of screen)
    padding = 0.004,            -- the padding for the background box (percentage of screen)
    buttonSize = 0.015,         -- The size of the button (percentage of screen)
    textOffset = 0.00,          -- y-offset for the text for custom fonts (GTAV native fonts are handled by the instance)
    offset = vector3(0, 0, 0)   -- The offset to apply to the prompt position
    backgroundColor = { r = 0, g = 0, b = 0, a = 100 },     -- background box color
    labelColor = { r = 255, g = 255, b = 255, a = 255 },    -- the label color
    buttonColor = { r = 255, g = 255, b = 255, a = 255 },   -- the button's background color
    keyColor = { r = 0, g = 0, b = 0, a = 255 },            -- the button's text color
    canDraw = function()
        -- this should return a boolean as to whether the instance should be drawn
    end,    
    canInteract = function()
        -- this should return a boolean as to whether the keypress can be fired
    end,
    debug = false -- Draws debug markers to show draw and interact distances
})
```

---

## Events

```lua
local myPrompt = vPrompt:Create({ ... })

myPrompt:On('interact', function()
    -- Do something when the player presses the key
end)

myPrompt:On('enterInteractZone', function()
    -- Do something when the player enters the interaction zone
end)

myPrompt:On('exitInteractZone', function()
    -- Do something when the player exits the interaction zone
end)

myPrompt:On('show', function()
    -- Do something when the prompt becomes visible
end)

myPrompt:On('hide', function()
    -- Do something when the prompt gets hidden
end)
```

---

## Methods

#### Update the coords
```lua
myPrompt:SetCoords(
    coords --[[ table | vec3 ]]
)
```

Won't work if `entity` or `bone` options are used

#### Update key
```lua
myPrompt:SetKey(
    key --[[ string ]]
)
```

#### Update label
```lua
myPrompt:SetLabel(
    label --[[ string ]]
)
```

#### Update the background colour
```lua
myPrompt:SetBackgroundColor(
    r --[[ integer ]],
    g --[[ integer ]],
    b --[[ integer ]],
    a --[[ integer ]]
)
```

#### Update font color of the label
```lua
myPrompt:SetLabelColor(
    r --[[ integer ]],
    g --[[ integer ]],
    b --[[ integer ]],
    a --[[ integer ]]
)
```

#### Update font color of the button
```lua
myPrompt:SetKeyColor(
    r --[[ integer ]],
    g --[[ integer ]],
    b --[[ integer ]],
    a --[[ integer ]]
)
```

#### Update the background color of the button
```lua
myPrompt:SetButtonColor(
    r --[[ integer ]],
    g --[[ integer ]],
    b --[[ integer ]],
    a --[[ integer ]]
)
```

#### Destroy the instance
```lua
myPrompt:Destroy()
```

NOTE: The instance is automatically destroyed if the resource using it is stopped / restarted

---
