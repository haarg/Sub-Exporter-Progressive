use strict;
use warnings;

use Test::More 0.96;
use List::Util 'first';
use Carp;
use lib 't/lib';
use A::Junk ':other';

BEGIN {
   unshift @INC, sub { croak 'Shouldn\'t load Sub::Exporter' if $_[1] eq 'Sub/Exporter.pm' };
}

ok(!main->can('junk1'), 'junk1 not exported');
ok(!main->can('junk2'), 'junk2 not exported');
ok(main->can('junk3'), 'junk3 exported');
ok(! $INC{'Sub/Exporter.pm'}, 'Sub::Exporter not loaded');

BEGIN {
   package Local::Exporter;
   use Sub::Exporter::Progressive -setup => {
      exports => [qw/ foo bar baz /],
      groups  => {
         default => [qw/ foo /],
         bb      => [qw/ bar baz /],
      },
   };
   use constant {
      foo => 1,
      bar => 2,
      baz => 3,
   };
   $INC{'Local/Exporter.pm'} = __FILE__;
};

my $i = 0;
sub check_tag
{
   my ($tag, $should, $shouldnt) = @_;
   my $pkg = 'Local::Importer' . ++$i;
   subtest "test the '$tag' tag" => sub
   {
      plan tests => 1 + @$should + @$shouldnt;
      local $@ = undef;
      
      ok(eval qq{
         package $pkg;
         use Local::Exporter qw( $tag );
         1;
      }, "$pkg compiled") or diag $@;
      
      ok( $pkg->can($_), "$pkg\->can(\"$_\")") for @$should;
      ok(!$pkg->can($_), "$pkg\->can't(\"$_\")") for @$shouldnt;
   }
}

check_tag(':default', [qw/foo/], [qw/bar baz/]);
check_tag('-default', [qw/foo/], [qw/bar baz/]);
check_tag(':default bar', [qw/foo bar/], [qw/baz/]);
check_tag('-default bar', [qw/foo bar/], [qw/baz/]);
check_tag('bar :default', [qw/foo bar/], [qw/baz/]);
check_tag('bar -default', [qw/foo bar/], [qw/baz/]);
check_tag(':bb', [qw/bar baz/], [qw/foo/]);
check_tag('-bb', [qw/bar baz/], [qw/foo/]);
check_tag(':all', [qw/foo bar baz/], []);
check_tag('-all', [qw/foo bar baz/], []);

done_testing;

