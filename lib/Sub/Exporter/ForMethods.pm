use strict;
use warnings;
package Sub::Exporter::ForMethods;

use Sub::Name ();

use Sub::Exporter -setup => {
  exports => [ qw(method_installer) ],
};

sub method_installer { 
  sub { 
    my ($arg, $to_export) = @_; 

    my $into = $arg->{into};

    for (my $i = 0; $i < @$to_export; $i += 2) {
      my ($as, $code) = @$to_export[ $i, $i+1 ];
      
      next if ref $as;

      $to_export->[ $i + 1 ] = Sub::Name::subname(
        join(q{::}, $into, $as),
        sub { $code->(@_) },
      );
    }
 
    Sub::Exporter::default_installer($arg, $to_export); 
  }; 
} 

1;
