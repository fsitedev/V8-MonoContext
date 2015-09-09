# Perl V8::MonoContext

V8::MonoContext - XS perl binding for V8 MonoContext library
Commonly intended for rendering 'fest' templates

# INSTALLATION

First of all install v8monoctx shared library and set 
V8_VERSION and V8_PREFIX environment variables

To install this perl module type the following:

  perl Makefile.PL
  make
  make test
  sudo make install

# DEPENDENCIES FOR PERL MODULE

This module requires these other modules and libraries:

  Perl >5.10.1
  Perl ExtUtils-Embed
  Perl ExtUtils-Manifest
  Installed shared v8monoctx library
