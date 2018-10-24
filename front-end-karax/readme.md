# Front-End-Karax
This is extended example for Karax based on [login][login-example] example.  
The extended example is coupled together with server side application to
serve the additional data in which front-end couldn't have.

The example using version:

* Jester: 0.4.1
* Nim: 0.19.1
* Karax: #head

To run this example, do instruction below:

1. Compile [karun][karun] from Karax's git folder, need to clone the
Karax's git to do it.
2. Compile the `login_page.nim` with `karun`. Aka `karun login_page.nim`.
3. Compile `server.nim`.
4. Run the server `./server` for unix-based or `server.exe` for Windows.
5. Head to `localhost:3000/` to see redirection works correctly.
6. Head to `localhost:3000/managing` to see the login page.
7. The username and password is `dummy`, fill other word if we want to see
how it's handled when we can't login.
8. As soon we're able to login, our page will iterate the menu and tell us
our `sessid` which that's session id.

[login-example]: https://github.com/pragmagic/karax/blob/master/examples/login.nim 
[karun]: https://github.com/pragmagic/karax/blob/master/karax/tools/karun.nim
