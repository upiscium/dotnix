vim.cmd("autocmd!")
local opt = vim.opt
vim.scriptencoding = "utf-8"
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.fileformat = "unix"
opt.number = true
opt.relativenumber = false
opt.mouse = "a"
opt.title = true
opt.autoindent = true
opt.smartindent = true
opt.breakindent = true
opt.hlsearch = true
opt.backup = false
opt.showcmd = true
opt.cmdheight = 2
opt.laststatus = 2
opt.expandtab = true
opt.scrolloff = 10
opt.shell = "zsh"
opt.shellquote = ""
opt.shellxquote = ""
opt.inccommand = "split"
opt.ignorecase = true
opt.smarttab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.wrap = false
opt.helplang = "en"
opt.updatetime = 300
opt.showtabline = 4
opt.clipboard = "unnamedplus"

-- SSH 先では OSC 52 経由でローカル端末のクリップボードにコピーする
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
	local osc52 = require("vim.ui.clipboard.osc52")
	-- 多くの端末は OSC 52 の読み出しを許可しないため、ペーストは無名レジスタから行う
	local function paste()
		return {
			vim.fn.split(vim.fn.getreg(""), "\n"),
			vim.fn.getregtype(""),
		}
	end
	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = osc52.copy("+"),
			["*"] = osc52.copy("*"),
		},
		paste = {
			["+"] = paste,
			["*"] = paste,
		},
	}
end
opt.termguicolors = true
opt.signcolumn = "yes"
opt.hidden = true
opt.swapfile = true
opt.wrap = true
opt.pumblend = 7
opt.list = true
opt.cursorline = true
opt.completeopt = "menu,menuone,noselect"

opt.foldcolumn = '1'
opt.foldmethod = 'indent'
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
