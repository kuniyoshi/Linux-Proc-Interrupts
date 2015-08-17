use strict;
use warnings;
package Linux::Proc::Interrupts;

sub parse_per_hardware_line {
    my $line      = shift;
    my $cpu_count = shift;
    my @columns = split m{:?\s+}, $line, 3 + $cpu_count;
    my $id = shift @columns;
    my $devices_column = pop @columns;
    my $type = pop @columns;
    my @counts = @columns;
    my @devices = split m{,\s+}, $devices_column;
    return ( $id, \@counts, $type, \@devices );
}

sub parse_global {
    my $line      = shift;
    my $cpu_count = shift;
    my @columns = split m{:?\s+}, $line, 2 + $cpu_count;
    my $id = shift @columns;
    my $description = pop @columns;
    my @counts = @columns;
    return ( $id, \@counts, $description );
}

sub parse_lines {
    my @lines = @_;
    my %interrupt;

    @lines = map { s{\A \s+ }{}msx; s{ \s+ \z}{}msx; $_ } @lines;
    my $cpu_line = shift @lines;
    my @cpus = split m{\s+}, $cpu_line;

    for my $line ( @lines ) {
        if ( $line =~ m{\A \d+ : }msx ) {
            my( $num, $counts_ref, $type, $devices_ref ) = parse_per_hardware_line( $line, scalar @cpus );
            $interrupt{ $type }{num} = $num;
            @{ $interrupt{ $type } }{ @cpus } = @{ $counts_ref };
            $interrupt{ $type }{devices} = $devices_ref;
        }
        elsif ( $line =~ m{\A (?:ERR|MIS): }msx ) {
            my( $id, $count ) = split m{:\s+}, $line;
            $interrupt{ $id } = $count;
        }
        else {
            my( $id, $counts_ref, $description ) = parse_global( $line, scalar @cpus );
            $interrupt{ $id }{description} = $description;
            @{ $interrupt{ $id } }{ @cpus } = @{ $counts_ref };
        }
    }

    return %interrupt;
}

1;
