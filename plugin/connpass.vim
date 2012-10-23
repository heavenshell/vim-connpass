" File:     connpass.vim
" Author:   Shinya Ohyanagi <sohyanagi@gmail.com>
" Version:  0.0.1
" WebPage:  http://github.com/heavenshell/vim-connpass/
" Description: Search Cannpass
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -range=0 -complete=customlist,connpass#complete Connpass
  \ call connpass#search(<q-args>, <count>, <line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo
