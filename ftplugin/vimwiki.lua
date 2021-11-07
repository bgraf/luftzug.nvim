local lzug = require('luftzug')

vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>LzugAddReference', "<cmd>call v:lua.lzug_add_reference()<CR>", { noremap = true})
vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>LzugFollowFootnoteOrLink', "<cmd>call v:lua.lzug_handle_tab()<CR>", { noremap = true})

if vim.g.luftzug_follow_link_keymap then
    vim.api.nvim_buf_set_keymap(0, 'n', vim.g.luftzug_follow_link_keymap, "<Plug>LzugFollowFootnoteOrLink", { noremap = false })
end

