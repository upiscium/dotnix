require("lspconfig")
local lsp_names = {
	"bashls",
	"clangd",
	"cmake",
	"denols",
	"docker_compose_language_service",
	"dockerls",
	"efm",
	"eslint",
	"graphql",
	"html",
	"hyprls",
	"jsonls",
	"nil_ls",
	"lua_ls",
	"mdx_analyzer",
	"basedpyright",
  "ruff",
	"omnisharp",
	"rust_analyzer",
	"taplo",
	"terraformls",
	"tinymist",
	"ts_ls",
	"vimls",
	"yamlls",
}

for _, server_name in ipairs(lsp_names) do
	local opts = {
		capabilities = require("blink.cmp").get_lsp_capabilities(),
		-- capabilities = vim.lsp.protocol.make_client_capabilities(),
	}
	if server_name == "denols" then
		opts.root_dir = function(_, callback)
			local root_dir = vim.fs.root(0, {
				"deno.json",
				"deno.jsonc",
				"deps.ts",
			})
			if root_dir then
				callback(root_dir)
			end
		end
		opts.init_options = {
			lint = true,
			unstable = true,
			suggest = {
				imports = {
					hosts = {
						["https://deno.land"] = true,
						["https://cdn.nest.land"] = true,
						["https://crux.land"] = true,
					},
				},
			},
		}
	elseif server_name == "clangd" then
		opts.cmd = {
			"clangd",
			"--offset-encoding=utf-16",
			"--enable-config",
			"--header-insertion=never",
			"--clang-tidy",
			"--background-index",
			"--query-driver=/nix/store/**/*",
			"--compile-commands-dir=build",
			"--log=error",
			-- "--index=x86_64-unknown-linux-gnu",
		}
		opts.filetypes = { "c", "cpp", "objc", "objcpp", "hpp", "h" }
		opts.init_options = {
			fallbackFlags = { "-std=c++20" },
		}
	elseif server_name == "stylelint_lsp" then
		opts.filetypes = { "css", "scss", "less", "sass" } -- exclude javascript and typescript
	elseif server_name == "jsonls" then
		opts.settings = {
			json = {
				schemas = require("schemastore").json.schemas(),
				validate = true,
			},
		}
	elseif server_name == "omnisharp" then
		opts.cmd = { "OmniSharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) }
		opts.root_dir = function(fname)
			-- Unityのプロジェクトルートを見つけるために .sln を探す
			local root_files = { "*.sln", "*.csproj", "omnisharp.json", "function.json" }
			return vim.fs.root(0, root_files) or vim.fn.getcwd()
		end
	elseif server_name == "yamlls" then
		opts.settings = {
			yaml = {
				schemaStore = {
					enable = true,
					url = "",
				},
				schemas = require("schemastore").yaml.schemas(),
			},
		}
	elseif server_name == "tinymist" then
		opts.settings = {
			exportPdf = "onType",
			formatterMode = "typstyle",
		}
	end
	vim.lsp.config(server_name, opts)
	vim.lsp.enable(server_name)
end

local function on_list(options)
	vim.fn.setqflist({}, " ", options)
	vim.api.nvim_command("cfirst")
end

vim.lsp.buf.definition({ on_list = on_list })
vim.lsp.buf.references(nil, { on_list = on_list })
vim.diagnostic.config({
	virtual_text = {
		source = true,
	},
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		-- client.server_capabilities.semanticTokensProvider = nil
		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true)
		end
	end,
})
