#!perl

use strict;
use Test::More tests => 68;

use HTTP::Validate qw(:keywords :validators);

sub test_validator { };

# Test that we can create new HTTP::Validate objects, both permissive and not.

my $TestValidation = new_ok( 'HTTP::Validate' => [], 'new validation' );
my $TestPermissive = new_ok( 'HTTP::Validate' => [ allow_unrecognized => 1 ], 
			     'new validation permissive' );

# Create some rulesets to use during the following tests:

eval {
     define_ruleset 'simple params' => 
	 { param => 'foo' },
	 { param => 'bar' };
     
     $TestValidation->define_ruleset('simple params' =>
	 { param => 'foo' },
	 { param => 'bar' });
     
     $TestPermissive->define_ruleset('simple params' =>
	 { param => 'foo' },
	 { param => 'bar' });
     
     define_ruleset 'multiple params' =>
	 { optional => 'foo', multiple => 1 },
	 { optional => 'bar', multiple => 1 };
     
     define_ruleset 'split params' =>
	 { optional => 'foo', split => ',' },
	 { optional => 'bar', split => qr{ : } };
     
     define_ruleset 'empty params' => 
	 { optional => 'foo', valid => FLAG_VALUE },
	 { optional => 'bar', valid => EMPTY_VALUE },
	 { optional => 'baz', valid => ANY_VALUE };
     
     define_ruleset 'default value' =>
         { optional => 'bar', valid => INT_VALUE, default => 74 }; 
};

ok( !$@, 'test rulesets' ) or diag( "    message was: $@" ) if $@;

# Do some simple validations, and test that the 'unrecognized parameter'
# mechanism works properly.

my %simple_params = ( foo => 1, bar => 2 );
my %missing_param = ( foo => 1 );
my %extra_param = ( foo => 1, bar => 2, baz => 3 );

my ($result1, $result2, $result3, $result4, $result5);

eval {
    $result1 = check_params('simple params', {}, \%simple_params);
    $result2 = check_params('simple params', {}, \%missing_param);
    $result3 = check_params('simple params', {}, \%extra_param);
    $result4 = $TestValidation->check_params('simple params', {}, \%extra_param);
    $result5 = $TestPermissive->check_params('simple params', {}, \%extra_param);
};

ok( !$@, 'simple params validation' );
diag( "    message was: $@" ) if $@;

is( $result1->value('foo'), '1', 'simple params 1' );
is( $result1->value('bar'), '2', 'simple params 2' );
is( $result1->errors, 0, 'simple params 3');
is( $result1->warnings, 0, 'simple params 4');

is( $result2->value('foo'), '1', 'missing param 1' );
is( $result2->value('bar'), undef, 'missing param 2' );
is( $result2->errors, 0, 'missing param 3');
is( $result2->warnings, 0, 'missing param 4');

is( $result3->errors('baz'), 1, 'extra param error 1' );
is( $result3->errors, 1, 'extra param error 1a' );
my ($errmsg) = $result3->errors('baz');
is( $errmsg, "unknown parameter 'baz'", 'extra param error 2' );
is( $result3->warnings, 0, 'extra param error 3');

is( $result4->errors('baz'), 1, 'extra param object error 1' );
is( $result4->errors, 1, 'extra param object error 1a' );
($errmsg) = $result4->errors('baz');
is( $errmsg, "unknown parameter 'baz'", 'extra param object error 2' );
is( $result4->warnings, 0, 'extra param object error 3');

is( $result5->errors('baz'), 0, 'extra param permissive 1' );
is( $result5->errors, 0, 'extra param permissive 1a');
($errmsg) = $result5->errors('baz');
is( $errmsg, undef, 'extra param permissive 2' );
is( $result5->warnings, 1, 'extra param permissive 3');
is( $result5->warnings('baz'), 1, 'extra param permissive 4');
my ($warnmsg) = $result5->warnings('baz');
is( $warnmsg, "unknown parameter 'baz'", 'extra param permissive 5');

# Test that combinations of hashrefs and other parameters work properly, and
# that multiple parameters are handled properly.

eval {
    $result1 = check_params('simple params', {}, [ \%missing_param, 'bar' => 2 ]);
    $result3 = check_params('simple params', {}, [ \%simple_params, bar => 3 ]);
    $result4 = check_params('multiple params', {}, [ \%simple_params, bar => 3 ]);
};

ok( !$@, 'combo params validation' );
diag( "    message was: $@" ) if $@;

