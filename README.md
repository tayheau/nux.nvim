# nux.nvim - A neovim mutliplexer

## Multiplexer inside nvim giving you control on your workspaces.
>[!IMPORTANT] WIP - Contributions and stars are welcome ! 
> Checkout the [TODO](#todo) section for upcoming features.
---

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [TODO](#todo)

---

[](https://github.com/user-attachments/assets/04810905-0a3d-42e5-8a4a-2e7beeaaf9e2)

---
## Features
- __Project Picker__: Quickly switch between projects.
- __Custom Project Layouts__: Define project roots and specify which files open in a new tab. Tabs open files in a spiral layout.
- __Smart Tab Naming__: Tabs automatically adapt names to match the current project.
- __Terminal Integration__: Open terminal sessions from your project configuration using term.
- __Flexible File Selection (WIP)__: Advanced filtering with a domain-specific language (DSL) for selecting files by folder, type, or last modified time.

## Installation 
`vim.pack`
```lua
vim.pack.add(
	{ src = "https://github.com/tayheau/nux.nvim" }
)
```
`lazy.nvim`
```lua
{
  "tayheau/nux.nvim"
}
```

## Usage
1. __Create a `projects` file__ (currently in `.config/nvim`) specifying the root and the files you want to open:
```
~/Foo/bar far.c term
```
    - `term` opens a terminal in that tab.
2. __Open the project picker__: select the project using `:Nux pickprojects` and let nux.nvim arrange your workspace automatically.
3. __Tabs__: Tabs will be named smartly based on your project, keeping your workspace organized.

## Configuration
Currently, the plugin is purely lazy loaded so there is no need to call `setup()` but it also mean no configuration at the moment. This is the very first commit so this is more of a personnal project but once again you are more than welcome to contribute to it and help `nux.nvim` to become a complete and robust nvim multiplexer !

One personnal recommandation would be to bind some key to the `:Nux pickprojects` command : 
```lua
vim.keymap.set('n', '<leader>p', ':Nux pickprojects<CR>')
```

## TODO
- select if you want the built-in header setup()
- close all buffers of the tab when closing the tab (except potentially running term process and non saved files) setup()
- save current layout on quit
- launch terminal process in background or front
- dont allow duplicates (show it in the picker too)
- allow custom name (inplace or not) rename(tabId, newName, inplace:bool) renameInplace() = partial rename(tabId, newName, true)
- ~~Floating window selector - shows files in different hl~~
    - make parser and domain specific language to allow more control on files :
    - e.g: <root-folder> {LAST_MODIFIED:folder}/*.py
    - 1st LEXING : split into tokens
    - 2nd PARSING: understanding thoses tokens
    - 3rd BUILDING : return a comprehensive list of instructions (dict root, files)
