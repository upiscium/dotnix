-- auto bootstrap lazy.nvim ======================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- setup lazy.nivm ==========================================================

require("lazy").setup({
	{ import = "plugins.startup" },
	{ import = "plugins.lazyLoad", lazy = true },
}, {
	-- The packaged config lives in the Nix store rather than stdpath("config").
	-- lazy.nvim's default runtimepath reset would otherwise discard that path,
	-- making both imported specs and later require() calls unavailable.
	performance = {
		rtp = {
			reset = false,
		},
	},
})
