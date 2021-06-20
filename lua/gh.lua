local stringx = require("pl.stringx")
local gh = {}
local history = {}
local api = vim.api
local ex = vim.cmd
local v = vim.fn
local bmap = vim.api.nvim_buf_set_keymap
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
gh["sub-cmd"] = function(cmd)
  local pr_num = string.match(api.nvim_get_current_line(), "^%s+#(%d+)")
  if pr_num then
    return ex(("Gh " .. string.format(cmd, pr_num)))
  end
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
local function fnref(name, _3fargs)
  local args = string.gsub(vim.inspect((_3fargs or {})), "%s+", " ")
  return (":lua require('gh')['" .. name .. "'](table.unpack(" .. args .. "))<cr>")
end
gh.keymap = function()
  local tokens = stringx.split(string.match(v.expand("%:t"), "%d*:(.*)"))
  local opts = {nowait = true, silent = true}
  bmap(0, "n", "q", fnref("hist-back"), opts)
  local _0_ = tokens
  if ((type(_0_) == "table") and ((_0_)[1] == "gh") and ((_0_)[2] == "pr") and ((_0_)[3] == "status") and true) then
    local _ = (_0_)[4]
    bmap(0, "n", "<enter>", fnref("sub-cmd", {"pr view %s --comments"}), opts)
    bmap(0, "n", "h", fnref("sub-cmd", {"pr --help"}), opts)
    bmap(0, "n", "c", fnref("sub-cmd", {"pr checks %s"}), opts)
    bmap(0, "n", "CC", fnref("sub-cmd", {"pr checkout %s"}), opts)
    bmap(0, "n", "l", fnref("sub-cmd", {"pr list"}), opts)
    bmap(0, "n", "d", fnref("sub-cmd", {"pr diff %s"}), opts)
    bmap(0, "n", "o", fnref("sub-cmd", {"pr view %s --web"}), opts)
    return bmap(0, "n", "n", fnref("next-line"), opts)
  end
end
gh.setup = function()
  return ex("\n        augroup nvim-gh\n        au!\n        au TermOpen term://*:gh* lua require'gh'.keymap()\n        augroup END\n        command! -nargs=* Gh :lua require'gh'.command(<f-args>)\n        ")
end
return gh
