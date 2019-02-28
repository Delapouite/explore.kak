# Explore

[![IRC Badge]][IRC]

###### [Usage] | [Documentation] | [Contributing]

> A file explorer for [Kakoune].

![Demo]

## Installation

### [Pathogen]

``` kak
pathogen-infect /home/user/repositories/github.com/alexherbo2/explore.kak
```

## Usage

Edit a directory:

``` kak
edit .
```

- Use <kbd>Return</kbd> to edit files (works with multiple selections).
- Use <kbd>Backspace</kbd> to edit parent directory.
- Use <kbd>.</kbd> to show hidden files.
- Use <kbd>R</kbd> to show directory entries recursively.
- Use <kbd>q</kbd> to change directory and quit.
- Use <kbd>Escape</kbd> to close buffer.

## Configuration

### [fd]

``` kak
define-command -hidden explore-files-fd -params 0..1 %{
  explore-files-display "fd %sh(test $kak_opt_explore_files_show_hidden = true && echo --hidden)" %arg(1)
}

hook global WinSetOption filetype=directory %{
  map window normal R ':<space>explore-files-fd %val(bufname)<ret>'
}
```

## Options

- `explore_files_show_hidden` `bool`: Whether to show hidden files (Default: `no`)

## Faces

- `ExploreFiles` `magenta,default`: Face used to show files
- `ExploreDirectories` `cyan,default`: Face used to show directories

## Credits

Similar extensions:

- [TeddyDD]/[kakoune-edit-or-dir]
- [occivink]/[kakoune-filetree]

[Kakoune]: http://kakoune.org
[IRC]: https://webchat.freenode.net?channels=kakoune
[IRC Badge]: https://img.shields.io/badge/IRC-%23kakoune-blue.svg
[Demo]: images/demo.gif
[Usage]: #usage
[Documentation]: #commands
[Contributing]: CONTRIBUTING
[Pathogen]: https://github.com/alexherbo2/pathogen.kak
[fd]: https://github.com/sharkdp/fd
[TeddyDD]: https://github.com/TeddyDD
[kakoune-edit-or-dir]: https://github.com/TeddyDD/kakoune-edit-or-dir
[occivink]: https://github.com/occivink
[kakoune-filetree]: https://github.com/occivink/kakoune-filetree
