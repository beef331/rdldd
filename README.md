# Really Dumb ldd

This is a binary acompanied by a library to inject into a program.
It replaces `dlopen` with our own `dlopen` that sends those to a named pipe to the host program.

As this is a library containing nimble package installing does require providing a sudo password to move the library to your `/usr/lib`.

