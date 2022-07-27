local null_ls = require("null-ls")

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local formatting = null_ls.builtins.formatting

local sources = {
	formatting.autopep8,
	formatting.stylua,
	formatting.shfmt,
	formatting.clang_format.with({
		extra_args = { "-style=file:'/home/fushen/.clang-format'", "-fallback-style=none" },
	}),
	formatting.latexindent,
	formatting.prettier,
	formatting.rustfmt,
}

null_ls.setup({
	sources = sources,
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
					vim.lsp.buf.formatting_sync()
				end,
			})
		end
	end,
})
