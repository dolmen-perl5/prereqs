use strict;
use warnings;
package prereqs;

use CPAN::Meta::Prereqs '2.132830';
use CPAN::Meta::Requirements 2.121;

sub import {
    return unless @_ > 1;
    goto &load
}

sub load
{
    my $prereqs = pop;
    # Allow a bare hashref
    unless ($prereqs->can('requirements_for')) {
	require CPAN::Meta::Prereqs;
	$prereqs = CPAN::Meta::Prereqs->new($prereqs)
    }

    my (undef, %options) = @_;

    my $reqs = $prereqs->requirements_for('runtime', 'requires');

    unless ($reqs->accepts_module(perl => $])) {
	require Carp;
	Carp::croak(sprintf "Your Perl (%s) is not in the range '%s'", $], $reqs->requirements_for_module('perl'))
    }

    # This code is inspired by CPAN::Meta::Check::_check_dep
    foreach my $module ($reqs->required_modules) {
	next if $module eq 'perl'; # Handled above
	(my $path = "$module.pm") =~ s{::}{/}g;
	unless (eval { require $path }) {
	    my $err = $@;
	    require Carp;
	    Carp::croak("$err\nMissing prereq: $module ".$reqs->requirements_for_module($module));
	}
	my $version = eval { $module->VERSION };
	unless ($reqs->accepts_module($module, $version || 0)) {
	    require Carp;
	    Carp::croak(sprintf
		q{Installed version (%s) of %s is not in range '%s'},
		defined $version ? $version : 'undef',
		$module,
		$reqs->requirements_for_module($module),
	    )
	}
    }
}

1;

=encoding UTF-8

=head1 NAME

prereqs - Preload modules specified in a CPAN::Meta::Prereqs object

=head1 SYNOPSIS

Preload modules (C<require>) and enforce version checks:

    use prereqs +{
	runtime => {
	    requires => {
		'Some::Module' => '>1.234, <1.400',
		...
	    }
	}
    };


Preload C<runtime>/C<requires> modules from a F<cpanfile>:

    use Module::CPANfile ();
    use prereqs Module::CPANfile->load->prereqs;

I<Note>: this example loads a F<cpanfile> from the current directory. That
can be a security issue if that file is writable by an attacker.

Use the C<load> method instead of C<import>:

    use prereqs;

    prereqs->load(...);

=head1 DESCRIPTION

Load runtime prereqs (see L<perlfunc/require>) defined in a
L<CPAN::Meta::Prereqs> object. Version requirements are checked and an
exception is raised if one doesn't match.

The C<import> method of each module is not called.

=head1 AUTHOR

Olivier Mengué L<mailto:dolmen@cpan.org>

