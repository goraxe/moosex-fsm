package MooseX::FSM;

use Moose ();
use Carp qw(carp croak cluck confess);
use MooseX::FSM::State;

use Moose::Exporter


=head1 NAME

MooseX::FSM is a moosish Finite State Machine

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS


=head1 DESCRIPTION

MooseX::FSM is an implementation of a Finite State Machine using Moose.  The core idea is that you define a bunch of states the FSM can have.
Each state defines the methods and attributes that are available when the FSM is in that state.  Transition criteria between states is defined.  When that criteria is met the FSM transitions to that state.  A state can have an enter and exit function that is called when the state is entered or left.  This module currently has an evolving api as I learn about Moose discover other cool modules the api is subject to change.  

There is a slightly convoluted example of scanning a set of directories and calculating the total size of files contained

=begin example

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

	package main;

	my $fsm = Example::FSM01->new();
	$fsm->run($ENV{'HOME'});

=end example


	New syntax sugar coming soon
	state 'start' (
		enter => 
	)


=head1 FUNCTIONS

=head2 init_meta
the init_meta function is used internaly by Moose to setup the base class which MooseX::FSM provides
=cut

=head1 ATTRIBUTES

=head2 start_state
is a read only attribute which defines the state the FSM will be in when when its started up.  At the moment the start method must be called on the FSM before it does any work

=head2 current_state
is a read write attribute which returns the state the FSM is in when accessed.  When supplied with a new state this is checked to ensure its a valid state for the FSM.  At the moment no check is made to see if the transition is valid.  The FSM after being written is then in the new state.



=cut
Moose::Exporter->setup_import_methods ( also => 'Moose');

sub init_meta {
	shift;
	my %options = @_;
	my $meta = Moose->init_meta(%options);

	Moose::Util::MetaRole::apply_base_class_roles (
		for_class	=> $options{for_class},
		roles 		=> [ 'MooseX::FSM::Role::Object'],
	);
	return $meta;
}

1;

package MooseX::FSM::Role::Object;

use Moose::Role;
use Carp;

after BUILDALL => sub  {
	my $self = shift;

	# store the original methods inside the object
	foreach my $method ($self->meta->get_all_methods() ) {
		$self->debug ("storing method -> " . $method->name() . "\n");
		$self->base_methods()->{$method->name()} = $method;
	}

	# store the original attributes inside the object
	# but store states so we can look them up seperatly
	foreach my $attr ($self->meta->get_all_attributes() ) {

		if ( $attr->does('MooseX::FSM::State') ) {
			$self->debug("storing state -> " . $attr->name() . "\n");
#			$self->debug(Dumper($attr));
			$self->state_list()->{$attr->name()} = $attr;
		} else {

			$self->debug("storing attribute -> " . $attr->name() . "\n");
			$self->base_attributes()->{$attr->name()} = $attr;
		}
	}

	$self->_remove_methods();
};



has 'current_state' => (
	is		=> 'rw',
	trigger => \&transition_to_state,
);

has 'previous_state' => (
	is		=> 'rw',
	lazy_build => 1, 
#	isa => 'String',
);

sub _build_previous_state {
	return "";
}

before 'current_state' => sub {
	my ($self, $state) = @_;
	# just store the previous state so we call exit on it
	if ($state) {
		$self->debug("setting previous_state $state\n");
		$self->previous_state($state);
	}
};

has 'start_state' => (
	is		=> 'ro',
	required	=> 0,
	default		=> sub { 'start' }, 
);

has 'base_methods' => (
	is			=> 'ro',
	required	=> 0,
	isa			=> 'HashRef',
	default		=> sub { {}; },
);

has 'base_attributes' => (
	is			=> 'ro',
	required	=> 0,
	isa			=> 'HashRef',
	default		=> sub { {}; },
);

has 'state_list' => (
	is			=> 'ro',
	required	=> 0,
	isa			=> 'HashRef',
	default		=> sub { {}; },
);

has _args => (
	is			=> 'rw',
);

=head2 debug
a simple debug method to log any messages apprioriately
=cut
sub debug {
	my ($self, $message) = @_;
#	if ($self->is_debugging) {
		print $message;
#	}
}

sub error {
	my ($self, $message, @rest) = @_;
	carp "error: $message";
}

sub run {
	my $self = shift;
	$self->debug ("going to transition into the start state\n");
#	$self->transition_to_state($self->start_state());
	$self->_args(@_);
	$self->current_state($self->start_state());
}

