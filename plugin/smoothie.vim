" nnoremap <silent> <C-D>      :<C-U>call smoothie#downwards() <CR>
" nnoremap <silent> <C-U>      :<C-U>call smoothie#upwards()   <CR>
" nnoremap <silent> <C-F>      :<C-U>call smoothie#forwards()  <CR>
" nnoremap <silent> <S-Down>   :<C-U>call smoothie#forwards()  <CR>
nnoremap <silent> <PageDown> :<C-U>call smoothie#downwards()  <CR>
" nnoremap <silent> <C-B>      :<C-U>call smoothie#backwards() <CR>
" nnoremap <silent> <S-Up>     :<C-U>call smoothie#backwards() <CR>
nnoremap <silent> <PageUp>   :<C-U>call smoothie#upwards() <CR>

" nmap <silent> n :<C-u>if &hlsearch \| set hlsearch \| endif<CR>:<C-U>call smoothie#next_match() <CR>
" nmap <silent> N :<C-u>if &hlsearch \| set hlsearch \| endif<CR>:<C-U>call smoothie#prev_match() <CR>
" nmap <silent> * :<C-u>if &hlsearch \| set hlsearch \| endif<CR>:<C-U>call smoothie#next_occurance() <CR>
" nmap <silent> # :<C-u>if &hlsearch \| set hlsearch \| endif<CR>:<C-U>call smoothie#prev_occurance() <CR>
" nmap <silent> gg :<C-U>call smoothie#beg_of_file() <CR>
" nmap <silent> G :<C-U>call smoothie#end_of_file() <CR>

nmap <silent> <F4> :<C-U>call smoothie#displayBar()<CR>

nmap <silent> n n<F4>
nmap <silent> N N<F4>
nmap <silent> * *<F4>
nmap <silent> # #<F4>
nmap <silent> gg gg<F4>
nmap <silent> G G<F4>
