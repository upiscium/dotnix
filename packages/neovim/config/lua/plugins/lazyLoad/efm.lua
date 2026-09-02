return {
	"mattn/efm-langserver",
	dependencies = {
		{ "neovim/nvim-lspconfig" }, -- for backward compatibility
		{ "creativenull/efmls-configs-nvim" },
	},
	config = function()
		local nvim_lsp_efm = vim.lsp.efm
		-- local languages = require("efmls-configs.defaults").languages()

		local stylua = require("efmls-configs.formatters.stylua")
		local clang_format = require("efmls-configs.formatters.clang_format")
		local clang_tidy = require("efmls-configs.linters.clang_tidy")
		local latexindent = require("efmls-configs.formatters.latexindent")
		local cmake_lint = require("efmls-configs.linters.cmake_lint")
		local shellcheck = require("efmls-configs.linters.shellcheck")
		local rustfmt = require("efmls-configs.formatters.rustfmt")
		local yamllint = require("efmls-configs.linters.yamllint")
		local prettier = require("efmls-configs.formatters.prettier")
		local nixfmt = require("efmls-configs.formatters.nixfmt")
		local textlint = require("efmls-configs.linters.textlint")
		-- Python
		local ruff = require("efmls-configs.formatters.ruff")
		local black = require("efmls-configs.formatters.black")
		local isort = require("efmls-configs.formatters.isort")
		local autopep8 = require("efmls-configs.formatters.autopep8")
		local flake8 = require("efmls-configs.linters.flake8")
		local mypy = require("efmls-configs.linters.mypy")

		-- customized or manually installed linters/formatters
		local cmake_format = {
			formatCommand = "cmake-format ${--line-width:100} -",
			formatStdin = true,
			rootMarkers = { "CMakeLists.txt" },
		}

		vim.lsp.config("efm", {
			init_options = {
				documentFormatting = true,
				codeAction = true,
			},
			filetypes = {
				"c",
				"cmake",
				"cpp",
				"cs",
				"json",
				"lua",
				"markdown",
				"nix",
				"python",
				"rust",
				"sh",
				"typst",
				"yaml",
			},
			settings = {
				rootMarkers = { ".git/" },
				languages = {
					c = { clang_format, clang_tidy },
					-- c = { clang_format },
					cmake = { cmake_lint, cmake_format },
					cpp = { clang_format, clang_tidy },
					-- cpp = { clang_format },
					json = { prettier },
					latex = { latexindent },
					lua = { stylua },
					markdown = { textlint },
					nix = { nixfmt },
					python = { ruff, black, isort, autopep8, flake8, mypy },
					rust = { rustfmt },
					sh = { shellcheck },
					typst = { typstyle },
					yaml = { yamllint },
				},
			},
		})

		-- Format on save
		local lsp_fmt_group = vim.api.nvim_create_augroup("LspFormattingGroup", {})
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = lsp_fmt_group,
			callback = function(ev)
				local efm = vim.lsp.get_clients({ name = "efm", bufnr = ev.buf })

				if vim.tbl_isempty(efm) then
					return
				end

				if vim.bo.filetype == "typst" or vim.bo.filetype == "tex" then
					vim.cmd("silent! %s/。/. /g | silent! %s/、/, /g")
				end

				vim.lsp.buf.format({ name = "efm" })
			end,
		})
	end,
	event = "BufReadPre",
}
