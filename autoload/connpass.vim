" Insert Docstring.
" Last Change:  2012-10-24
" Maintainer:   Shinya Ohyanagi <sohyanagi@gmail.com>
" License:      This file is placed in the public domain.
" NOTE:         This module is heavily inspired by togetter-vim
let s:save_cpo = &cpo
set cpo&vim

let s:connpass_uri = 'http://connpass.com/api/v1/event/'
let s:connpass_req_params = [
  \ 'event_id', 'event_id', 'keyword', 'keyword_or', 'ym', 'ymd',
  \ 'nickname=', 'owner_nickname', 'series_id', 'start'
  \]

let s:result_list = []
let s:result_events = []

function! s:build_query(args)
  let querys = split(a:args, ' ')
  let requests = []
  for query in querys
    let arg = split(query, '=')
    let key = substitute(arg[0], '^-', '', '')
    if count(s:connpass_req_params, key) == 0
      echohl WarningMsg
      echo printf("Request parameter '%s' is invalid.", key)
      echohl None
      return
    endif

    let val = ''
    if len(arg[1:]) > 1
      let val = join(arg[1:], '=')
    else
      let val = arg[1]
    endif
    call add(requests, printf('%s=%s', key, val))
  endfor

  return join(requests, '&')
endfunction

function! connpass#complete(lead, cmd, pos)
  let args = map(copy(s:connpass_req_params), '"-" . v:val . "="')
  return filter(args, 'v:val =~# "^".a:lead')
endfunction

function! connpass#search(...)
  let query = s:build_query(a:000[0])
  if query != ''
    let query = printf('?%s', query)
  endif
  let uri = s:connpass_uri . query
  call s:connpass_list(uri)
endfunction

function! s:connpass_list(uri)
  " This function copy lots from toggeter-vim.
  " see https://github.com/mattn/togetter-vim/blob/master/plugin/togetter.vim#L44
  let winnum = bufwinnr(bufnr('^Connpass$'))
  if winnum != -1
    if winnum != bufwinnr('%')
      echomsg 'foo'
      exe winnum 'wincmd w'
    endif
  else
    exec 'silent noautocmd split Connpass'
  endif
  setlocal modifiable
  silent %d
  redraw | echo "fetching feed..."
  let response = webapi#http#get(a:uri)
  let content = webapi#json#decode(response.content)
  let results_available = content['results_available']

  let results_start = content['results_start']
  let s:result_events = copy(content['events'])
  let events = content['events']

  call setline(1, map(events, 'v:val["title"]." : ".v:val["owner_nickname"]'))
  let s:result_list = events
  setlocal buftype=nofile bufhidden=delete noswapfile
  setlocal nomodified
  setlocal nomodifiable
  nmapclear <buffer>
  syntax clear
  syntax match SpecialKey /[\x21-\x7f]\+$/
  nnoremap <silent> <buffer> <cr> :call <SID>connpass_detail()<cr>
  nnoremap <silent> <buffer> q :close<cr>
  redraw | echo ""
endfunction

function! s:connpass_detail()
  let line = line('.') - 1
  let event = s:result_events[line]
  let event_id = event['event_id']
  let title = event['title']
  let catch = event['catch']
  let description = webapi#html#decodeEntityReference(substitute(event['description'], '<[\/]*.\{-}>', '', 'g'))
  let event_url = event['event_url']

  let lines = ''
  let lines .= 'Title: ' . title . ' Event id: ' . event_id . "\n"
  let lines .= 'Owner: ' . event['owner_nickname'] . "\n"
  let lines .= 'Start: ' . event['started_at'] . ' End: ' . event['ended_at'] . "\n"
  let lines .= 'Address: ' . event['address'] . ' ' . event['place'] . "\n"
  let lines .= 'Accepted / Limit: ' . event['accepted'] . ' / ' . event['limit'] . "\n"
  let lines .= 'Waiting: ' . event['waiting'] . "\n"
  let lines .= 'Event type: ' . event['event_type'] . "\n"

  let lines .= 'Hash Tag: ' . event['hash_tag'] . "\n"
  let lines .= 'Catch: ' . catch . "\n"
  let lines .= 'Url: ' . event_url . "\n"

  let lines .= 'Description:' . "\n"
  let lines .= '------------' . "\n"
  let lines .=  description . "\n"

  let winnum = bufwinnr(bufnr('^Connpass$'))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
  else
    exec 'silent noautocmd split Connpass'
  endif
  setlocal modifiable
  silent %d
  silent put!= lines
  normal! Ggg

  setlocal buftype=nofile bufhidden=hide noswapfile
  setlocal nomodified
  setlocal nomodifiable
  syntax clear
  syntax match Constant /^[a-zA-Z0-9_]*$/
  syntax match SpecialKey /^-\+$/
  syntax match Type /\<\(http\|https\|ftp\):\/\/[\x21-\x7f]\+/
  nmapclear <buffer>
  nnoremap <silent> <buffer> q :close<cr>
  redraw | echo ""
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
