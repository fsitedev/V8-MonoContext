use 5.010001;
use ExtUtils::MakeMaker;
use Config;

die 'No V8_PREFIX in ENV found'  unless $ENV{V8_PREFIX};

my $CC = 'g++';

WriteMakefile(
    NAME              => 'V8::MonoContext',
    VERSION_FROM      => 'lib/V8/MonoContext.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/V8/MonoContext.pm', # retrieve abstract from module
       AUTHOR         => 'fsitedev <fsite.dev@gmail.com>') : ()),
    LIBS              => ['-lv8monoctx'],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. -I$ENV{V8_PREFIX}/include",
    CC                => $CC,
    LD                => $CC,
	XSOPT             => '-C++ -hiertype',
);

