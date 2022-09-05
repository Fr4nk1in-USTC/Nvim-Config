-- check if lspconfig is installed
local status, _ = pcall(require, "lspconfig")

if not status then
	return
end

-- import my own mapping function
local map = require("mappings").map

-- diagnostic appearence
vim.diagnostic.config({
	virtual_text = true,
	virtual_lines = false,
	update_in_insert = true,
})
---- Toggle diagnostic appearence
local function toggle_diagnostic()
	local current = vim.diagnostic.config().virtual_text
	vim.diagnostic.config({
		virtual_text = not current,
		virtual_lines = current,
		update_in_insert = not current,
	})
end
---- Diagnostic hints
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- lspsaga config & mappings
local saga_status, saga = pcall(require, "lspsaga")

local saga_mapping
if saga_status then
	saga.init_lsp_saga({
		show_outline = {
			win_position = "left",
			win_with = "NvimTree",
			auto_preview = false,
			jump_key = "<CR>",
			auto_refresh = true,
		},
	})

	-- Outline
	map("n", "<leader>o", "<cmd>LSoutlineToggle<CR>", nil, "Toggle LSP Outline")

	saga_mapping = function(bufnr)
		local bufopts = {
			noremap = true,
			silent = true,
			buffer = bufnr,
		}
		-- finder
		map("n", "gf", "<cmd>Lspsaga lsp_finder<CR>", bufopts, "Open lspsaga finder")

		-- code action
		map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", bufopts, "Show code actions")
		map("v", "<leader>ca", "<cmd><C-U>Lspsaga range_code_action<CR>", bufopts, "Show code actions for range")

		-- hover doc
		map("n", "K", "<cmd>Lspsaga hover_doc<CR>", bufopts, "Show hover doc")
		-- scroll down hover doc or scroll in definition preview
		map("n", "<C-f>", function()
			require("lspsaga.action").smart_scroll_with_saga(1)
		end, bufopts, "Scroll down hover doc or scroll in definition preview")
		-- scroll up hover doc
		map("n", "<C-b>", function()
			require("lspsaga.action").smart_scroll_with_saga(-1)
		end, bufopts, "Scroll up hover doc or scroll in definition preview")

		-- rename
		map("n", "gr", "<cmd>Lspsaga rename<CR>", bufopts, "Rename symbol")

		-- preview definition
		map("n", "gpd", "<cmd>Lspsaga preview_definition<CR>", bufopts, "Preview definition")

		-- diagnostics
		map("n", "<leader>d", "<cmd>Lspsaga show_line_diagnostics<CR>", bufopts, "Show line diagnostics")
		map("n", "<leader>cd", "<cmd>Lspsaga show_cursor_diagnostics<CR>", bufopts, "Show cursor diagnostics")
		map("n", "[e", "<cmd>Lspsaga diagnostic_jump_next<CR>", bufopts, "Goto previous diagnostic")
		map("n", "]e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", bufopts, "Goto next diagnostic")
		map("n", "[E", function()
			require("lspsaga.diagnostic").goto_prev({ severity = vim.diagnostic.severity.ERROR })
		end, bufopts, "Goto previous error")
		map("n", "]E", function()
			require("lspsaga.diagnostic").goto_next({ severity = vim.diagnostic.severity.ERROR })
		end, bufopts, "Goto next error")
	end
else
	-- if lspsaga is not installed, use lsp native commands
	saga_mapping = function(bufnr)
		local bufopts = {
			noremap = true,
			silent = true,
			buffer = bufnr,
		}
		-- hover doc
		map("n", "K", vim.lsp.buf.hover, bufopts, "Show hover doc")
		-- code action
		map("n", "<space>ca", vim.lsp.buf.code_action, bufopts, "Show code actions")
		-- rename
		map("n", "<space>gr", vim.lsp.buf.rename, bufopts, "Rename symbol")
		-- diagnostics
		map("n", "<space>d", vim.diagnostic.open_float, bufopts, "Open diagnostics window")
		map("n", "[e", vim.diagnostic.goto_prev, bufopts, "Go to previous diagnostic")
		map("n", "]e", vim.diagnostic.goto_next, bufopts, "Go to next diagnostic")
		map("n", "<space>q", vim.diagnostic.setloclist, bufopts, "Open diagnostic location list")
	end
end

-- check if lsp_signature is installed
local signature_status, signature = pcall(require, "lsp_signature")

local signature_mapping
-- lsp_signature
if signature_status then
	signature_mapping = function(bufnr)
		signature.on_attach({
			toggle_key = "<C-s>",
		})
	end
else
	signature_mapping = function(bufnr)
		local bufopts = {
			noremap = true,
			silent = true,
			buffer = bufnr,
		}
		map("n", "<C-s>", vim.lsp.buf.signature_help, bufopts, "Show signature help")
	end
end

-- check if lsp_lines is installed
local lines_status, lines = pcall(require, "lsp_lines")
if lines_status then
	lines.setup()
end

-- lsp config
---- Use an on_attach function to only map the following keys
---- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
	-- Enable completion triggered by <c-x><c-o>
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	local bufopts = {
		noremap = true,
		silent = true,
		buffer = bufnr,
	}

	map("n", "gD", vim.lsp.buf.declaration, bufopts, "Go to declaration")
	map("n", "gd", vim.lsp.buf.definition, bufopts, "Go to definition")
	map("n", "gi", vim.lsp.buf.implementation, bufopts, "Go to implementation")
	map("n", "<space>D", vim.lsp.buf.type_definition, bufopts, "Go to type definition")
	map("n", "gR", vim.lsp.buf.references, bufopts, "Find references")

	saga_mapping(bufnr)

	map("", "<leader>l", toggle_diagnostic, bufopts, "Toggle lsp_lines")

	signature_mapping(bufnr)

	local navic_status, navic = pcall(require, "nvim-navic")
	if navic_status then
		navic.attach(client, bufnr)
	end

	client.resolved_capabilities.document_formatting = false
end

-- mason configuration
local mason_status, mason = pcall(require, "mason")
if not mason_status then
	return
end
-- mason installer
require("mason").setup({
	ui = {
		border = "rounded",
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

-- mason lsp config
local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lspconfig_status then
	return
end
-- ensured install some lsp
mason_lspconfig.setup({
	ensure_installed = {
		"bash-language-server",
		"lua-language-server",
		"vim-language-server",
		"json-lsp",
		"pyright",
		"clangd",
	},
	automatic_installation = true,
})

-- Add additional capabilities supported by nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_status, cmp = pcall(require, "cmp_nvim_lsp")
if cmp_status then
	capabilities = cmp.update_capabilities(capabilities)
end

-- Clangd specific capabilities
local clangd_capabilities = capabilities
clangd_capabilities.textDocument.semanticHighlighting = true
clangd_capabilities.offsetEncoding = "utf-8"

mason_lspconfig.setup_handlers({
	function(server_name)
		require("lspconfig")[server_name].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end,
	["clangd"] = function()
		require("lspconfig").clangd.setup({
			on_attach = on_attach,
			capabilities = clangd_capabilities,
		})
	end,
	["ltex"] = function()
		require("lspconfig").ltex.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			filetypes = { "tex", "bib" },
			settings = {
				ltex = {
					enabled = {
						"latex",
						"tex",
						"bib",
					},
					checkFrequency = "save",
					completionEnabled = false,
				},
			},
		})
	end,
})
