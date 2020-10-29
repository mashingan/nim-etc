# Front-End-Karax
This is extended example for Karax based on [login][login-example] example.  
The extended example is coupled together with server side application to
serve the additional data in which front-end couldn't have.

The example using version:

* Jester: 0.5.0
* Nim: 1.4.0
* Karax: 1.1.3

To run this example, do instruction below:

1. Install Jester with `nimble install jester`.
2. Install Karax and Karun with `nimble install karax`.
3. Compile the `login_page.nim` with `karun` so `karun login_page.nim` or for release version `karun -d:release login_page.nim`.
4. Move `app.html` and `app.js` to the `pkgs` folder.
5. Compile `server.nim` with `nim c server.nim`. Add the `--run or -r` to immediately run the server.
6. Head to `localhost:3000` to see redirection works correctly.
7. Head to `localhost:3000/managing` to see the login page.
8. Fill username and password with `dummy` (literally) to login.
9. Try with other combinations to see if we can't login handled properly.
10. Try register the new username-password combination for new user.
11. After we login, we'll see a menu list of available pages.

For the completion, here's what I do

```
$ cd front-end-karax
$ nimble install jester
$ nimble install karax
$ karun -d:danger login_page.nim
$ mkdir public
$ mv app* public
$ nim c -r -d:danger server.nim
...snip...
...snip...
INFO Jester is making jokes at http://127.0.0.1:3000 (all interfaces)
```

After that we open the browser to `http://localhost:3000/managing`

[login-example]: https://github.com/pragmagic/karax/blob/master/examples/login.nim 
[karun]: https://github.com/pragmagic/karax/blob/master/karax/tools/karun.nim
