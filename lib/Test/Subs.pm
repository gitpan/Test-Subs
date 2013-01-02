package Test::Subs;
our $VERSION = '0.01';
use strict;
use warnings;
use Exporter 'import';
use Filter::Simple;
use Carp;

our @EXPORT = ('test', 'todo', 'not_ok', 'match', 'fail', 'failwith', 'comment');

my (@tests, @todo, @comments);
my ($has_run, $is_running);

sub check_text {
	my ($t) = @_;

	if (defined $t) {
		$t =~ m/^([^\n]*)/;
		return " - $1";
	} else {
		return '';
	}
}

sub check_run {
	my @c = caller(0);

	if ($is_running) {
		croak "You cannot call '$c[3]' inside of an other test"
	}
}

sub test (&;$) {
	check_run();

	push @tests, {
			code => $_[0],
			text => check_text($_[1])
		};
}

sub match (&$;$) {
	my ($v, $re, $t) = @_;

	check_run();

	$re = qr/$re/ if not ref $re;
	push @tests, {
			code => sub { $v->() =~ m/$re/ }, 
			text => check_text($t)
		};
}

sub todo (&;$) {
	check_run();

	push @tests, {
			code => $_[0],
			text => check_text($_[1])
		};
	push @todo, scalar(@tests)
}

sub not_ok (&;$) {
	my $v = $_[0];

	check_run();

	push @tests, {
			code => sub { not $v->() },
			text => check_text($_[1])
		};
}

sub fail (&;$) {
	my $v = $_[0];

	check_run();

	push @tests, {
			code => sub { eval { $v->() }; $@ }, 
			text => check_text($_[1])
		};
}

sub failwith (&$;$) {
	my ($v, $re, $t) = @_;

	check_run();

	$re = qr/$re/ if not ref $re;
	push @tests, {
			code => sub { eval { $v->() }; $@ =~ m/$re/ }, 
			text => check_text($t)
		};
}

sub comment (&) {
	my ($c) = @_;
	if ($is_running) { # undocumented feature
		my $r = eval { $c->() };
		chomp($r);
		print STDERR $r."\n";
	} else {
		push @comments, {
				comment => $c,
				after => scalar(@tests)
			};
	}
}

sub print_comment {
	my ($test) = @_;

	while (@comments and $comments[0]->{after} == $test) {
		my $c = shift @comments;
		my $r = eval { $c->{comment}->() };
		chomp($r);
		print STDERR $r."\n";
	}
}

sub run_test {
	$is_running = 1;

	my $nb_test = @tests;
	my $todo_str =  @todo ? ' todo '.join(' ', @todo).';' : '';
	
	printf STDOUT "1..%d%s\n", $nb_test, $todo_str;
	
	my $count = 0;
	print_comment($count);
	for my $t (@tests) {
		my $r = eval { $t->{code}->() };
		chomp(my $cr = $r);
		my $m = sprintf $t->{text}, $cr;
		printf STDOUT "%sok %d%s\n",  ($r ? '' : 'not '), ++$count, $m;
		print_comment($count);
	}

	$has_run = 1;
}

BEGIN {
	select(STDERR);
}

END {
	if (not $has_run) {
		printf STDOUT "1..1\nnot ok 1 - compilation of file '$0' failed.\n";
	}
}

FILTER {
	$_ .= ';Test::Subs::run_test()'
};

1;

=encoding utf-8

=head1 NAME

Test::Subs - Test your modules with a lightweight anonymous block based syntax

=head1 SYNOPSIS

  use SomeModule;
  use Test::Subs;
  
  test { 1 == 2 };

=head1 DESCRIPTION

This module provide a very lightweight syntax to run C<Test::Harness> or
C<Tap::Harness> compliant test on your code.

As opposed to other similar packages, the two main functionnalities of C<Test::Subs>
are that the tests are anonymous code block (rather than list of values), which
are (subjectively) cleaner and easier to read, and that you do not need to
pre-declare the number of tests that are going to be run (so all modifications in
a test file are local).

