(local stringx (require :pl.stringx))

(local gh {})

(local history [])

(local api vim.api)
(local ex vim.cmd)
(local v vim.fn)
(local bmap vim.api.nvim_buf_set_keymap)

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

(fn gh.sub-cmd [cmd]
  (let [pr-num (-> (api.nvim_get_current_line) (string.match "^%s+#(%d+)"))]
    (when pr-num
      (ex (.. "Gh " (string.format cmd pr-num))))))

(fn gh.pr-view []
  (let [pr-num (-> (api.nvim_get_current_line) (string.match "^%s+#(%d+)"))]
    (when pr-num
      (ex (.. "Gh pr view " pr-num)))))

(fn gh.pr-diff []
  (let [pr-num (-> (api.nvim_get_current_line) (string.match "^%s+#(%d+)"))]
    (when pr-num
      (ex (.. "Gh pr diff " pr-num)))))

(fn fnref [name ?args]
  (local args (string.gsub (vim.inspect (or ?args {})) "%s+" " "))
  (.. ":lua require('gh')['" name "'](table.unpack(" args "))<cr>"))

(fn gh.keymap []
  (let [tokens ;
        (-> (v.expand "%:t")
            (string.match "%d*:(.*)")
            (stringx.split))
        opts {:nowait true :silent true}]
    ;; Map for all modes
    (bmap 0 :n :q (fnref :hist-back) opts)
    (match tokens
      [:gh :pr :status _]
      ;: Pr Status maps
      (do
        (bmap 0 :n :<enter> (fnref :sub-cmd ["pr view %s --comments"]) opts)
        (bmap 0 :n :h (fnref :sub-cmd ["pr --help"]) opts)
        (bmap 0 :n :c (fnref :sub-cmd ["pr checks %s"]) opts)
        (bmap 0 :n :CC (fnref :sub-cmd ["pr checkout %s"]) opts)
        (bmap 0 :n :l (fnref :sub-cmd ["pr list"]) opts)
        (bmap 0 :n :d (fnref :sub-cmd ["pr diff %s"]) opts)
        (bmap 0 :n :o (fnref :sub-cmd ["pr view %s --web"]) opts)
        (bmap 0 :n :n (fnref :next-line) opts)))))

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

