local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

require("telescope").setup({
	require("telescope").load_extension("lazygit"),
})

map("n", "<leader>ft", ":Telescope<CR>", opts)
map("n", "<leader>ff", ":Telescope find_files<CR>", opts)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts)
map("n", "<leader>fh", ":Telescope help_tags<CR>", opts)
