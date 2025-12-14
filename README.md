# chace.nvim

Neovim plugin for CHACE (CHamal's AutoComplete Engine) - a controlled AI-assisted code completion tool.

## Overview

**chace.nvim** integrates the CHACE Rust engine into Neovim, providing focused AI code completion.  Instead of generating large code blocks, CHACE targets specific functions at your cursor position and generates the implementation.

## Features

- Targets empty function definitions at cursor position
- Sends minimal context to LLM (function signature and documentation only)
- Reduces token usage and produces predictable results
- Supports multiple LLM backends (Gemini, Groq)
- Currently supports Rust language

## Requirements

- Neovim 0.11+
- CHACE engine running (see [CHACE](https://github.com/chamal1120/chace))
- Unix socket support (Linux/macOS)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'chamal1120/chace.nvim',
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
  config = function()
    require('chace').setup({
      debug = false,
      show_notifications = true,
    })
  end
}
```

## Setup

Ensure the CHACE engine is running before using the plugin:

```bash
# Start CHACE server
chace
```

Configure environment variables for LLM providers:

```bash
export GEMINI_API_KEY="your-api-key"
export GROQ_API_KEY="your-api-key"
```

## Usage

Place your cursor inside an empty function definition and trigger completion:

```vim
:Chace
```

or use the keybind `leader + c`

## Configuration

Default configuration:

```lua
require('chace').setup({
  debug = false, -- Set to true to enable debug logs
  show_notifications = true, -- Set to false to suppress all notifications
  model = "groq", -- set model (ie: "Gemini")
  keymap = "<leader>c", -- set keymap
})
```

## License

MIT License - see [LICENSE](LICENSE) for details.
