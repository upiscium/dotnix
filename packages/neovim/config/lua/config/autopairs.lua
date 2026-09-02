local status, npairs = pcall(require, "nvim-autopairs")
if not status then
  return
end

local Rule = require("nvim-autopairs.rule")

npairs.add_rule(Rule("$$", "$$", "tex"))
npairs.setup({
  map_c_h = true,
  map_c_w = true,
  check_ts = true,
  enable_check_bracket_line = true,
})
