# vPrompt
 3D Interactive Prompts for FiveM

- [Installation](#installation)
- [Usage](#usage)
- [Events](#events)
- [Options](#options)
- 
---

## Requirements
* None!
 
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
local pcoords = GetEntityCoords(player)
local bin = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, 5.0, -654402915)

local myPrompt = vPrompt:Create({
    key = "E",
    label = "Open Boot",
    entity = bin
})
```

Create prompt for entity bone:
```lua
local vehicle = GetClosestVehicle(x, y, z, 5.00, 0, 70)
local myPrompt = vPrompt:Create({
    key = "E",
    label = "Pick Doorlock",
    bone = {
        entity = vehicle, -- the entity
        name = 'door_dside_f' -- the bone name
    }
})
```

Destroy an instance:
```lua
myPrompt:Destroy()
```

NOTE: The instance is automatically destroyed if the resource using it is stopped / restarted

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

## Options
```lua
local myPrompt = vPrompt:Create({
    key = 'E',              -- the key to be pressed
    label = 'Press Me',     -- the label
    font = 0,               -- the font to be used
    scale = 0.4,            -- the font scale
    margin - 0.008,         -- The left / right margin for the label text
    padding = 0.004,        -- the padding for the background box
    offsetY = 0.00,         -- y-offset for the text (for custom fonts - GTAV native fonts are handled by the instance)
    drawDistance = 4.0,     -- The distance from the coords / entity / bone before the prompt is drawn
    interactDistance - 2.0, -- The distance from the coords / entity / bone before the player can interact
    backgroundColor = { r = 0, g = 0, b = 0, a = 100 },     -- background box color
    labelColor = { r = 255, g = 255, b = 255, a = 255 },    -- the label color
    buttonColor = { r = 255, g = 255, b = 255, a = 255 },   -- the button's background color
    buttonLabelColor = { r = 0, g = 0, b = 0, a = 255 },    -- the button's text color
    canDraw = function()
        -- this should return a boolean
    end
})
```