is( $result1->value('foo'), '1', 'combo params 1' );
is( $result1->value('bar'), '2', 'combo params 2' );
is( $result1->errors, 0, 'combo params 3');
is( $result1->warnings, 0, 'combo params 4');

is( $result3->value('foo'), '1', 'multiple params 1' );
is( $result3->errors, 1, 'multiple params 3');
($errmsg) = $result3->errors;
cmp_ok( $errmsg, '=~', "^you may only specify one value for '?bar'?", 'multiple params 4');
is( $result3->warnings, 0, 'multiple params 5');

is_deeply( $result4->value('foo'), [1], 'multiple good 1' );
is_deeply( $result4->value('bar'), [2, 3], 'multiple good 2' );
is( $result4->errors, 0, 'multiple good 3');
is( $result4->warnings, 0, 'multiple good 4');

# Test that parameter splitting works properly

eval {
    $result1 = check_params('split params', {}, [ foo => 'abc, , def,ghi  ,, jkl', bar => '' ]);
    $result2 = check_params('split params', {}, [ bar => 'abc : def  :  ghi:jkl' ]);
    $result3 = check_params('split params', {}, [ foo => ',, ,' ]);
};

ok( !$@, 'split params validation' );
diag( "    message was: $@" ) if $@;

is_deeply( $result1->value('foo'), ['abc', 'def', 'ghi', 'jkl'], 'split good 1' );
is( $result1->value('bar'), undef, 'split good 2');
is( $result1->errors, 0, 'split good 3') or diag explain $result1->errors;
is( $result1->warnings, 0, 'split good 4') or diag explain $result1->warnings;

is_deeply( $result2->value('bar'), ['abc', 'def ', ' ghi:jkl'], 'split good 1a' ) or diag explain $result2->value('bar');
is( $result2->errors, 0, 'split good 2a') or diag explain $result2->errors;
is( $result2->warnings, 0, 'split good 3a') or diag explain $result2->warnings;

is( $result3->value('foo'), undef, 'split good 1b');
is( $result3->errors, 0, 'split good 2b') or diag explain $result3->errors;
is( $result3->warnings, 0, 'split good 3b') or diag explain $result3->warnings;

# Test that empty params work properly

my %undef_params = ( foo => undef, bar => undef, baz => undef );
my %empty_params = ( foo => '', bar => '', baz => '' );
my %no_flag_params = ( bar => 'abc', baz => 'abc' );

eval {
    $result1 = check_params('empty params', {}, \%undef_params);
    $result2 = check_params('empty params', {}, \%empty_params);
    $result3 = check_params('empty params', {}, \%no_flag_params);
};

ok( !$@, 'empty params validation' );
diag("    message was: $@" ) if $@;

is( $result1->value('foo'), 1, 'flag good 1' );
is( $result1->value('bar'), undef, 'empty good 1' );
is( $result1->value('baz'), undef, 'any good 1' );

is( $result2->value('foo'), 1, 'flag good 2' );
is( $result2->value('bar'), undef, 'empty good 2' );
is( $result2->value('baz'), undef, 'any good 2' );

is( $result3->value('foo'), undef, 'flag good 3' );
is( $result3->value('bar'), undef, 'empty good 3' );
is( $result3->value('baz'), 'abc', 'any good 3' );

is( $result3->errors, 1, 'empty param error');

# Test that 'validation_settings' works properly

eval {
    validation_settings(allow_unrecognized => 1);
    $result1 = check_params('simple params', {}, \%extra_param);
};

ok( !$@, 'call to validation_settings' ) or diag( "    message was: $@" );

is( $result1->errors, 0, 'extra param separate 1');
is( $result1->warnings, 1, 'extra param separate 2');
is( $result1->warnings('baz'), 1, 'extra param separate 3');
($warnmsg) = $result1->warnings('baz');
is( $warnmsg, "unknown parameter 'baz'", 'extra param separate 4');

# Test that 'default' works properly

eval {
    $result1 = check_params('default value', {}, \%missing_param);
};

ok( !$@, 'default value check' );
diag( "    message was: $@" ) if $@;

is( $result1->value('bar'), 74, 'default value 1' );

eval {
     define_ruleset 'default value 2' =>
         { optional => 'bar', valid => [POS_VALUE, EMPTY_VALUE], default => -4 }; 
};

cmp_ok( $@, '=~', "^the default value '-4' failed all of the validators", 'bad default value' );
