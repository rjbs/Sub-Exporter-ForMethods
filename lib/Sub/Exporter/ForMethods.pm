use strict;
use warnings;
package Sub::Exporter::ForMethods;
# ABSTRACT: helper routines for using Sub::Exporter to build methods

use Scalar::Util 'blessed';
use Sub::Name ();

use Sub::Exporter 0.978 -setup => {
  exports => [ qw(method_installer) ],
};

=head1 SYNOPSIS

In an exporting library:

  package Method::Builder;

  use Sub::Exporter::ForMethods qw(method_installer);

  use Sub::Exporter -setup => {
    exports   => [ method => \'_method_generator' ],
    installer => method_installer,
  };

  sub _method_generator {
    my ($self, $name, $arg, $col) = @_;
    return sub { ... };
  };

In an importing library:

  package Vehicle::Autobot;
  use Method::Builder method => { -as => 'transform' };

=head1 DESCRIPTION

The synopsis section, above, looks almost indistinguishable from any other
use of L<Sub::Exporter|Sub::Exporter>, apart from the use of
C<method_installer>.  It is nearly indistinguishable in behavior, too.  The
only change is that subroutines exported from Method::Builder into named slots
in Vehicle::Autobot will be wrapped in a subroutine called
C<Vehicle::Autobot::transform>.  This will insert a named frame into stack
traces to aid in debugging.

More importantly (for the author, anyway), they will not be removed by
L<namespace::autoclean|namespace::autoclean>.  This makes the following code
work:

  package MyLibrary;

  use Math::Trig qw(tan);         # uses Exporter.pm
  use String::Truncate qw(trunc); # uses Sub::Exporter's defaults

  use Sub::Exporter::ForMethods qw(method_installer);
  use Mixin::Linewise { installer => method_installer }, qw(read_file);

  use namespace::autoclean;

  ...

  1;

After MyLibrary is compiled, C<namespace::autoclean> will remove C<tan> and
C<trunc> as foreign contaminants, but will leave C<read_file> in place.  It
will also remove C<method_installer>, an added win.

=head1 EXPORTS

Sub::Exporter::ForMethods offers only one routine for export, and it may also
be called by its full package name:

=head2 method_installer

  my $installer = method_installer(\%arg);

This routine returns an installer suitable for use as the C<installer> argument
to Sub::Exporter.  It updates the C<\@to_export> argument to wrap all code that
will be installed by name in a named subroutine, then passes control to the
default Sub::Exporter installer.

The only argument to C<method_installer> is an optional hashref which may
contain a single entry for C<rebless>.  If the value for C<rebless> is true,
when a blessed subroutine is wrapped, the wrapper will be blessed into the same
package.

=cut

sub method_installer {
  my ($mxi_arg) = @_;
  my $rebless = $mxi_arg->{rebless};

  sub {
    my ($arg, $to_export) = @_;

    my $into = $arg->{into};

    for (my $i = 0; $i < @$to_export; $i += 2) {
      my ($as, $code) = @$to_export[ $i, $i+1 ];

      next if ref $as;
      my $sub = sub { $code->(@_) };
      if ($rebless and defined (my $code_pkg = blessed $code)) {
        bless $sub, $code_pkg;
      }

      $to_export->[ $i + 1 ] = Sub::Name::subname(
        join(q{::}, $into, $as),
        $sub,
      );
    }

    Sub::Exporter::default_installer($arg, $to_export);
  };
}

1;
