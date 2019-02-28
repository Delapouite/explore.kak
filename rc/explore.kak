declare-option -docstring 'Whether to show hidden files' bool explore_show_hidden no

declare-option -hidden str explore
declare-option -hidden int explore_file_count

set-face global ExploreFiles 'magenta,default'
set-face global ExploreDirectories 'cyan,default'

add-highlighter shared/directory regions
add-highlighter shared/directory/content default-region group
add-highlighter shared/directory/content/files regex '^.+$' 0:ExploreFiles
add-highlighter shared/directory/content/directories regex '^.+/$' 0:ExploreDirectories

define-command -hidden explore-display -params 1..2 %{ evaluate-commands %sh{
  command=$1
  path=$(realpath "${2:-.}")
  name=$(basename "$path")
  out=$(mktemp --directory)
  fifo=$out/fifo
  last_buffer_name=$(basename "$kak_bufname")
  mkfifo $fifo
  cd "$path"
  (eval "$command" > $fifo) < /dev/null > /dev/null 2>&1 &
  echo "
    edit -fifo %($fifo) %($path)
    set-option buffer filetype directory
    hook -once window NormalIdle '' %{
      evaluate-commands -save-regs / %{
        set-register / %(\b\Q$last_buffer_name\E\b)
        try %(execute-keys n)
      }
      echo -markup {Information} %(Showing $name/ entries)
    }
    hook -always -once buffer BufCloseFifo '' %(nop %sh(rm --recursive $out))
  "
}}

define-command -hidden explore-smart -params 0..1 %{ evaluate-commands %sh{
  file=${1:-.}
  edit=$(test -d "$file" && echo explore || echo edit)
  echo "$edit %($file)"
}}

define-command -hidden explore -params 0..1 -docstring 'Edit directory entries' %{
  explore-display "ls --dereference --group-directories-first --indicator-style=slash %sh(test $kak_opt_explore_show_hidden = true && echo --almost-all)" %arg(1)
}

define-command -hidden explore-recursive -params 0..1 -docstring 'Edit directory entries recursively' %{
  explore-display "find %sh(test $kak_opt_explore_show_hidden = false && echo -not -path ""'*/.*'"")" %arg(1)
}

define-command -hidden explore-forward -docstring 'Edit selected files' %{
  set-option current explore %val(bufname)
  execute-keys '<a-s>;<a-x>_'
  set-option current explore_file_count %sh(count() { echo $#; }; count $kak_selections_desc)
  evaluate-commands -draft -itersel %{
    evaluate-commands -client %val(client) explore-smart "%val(bufname)/%reg(.)"
  }
  delete-buffer %opt(explore)
  evaluate-commands %sh{
    count=$kak_opt_explore_file_count
    test $count -gt 1 &&
      echo "echo -markup {Information} %[$count files opened]"
  }
}

define-command -hidden explore-back -docstring 'Edit parent directory' %{
  set-option current explore %val(bufname)
  explore "%opt(explore)/.."
  delete-buffer %opt(explore)
  echo -markup {Information} "Showing %sh(basename ""$kak_bufname"")/ entries"
}

define-command -hidden explore-change-directory -docstring 'Change directory and quit' %{
  change-directory %val(bufname)
  delete-buffer
}

define-command -hidden explore-toggle-hidden -docstring 'Toggle hidden files' %{
  set-option current explore_show_hidden %sh{
    if test $kak_opt_explore_show_hidden = true; then
      echo no
    else
      echo yes
    fi
  }
  explore %val(bufname)
}

hook global WinSetOption filetype=directory %{
  add-highlighter window/ ref directory
  map window normal <ret> ':<space>explore-forward<ret>'
  map window normal <backspace> ':<space>explore-back<ret>'
  map window normal . ':<space>explore-toggle-hidden<ret>'
  map window normal R ':<space>explore-recursive %val(bufname)<ret>'
  map window normal q ':<space>explore-change-directory<ret>'
  map window normal <esc> ':<space>delete-buffer<ret>'
}

hook global WinSetOption filetype=(?!directory).* %{
  remove-highlighter window/directory
}

define-command -hidden explore-enable %{
  hook window -group explore RuntimeError '\d+:\d+: ''\w+'' (.+): is a directory' %{
    # Hide error message
    echo
    explore %val(hook_param_capture_1)
  }
  hook window -group explore RuntimeError 'unable to find file ''(.+)''' %{
    # Hide error message
    echo
    explore-smart %val(hook_param_capture_1)
  }
}

hook -group explore global WinCreate .* %{
  explore-enable
}
