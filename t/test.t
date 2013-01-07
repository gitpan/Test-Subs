use strict;
use warnings;
use Test::Subs;
use t::data::Test::Subs::A;

our $t = 1;
END { $t = 2 }

test { 1 == 1 } 'first test';
test { 42 } 'tested and got %s';

test { $t::data::Test::Subs::A::v == 1 };
test { $t == 1 };

todo { print "some comment\n"; 1 == 2 } 'not yet implemented...';

comment { 'some other comment' };

not_ok { 0 };

match { 'test' } '.{4}';

debug { 0 };

fail { die "fail" } 'throwing "%s"';

failwith { test {1} } 'cannot call';

__DATA__

nothing here...
