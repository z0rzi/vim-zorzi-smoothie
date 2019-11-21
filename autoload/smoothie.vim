if !exists('g:smoothie_update_interval')
  ""
  " Time (in milliseconds) between subseqent screen/cursor postion updates.
  " Lower value produces smoother animation.  Might be useful to increase it
  " when running Vim over low-bandwidth/high-latency connections.
  let g:smoothie_update_interval = 20
endif

if !exists('g:smoothie_base_speed')
  ""
  " Base scrolling speed (in lines per second), to be taken into account by
  " the velocity calculation algorithm.  Can be decreased to achieve slower
  " (and easier to follow) animation.
  let g:smoothie_base_speed = 10
endif

if !exists('g:smoothie_break_on_reverse')
  ""
  " Stop immediately if we're moving and the user requested moving in opposite
  " direction.  It's mostly useful at very low scrolling speeds, hence
  " disabled by default.
  let g:smoothie_break_on_reverse = 0
endif

""
" Execute {command}, but saving 'scroll' value before, and restoring it
" afterwards.  Useful for some commands (such as ^D or ^U), which overwrite
" 'scroll' permanently if used with a [count].
function s:execute_preserving_scroll(command)
  let l:saved_scroll = &scroll
  execute a:command
  let &scroll = l:saved_scroll
endfunction

""
" Scroll the window up by one line, or move the cursor up if the window is
" already at the top.  Return 1 if cannot move any higher.
function s:step_up()
  if line('.') > 1
    call s:execute_preserving_scroll("normal! 1\<C-U>")
    return 0
  else
    return 1
  endif
endfunction

""
" Scroll the window down by one line, or move the cursor down if the window is
" already at the bottom.  Return 1 if cannot move any lower.
function s:step_down()
  if line('.') < line('$')
    call s:execute_preserving_scroll("normal! 1\<C-D>")
    return 0
  else
    return 1
  endif
endfunction

""
" Perform as many steps up or down to move {lines} lines from the starting
" position (negative {lines} value means to go up).  Return 1 if hit either
" top or bottom, and cannot move further.
function s:step_many(lines)
  let l:remaining_lines = a:lines
  while 1
    if l:remaining_lines < 0
      if s:step_up()
        return 1
      endif
      let l:remaining_lines += 1
    elseif l:remaining_lines > 0
      if s:step_down()
        return 1
      endif
      let l:remaining_lines -= 1
    else
      return 0
    endif
  endwhile
endfunction

""
" A Number indicating how many lines do we need yet to move down (or up, if
" it's negative), to achieve what the user wants.
let s:target_displacement = 0
let s:target_column = 0

""
" A Float between -1.0 and 1.0 keeping our position between integral lines,
" used to make the animation smoother.
let s:subline_position = 0.0

""
" Start the animation timer if not already running.  Should be called when
" updating the target, when there's a chance we're not already moving.
function s:start_moving()
  if !exists('s:timer_id')
    let s:timer_id = timer_start(g:smoothie_update_interval, function("s:movement_tick"), {'repeat': -1})
  endif
endfunction

""
" Stop any movement immediately, and disable the animation timer to conserve
" power.
function s:stop_moving()
  let s:target_displacement = 0
  let s:subline_position = 0.0
  if exists('s:timer_id')
    call timer_stop(s:timer_id)
    unlet s:timer_id
  endif
endfunction

""
" Calculate optimal movement velocity (in lines per second, negative value
" means to move upwards) for the next animation frame.
"
" TODO: current algorithm is rather crude, would be good to research better
" alternatives.
function s:compute_velocity()
  return g:smoothie_base_speed * (s:target_displacement + s:subline_position)
endfunction

""
" Execute single animation frame.  Called periodically by a timer.  Accepts a
" throwaway parameter: the timer ID.
function s:movement_tick(_)
  if s:target_displacement == 0
    call s:stop_moving()
    call s:afterScroll()
    return
  endif

  let l:subline_step_size = s:subline_position + (g:smoothie_update_interval/1000.0 * s:compute_velocity())
  let l:step_size = float2nr(trunc(l:subline_step_size))

  if abs(l:step_size) > abs(s:target_displacement)
    " clamp step size to prevent overshooting the target
    let l:step_size = s:target_displacement
  end

  if s:step_many(l:step_size)
    " we've collided with either buffer end
    call s:stop_moving()
  else
    let s:target_displacement -= l:step_size
    let s:subline_position = l:subline_step_size - l:step_size
  endif

  if l:step_size
    " Usually Vim handles redraws well on its own, but without explicit redraw
    " I've encountered some sporadic display artifacts.  TODO: debug further.
    redraw
  endif
