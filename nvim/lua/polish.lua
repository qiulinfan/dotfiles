-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

vim.keymap.set("i", "<C-x><C-c>", "<Esc>", { desc = "Insert mode: Ctrl-X Ctrl-C to Normal mode" })
vim.keymap.set("n", "<Space>", "i", { desc = "Normal mode: Space to Insert mode" })

vim.cmd [[cnoreabbrev <expr> qa getcmdtype() == ':' && getcmdline() ==# 'qa' ? 'wq' : 'qa']]