Using this module is just a matter of C<use Test::Subs> followed by the
declaration of your tests with the functions described below. All tests are then
run at the end of the execution of your test file.

As a protection against some error, if the compilation phase fail, the output of
the test file will be one failed pseudo-test.

=head1 FUNCTIONS

This is a list of the public function of this library. Functions not listed here
are for internal use only by this module and should not be used in any external
code unless .

All the functions described below are automatically exported into your package
except if you explicitely request to opposite with C<use Test::Subs ();>.

Finally, these function must all be called from the top-level and not inside of
the code of another test function. That is because the library must know the
number of test before their execution.

=head2 test

  test { CODE };
  test { CODE } DESCR;

This function register a code-block containing a test. During the execution of
the test, the code will be run and the test will be deemed successful if the
returned value is C<true>.

The optionnal C<DESCR> is a string (or an expression returning a string) which
will be added as a comment to the result of this test. If this string contains
a C<printf> I<conversion> (e.g. C<%s> or C<%d>) it will be replaced by the result
of the code block.

=head2 todo

  todo { CODE };
  todo { CODE } DESCR;

This function is the same as the function C<test>, except that the test will be
registered as I<to-do>. So a failure of this test will be ignored when your test
is run inside a test plan by C<Test::Harness> or C<Tap::Harness>.

=head2 match

  match { CODE } REGEXP;
  match { CODE } REGEXP, DESCR;

This function declares a test which will succeed if the result of the code block
match the given regular expression.

The regexp may be given as a scalar string or as a C<qr> encoded regexp.

=head2 not_ok

  not_ok { CODE };
  not_ok { CODE } DESCR;

This function is exactly the opposite of the C<test> one. The test that it declares
will succeed if the code block return a C<false> value.

=head2 fail

  fail { CODE };
  fail { CODE } DESCR;

This function declares a test that will succeed if its code block C<die> (raise
any exception).

=head2 failwith

  failwith { CODE } REGEXP;
  failwith { CODE } REGEXP, DESCR;

As for the C<fail> function, this function declares a test which expects that its
code block C<die>. Except that the test will succeed only if the raised exception
(the content of the C<$@> variable) match the given regular expression.

The regexp may be given as a scalar string or as a C<qr> encoded regexp.

=head2 comment

  comment { CODE };

This function evaluate its code and display the resulting value on the standard
error handle. The buffering on C<STDOUT> and C<STDERR> is deactivated when
C<Test::Subs> is used and the output of this function should appear in between
the result of the test when the test file is run stand-alone.

This function must be used outside of the code the other functions described
above. The output comment to C<STDERR> inside a test, just use the C<print> or
C<printf> function. The default output has been C<select>-ed to C<STDERR> so
the result of the test will not be altered.

=head1 EXAMPLE

Here is an example of a small test file using this module.

  use strict;
  use warnings;
  use Test::Subs;
  
  test { 1 == 1 } 'This is the first test';
  
  todo { 1 == 2 };
  
  not_ok { 0 };
  
  fail { die "fail" };

Run through C<Test::Harness> this file will pass, with only the second test failing
(but marked I<todo> so that's OK).

=head1 CAVEATS

The standard set by C<Test::Harness> is that all output to C<STDOUT> is
interpreted by the test parser. So a test file should write additional output
only to C<STDERR>. This is what will be done by the C<comment> fonction. To help
with this, during the execution of your test file, the C<STDERR> file-handle will
be C<select>-ed. So any un-qualified C<print> or C<printf> call will end in
C<STDERR>.

This package use source filtering (with L<C<Filter::Simple>|Filter::Simple>).
The filter applied is very simple, but there is a slight possibility that it is
incompatible with other source filter. If so, do not hesitate to report this as
a bug.

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-subs@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Subs>.

=head1 SEE ALSO

L<Test>, L<Test::Tiny>, L<Test::Lite>, L<Test::Simple>

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 VERSION

Version 0.01 (December 2012)


=head1 COPYRIGHT & LICENSE

Copyright 2012 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


