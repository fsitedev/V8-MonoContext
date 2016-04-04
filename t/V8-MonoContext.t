use strict;
use warnings;

use ExtUtils::testlib;
use FindBin;
use Encode qw/decode/;
use Data::Dumper;
use File::Temp;
use IO::Handle;

use Test::More tests => 19;
BEGIN { use_ok('V8::MonoContext') };

my $out;
my $json;
my $json_file	= "$FindBin::Bin/../t_data/json";
my $tt_file		= "$FindBin::Bin/../t_data/js";
my $zero_file	= "$FindBin::Bin/../t_data/zero_embed";

open FH, $json_file or die;
	{local $\ = undef; $json = <FH>};
close FH;

my $obj = V8::MonoContext->new({run_low_memory_notification => 2, run_idle_notification_loop => 6, watch_templates => 1, cmd_args => '--max-old-space-size=128'});

my $sum_stat;
my $last_stat;
my $last_heap;
sub print_stat {
	$obj->idle_notification(11);
	$obj->low_memory_notification;

	my $stat = $obj->counters;
	my $heap = $obj->heap_stat;

	foreach (keys %$stat) {
		$sum_stat->{$_} += $stat->{$_};
	}
	
	my $str = sprintf 'CNT:%d, EXEC:%.06f, COMPILE:%.06f, RLMN:%.06f, RINL:%.06f, H_LIMIT:%d, H_TOTAL:%d(%d%%), H_USED:%d(%d%%), H_PHYS:%d(%d%%), H_EXEC:%d(%d%%)  %s',
		$stat->{request_num},
		$stat->{exec_time},
		$stat->{compile_time},
		$stat->{run_low_memory_notification_time},
		$stat->{run_idle_notification_loop_time},

		$heap->{limit},
		$heap->{total},
		$last_heap->{total} ? (100 * $heap->{total} / $last_heap->{total} - 100) : 0,
		$heap->{used},
		$last_heap->{used} ? (100 * $heap->{used} / $last_heap->{used} - 100) : 0,
		$heap->{total_physical},
		$last_heap->{total_physical} ? (100 * $heap->{total_physical} / $last_heap->{total_physical} - 100) : 0,
		$heap->{total_executable},
		$last_heap->{total_executable} ? (100 * $heap->{total_executable} / $last_heap->{total_executable} - 100) : 0,
	
		$_[0];

	$last_stat = $stat;
	$last_heap = $heap;

	return $str;
}

ok $obj->load_file($tt_file), print_stat('Load file');
ok !$obj->counters->{run_low_memory_notification_time}, 'Check empty gc time';

ok $obj->execute_file($tt_file, \$out), print_stat('Execute file with no append not json');
ok !$out, 'Check empty output';

ok $obj->execute_file($tt_file, \$out), print_stat('Execute file with no append not json again');
ok $obj->counters->{run_low_memory_notification_time} > 0, 'Check not empty gc time';

ok $obj->execute_file($tt_file, \$out, {append => ';fest["top.xml"]( JSON.parse(__dataFetch()) );'}), print_stat('Execute file with append');
ok length decode('utf8', $out) == 31478, 'Check size after empty json';

ok $obj->execute_file($tt_file, \$out, {append => ';fest["top.xml"]( JSON.parse(__dataFetch()) );', json => $json}), print_stat('Execute file with append and json');
ok length decode('utf8', $out) == 551294, 'Check output length';

ok $obj->execute_file($tt_file, \$out, {append => ';fest["top.xml"]( JSON.parse(__dataFetch()) );', json => $json}), print_stat('Execute file with append and json again');
ok length decode('utf8', $out) == 551294, 'Check output length again';

ok $obj->execute_file($tt_file, \$out, {append => ';fest["top.xml"]( JSON.parse(__dataFetch()) )', json => $json}), print_stat('Execute file with run and json again');
ok length decode('utf8', $out) == 551294, 'Check output length again';
ok $obj->counters->{run_idle_notification_loop_time} > 0, 'Check not empty gc time';

#ok $obj->execute_file($tt_file, \$out, {run => 'fest["top.xml"]( JSON.parse(__dataFetch()) )', json => $json}), print_stat('Execute file with run and json again');
#ok length decode('utf8', $out) == 551294, 'Check output length again';

$obj->execute_file($zero_file, \$out, {append => 'aaa'});
ok length $out == 11, 'Check \0 embeded symbol';

my $die_true;
eval {
	local $SIG{__DIE__} = sub {$die_true = $_[0] =~ m{^Error opening file /tmp/nonexistent.js: No such file or directory}};
	$obj->execute_file("/tmp/nonexistent.js", \$out, {append => ';fest["top.xml"]( JSON.parse(__dataFetch()) )', json => $json});
};
ok $die_true, "Catch die message";

my $tmp = File::Temp->new(UNLINK => 1);
print $tmp "throw new Error('division by zero')";
$tmp->autoflush(1);

undef $die_true;
eval {
	local $SIG{__DIE__} = sub {$die_true = $_[0] =~ m{division by zero}};
	$obj->load_file($tmp->filename);
};
ok $die_true, "Catch die message";

printf "\nRESULT:\n%d requests, TOTAL:%.06f sec, EXEC:%.06f sec, COMPILE:%.06f sec, RLMN:%.06f sec, RINL:%.06f sec, H_LIMIT:%d MB, H_TOTAL:%d MB, H_USED:%d MB, H_PHYS:%d MB, H_EXEC:%d MB\n",
	$sum_stat->{request_num},
	$sum_stat->{exec_time} + $sum_stat->{compile_time} + $sum_stat->{run_low_memory_notification_time} + $sum_stat->{run_idle_notification_loop_time},

	$sum_stat->{exec_time},
	$sum_stat->{compile_time},
	$sum_stat->{run_low_memory_notification_time},
	$sum_stat->{run_idle_notification_loop_time},

	$last_heap->{limit} / 1024,
	$last_heap->{total} / 1024,
	$last_heap->{used} / 1024,
	$last_heap->{total_physical} / 1024,
	$last_heap->{total_executable} / 1024;

