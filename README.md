<div style="text-align: left;">
  <img src="assets/chace.nvim-logo.png" style="width:70%; margin: 0 auto;" />
</div>

## Overview

**CHACE.nvim** is an AI based code completion plugin built for neovim targetting **power users** or people who are fed up with AI splashing slop all over their codebases. It utilizes a blazing fast treesitter based backend [CHACE](https://github.com/chamal1120/chace) that parses the current buffer, selects and sends the minimal context (which can only be expanded on user's decision) to an LLM of choice for generating implementaions.

This is not an inline completion tool for completing every line you type. I specifically built this for trying out a new **zen AI code completions experience** where a user only calls an LLM when needed for implementing complex (or cumbersome) logics which lives inside functions/methods most of the time. I believe this approach is better because this way we can lay the blueprints (the classes, objects, structs and traits) ourselves and only call an LLM for help to implement something that is complicated or lazy to implement manually.

> [!NOTE]
> This plugin is in early-development so bugs and breaking changes might occur.

## Demo
![CHACE demo showing it's cabapilities](assets/demo.webp)

## Features

- Targets function declerations at cursor position
- Sends minimal context to LLM ( as of now function decleration and documentation only)
- Supports multiple LLM backends (Gemini, groq)
- Incurs less tokens compared to tools like GitHub Copilot or agents like cursor for implementing the same function.
- Tracks token usage.

## Requirements

- Neovim 0.11+
- CHACE engine installed (see [CHACE](https://github.com/chamal1120/chace))
- Unix socket support (Linux/macOS)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'chamal1120/chace.nvim',
  cmd = { "Chace", "ChaceAddSnippet", "ChaceClearContexts" },
  keys = { 
      { "<leader>c", desc = "Chace Run" },
      { "<leader>ct", mode = "v", desc = "Chace Add Snippet" } 
  },
  config = function()
    require('chace').setup({
      debug = false,
      show_notifications = true,
    })
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'chamal1120/chace.nvim',
  cmd = { "Chace", "ChaceAddSnippet", "ChaceClearContexts" },
  keys = { 
      { "<leader>c", desc = "Chace Run" },
      { "<leader>ct", mode = "v", desc = "Chace Add Snippet" } 
  },
  config = function()
    require('chace').setup({
      debug = false,
      show_notifications = true,
    })
  end
}
```

## Setup

1. Configure environment variables for LLM providers:

```bash
export GEMINI_API_KEY="your-api-key"
export GROQ_API_KEY="your-api-key"
```

## Usage

2. Place your cursor inside an empty function decleration and trigger completion:

```vim
:Chace
```

or use the keybind `leader + c`

## Configuration

Default configuration:

```lua
require('chace').setup({
  debug =               false,          -- Set to true to enable debug logs
  show_notifications =  true,           -- Set to false to suppress all notifications
  model =               "groq",         -- set model (Gemini/groq)
  keymap =              "<leader>c",    -- set completion key
  add_keymap =          "<leader>ct",   -- set add to context key
  clear_keymap =        "<leader>cu",   -- set clear contexts list key
})
```

## License

MIT License - see [LICENSE](LICENSE) for details.
