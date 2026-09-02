local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- builtin
keymap.set("i", "hj", "<ESC>", opts)
keymap.set("i", "<C-b>", "<ESC>", opts)
keymap.set("n", "j", "gj", opts)
keymap.set("n", "k", "gk", opts)
keymap.set("v", "j", "gj", opts)
keymap.set("v", "k", "gk", opts)
keymap.set("t", "<ESC>", "<C-\\><C-n>", opts)
keymap.set("t", "<C-[>", "<C-\\><C-n>", opts)
keymap.set("n", "<C-b>h", "<cmd>BufferPrevious<CR>", opts)
keymap.set("n", "<C-b><C-h>", "<cmd>BufferPrevious<CR>", opts)
keymap.set("n", "<C-b>l", "<cmd>BufferNext<CR>", opts)
keymap.set("n", "<C-b><C-l>", "<cmd>BufferNext<CR>", opts)
keymap.set("n", "<C-b>d", "<cmd>BufferDelete<CR>", opts)
keymap.set("n", "<C-b><C-d>", "<cmd>BufferClose<CR>", opts)
keymap.set("n", "<C-i>", "<C-a>", opts) -- increment
keymap.set("n", "sa", "ggVG", opts) -- select all
keymap.set("n", "sw", "vw", opts) -- select word
keymap.set("n", "dl", "d$", opts) -- delete to end of line
keymap.set("n", "dh", "d0", opts) -- delete to beginning of line
keymap.set("n", "zM", require("ufo").closeAllFolds)
keymap.set("n", "zR", require("ufo").openAllFolds)
keymap.set("n", "H", "za")
keymap.set("n", "L", "zo")
keymap.set("n", "<Space>h", "zM")
keymap.set("n", "<Space>l", "zR")

-- plugins
-- Neo-tree
keymap.set("n", "<Space>e", "<cmd>Neotree<CR>", { noremap = true, silent = true })
-- ohters in neo-tree.lua

-- telescope
keymap.set("n", "<Space>g", "<cmd>Telescope git_files<CR>", { noremap = true, silent = true })
keymap.set("n", "<Space>f", "<cmd>Telescope find_files<CR>", { noremap = true, silent = true })
keymap.set("n", "<Space>o", "<cmd>Telescope oldfiles<cr>", { noremap = true, silent = true })
keymap.set("n", "<Space>r", "<cmd>Telescope live_grep<CR>", { noremap = true, silent = true })

-- lightspeed
-- keymap.set("n", "s", "<Plug>Lightspeed_s", { noremap = true, silent = true })

-- builtin lsp
keymap.set("n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true }) -- rename
keymap.set("n", "gm", "<cmd>lua vim.lsp.buf.format()<CR>", { silent = true }) -- format
keymap.set("n", "GE", vim.diagnostic.goto_prev, { silent = true }) -- go to previous diagnostic
keymap.set("n", "gE", vim.diagnostic.goto_prev, { silent = true }) -- go to previous diagnostic
keymap.set("n", "ge", vim.diagnostic.goto_next, { silent = true }) -- go to next diagnostic
keymap.set("n", "gd", function()
	vim.cmd("vsplit")
	require("telescope.builtin").lsp_definitions()
end, { silent = true }) -- go to definition
keymap.set("n", "gt", require("telescope.builtin").lsp_type_definitions, { silent = true }) -- go to type definition

-- markdown-preview
keymap.set("n", "<C-m>d", "<Plug>MarkdownPreviewToggle", { noremap = false, silent = true })

-- toggleterm
keymap.set("n", "<Space>tv", "<cmd>ToggleTerm direction=vertical size=100<CR>", { noremap = true, silent = true })
keymap.set("n", "<Space>th", "<cmd>ToggleTerm direction=horizontal size=12<CR>", { noremap = true, silent = true })
keymap.set("n", "<Space>tf", "<cmd>ToggleTerm direction=float<CR>", { noremap = true, silent = true })
keymap.set("n", "<Space>tt", "<cmd>lua tig_toggle()<CR>", { noremap = true, silent = true })
keymap.set("t", "<C-n>", "<cmd>ToggleTerm<CR>", { noremap = true, silent = true })

-- camel-case-motion
keymap.set("n", "cw", "<Plug>CamelCaseMotion_w", { noremap = true, silent = true })
-- keymap.set("n", "cb", "<Plug>CamelCaseMotion_b", { noremap = true, silent = true })
-- keymap.set("n", "ce", "<Plug>CamelCaseMotion_e", { noremap = true, silent = true })
-- keymap.set("n", "ycw", "v<Plug>CamelCaseMotion_iwy", { noremap = true, silent = true })
-- keymap.set("n", "vb", "v<Plug>CamelCaseMotion_ib", { noremap = true, silent = true })
-- keymap.set("n", "ve", "v<Plug>CamelCaseMotion_ie", { noremap = true, silent = true })
keymap.set("n", "dcw", "d<Plug>CamelCaseMotion_w", { noremap = true, silent = true })
-- keymap.set("n", "dcb", "d<Plug>CamelCaseMotion_b", { noremap = true, silent = true })
-- keymap.set("n", "de", "d<Plug>CamelCaseMotion_e", { noremap = true, silent = true })

-- nvim-dap
-- local status, dap = pcall(require, "dap")
-- if status then
--   keymap.set("n", "<F5>", function()
--     dap.continue()
--   end)
--   keymap.set("n", "<F10>", function()
--     dap.step_over()
--   end)
--   keymap.set("n", "<F11>", function()
--     dap.step_into()
--   end)
--   keymap.set("n", "<F12>", function()
--     dap.step_out()
--   end)
--   keymap.set("n", "<Leader>b", function()
--     dap.toggle_breakpoint()
--   end)
--   keymap.set("n", "<Leader>B", function()
--     dap.set_breakpoint()
--   end)
--   keymap.set("n", "<Leader>lp", function()
--     dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
--   end)
--   keymap.set("n", "<Leader>dr", function()
--     dap.repl.open()
--   end)
--   keymap.set("n", "<Leader>dl", function()
--     dap.run_last()
--   end)
--   keymap.set({ "n", "v" }, "<Leader>dh", function()
--     require("dap.ui.widgets").hover()
--   end)
--   keymap.set({ "n", "v" }, "<Leader>dp", function()
--     require("dap.ui.widgets").preview()
--   end)
--   keymap.set("n", "<Leader>df", function()
--     local widgets = require("dap.ui.widgets")
--     widgets.centered_float(widgets.frames)
--   end)
--   keymap.set("n", "<Leader>ds", function()
--     local widgets = require("dap.ui.widgets")
--     widgets.centered_float(widgets.scopes)
--   end)
-- end
