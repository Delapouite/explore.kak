declare-option -docstring 'Whether to show hidden files' bool edit_directory_show_hidden no
declare-option -docstring 'Whether extension is active' bool edit_directory_enabled no

declare-option -hidden str edit_directory
declare-option -hidden int edit_directory_file_count
declare-option -hidden -docstring 'Shell command run to show directory entries' str edit_directory_command 'ls --almost-all --dereference --group-directories-first --indicator-style=slash'
declare-option -hidden -docstring 'Shell command run to show directory entries recursively' str edit_directory_command_recursive 'find'

set-face global EditDirectoryFiles 'magenta,default'
set-face global EditDirectoryDirectories 'cyan,default'

add-highlighter shared/directory regions
add-highlighter shared/directory/content default-region group
add-highlighter shared/directory/content/files regex '^.+$' 0:EditDirectoryFiles
add-highlighter shared/directory/content/directories regex '^.+/$' 0:EditDirectoryDirectories

define-command -hidden edit-directory -params 1 %{
  edit -scratch %sh(realpath "$1")
  set-option buffer filetype directory
  execute-keys "%%d<a-!>cd %arg(1); %opt(edit_directory_command)<ret>d"
  evaluate-commands %sh{
    test $kak_opt_edit_directory_show_hidden = false && {
      echo "try %[execute-keys -draft '%<a-s><a-k>^[.][^/]|/[.]<ret>d']"
    }
  }
  info "Showing %sh(basename ""$kak_bufname"")/ entries"
}

define-command -hidden edit-directory-recursive %{
  execute-keys "%%d<a-!>cd %val(bufname); %opt(edit_directory_command_recursive)<ret>d"
  evaluate-commands %sh{
    test $kak_opt_edit_directory_show_hidden = false && {
      echo "try %[execute-keys -draft '%<a-s><a-k>^[.][^/]|/[.]<ret>d']"
    }
  }
  info "Showing %sh(basename ""$kak_bufname"")/ entries recursively"
}

define-command -hidden edit-directory-forward %{
  set-option current edit_directory %val(bufname)
  execute-keys '<a-s>'
  set-option current edit_directory_file_count %sh(count() { echo $#; }; count $kak_selections_desc)
  evaluate-commands -draft -itersel %{
    execute-keys ';<a-x>_'
    evaluate-commands -draft %sh{
      test -d "$kak_bufname/$kak_main_reg_dot" &&
        echo edit-directory ||
        echo edit
    } "%val(bufname)/%reg(.)"
  }
  execute-keys '<space>;<a-x>_'
  evaluate-commands %sh{
    test -d "$kak_bufname/$kak_main_reg_dot" &&
      echo edit-directory ||
      echo edit
  } "%val(bufname)/%reg(.)"
  delete-buffer %opt(edit_directory)
  evaluate-commands %sh{
    count=$kak_opt_edit_directory_file_count
    test $count -gt 1 &&
      echo "info %[$count files opened]"
  }
}

define-command -hidden edit-directory-back %{
  set-option current edit_directory %val(bufname)
  edit-directory "%val(bufname)/.."
  set-register / "\b\Q%sh(basename ""$kak_opt_edit_directory"")\E\b"
  execute-keys n
  delete-buffer %opt(edit_directory)
  info "Showing %sh(basename ""$kak_bufname"")/ entries"
}

define-command -hidden edit-directory-change-directory %{
  change-directory %val(bufname)
  delete-buffer
}

hook global WinSetOption filetype=directory %{
  add-highlighter window/ ref directory
  map window normal <ret> ':<space>edit-directory-forward<ret>'
  map window normal <backspace> ':<space>edit-directory-back<ret>'
  map window normal . ':<space>edit-directory-toggle-hidden<ret>'
  map window normal R ':<space>edit-directory-recursive<ret>'
  map window normal q ':<space>edit-directory-change-directory<ret>'
  map window normal <esc> ':<space>delete-buffer<ret>'
}

hook global WinSetOption filetype=(?!directory).* %{
  remove-highlighter window/directory
}

define-command edit-directory-toggle-hidden -docstring 'Toggle hidden files' %{
  set-option window edit_directory_show_hidden %sh{
    if test $kak_opt_edit_directory_show_hidden = true; then
      echo no
    else
      echo yes
    fi
  }
  edit-directory %val(bufname)
}

define-command edit-directory-enable -docstring 'Enable editing directories' %{
  hook window -group edit-directory RuntimeError '\d+:\d+: ''\w+'' (.+): is a directory' %{
    edit-directory %val(hook_param_capture_1)
  }
  hook window -group edit-directory RuntimeError 'unable to find file ''(.+)''' %{
    evaluate-commands %sh{
      test -d "$kak_hook_param_capture_1" || {
        echo fail Not a directory
      }
    }
    edit-directory %val(hook_param_capture_1)
  }
  set-option window edit_directory_enabled yes
}

define-command edit-directory-disable -docstring 'Disable editing directories' %{
  remove-hooks window edit-directory
  set-option window edit_directory_enabled no
}

define-command edit-directory-toggle -docstring 'Toggle editing directories' %{ evaluate-commands %sh{
  if $kak_opt_edit_directory_enabled = true; then
    echo edit-directory-disable
  else
    echo edit-directory-enable
  fi
}}
