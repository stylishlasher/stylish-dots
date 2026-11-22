-- Options (LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 6
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitright = true
opt.ignorecase = true
opt.smartcase = true
opt.undofile = true
opt.updatetime = 200
opt.timeoutlen = 400
opt.clipboard = "unnamedplus"
opt.confirm = true
opt.pumheight = 12
opt.fillchars = { eob = " ", foldopen = "", foldclose = "", fold = " ", foldsep = " " }
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- RU layout support
opt.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"
