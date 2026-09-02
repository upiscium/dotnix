-- ~/.config/nvim/lua/plugins/lazyLoad/cc-component.lua
local active_requests = {}
local spinner_index = 1
local spinner_symbols = {
  "G", "Ge", "Gen", "Gene", "Gener", "Genera", "Generat", "Generati",
  "Generatin", "Generating", "Generating.", "Generating..",
  "Generating...", "Generating....", "Generating.....",
  "Generating......",
}
local spinner_symbols_len = #spinner_symbols

vim.api.nvim_create_augroup("CodeCompanionHooks", { clear = true })
vim.api.nvim_create_autocmd("User", {
  pattern = { "CodeCompanionRequestStarted", "CodeCompanionRequestFinished" },
  group = "CodeCompanionHooks",
  callback = function(event)
    local id = event.data and event.data.id
    if not id then return end
    if event.match == "CodeCompanionRequestStarted" then
      active_requests[id] = true
    elseif event.match == "CodeCompanionRequestFinished" then
      active_requests[id] = nil
    end
  end,
})

local function cc_spinner()
  return function()
    if next(active_requests) ~= nil then
      spinner_index = (spinner_index % spinner_symbols_len) + 1
      return spinner_symbols[spinner_index]
    else
      return ""
    end
  end
end

return {
  cc_spinner = cc_spinner,
}