sub _remove_methods {
	my $self = shift;

	my @keep_funcs = qw( current_state transition_to_state debug meta state_table error ); 
	my $keep_re = join "|", @keep_funcs;
	$keep_re = qr/$keep_re/;
	my $meta = $self->meta();

	foreach my $method ($meta->get_all_methods) {
		next if ($method =~ $keep_re);
		$self->debug("\t -> removing " . $method->package_name() . "::". $method->name() . "\n");
		$meta->remove_method($method->name);
	}

	$self->debug("done remove methods\n");

}


sub _resolve_state_methods {
	my $self = shift;
	my $state_attr = shift;
	my $meta = $self->meta();


	$self->debug("resolving methods for new state" . $state_attr->name() . "\n");
	my $current_state = $self->state_list()->{$self->current_state()};
	my $current_methods = $current_state->methods(); # :->get_value($self);
	my $previous_state;
	my $previous_methods;

	if ($self->has_previous_state() ) {
# just for debug
		$self->debug("previous state looks like " . $self->previous_state() . "\n");
		$previous_state = $self->state_list()->{$self->previous_state()};
		$previous_methods = defined $previous_state ? $previous_state->methods() : {} ;
	}



	my @add_methods;
	my @del_methods;
	# remove previous methods
	foreach my $method ( keys %$previous_methods) {
		$meta->remove_method($method)
	}

	# add new methods
	while ( my ($method, $sub) = each %$current_methods) {
		$meta->add_method($method, $sub);
	}

	my $transitions = $state_attr->transitions();
	# add transitions
	while ( my ($method, $new_state) = each %$transitions ) {
		$meta->add_after_method_modifier($method, sub { my $self = shift; return if ($self->current_state() eq $new_state); $self->current_state($new_state); });
	}
#	foreach my $current_method (keys %$current_method) {
#		if (exists $previous_methods->{$current_method} && $previous_methods->{$current_method} == $current_method->{) {
#			
#	}

#	$self->debug("going to look at input");
#	if ($input && ref ($input) eq 'HASH') {
#		$self->debug(" yo input has info");
#		while ( my ($key, $sub) = each %$input) {
#			$self->debug("adding method : " . $key . ": ". $sub .   "\n");
#			$meta->add_method($key,$sub); 
#			if (my $new_state =  $transitions->{$key}) { 
#				$self->debug("\tsetting transition for input $key to $new_state\n");
#				# TODO cache transtion sub routines
#				$meta->add_after_method_modifier($key, sub { my $self = shift; return if ($self->current_state() eq $new_state); $self->current_state($new_state); });
#			}
#		}

#	}
	return $meta;
}


sub transition_to_state {
	my ($self, $state, @rest)  = @_;
	$self->debug( "transition to state $state\n");
	my $meta = $self->meta;


	if (my $state_attr = $self->state_list->{$state}) {
		# call exit on current_state

		# long winded need to reduce
		my $exit = $self->state_list->{$self->previous_state}->exit();
		&$exit($self, $self->_args());

		$meta = $self->_resolve_state_methods($state_attr);
		
		# call enter on new state
		my $enter = $state_attr->enter();
		&$enter($self, $self->_args());

	}
	else {
		$self->error("could not transition to '$state' as it doesn't exist");
	}
		#my $start_state = $meta->get_attribute($start_state_attribute);
	return $meta; #$self->meta($meta);
}


sub debug_print_attrs {
	my $self = shift;
	my $meta = $self->meta();

	foreach my $attr ($meta->get_all_attributes() ) {
		$self->debug("\t -> attribute -> " . $attr->name() . "\n");
	}
}

sub debug_print_methods {
	my $self = shift;
	my $obj = shift;
	my $meta;
	if ($obj ) {
		$meta = $obj->meta();
	} else {
		$meta =  $self->meta();
	}

	foreach my $method ($meta->get_all_methods() ) {
		$self->debug ("\t -> method -> " . $method->name() . "\n");
	}
}
1;
=head1 AUTHOR

Gordon Irving, C<< <goraxe at goraxe dot me dotty uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-fsm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=moosex-fsm>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::FSM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=moosex-fsm>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/moosex-fsm>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/moosex-fsm>

=item * Search CPAN

L<http://search.cpan.org/dist/moosex-fsm>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Gordon Irving, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
no Moose;
1; # End of MooseX::FSM
