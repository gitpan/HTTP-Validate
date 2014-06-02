#!perl

use strict;
use Test::More tests => 28;

use HTTP::Validate qw(:keywords :validators);

# Create some rulesets to use during the following tests:

eval {
     define_ruleset 'integer' =>
	 { param => 'int1', valid => INT_VALUE },
	 { param => 'int2', valid => INT_VALUE },
	 { param => 'int3', valid => INT_VALUE },
	 { param => 'int4', valid => INT_VALUE },
	 { param => 'int5', valid => INT_VALUE },
	 { param => 'int6', valid => INT_VALUE };
     
     define_ruleset 'decimal' =>
	 { param => 'dec1', valid => DECI_VALUE },
	 { param => 'dec2', valid => DECI_VALUE },
	 { param => 'dec3', valid => DECI_VALUE },
	 { param => 'dec4', valid => DECI_VALUE },
	 { param => 'dec5', valid => DECI_VALUE },
	 { param => 'dec6', valid => DECI_VALUE },
	 { param => 'dec7', valid => DECI_VALUE };
     
     my $test_int = INT_VALUE(-4, 5);
     
     define_ruleset 'int range' =>
	 { param => 'int01', valid => $test_int },
	 { param => 'int02', valid => $test_int },
	 { param => 'int03', valid => $test_int },
	 { param => 'int04', valid => $test_int },
	 { param => 'int05', valid => $test_int },
	 { param => 'int06', valid => POS_VALUE },
	 { param => 'int07', valid => POS_VALUE },
	 { param => 'int08', valid => POS_VALUE },
	 { param => 'int09', valid => POS_ZERO_VALUE },
	 { param => 'int10', valid => POS_ZERO_VALUE },
	 { param => 'int11', valid => POS_ZERO_VALUE };
     
     my $test_dec = DECI_VALUE(-0.01, 15.4);
     my $test_dec2 = DECI_VALUE(2, 5);
     
     define_ruleset 'dec range' => 
	 { param => 'dec01', valid => $test_dec },
	 { param => 'dec02', valid => $test_dec },
	 { param => 'dec03', valid => $test_dec },
	 { param => 'dec04', valid => $test_dec },
	 { param => 'dec05', valid => $test_dec },
	 { param => 'dec06', valid => $test_dec2 },
	 { param => 'dec07', valid => $test_dec2 },
	 { param => 'dec08', valid => $test_dec2 };
     
     my $test_match1 = MATCH_VALUE('ab*');
     my $test_match2 = MATCH_VALUE(qr{ab*});
     
     define_ruleset 'match test' =>
	 { param => 'match1', valid => $test_match1 },
	 { param => 'match2', valid => $test_match2 },
	 { param => 'match3', valid => $test_match1 },
	 { param => 'match4', valid => $test_match2 },
	 { param => 'match5', valid => $test_match1 },
	 { param => 'match6', valid => $test_match2 };
     
     my $test_enum = ENUM_VALUE('abc', 'def', 'ghi');
     
     define_ruleset 'enum test' =>
	 { param => 'enum1', valid => $test_enum },
	 { param => 'enum2', valid => $test_enum },
	 { param => 'enum3', valid => $test_enum };
};

ok( !$@, 'test rulesets' ) or diag( "    message was: $@");

# Now test numeric parameter values

my ($result1, $result2, $result3, $result4, $result5, $result6);

eval {
    $result1 = check_params('integer', {}, [int1 => 23, int2 => -23, int3 => 23.5, 
			       int4 => 'abc', int5 => '', int6 => '0']);
    $result2 = check_params('decimal', {}, [dec1 => 23, dec2 => -23, dec3 => 23.5,
			       dec4 => 'abc', dec5 => '', dec6 => '0', dec7 => '0.23e3']);
    $result3 = check_params('int range', {}, [int01 => 0, int02 => 5, int03 => -4, int04 => 6, 
			       int05 => -5, int06 => 0, int07 => 1, int08 => -1,
			       int09 => 0, int10 => 1, int11 => -1]);
    $result4 = check_params('dec range', {}, [dec01 => 0, dec02 => 15.4, dec03 => -0.01,
			       dec04 => 15.400001, dec05 => -0.02, dec06 => '0.3e1',
			       dec07 => '0.1e1', dec08 => 0]);
    $result5 = check_params('match test', {}, [match1 => 'Abb', match2 => 'Abb',
			       match3 => 'abc', match4 => 'abc',
			       match5 => '', match6 => '']);
    $result6 = check_params('enum test', {}, [enum1 => 'abc', enum2 => 'Abc', enum3 => 'foo']);
};

ok( !$@, 'test validations' ) or diag("    message was: $@");

cmp_ok($result1->value('int1'), '==', 23.0, 'int1');
cmp_ok($result1->value('int2'), '==', -23.0, 'int2');
is($result1->value('int3'), undef, 'int3');
is($result1->value('int4'), undef, 'int4');
is($result1->value('int5'), undef, 'int5');
cmp_ok($result1->value('int6'), '==', 0, 'int6');

is_deeply([sort $result1->keys], ['int1', 'int2', 'int6'], 'int params 1');
is_deeply([sort $result1->error_keys], ['int3', 'int4'], 'int params 2');

cmp_ok($result2->value('dec1'), '==', 23, 'dec1');
cmp_ok($result2->value('dec2'), '==', -23, 'dec2');
cmp_ok($result2->value('dec3'), '==', 23.5, 'dec3');
is($result2->value('dec4'), undef, 'dec4');
is($result2->value('dec5'), undef, 'dec5');
cmp_ok($result2->value('dec6'), '==', 0, 'dec6');
cmp_ok($result2->value('dec7'), '==', 2.3e2, 'dec7');

is_deeply([sort $result2->keys], ['dec1', 'dec2', 'dec3', 'dec6', 'dec7'], 'dec params 1');
is_deeply([sort $result2->error_keys], ['dec4'], 'dec params 2');

is_deeply([sort $result3->keys], ['int01', 'int02', 'int03', 'int07', 'int09', 'int10'], 'int range 1');
is_deeply([sort $result3->error_keys], ['int04', 'int05', 'int06', 'int08', 'int11'], 'int range 2');

is_deeply([sort $result4->keys], ['dec01', 'dec02', 'dec03', 'dec06'], 'dec range 1');
is_deeply([sort $result4->error_keys], ['dec04', 'dec05', 'dec07', 'dec08'], 'dec range 2');

is_deeply([sort $result5->keys], ['match1', 'match2'], 'match 1');
is_deeply([sort $result5->error_keys], ['match3', 'match4'], 'match 2');

is_deeply([sort $result6->keys], ['enum1', 'enum2'], 'enum 1');
is_deeply([sort $result6->error_keys], ['enum3'], 'enum 2');
is($result6->value('enum2'), 'abc', 'enum 3');

