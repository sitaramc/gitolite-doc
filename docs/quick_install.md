# quick install and setup

----

!!! danger ""
    If your Unix-fu and ssh-fu are good, this will work for you.  Otherwise,
    please click the "next" button up there on the right for a more leisurely,
    detailed, drive through the install process.

### distro package install

Tip: look for packages called 'gitolite3' before you look for 'gitolite'.

### install from source

If you're comfortable with Unix and ssh, just copy your ssh public key from
your workstation to the hosting user, then do something like this:

```sh
su - git
mkdir -p ~/bin

git clone https://github.com/sitaramc/gitolite
gitolite/install -ln ~/bin          # please use absolute path here
gitolite setup -pk yourname.pub
```

Please be sure to read any messages produced by these steps, especially the
last one, to make sure things went OK.

Notes:

1.  If your [hosting user][hu] is not 'git', substitute accordingly.
2.  Make sure `~/bin` is in `$PATH`.  If it is not, add something to your
    shell startup files to make it so.  If some other writable directory is in
    the path, you can use that if you like.
3.  Substitute your name for "yourname" :-)

[hu]: concepts.md#the-hosting-user
