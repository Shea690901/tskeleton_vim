" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    64

if &cp || exists("loaded_tskeleton_snippets_autoload")
    finish
endif
let loaded_tskeleton_snippets_autoload = 1


if !exists('g:tskeleton#snippets#force')
    " If true, allow snippets to overwrite other skeletons.
    let g:tskeleton#snippets#force = 0   "{{{2
endif


function! tskeleton#snippets#Initialize() "{{{3
endf


function! tskeleton#snippets#FiletypeBits(dict, type) "{{{3
    " TLogVAR a:type
    " TAssert IsDictionary(a:dict)
    " TAssert IsString(a:type)
    let bf = split(globpath(&rtp, 'snippets/'. a:type .'.snippets'), '\n')
    let bf = map(bf, 'fnamemodify(v:val, ":p")')
    if exists('g:snippets_dir')
        " TLogVAR g:snippets_dir
        let sfiles = split(globpath(g:snippets_dir, 'snippets/'. a:type .'.snippets'), '\n')
        " TLogVAR sfiles
        for sfile in sfiles
            let sfile = fnamemodify(sfile, ':p')
            if index(bf, sfile) == -1
                call add(bf, sfile)
            endif
        endfor
    endif
    " let cx = tskeleton#CursorMarker('rx')
    " let cm = tskeleton#CursorMarker()
    for f in bf
        " TLogVAR f
        if !isdirectory(f) && filereadable(f)
            let cache_name = tskeleton#MaybePathshorten(f)
            let cfile = tlib#cache#Filename('tskel_snip', tlib#url#Encode(cache_name), 1)
            let ftime = getftime(f)
            let snippets = tlib#cache#Value(cfile, 'tskeleton#snippets#Generator', ftime, [f])
            " TLogVAR snippets
            call extend(a:dict, snippets, g:tskeleton#snippets#force ? 'force' : 'keep')
        endif
    endfor
endf


function! tskeleton#snippets#Generator(filename) "{{{3
    let snippets = {}
    let lines = readfile(a:filename)
    let def = {}
    let indent = ''
    let mode = 'find'
    let max = len(lines)
    let lnum = 0
    while lnum < max
        let line = lines[lnum]
        " TLogVAR lnum, line
        if mode == 'find'
            if line =~ '^#'
                " ignore
            elseif line =~ '^snippet\s'
                let name = matchstr(line, '^snippet\s\+\zs\S\+')
                let def = {'cname': name, 'mname': name, 'text': '', 'type': 'tskeleton', 'meta': {}, 'bitfile': a:filename}
                let mode = 'PARSE'
            else
                " shouldn't be here
            endif
        elseif mode ==? 'parse'
            if line =~ '^\s' || empty(line)
                if mode ==# 'PARSE'
                    let s:first_pos = 1
                    let mode = 'parse'
                    let indent = matchstr(line, '^\s\+')
                endif
                let pre = empty(def.text) ? '' : "\n"
                let body = s:ConvertSnippet(strpart(line, strlen(indent)))
                let def.text .= pre . body
            else
                if !empty(def)
                    " TLogVAR def
                    let snippets[def.cname] = def
                endif
                let mode = 'find'
                let lnum -= 1
            endif
        endif
        let lnum += 1
    endwh
    return snippets
endf


function! s:ConvertSnippet(line) "{{{3
    " TLogVAR a:line
    let line = substitute(a:line,
                \ '\$\(\([1-9]\)$\|\([1-9]\)\|{\([1-9]\)}$\|{\([1-9]\)}\|{\([1-9]:[^}]\+\)}$\|{\([1-9]:[^}]\+\)}\)',
                \ '\=s:Pos(a:line, submatch(2), submatch(3), submatch(4), submatch(5), submatch(6), submatch(7))',
                \ 'g')
    return line
endf


function! s:Pos(line, simpleeol, simple, exteol, ext, extnoteeol, extnote) "{{{3
    " TLogVAR a:simpleeol, a:simple, a:exteol, a:ext, a:extnoteeol, a:extnote
    if !empty(a:simpleeol)
        " return '<++>'
        return printf('<+%s+>', s:Name(a:simple))
    elseif !empty(a:simple)
        return printf('<+%s+>', s:Name(a:simple))
    elseif !empty(a:exteol)
        " return '<++>'
        return printf('<+%s+>', s:Name(a:exteol))
    elseif !empty(a:ext)
        return printf('<+%s+>', s:Name(a:ext))
    elseif !empty(a:extnoteeol)
        " return printf('<+/%s+>', matchstr(a:extnoteeol, '^\d\+:\zs.*$'))
        return printf('<+%s/%s+>', s:Name(matchstr(a:extnoteeol, '^\d\+')), matchstr(a:extnoteeol, '^\d\+:\zs.*$'))
    elseif !empty(a:extnote)
        return printf('<+%s/%s+>', s:Name(matchstr(a:extnote, '^\d\+')), matchstr(a:extnote, '^\d\+:\zs.*$'))
    else
        throw "tskeleton/Snippets: Internal error when parsing ". a:line
    endif
endf


function! s:Name(num) "{{{3
    if s:first_pos
        let s:first_pos = 0
        return 'CURSOR'
    else
        return 'POS'. a:num
    endif
endf

