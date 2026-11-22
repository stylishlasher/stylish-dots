vim.cmd("hi clear")
vim.o.termguicolors = true
vim.g.colors_name = "dots"

local paths = {
  vim.fn.expand("~/.local/state/quickshell/user/generated/colors.json"),
  vim.fn.expand("~/.local/state/quickshell/user/generated/material_colors.json"),
}
local data
for _, p in ipairs(paths) do
  local f = io.open(p, "r")
  if f then
    local ok, j = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if ok and type(j) == "table" then data = j; vim.g.dots_colors_path = p; break end
  end
end
data = data or {}

local function get(name, default)
  local camel = name:gsub("_(%l)", function(c) return c:upper() end)
  return data[name] or data[camel] or data["m3" .. camel] or default
end

local c = {
  bg = get("surface", "#1a1b26"), bg_dim = get("surface_container_low", "#1f2030"),
  bg_hi = get("surface_container_high", "#292a3a"), fg = get("on_surface", "#c0caf5"),
  fg_dim = get("on_surface_variant", "#9aa5ce"), outline = get("outline_variant", "#444a60"),
  primary = get("primary", "#7aa2f7"), on_primary = get("on_primary", "#1a1b26"),
  secondary = get("secondary", "#bb9af7"), tertiary = get("tertiary", "#e0af68"),
  error = get("error", "#f7768e"), sel = get("secondary_container", "#33467c"),
}

local function hl(g, o) vim.api.nvim_set_hl(0, g, o) end
hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.bg_dim })
hl("FloatBorder", { fg = c.primary, bg = c.bg_dim })
hl("CursorLine", { bg = c.bg_dim })
hl("CursorLineNr", { fg = c.primary, bold = true })
hl("LineNr", { fg = c.outline })
hl("Visual", { bg = c.sel })
hl("Search", { fg = c.on_primary, bg = c.primary })
hl("IncSearch", { fg = c.on_primary, bg = c.tertiary })
hl("Pmenu", { fg = c.fg, bg = c.bg_dim })
hl("PmenuSel", { bg = c.sel })
hl("StatusLine", { fg = c.fg, bg = c.bg_dim })
hl("WinSeparator", { fg = c.outline })
hl("MatchParen", { fg = c.tertiary, bold = true })
hl("Folded", { fg = c.fg_dim, bg = c.bg_dim })
hl("SignColumn", { bg = c.bg })
hl("Comment", { fg = c.fg_dim, italic = true })
hl("Constant", { fg = c.tertiary })
hl("String", { fg = c.secondary })
hl("Number", { fg = c.tertiary })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.primary })
hl("Statement", { fg = c.primary, bold = true })
hl("Keyword", { fg = c.primary, italic = true })
hl("Type", { fg = c.tertiary })
hl("Operator", { fg = c.fg_dim })
hl("PreProc", { fg = c.secondary })
hl("Special", { fg = c.tertiary })
hl("DiagnosticError", { fg = c.error })
hl("DiagnosticWarn", { fg = c.tertiary })
hl("DiagnosticInfo", { fg = c.primary })
hl("DiagnosticHint", { fg = c.secondary })
hl("GitSignsAdd", { fg = c.secondary })
hl("GitSignsChange", { fg = c.tertiary })
hl("GitSignsDelete", { fg = c.error })
for from, to in pairs({ ["@variable"] = "Identifier", ["@string"] = "String", ["@function"] = "Function", ["@keyword"] = "Keyword", ["@type"] = "Type", ["@number"] = "Number", ["@comment"] = "Comment", ["@operator"] = "Operator", ["@constant"] = "Constant", ["@punctuation"] = "Operator" }) do
  vim.api.nvim_set_hl(0, from, { link = to })
end

-- автообновление при смене обоев
local dir = vim.g.dots_colors_path and vim.fn.fnamemodify(vim.g.dots_colors_path, ":h")
if dir and not vim.g.dots_watching then
  vim.g.dots_watching = true
  local w = vim.uv.new_fs_event()
  local t = vim.uv.new_timer()
  w:start(dir, {}, function()
    t:stop()
    t:start(300, 0, vim.schedule_wrap(function() vim.cmd.colorscheme("dots") end))
  end)
end

-- Markdown
hl("@markup.heading", { fg = c.primary, bold = true })
for i = 1, 6 do
  hl("@markup.heading." .. i, { fg = c.primary, bold = true })
end
hl("@markup.strong", { fg = c.fg, bold = true })
hl("@markup.italic", { fg = c.fg, italic = true })
hl("@markup.strikethrough", { fg = c.fg_dim, strikethrough = true })
hl("@markup.raw", { fg = c.tertiary, bg = c.bg_dim })
hl("@markup.raw.block", { fg = c.tertiary })
hl("@markup.list", { fg = c.secondary })
hl("@markup.quote", { fg = c.fg_dim, italic = true })
hl("@markup.link", { fg = c.secondary })
hl("@markup.link.label", { fg = c.secondary, underline = true })
hl("@markup.link.url", { fg = c.fg_dim, underline = true })
hl("@punctuation.special", { fg = c.secondary })
hl("@punctuation.delimiter", { fg = c.fg_dim })
hl("@string.escape", { fg = c.tertiary })
hl("Title", { fg = c.primary, bold = true })

-- render-markdown
for i = 1, 6 do
  hl("RenderMarkdownH" .. i, { fg = c.primary, bold = true })
  hl("RenderMarkdownH" .. i .. "Bg", { fg = c.primary, bg = c.bg_hi, bold = true })
end
hl("RenderMarkdownCode", { bg = c.bg_dim })
hl("RenderMarkdownCodeInline", { fg = c.tertiary, bg = c.bg_dim })
hl("RenderMarkdownBullet", { fg = c.secondary })
hl("RenderMarkdownQuote", { fg = c.fg_dim })
