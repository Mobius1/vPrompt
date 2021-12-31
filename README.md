# vPrompt
 3D Interactive Prompts for FiveM

- [Installation](#installation)
- [Usage](#usage)
- [Events](#events)

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

If you need to restart a resource that has an instance of `vPrompt` then use the `Destroy()` method as follows:

```lua
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        myPrompt:Destroy()
    end
end)
```

## Events

```lua
local myPrompt = vPrompt:Create({ ... })

myPrompt:On('interact', function()
    -- Do something when the player presses the key
end)

prompt:On('enterInteractionZone', function()
    -- Do something when the player enters the interaction zone
end)

prompt:On('exitInteractionZone', function()
    -- Do something when the player exits the interaction zone
end)

myPrompt:On('show', function()
    -- Do something when the prompt becomes visible
end)

myPrompt:On('hide', function()
    -- Do something when the prompt gets hidden
end)
```