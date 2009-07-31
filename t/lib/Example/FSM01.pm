package Example::FSM01;
use MooseX::FSM;

has 'processing_dir' (
	is			=> 'ro',
	traits		=> 'State',
	isa			=> 'MooseX::FSM::State',
	enter		=> 'init',
	exit		=> 'end',
	input		=> [ add_file => \&process_file, add_dir => 'process_dir' ]
);

has 'procesing_file' (
	is			=> 'ro',
	traits		=> 'State',
	isa			=> 'MooseX::FSM::State',
	enter		=> 'display_file',
	input		=> [ add_size => 'inc_size' ],
);

has 'start' (
	is			=> 'ro',
	isa			=> 'MooseX::FSM::State',
	metaclass	=> 'state',
	enter		=> 'init',
	input		=> [ scan_dirs , add_dir => 'process_dir' ],
	transition	=> [ add_dir => processing_dir, after => { scan_dirs => 'end' } ],
);

has 'end' (
	is			=> 'ro'
	traits		=> 'State',
	enter		=> 'disaply_total_size',
	exit		=> 'reset',
);

sub scan_dirs {
	my $self = shift;
	my @scan_dirs = @_;
	foreach my $dir (@scan_dirs) {
		$self->add_dir($dir);
	}
}

sub process_dir {
	my ($self, $dir) = @_;
	opendir DIR, $dir;
	while (my $file = readdir DIR) {
		if ( -f $file ) {
			$self->add_file($file);
		}
		elsif ( -d $file ) {
			$self->add_dir($file);
		}
	}
}

sub process_file {
	my ($self, $file) = @_;
	# element 7 is the size from stat
	my $size = (stat($file))[7];
	print "size $size";
	$self->add_size($size);
}


1;
