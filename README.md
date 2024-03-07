# Really Dumb ldd

This is a binary acompanied by a library to inject into a program.
It replaces `dlopen` with our own `dlopen` that appends loaded libraries to a list.
Then it saves them to a file by default.

As this is a library containing nimble package installing does require providing a sudo password to move the library to your `/usr/lib`.

