local stringx = require("pl.stringx")
local gh = {}
local history = {}
local api = vim.api
local ex = vim.cmd
local v = vim.fn
local bmap
local function _0_(...)
  return vim.api.nvim_buf_set_keymap(0, ...)
end
bmap = _0_
local function hist_push(s)
  return table.insert(history, s)
end
local function hist_pop()
  return table.remove(history)
end
local function hist_last()
  return history[#history]
end
gh["hist-back"] = function()
  if (#history <= 1) then
    return ex(":q")
  else
    hist_pop()
    return ex(table.concat({"term", "gh", table.unpack(hist_last())}, " "))
  end
end
gh.command = function(...)
  hist_push({...})
  return ex(table.concat({"term", "gh", ...}, " "))
end
gh["next-line"] = function()
  return print("next")
end
local function fnref(name, _3fargs)
  local args = string.gsub(vim.inspect((_3fargs or {})), "%s+", " ")
  return (":lua require('gh')['" .. name .. "'](table.unpack(" .. args .. "))<cr>")
end
gh["pr-view"] = function()
  local pr_num = string.match(api.nvim_get_current_line(), "^%s+#(%d+)")
  if pr_num then
    return ex(("Gh pr view " .. pr_num))
  end
end
gh["pr-diff"] = function()
  local pr_num = string.match(api.nvim_get_current_line(), "^%s+#(%d+)")
  if pr_num then
    return ex(("Gh pr diff " .. pr_num))
  end
end
local pr_pattern = "^%(%d+)"
gh["pr-sub-cmd"] = function(cmd)
  local id = string.match(api.nvim_get_current_line(), pr_pattern)
  if id then
    return ex(("Gh " .. string.format(cmd, id)))
  end
end
local run_pattern = "%s(%d+)$"
gh["run-sub-cmd"] = function(cmd)
  local id = string.match(api.nvim_get_current_line(), run_pattern)
  if id then
    return ex(("Gh " .. string.format(cmd, id)))
  end
end
gh.keymap = function()
  local tokens = stringx.split(string.match(v.expand("%:t"), "%d*:(.*)"))
  local opts = {nowait = true, silent = true}
  bmap("n", "q", fnref("hist-back"), opts)
  local _1_ = tokens
  if ((type(_1_) == "table") and ((_1_)[1] == "gh") and ((_1_)[2] == "run") and ((_1_)[3] == "list") and true) then
    local _ = (_1_)[4]
    return bmap("n", "<enter>", fnref("run-sub-cmd", {"run view %s"}), opts)
  elseif ((type(_1_) == "table") and ((_1_)[1] == "gh") and ((_1_)[2] == "pr") and ((_1_)[3] == "status") and true) then
    local _ = (_1_)[4]
    bmap("n", "<enter>", fnref("pr-sub-cmd", {"pr view %s --comments"}), opts)
    bmap("n", "h", fnref("pr-sub-cmd", {"pr --help"}), opts)
    bmap("n", "c", fnref("pr-sub-cmd", {"pr checks %s"}), opts)
    bmap("n", "CC", fnref("pr-sub-cmd", {"pr checkout %s"}), opts)
    bmap("n", "l", fnref("pr-sub-cmd", {"pr list"}), opts)
    bmap("n", "d", fnref("pr-sub-cmd", {"pr diff %s"}), opts)
    bmap("n", "o", fnref("pr-sub-cmd", {"pr view %s --web"}), opts)
    return bmap("n", "n", fnref("next-line"), opts)
  end
end
gh.setup = function()
  return ex("\n        augroup nvim-gh\n        au!\n        au TermOpen term://*:gh* lua require'gh'.keymap()\n        augroup END\n        command! -nargs=* Gh :lua require'gh'.command(<f-args>)\n        ")
end
return gh