endfunction

""
" Set a new target where we should move to (in lines, relative to our current
" position).  If we're already moving, try to do the smart thing, taking into
" account our progress in reaching the target set previously.
function s:update_target(lines)
  if g:smoothie_break_on_reverse && s:target_displacement * a:lines < 0
    call s:stop_moving()
  else
    let s:target_displacement += a:lines
    call s:start_moving()
  endif
endfunction

""
" Helper function to set 'scroll' to [count], similarly to what native ^U and
" ^D commands do.
function s:count_to_scroll()
  if v:count
    let &scroll=v:count
  end
endfunction

function s:afterScroll()
  if exists("s:target_column") && s:target_column > 0
    call setpos('.', getpos('.')[:1] + [s:target_column] + [0])
    norm!hl
    let s:target_column = 0
  endif

  call s:displayBar()
endfunction

""
" Smooth equivalent to ^D.
function smoothie#downwards()
  call s:count_to_scroll()
  call s:update_target(&scroll)
endfunction

""
" Smooth equivalent to ^U.
function smoothie#upwards()
  call s:count_to_scroll()
  call s:update_target(-&scroll)
endfunction

""
" Smooth equivalent to ^F.
function smoothie#forwards()
  call s:update_target(winheight(0) * v:count1)
endfunction

""
" Smooth equivalent to ^B.
function smoothie#backwards()
  call s:update_target(-winheight(0) * v:count1)
endfunction


function smoothie#next_match()
  let destPos = searchpos(@/, 'n')
  call s:update_target( -line('.') + destPos[0] )
  let s:target_column = destPos[1]
endfunction

function smoothie#prev_match()
  let destPos = searchpos(@/, 'nb')
  call s:update_target( -line('.') + destPos[0] )
  let s:target_column = destPos[1]
endfunction


function smoothie#next_occurance()
  let @/='\<' . expand('<cword>') . '\>'
  call smoothie#next_match()
endfunction

function smoothie#prev_occurance()
  let @/='\<' . expand('<cword>') . '\>'
  call smoothie#next_match()
endfunction

function smoothie#beg_of_file()
  call s:update_target( -line('.') )
endfunction

function smoothie#end_of_file()
  call s:update_target( line('$') - line('.') )
endfunction


if !exists("g:scroll_str")
    let g:scroll_str = "█"
    let g:scroll_str_length = 3 " because vim can't count string with special characters
endif

function! s:displayBar()
  set nomore

  " let curpos = getpos('.')
  let totalLines = line('$')
  let drawableWidth = winwidth(0) -15 - g:scroll_str_length

  let matches = []

  let l=0
  while l <= line('$')
    if matchstr(getline(l), @/) != ''
      let matches += [ l * drawableWidth / totalLines ]
    endif
    let l+=1
  endwhile
  let cursor = ( drawableWidth ) * line('.') / totalLines

  let bar=''
  let prev = 0

  let cursorSizePre = g:scroll_str_length/2 + ( g:scroll_str_length+1 )%2
  let cursorSizePost = g:scroll_str_length - cursorSizePre - 1

  for m in matches
    if m <= prev | continue | endif

    if cursor>0 && cursor == m

      let bar .= repeat(' ', cursor - cursorSizePre - prev) . g:scroll_str
      let prev = cursor + cursorSizePost
      let cursor = 0

    elseif cursor>0 && (cursor-cursorSizePre) <= m

      let bar .= repeat(' ', cursor - cursorSizePre - prev) . g:scroll_str
      let prev = cursor + cursorSizePost
      let cursor = 0

      let bar .= repeat(' ', m-prev-1) . ':'
      let prev=m

    else

      let bar .= repeat(' ', m-prev-1) . ':'
      let prev=m

    endif
  endfor

  echo bar
endfunction
