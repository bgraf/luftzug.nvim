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
    vim.cmd(':startinsert!')
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

local function get_current_lines() 
    local nlines = vim.api.nvim_buf_line_count(0)
    return vim.api.nvim_buf_get_lines(0, 0, nlines, true)
end

local function find_line_of_heading1(name, lines)
    if lines == nil then
        lines = get_current_lines()
    end

    name = '# ' .. name

    for i=1,#lines do
        if lines[i] == name then
            return i, lines
        end
    end

    return nil, lines
end

local function find_last_text_line_heading1(heading_lineno, lines)
    local lineno = heading_lineno

    for i=heading_lineno+1, #lines do
        local prefix = lines[i]:sub(1,2)
        if prefix == '# ' then
            break
        end

        local is_empty = #trim(lines[i]) == 0
        if not is_empty then
            lineno = i
        end
    end

    return lineno
end

local function append_to_heading1(name, f)
    local lines = get_current_lines()

    local heading_lineno = find_line_of_heading1(name, lines)
    if not heading_lineno then return end

    local last_block_line = find_last_text_line_heading1(heading_lineno, lines)

    add_current_position_to_jumplist()
    vim.fn.append(last_block_line, {'', ''})
    goto_line(last_block_line+2)

    f(last_block_line+2)
end

function _G.lzug_add_reference()
    append_to_heading1(
        'Referenzen',
        function (_)
            start_insert()
        end
    )
end

function _G.lzug_add_link()
    append_to_heading1(
        'Links',
        function (lineno)
            -- I don't know why I need to insert two spaces here, otherwise the inserted link
            -- eats the "plus" symbol.
            vim.fn.setline(lineno, "+  ")
            start_insert()
            vim.cmd(':ZettelSearch')
            vim.api.nvim_feedkeys(':title: ', 'n', true)
        end
    )
end

local function find_max_footnote_id()
    local max_footnote_id = 0

    local pat = '\\[\\^\\d\\+\\]'
    local reg = vim.regex(pat)

    local nlines = vim.api.nvim_buf_line_count(0)
    for i=0,nlines-1 do

        local current_start = 0

        while true do
            local res = reg:match_line(0, i, current_start)
            if not res then break end
            -- Make res absolute, because reg:match_line returns relative to current_start.
            res = res + current_start

            local line = vim.api.nvim_buf_get_lines(0, i, i+1, true)[1]

            local s, e = find_footnote_start(line, res+2)
            if not s then print("error!"); return nil end

            local footnote_id = tonumber(line:sub(s, e))

            current_start = e+1

            if footnote_id > max_footnote_id then
                max_footnote_id = footnote_id
            end
        end
    end

    return max_footnote_id
end

function M.add_footnote(args)
    args = trim(args)

    local max_footnote_id = find_max_footnote_id()
    if not max_footnote_id then return end

    local next_footnote_id = max_footnote_id+1

    vim.api.nvim_put({'[^' .. next_footnote_id .. ']'}, 'c', true, true)

    local window_state = vim.fn['winsaveview']()

    append_to_heading1(
        'Referenzen',
        function (_)
            vim.api.nvim_put({'[^' .. next_footnote_id .. ']: ' .. args}, 'c', true, true)
            if args:len() == 0 then
                start_insert()
            else
                vim.fn['winrestview'](window_state)
            end
        end
    )
end

return M
