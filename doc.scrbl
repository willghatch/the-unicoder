#lang scribble/manual
@(require (for-label racket/base
                     ))

@title[#:tag "the-unicoder"]{The Unicoder}
@author+email["William Hatch" "william@hatch.uno"]

@defmodule[the-unicoder]

This is a tool for inputting Unicode characters.

At the moment it only works on Unix systems running X11, and it requires
the program @code{xdotool} to be installed.

To use @racket[the-unicoder], simply run @code{the-unicoder} or
@code{racket -l the-unicoder} in a terminal or from a keyboard shortcut.
You may notice that its startup time is too long to make it terribly
useful for common use.  To improve this, you can run a the-unicoder
server and send it commands with a the-unicoder client.

Summary of options below:

@itemlist[
  @item{@code{--server}: Run a server that accepts commands.  Requires @code{--path} or @code{--port}.}
  @item{@code{--client}: Send a command to the server.  Requires @code{--path} or @code{--port}.}
  @item{@code{--path <path to socket>}: use a Unix domain socket at that path.  Currently only available on Linux and Mac OSX.}
  @item{@code{--port <port number>}: use the given TCP port.  While it only accepts connections from localhost, it will still let anyone else with access to your machine make you type anything they want.  So, be ye warned.}
  @item{@code{--command <command name>}: Which command to use with the client.  Options are @code{prompt} (the default), and @code{reload} (reloads configuration files).}
  @item{@code{--help}: Show a list of options.}
]

@section{Configuration}

@code{the-unicoder} configuration files live in
@code{$XDG_CONFIG_HOME/the-unicoder/unicoder-table}
(@code{$XDG_CONFIG_HOME} defaults to @code{$HOME/.config} on Unix and
@code{C:\Users\username\AppData\Local} on Windows), or in
@code{$dir/the-unicoder/unicoder-table} where @code{$dir} is any
directory in @code{$XDG_CONFIG_DIRS}.  Multiple can be specified.

@code{unicoder-table} should consist of a single hash table readable by the default racket reader, like so:

@codeblock{
#hash(
("description of the letter upsilon" . "υ")
("description of the couch emoji" . "🛋")
("lam" . "λ")
("ycpash" . "you can put a string here")
)
}

