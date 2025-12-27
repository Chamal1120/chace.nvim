-- Minimal init file for running tests
vim.cmd([[set runtimepath=$VIMRUNTIME]])
vim.cmd([[set packpath=/tmp/nvim/site]])

local package_root = "/tmp/nvim/site/pack"
local install_path = package_root .. "/packer/start/plenary.nvim"

vim.opt.runtimepath:append(vim.fn.getcwd())
