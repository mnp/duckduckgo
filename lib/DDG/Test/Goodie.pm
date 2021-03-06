package DDG::Test::Goodie;
# ABSTRACT: Adds keywords to easily test Goodie plugins.

use strict;
use warnings;
use Carp;
use Test::More;
use DDG::Test::Block;
use DDG::ZeroClickInfo;
use Package::Stash;

binmode STDOUT, ':utf8';
binmode Test::More->builder->output, ':utf8';
binmode Test::More->builder->failure_output, ':utf8';

=head1 DESCRIPTION

Installs functions for testing Goodies.

B<Warning>: Be aware that you only use this module inside your test files in B<t/>.

=cut

sub import {
	my ( $class, %params ) = @_;
	my $target = caller;
	my $stash = Package::Stash->new($target);

=keyword test_zci

Easy function to generate a L<DDG::ZeroClickInfo> for the test. See
L</ddg_goodie_test>.

You can predefine parameters via L</zci>.

=cut

	my %zci_params;

	$stash->add_symbol('&test_zci', sub {
		my $answer = shift;
		ref $_[0] eq 'HASH' ?
			DDG::ZeroClickInfo->new(%zci_params, %{$_[0]}, answer => $answer ) :
			DDG::ZeroClickInfo->new(%zci_params, @_, answer => $answer )
	});

=keyword zci

You can predefine L<DDG::ZeroClickInfo> parameters for usage in L</test_zci>.

This function can be used several times to change specific defaults on the
fly.

=cut

	$stash->add_symbol('&zci', sub {
		if (ref $_[0] eq 'HASH') {
			for (keys %{$_[0]}) {
				$zci_params{$_} = $_[0]->{$_};
			}
		} else {
			while (@_) {
				my $key = shift;
				my $value = shift;
				$zci_params{$key} = $value;
			}
		}
	});

=keyword ddg_goodie_test

With this function you can easily generate a small own L<DDG::Block> for
testing your L<DDG::Goodie> alone or in combination with others.

  ddg_goodie_test(
	[qw( DDG::Goodie::MyGoodie )],
	'mygooodie data' => test_zci('data', html => '<div>data</div>'),
	'mygooodie data2' => test_zci('data2', html => '<div>data2</div>'),
  );

=cut

	$stash->add_symbol('&ddg_goodie_test', sub { block_test(sub {
			my ($query, $answer, $zci) = @_;
		subtest "Query: $query" => sub {
			if ($answer) {
				# Check regex tests
				for (grep { defined $zci->$_ } qw/answer html heading/) {
					if (ref $zci->$_ eq 'Regexp') {
						like($answer->$_, $zci->$_, 'Regexp: ' . $_ );
						$zci->{$_} = $answer->$_;
					} elsif ($zci->$_ eq '-ANY-') {
						pass('-ALL- pass: ' . $_);
						$zci->{$_} = $answer->$_;
					}
				}
				if ($zci->has_structured_answer) {
					my $e_sa = $zci->structured_answer;
					my $g_sa = $answer->structured_answer;
					foreach my $key (grep { defined $e_sa->{$_} } sort keys %$e_sa) {
						if (ref $e_sa->{$key} eq 'Regexp') {
							like($g_sa->{$key}, $e_sa->{$key}, 'Regexp: structured_answer{' . $key . '}');
							$g_sa->{$key} = $e_sa->{$key};
						} elsif ($e_sa->{$key} eq '-ANY-') {
							pass('-ALL- pass: structured_answer{' . $key . '}');
							$g_sa->{$key} = $e_sa->{$key};
						}
					}
				}
				$zci->{caller} = $answer->caller;    # TODO: Review all this cheating; seriously.
				is_deeply($answer,$zci,'Deep: full ZCI object');
			} else {
				fail('Expected result but dont get one on '.$query) unless defined $answer;
			}
		};
		},@_)
	});

}

1;
