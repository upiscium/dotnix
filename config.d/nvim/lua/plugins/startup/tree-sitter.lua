return {
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			local ok, ts = pcall(require, "nvim-treesitter.configs")
			if not ok then
				return
			end
      vim.treesitter.language.register("hlsl", "shaderslang")
			ts.setup({
				event = "BufRead",
				ensure_installed = {
					"bash",
					"c",
					"cpp",
					"css",
					"dockerfile",
          "glsl",
					"go",
					"gomod",
					"graphql",
          "hlsl",
					"html",
					"java",
					"javascript",
					"json",
					"lua",
					"python",
					"regex",
					"rust",
					"toml",
					"tsx",
					"typescript",
					"yaml",
					"markdown",
					"cmake",
					"xml",
					"git_config",
					"gitcommit",
					"gitignore",
					"jsdoc",
					"latex",
					"markdown",
					"markdown_inline",
					"diff",
					"vimdoc",
					"typst",
				},
				highlight = {
					enable = true,
					disable = { "latex" },
					additional_vim_regex_highlighting = { "latex", "markdown" },
				},
				indent = {
					enable = true,
				},
				tree_docs = {
					enable = true,
				},
				autotag = {
					enable = true,
				},
				rainbow = {
					enable = true,
					extended_mode = true,
					max_file_lines = 1000,
				},
			})
		end,
	},
	-- {
	-- 	"nvim-treesitter/nvim-tree-docs",
	-- 	dependencies = { "nvim-treesitter/nvim-treesitter" },
	-- },
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
}
