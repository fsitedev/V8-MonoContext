package V8::MonoContext;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use V8::MonoContext ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '3.04';

require XSLoader;
XSLoader::load('V8::MonoContext', $VERSION);

# Preloaded methods go here.

__END__

=head1 NAME

V8::MonoContext - XS perl binding for V8 MonoContext library
Commonly intended for rendering 'fest' templates
 
=head1 SYNOPSIS
 
  # Make global monocontext object in master process of webserver
  package SomePackageUsedOnServerStartup;

  use V8::MonoContext;
  use JSON::XS;

  $v8 = V8::MonoContext->new({
    run_low_memory_notification => 300,
    cmd_args => '--max-old-space-size=128',
    (
		$ENV{DEVELOPMENT} ? (watch_templates => 1) : ()
	)
  });

  ...
  ...
  1;

  # Load Helpers and all the tools in lazy mode
  # They will be available throughout the life of the process
  my $js_libs_loaded;
  my $js_helpers_file = '/home/test/js/templates_context.js';

  # Method fires on each incoming request
  sub dispatch_request {

    # Load helpers in lazy mode
	if (!defined($js_libs_loaded) && -f $js_helpers_file) {
      $v8->load_file($js_helpers_file);
      $js_libs_loaded++;
    }

    # Extract template name (used as fest namespace)
    my $nspace = (split /\//, $tpl_file_path)[-2];
    
    # Prepare valid json string
    my $json = encode_json($data_hash_ref_for_template);
    
    # Rendering process. Output assigned into $out variable
    my $out;
    my $res = $v8->execute_file(
      '/home/test/js/test.xml.js',
      \$out,
      {
        json => $json,
        append => ';fest["test.xml"]( JSON.parse(__dataFetch()) );',
      }
    );
    
    # No errors
    # $out variable contains rendered content now
    if ($res) {
      # Different info can be recieved after request
      my $stat = $obj->counters;  # profiling data of all valuable v8 processing steps
      my $heap = $obj->heap_stat; # v8 memory heap stat
    }
    
    # Raise 500 error or smth. else
    else {}
  }

  1;

=head1 DESCRIPTION

Module utilizes one V8 context for process via V8 MonoContext library

All processed javascript files fall under the caching mechanism after
the compilation process.

Threads are not supported.

=head1 CONSTRUCTOR OPTIONS

=item "run_low_memory_notification"
Set the low memory notification v8 flag after specified number of requests.

=item "run_idle_notification_loop"
Check v8 idle notification flag in loop after specified number of requests.

=item "watch_templates"
Recompile template if it has been changed since last compilation.
Useful in development.

=item "cmd_args"
Pass command line options directly to v8. All keys can be explored from sources
http://v8.googlecode.com/svn/trunk/src/flag-definitions.h 

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

fsitedev, E<lt>fsite.dev@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by fsitedev

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
