local M = {}

M.usage_history = {}

---@class ChaceUsage
---@field prompt_tokens number
---@field completion_tokens number
---@field total_tokens number

---@type ChaceUsage
M.totals = {
    prompt_tokens = 0,
    completion_tokens = 0,
    total_tokens = 0,
}

---Adds a new usage record to the history
---@param usage table|nil The usage object from the rust backend
---@param backend string The name of the backend used
function M.add_usage(usage, backend)
    if not usage then
        return
    end

    local entry = {
        timestamp = os.date("%H:%M:%S"),
        backend = backend,
        prompt_tokens = usage.prompt_tokens or 0,
        completion_tokens = usage.completion_tokens or 0,
        total_tokens = usage.total_tokens or 0,
    }

    table.insert(M.usage_history, entry)

    print(string.format("[Chace] %s used %d tokens", backend, entry.total_tokens))

    M.totals.prompt_tokens = M.totals.prompt_tokens + entry.prompt_tokens
    M.totals.completion_tokens = M.totals.completion_tokens + entry.completion_tokens
    M.totals.total_tokens = M.totals.total_tokens + entry.total_tokens
end

---@return ChaceUsage
function M.get_total_session_tokens()
    return M.totals
end

return M
