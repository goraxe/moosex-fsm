use Test::More qw(no_plan);


# TODO use Test::Inline to extract the code straight from the module
use FindBin qw($Bin);
use File::Spec::Functions;
use lib catdir ($Bin, "lib");

use_ok ('Example::FSM01');

my $fsm = Example::FSM01->new();
isa_ok ($fsm, 'Example::FSM01', 'created example object');

my $test_dir = catdir($Bin, "test_dir1");

$fsm->run($test_dir);


#$fsm->start($ENV{'HOME'});
