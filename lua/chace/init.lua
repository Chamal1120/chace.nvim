local M = {}

M.config = {
    debug = false, -- Set to true to enable debug logs
    show_notifications = true, -- Set to false to suppress all notifications
    model = "groq",
    keymap = "<leader>c",
}

-- Setup function to configure the plugin
function M.setup(opts)
    M.config = vim.tbl_extend("force", M.config, opts or {})
    vim.api.nvim_create_user_command("Chace", function()
        require("chace").run()
    end, {})
    local map = M.config.keymap
    if map and map ~= false then
        vim.keymap.set("n", map, "<cmd>Chace<CR>", { noremap = true, silent = true, desc = "Chace ran!" })
    end
end

-- Safe notify function
local function safe_notify(msg, level, force)
    level = level or vim.log.levels.INFO

    -- Always show errors unless explicitly suppressed
    if level == vim.log.levels.ERROR then
        if M.config.show_notifications then
            vim.notify(tostring(msg), level)
        end
        return
    end

    -- Show debug logs only if debug mode is enabled
    if level == vim.log.levels.DEBUG and not M.config.debug then
        return
    end

    -- Show other notifications based on config, or if forced
    if M.config.show_notifications or force then
        vim.notify(tostring(msg), level)
    end
end

-- Convert byte index → (line, col)
local function byte_to_pos(buf, byte_index)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    local current = 0
    for i, line in ipairs(lines) do
        local nl = #line + 1 -- +1 for newline
        if current + nl > byte_index then
            return i - 1, byte_index - current
        end
        current = current + nl
    end
    return #lines - 1, 0
end

local function start_spinner(buf, cursor_line, spinner_chars)
    local spinner_index = 1
    local timer = vim.uv.new_timer()

    -- Create a namespace for our spinner
    local ns_id = vim.api.nvim_create_namespace("chace_spinner")

    -- Place initial virtual text using extmark
    local extmark_id = vim.api.nvim_buf_set_extmark(buf, ns_id, cursor_line, 0, {
        virt_text = { { spinner_chars[1], "Comment" } },
        virt_text_pos = "eol", -- Position at end of line
    })

    timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if vim.api.nvim_buf_is_valid(buf) then
                -- Update the extmark with new spinner character
                pcall(vim.api.nvim_buf_set_extmark, buf, ns_id, cursor_line, 0, {
                    id = extmark_id,
                    virt_text = { { spinner_chars[spinner_index], "Comment" } },
                    virt_text_pos = "eol",
                })
            end
            spinner_index = spinner_index + 1
            if spinner_index > #spinner_chars then
                spinner_index = 1
            end
        end)
    )

    return timer, ns_id, extmark_id
end

local function stop_spinner(timer, buf, ns_id)
    if timer and not timer:is_closing() then
        if timer:is_active() then
            timer:stop()
        end
        timer:close()
    end

    -- Remove the spinner
    vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
        end
    end)
end

local uv = vim.uv

local function send_request(socket_path, payload, on_response)
    local pipe = uv.new_pipe(false)

    pipe:connect(socket_path, function(err)
        if err then
            vim.schedule(function()
                safe_notify("Socket connect error: " .. tostring(err), vim.log.levels.ERROR)
            end)
            return
        end

        local request_json = vim.json.encode(payload) .. "\n"
        pipe:write(request_json)

        local buffer = ""
        pipe:read_start(function(err, chunk)
            if err then
                vim.schedule(function()
                    safe_notify("Read error: " .. tostring(err), vim.log.levels.ERROR)
                end)
                pipe:close()
                return
            end

            if chunk then
                buffer = buffer .. chunk
                if buffer:find("\n") then
                    pipe:read_stop()
                    pipe:close()
                    local line = buffer:match("^(.-)\n")
                    if line and #line > 0 then
                        local ok, decoded = pcall(vim.json.decode, line)
                        if ok then
                            on_response(decoded)
                        else
                            vim.schedule(function()
                                safe_notify("JSON decode failed: " .. tostring(decoded), vim.log.levels.ERROR)
                            end)
                        end
                    end
                end
            else
                -- Connection closed
                pipe:close()
            end
        end)
    end)
end

function M.run()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local buf = vim.api.nvim_get_current_buf()
    local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠏" }

    -- Get 0-based cursor position
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1] -- 1-based
    local col_num = cursor_pos[2] -- 0-based byte offset

    -- Calculate byte offset manually for consistency
    local lines = vim.api.nvim_buf_get_lines(buf, 0, line_num - 1, false)
    local cursor_byte = 0
    for _, line in ipairs(lines) do
        cursor_byte = cursor_byte + #line + 1 -- +1 for newline
    end
    cursor_byte = cursor_byte + col_num

    local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

    local spinner_timer, spinner_ns, spinner_extmark = start_spinner(buf, cursor_line, spinner_chars)

    local request = {
        source_code = text,
        cursor_byte = cursor_byte,
        backend = M.config.model,
    }

    vim.schedule(function()
        safe_notify("Sending payload: cursor_byte=" .. cursor_byte, vim.log.levels.DEBUG)
    end)

    send_request("/tmp/chace.sock", request, function(result)
        stop_spinner(spinner_timer, buf, spinner_ns)

        vim.schedule(function()
            safe_notify("Received result: " .. vim.inspect(result), vim.log.levels.DEBUG)
        end)

        if result.error ~= nil and result.error ~= vim.NIL then
            vim.schedule(function()
                safe_notify(result.error, vim.log.levels.ERROR)
            end)
            return
        end

        vim.schedule(function()
            local start_line, start_col = byte_to_pos(buf, result.start_byte)
            local end_line, end_col = byte_to_pos(buf, result.end_byte)

            -- Validate buffer is still valid
            if not vim.api.nvim_buf_is_valid(buf) then
                safe_notify("Buffer is no longer valid", vim.log.levels.ERROR)
                return
            end

            -- Get current line for indentation detection
            local ok, buf_lines = pcall(vim.api.nvim_buf_get_lines, buf, start_line, start_line + 1, false)
            if not ok then
                safe_notify("Failed to get lines: " .. tostring(buf_lines), vim.log.levels.ERROR)
                buf_lines = { "" }
            end

            local indent = ""
            if buf_lines[1] then
                indent = string.match(buf_lines[1], "^(%s*)") or ""
            end

            -- Format the replacement text with proper indentation
            local formatted = "\n"
                .. indent
                .. "    "
                .. (result.body or ""):gsub("\n", "\n" .. indent .. "    ")
                .. "\n"
                .. indent

            local replacement_lines = vim.split(formatted, "\n", { plain = true })

            -- Debug info
            safe_notify(
                string.format(
                    "Replacing from [%d,%d] to [%d,%d] with %d lines",
                    start_line,
                    start_col,
                    end_line,
                    end_col,
                    #replacement_lines
                ),
                vim.log.levels.DEBUG
            )

            -- Apply the text change
            local success, err = pcall(
                vim.api.nvim_buf_set_text,
                buf,
                start_line, -- 0-based start line
                start_col, -- 0-based start column (exclusive)
                end_line, -- 0-based end line (inclusive)
                end_col, -- 0-based end column (exclusive)
                replacement_lines
            )

            if not success then
                safe_notify("Failed to set text: " .. tostring(err), vim.log.levels.ERROR)
                return
            end

            safe_notify("CHACE applied successfully", vim.log.levels.INFO, true)
        end)
    end)
end

return M
