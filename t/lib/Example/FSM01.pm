package Example::FSM01;
use MooseX::FSM;
use Path::Class;

has 'processing_dir' =>  (
	is			=> 'ro',
	traits		=> [ 'State' ],
	methods		=> { 'add_file' => \&process_file, add_dir => \&process_dir },
	transitions => { '+add_file' => 'procesing_file' }
);

has 'procesing_file' => (
	is			=> 'ro',
	traits		=> [ 'State' ],
	enter		=> \&display_file,
	inputs		=> [ 'size' ],
	methods		=> { add_size => sub { warn "add_size called"; my $self = shift; my $size = shift; $self->size($self->size()+ $size); } },
#	transitions => { add_size => 'processing_dir' },
);

has 'start' => (
	is			=> 'ro',
	traits		=> [ 'State' ],
	enter		=> \&init,
	methods		=> { scan_dirs => \&scan_dirs, add_dir => \&process_dir },
	inputs		=> [ 'size' ],
#	exit 		=> \&disaply_total_size,
	transitions	=> { '+add_dir' => 'processing_dir',  scan_dirs => 'end'  },
);

has 'end' => (
	is			=> 'ro',
	traits		=> [ 'State' ],
	inputs		=> [ 'size' ], 
	enter		=> \&disaply_total_size,
	# called to reset the state at the end
	exit		=> \&init,
);

has 'size' => (
	is		=> 'rw',
	isa		=> 'Int',
	default	=> sub { 0; },
);


sub init {
	my $self = shift;
	$self->debug(1, "starting up\n");
	$self->size(0);
	$self->debug(1, "scanning dirs\n");
	$self->scan_dirs(@_);
}

sub scan_dirs {
	my $self = shift;
	my @scan_dirs = @_;
	foreach my $dir (@scan_dirs) {
		$self->add_dir($dir);
	}
}

sub process_dir {
	my ($self, $dir) = @_;
	opendir DIR, $dir or die "could not open $dir";
	while (my $file = readdir DIR) {
		next if ( $file =~ /^\.|\.\.$/);
		$file = file ($dir, $file); 
		if ( -f $file ) {
			warn "calling add_file";
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

sub display_file {
	my ($self, $file) =@_;
	print "gonna do some file displaying here\n";
	print "\t$file\n";
}

sub disaply_total_size {
	my $self = shift;
	print "size is " . $self->size() . "\n";
	return $self->size();

}

1;
