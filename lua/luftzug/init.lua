local M = {}

local function find_footnote_start(line, cursor_pos)
    local start_pos = nil
    for i=cursor_pos,2,-1 do
        local chr = line:sub(i-1, i)
        if chr == '[^' then
            start_pos = i+1
            break
        elseif line:sub(i, i) == '[' then
            return nil
        end
    end

    if not start_pos then
        return nil
    end

    local end_pos = nil

    for i=cursor_pos,#line do
        local chr = line:sub(i, i)
        if chr == ']' then
            end_pos = i-1
            break
        end
    end

    return start_pos, end_pos
end

local function extract_footnote(line, cursor_pos)
    local s, e = find_footnote_start(line, cursor_pos)
    if not s then return nil end
    print(s, e)
    return line:sub(s, e)
end

local function find_footnote_def(fn)
    local pat = string.format('^\\[\\^%s\\]:', fn)
    local reg = vim.regex(pat)

    local nlines = vim.api.nvim_buf_line_count(0)
    for i=0,nlines-1 do
        local res = reg:match_line(0, i)
        if res then
            local line = vim.api.nvim_buf_get_lines(0, i, i+1, true)
            return i
        end
    end

    return nil
end

local function fallback()
    vim.cmd(':VimwikiFollowLink')
end

local function add_current_position_to_jumplist()
    vim.cmd("normal! m'")
end

local function goto_line(lineno)
    vim.cmd(':' .. lineno)
end

local function start_insert()
    vim.cmd(':startinsert')
end

function _G.lzug_handle_tab()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local lin = vim.api.nvim_get_current_line()
    local chr = vim.api.nvim_get_current_line():sub(col, col)

    local fn = extract_footnote(lin, col)
    if not fn then return fallback() end

    local fn_def_lineno = find_footnote_def(fn)
    if not fn_def_lineno then return fallback() end

    -- Jump to position
    add_current_position_to_jumplist()
    goto_line(fn_def_lineno+1)
end

local function trim(s)
   return s:match'^%s*(.*%S)' or ''
end

function _G.lzug_add_reference()
    -- Find reference section
    local nlines = vim.api.nvim_buf_line_count(0)
    local lines = vim.api.nvim_buf_get_lines(0, 0, nlines, true)

    local ref_section_header = nil

    for i=1,#lines do
        if lines[i] == '# Referenzen' then
            ref_section_header = i
            break
        end
    end

    if not ref_section_header then return end

    local last_block_line = ref_section_header

    for i=ref_section_header+1, #lines do
        local prefix = lines[i]:sub(1,2)
        if prefix == '# ' then
            break
        end

        local is_empty = #trim(lines[i]) == 0
        if not is_empty then
            last_block_line = i
        end
    end

    add_current_position_to_jumplist()
    goto_line(last_block_line)
    vim.cmd('normal! 2o')
    start_insert()
end


return M
