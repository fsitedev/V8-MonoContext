# V8::MonoContext

XS perl binding for V8 MonoContext library

Commonly intended for rendering 'fest' templates

# INSTALLATION

First of all install [v8monoctx][1] shared library and set 
V8_VERSION and V8_PREFIX environment variables

To install this perl module type the following:

    perl Makefile.PL
    make
    make test
    sudo make install

# DEPENDENCIES FOR PERL MODULE

Module requires these other modules and libraries:

    perl >5.10.1
    perl ExtUtils-Embed
    perl ExtUtils-Manifest
    v8monoctx library


[1]: https://github.com/fsitedev/v8monoctx
