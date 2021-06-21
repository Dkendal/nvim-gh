(local stringx (require :pl.stringx))

(local gh {})

(local history [])

(local api vim.api)
(local ex vim.cmd)
(local v vim.fn)
(local bmap (partial vim.api.nvim_buf_set_keymap 0))

(fn hist-push [s]
  (table.insert history s))

(fn hist-pop []
  (table.remove history))

(fn hist-last []
  (. history (length history)))

(fn gh.hist-back []
  (if (<= (length history) 1)
      (ex ":q")
      (do
        (hist-pop)
        (ex (table.concat [:term :gh (table.unpack (hist-last))] " ")))))

(fn gh.command [...]
  (hist-push [...])
  (ex (table.concat [:term :gh ...] " ")))

(fn gh.next-line []
  (print :next))

(fn fnref [name ?args]
  (local args (string.gsub (vim.inspect (or ?args {})) "%s+" " "))
  (.. ":lua require('gh')['" name "'](table.unpack(" args "))<cr>"))

(fn gh.pr-view []
  (let [pr-num (-> (api.nvim_get_current_line) (string.match "^%s+#(%d+)"))]
    (when pr-num
      (ex (.. "Gh pr view " pr-num)))))

(fn gh.pr-diff []
  (let [pr-num (-> (api.nvim_get_current_line) (string.match "^%s+#(%d+)"))]
    (when pr-num
      (ex (.. "Gh pr diff " pr-num)))))

(local pr-pattern "^%(%d+)")

(fn gh.pr-sub-cmd [cmd]
  (let [id (-> (api.nvim_get_current_line) (string.match pr-pattern))]
    (when id
      (ex (.. "Gh " (string.format cmd id))))))

;; X  debugging                                     .github/workflows/ci.yml  feat-ci-2  push          938222443
(local run-pattern "%s(%d+)$")

(fn gh.run-sub-cmd [cmd]
  (let [id (-> (api.nvim_get_current_line) (string.match run-pattern))]
    (when id
      (ex (.. "Gh " (string.format cmd id))))))

(fn gh.keymap []
  (let [tokens ;
        (-> (v.expand "%:t")
            (string.match "%d*:(.*)")
            (stringx.split))
        opts {:nowait true :silent true}]
    ;; Map for all modes
    (bmap :n :q (fnref :hist-back) opts)
    (match tokens
      [:gh :run :list _]
      ;; Actions
      (do
        (bmap :n :<enter> (fnref :run-sub-cmd ["run view %s"]) opts))
      [:gh :pr :status _]
      ;: Pr Status maps
      (do
        (bmap :n :<enter> (fnref :pr-sub-cmd ["pr view %s --comments"]) opts)
        (bmap :n :h (fnref :pr-sub-cmd ["pr --help"]) opts)
        (bmap :n :c (fnref :pr-sub-cmd ["pr checks %s"]) opts)
        (bmap :n :CC (fnref :pr-sub-cmd ["pr checkout %s"]) opts)
        (bmap :n :l (fnref :pr-sub-cmd ["pr list"]) opts)
        (bmap :n :d (fnref :pr-sub-cmd ["pr diff %s"]) opts)
        (bmap :n :o (fnref :pr-sub-cmd ["pr view %s --web"]) opts)
        (bmap :n :n (fnref :next-line) opts)))))

(fn gh.setup []
  (do
    (ex "
        augroup nvim-gh
        au!
        au TermOpen term://*:gh* lua require'gh'.keymap()
        augroup END
        command! -nargs=* Gh :lua require'gh'.command(<f-args>)
        ")))

gh

