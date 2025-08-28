# nux.nvim
## A neovim mutliplexer
Multiplexer inside nvim giving you control on your workspaces.
---
>[!IMPORTANT] 
> Currently a WIP so any contributions or stars are welcome ;)
> Here is the current [`TODO`](# TODO)

>[!TIP]
> See more details in the [features](# Features) section.
> See how to install [here](# Installation)
---

[](https://github.com/user-attachments/assets/04810905-0a3d-42e5-8a4a-2e7beeaaf9e2)

---

## Installation 
`vim.pack`
```lua
vim.pack.add(
	{ src = "https://github.com/tayheau/nux.nvim" }
)
```
`lazy.nvim`
```lua


# TODO
- select if you wnat the built-in header setup()
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
