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

  redraw | echo "fetching feed..."
  let response = webapi#http#get(uri)
  let content = webapi#json#decode(response.content)
  let results_available = content['results_available']

  let results_start = content['results_start']
  let s:result_events = copy(content['events'])
  let events = content['events']

  call s:connpass_list(events)
  redraw | echo ''
endfunction

function! s:connpass_list(events)
  " This function copy lots from toggeter-vim.
  " see https://github.com/mattn/togetter-vim/blob/master/plugin/togetter.vim#L44
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

  call setline(1, map(deepcopy(a:events), 'v:val["title"]." : ".v:val["owner_nickname"]'))

  setlocal buftype=nofile bufhidden=delete noswapfile
  setlocal nomodified
  setlocal nomodifiable
  nmapclear <buffer>
  auto CursorMoved <buffer> setlocal cursorline
  syntax clear
  syntax match SpecialKey /[\x21-\x7f]\+$/
  nnoremap <silent> <buffer> <cr> :call <SID>connpass_detail()<cr>
  nnoremap <silent> <buffer> q :close<cr>
endfunction

function! s:connpass_detail()
  let line = line('.') - 1
  let event = s:result_events[line]
  let event_id = event['event_id']
  let title = event['title']

  let description = webapi#html#decodeEntityReference(substitute(event['description'], '<[\/]*.\{-}>', '', 'g'))
  let event_url = event['event_url']
  let place = substitute(event['place'], '\s\+$', '', 'g')

  let lines = ''
  let lines .= 'Title      : ' . title . ' Event id: ' . event_id . "\n"
  let lines .= 'Owner      : ' . event['owner_nickname'] . "\n"
  let lines .= 'Start      : ' . event['started_at'] . ' End: ' . event['ended_at'] . "\n"
  let lines .= 'Address    : ' . event['address'] . ' ' . place . "\n"
  let lines .= 'Accepted   : ' . event['accepted'] . "\n"
  let lines .= 'Limit      : ' . event['limit'] . "\n"
  let lines .= 'Waiting    : ' . event['waiting'] . "\n"
  let lines .= 'Event type : ' . event['event_type'] . "\n"
  let lines .= substitute('Hash Tag   : ' . event['hash_tag'], '\s\+$', '', 'g') . "\n"
  let lines .= substitute('Catch      : ' . event['catch'], '\s\+$', '', 'g') . "\n"
  let lines .= 'Url        : ' . event_url . "\n"
  let lines .= substitute('Description: ', '\s\+$', '', 'g') . "\n"
  let lines .= '------------' . "\n"
  let lines .= description

  let winnum = bufwinnr(bufnr('^Connpass$'))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
  else
    exec 'silent noautocmd split Connpass'
  endif

  setlocal modifiable
  redraw | echo 'Show detail...'
  silent %d


  silent put!= lines
  normal! Ggg

  setlocal buftype=nofile bufhidden=hide noswapfile
  setlocal nomodified
  setlocal nomodifiable
  auto CursorMoved <buffer> call s:cursor_moved()
  syntax clear
  syntax match Constant /^[a-zA-Z0-9_]*$/
  syntax match SpecialKey /^-\+$/
  syntax match Type /\<\(http\|https\|ftp\):\/\/[\x21-\x7f]\+/
  nmapclear <buffer>
  nnoremap <silent> <buffer> q :close<cr>
  nnoremap <silent> <buffer> b :call <SID>back_to_list()<cr>
  redraw | echo ''
endfunction

function! s:back_to_list()
  call s:connpass_list(s:result_events)
endfunction

function! s:cursor_moved()
  let l = line('.')
  if l > 13
    setlocal nocursorline
  else
    setlocal cursorline
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
