local lzug = require('luftzug')

vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>LzugAddReference', "<cmd>call v:lua.lzug_add_reference()<CR>", { noremap = true})
vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>LzugFollowFootnoteOrLink', "<cmd>call v:lua.lzug_handle_tab()<CR>", { noremap = true})
vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>LzugAddLink', "<cmd>call v:lua.lzug_add_link()<CR>", { noremap = true})

if vim.g.luftzug_follow_link_keymap then
    vim.api.nvim_buf_set_keymap(0, 'n', vim.g.luftzug_follow_link_keymap, "<Plug>LzugFollowFootnoteOrLink", { noremap = false })
end

-- vim.cmd([[command! -buffer LuftzugFormatBuffer :lua require'luftzug'.format_buffer()]])
-- vim.cmd([[autocmd BufWritePre <buffer> :LuftzugFormatBuffer]])

vim.cmd([[command! -nargs=* -buffer LzugAddFootnote :lua require'luftzug'.add_footnote(<q-args>)]])

