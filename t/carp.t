#!perl
use strict;
use warnings;

use Test::More;
plan tests => 3;

use lib 't/lib';

{
  package Class;
  use TestMexp
    foo => { -as => 'bar' },
    foo => { -as => 'baz' };

  use TestDexp
    foo => { -as => 'quux' };

  sub new { bless {} }
}

{
  my $mess = eval { Class->new->bar };
  like($mess, qr{Class::bar}, "bar method appears under its own name");
}

{
  my $mess = eval { Class->new->baz };
  like($mess, qr{Class::baz}, "baz method appears under its own name");
}

{
  my $mess = eval { Class->new->quux };
  unlike($mess, qr{Class::quuz}, "quuz method doesn't have its own name");
}

1;
