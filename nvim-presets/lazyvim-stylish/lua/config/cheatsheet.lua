local function open()
  pcall(vim.cmd, "helpclose")
  local path = vim.fn.stdpath("config") .. "/cheatsheet.md"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("cheatsheet.md не найден", vim.log.levels.ERROR)
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local w, h = math.floor(vim.o.columns * 0.8), math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = math.floor((vim.o.lines - h) / 2),
    style = "minimal", border = "rounded", title = " Cheatsheet ",
  })
  vim.bo[buf].filetype = "markdown"
  pcall(vim.treesitter.start, buf, "markdown")
  vim.wo[win].wrap = false
  vim.wo[win].conceallevel = 2
  vim.wo[win].spell = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
  vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = buf })
end

vim.keymap.set({ "n", "i" }, "<F1>", open, { desc = "Cheatsheet" })
vim.keymap.set("n", "<leader>H", open, { desc = "Cheatsheet" })
vim.api.nvim_create_user_command("Cheat", open, {})
