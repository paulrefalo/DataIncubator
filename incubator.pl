#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Date::Format;
use Date::Parse;
use Time::Local;
use Try::Tiny;
use lib "$ENV{HOME}/mylib/lib/perl5";
use DateTime;
## to run use: ./incubator.pl 311SRdata.csv                       

my @headers;
my %sr_data;
my %data;
my %master;
my $last_line = 0;
my $final;
my %agency;
my %latitude;

while ( defined( my $line = <> ) )
{
  chomp $line;
  @headers = split ",", $line;
  last;
}
my $notneeded = pop @headers;

$ARGV[0] = '311data.csv';

while ( defined( my $line = <> ) )
{
  next if $. == 1;
  chomp $line;
  my @columns = split ",", $line;
  my $long = pop @columns;
  my $lat = pop @columns;

  my $n = 0;
  foreach my $item (@headers) {
    $master{$columns[0]}{$item} = $columns[$n];
    $n++;
  }
  $last_line++;
  #last if $. > 2;
  $final = $line;
}
my $counter = 0;
my $current_agency;
my $current_lat;
my $duplicate_lat = 0;
my $lat_found = 0;
my ( @lats, @longs );
foreach my $entry (keys %master) {
  $current_agency = $master{$entry}{Agency};  
  if ( $agency{$current_agency} ) {
    $agency{$current_agency}++;
  } else {
    $agency{$current_agency} = 1;
  }
  
  $current_lat = $master{$entry}{Latitude};
  if (!($current_lat)) { next; }
  if (!($current_lat =~ /\d\d.\d+/)) { next; }
  $lat_found++;
  if ( $latitude{$current_lat} ) {
    $latitude{$current_lat}++;
    $duplicate_lat++;
  } else {
    $latitude{$current_lat} = 1;
  }
}

print "Number of duplicate latitudes found are: $duplicate_lat\n";

my $total_complaints = 0;
my $limit = 0;
foreach my $key ( sort { $agency{$b} <=> $agency{$a}} keys %agency )
{
  $total_complaints += $agency{$key};
  last if $limit > 5;
  print "$key: $agency{$key}\n";
  $limit++;
}

my $ratio = $agency{NYPD}/$total_complaints;
print "The second most popular agency, NYPD, has $agency{NYPD} complaints out of $total_complaints total\n";
print "NYPD accounts for $ratio of all complaints.\n";
my @latitudes;
my $lat_counter = 0;
my $total_lat_keys = scalar keys %latitude;
print "The number of unique lat keys is: $total_lat_keys\n";
print "The number of latitudes found is: $lat_found\n";
foreach my $key ( sort keys %latitude )
{
  $latitudes[$lat_counter] = $key;
  $lat_counter++;
}

foreach my $key (keys %master) {
  my $currentLat = $master{$key}{Latitude};
  my $currentLong = $master{$key}{Longitude};
  if (!($currentLat)) { next; }
  if (!($currentLat =~ /\d\d.\d+/)) { next; }
  if (!($currentLong)) { next; }
  if (!($currentLong =~ /\d\d.\d+/)) { next; }
  push(@lats, $currentLat);
  push(@longs, $currentLong);
}

print "The length of lats is: ", scalar(@lats), " and the length of longs is: ", scalar(@longs),"\n";
my $avgLat = average(@lats);
my $avgLong = average(@longs);

my $stdevLat = (std_dev($avgLat, @lats)) * 111.2;
my $stdevLong = (std_dev($avgLong, @longs)) * 111.2;
my $squareKM = $stdevLat * $stdevLong;
print "The square kilometers of a single-stdev is $squareKM\n";

my $lat_length = scalar @latitudes;
print "The number of latitudes is $lat_length\n";

my $lat90 = $lat_length * 0.9;
my $lat10 = $lat_length * 0.1;
my $lat_diff = $latitudes[$lat90] - $latitudes[$lat10];
print "The difference in latitude from the 90th perecentile and the 10th percentile is: $lat_diff\n";
print "The top latitude is: $latitudes[0] and bottom is $latitudes[-1]\n";

my %complaint;
my $aComplaint;
my (%brooklyn, %queens, %staten_island, %bronx, %manhattan);
my $borough;
my $pb = 'Park Borough';
my $ct = 'Complaint Type';
foreach my $key (keys %master) {
  $aComplaint = $master{$key}{$ct};
  if ( $complaint{$aComplaint} ) {
      $complaint{$aComplaint}++;
  } else {
      $complaint{$aComplaint} = 1;
  }
  if ( $master{$key}{$pb} eq 'BROOKLYN' ) {
    if ( $brooklyn{$aComplaint} ) {
      $brooklyn{$aComplaint}++;
    } else {
      $brooklyn{$aComplaint} = 1;
    }
  }
  if ( $master{$key}{$pb} eq 'QUEENS' ) {
    if ( $queens{$aComplaint} ) {
      $queens{$aComplaint}++;
    } else {
      $queens{$aComplaint} = 1;
    }
  }
  if ( $master{$key}{$pb} eq 'STATEN ISLAND' ) {
    if ( $staten_island{$aComplaint} ) {
      $staten_island{$aComplaint}++;
    } else {
      $staten_island{$aComplaint} = 1;
    }
  }
  if ( $master{$key}{$pb} eq 'BRONX' ) {
    if ( $bronx{$aComplaint} ) {
      $bronx{$aComplaint}++;
    } else {
      $bronx{$aComplaint} = 1;
    }
  }
  if ( $master{$key}{$pb} eq 'MANHATTAN' ) {
    if ( $manhattan{$aComplaint} ) {
      $manhattan{$aComplaint}++;
    } else {
      $manhattan{$aComplaint} = 1;
    }
  }
}
my ( $totalBrooklyn, $totalBronx, $totalStatenIsland, $totalQueens, $totalManhattan ) = 
  ( scalar keys %brooklyn, scalar keys %bronx, scalar keys %staten_island,
    scalar keys %queens, scalar keys %manhattan );

my $totalComplaints = scalar keys %complaint;
my ( %complaint_ratio, %brooklyn_ratio, %staten_island_ratio, %queens_ratio, %bronx_ratio, %manhattan_ratio );
foreach my $key (keys %complaint) {
  $complaint_ratio{$key} = $complaint{$key} / $totalComplaints;
}
foreach my $key (keys %brooklyn) {
  $brooklyn_ratio{$key} = $brooklyn{$key} / $totalBrooklyn;
}
foreach my $key (keys %bronx) {
  $bronx_ratio{$key} = $bronx{$key} / $totalBronx;
}
foreach my $key (keys %staten_island) {
  $staten_island_ratio{$key} = $staten_island{$key} / $totalStatenIsland;
}
foreach my $key (keys %queens) {
  $queens_ratio{$key} = $queens{$key} / $totalQueens;
}
foreach my $key (keys %manhattan) {
  $manhattan_ratio{$key} = $manhattan{$key} / $totalManhattan;
}
print "Length of Brooklyn ratio is: ", scalar keys %brooklyn_ratio, "\n";
print "Length of Bronx ratio is: ", scalar keys %bronx_ratio, "\n";
print "Length of Staten Island ratio is: ", scalar keys %staten_island_ratio, "\n";
print "Length of Queens ratio is: ", scalar keys %queens_ratio, "\n";
print "Length of Manhattan ratio is: ", scalar keys %manhattan_ratio, "\n";
my ( %brooklynSkewed, %bronxSkewed, %SISkewed, %queensSkewed, %manhattanSkewed );
foreach my $key (keys %complaint_ratio) {
  if ( $complaint_ratio{$key} < $brooklyn_ratio{$key} ) {
    $brooklynSkewed{$key} = $brooklyn_ratio{$key} / $complaint_ratio{$key};
  }
  if ( $complaint_ratio{$key} < $bronx_ratio{$key} ) {
    $bronxSkewed{$key} = $bronx_ratio{$key} / $complaint_ratio{$key};
  }
  if ( $complaint_ratio{$key} < $staten_island_ratio{$key} ) {
    $SISkewed{$key} = $staten_island_ratio{$key} / $complaint_ratio{$key};
  }
  if ( $complaint_ratio{$key} < $queens_ratio{$key} ) {
    $queensSkewed{$key} = $queens_ratio{$key} / $complaint_ratio{$key};
  }
  if ( $complaint_ratio{$key} < $manhattan_ratio{$key} ) {
    $manhattanSkewed{$key} = $manhattan_ratio{$key} / $complaint_ratio{$key};
  }
}
my $n = 0;
foreach my $key (sort { $brooklynSkewed{$b} <=> $brooklynSkewed{$a}} keys %brooklynSkewed) {
  print "Most skewed Brooklyn complaint is: $key at $brooklynSkewed{$key} vs $complaint_ratio{$key}\n" if $n < 1;
  $n++;
}
$n = 0;
foreach my $key (sort { $bronxSkewed{$b} <=> $bronxSkewed{$a}} keys %bronxSkewed) {
  print "Most skewed Bronx complaint is: $key at $bronxSkewed{$key} vs $complaint_ratio{$key}\n" if $n < 1;
  $n++;
}
$n = 0;
foreach my $key (sort { $SISkewed{$b} <=> $SISkewed{$a}} keys %SISkewed) {
  print "Most skewed Staten Island complaint is: $key at $SISkewed{$key} vs $complaint_ratio{$key}\n" if $n < 1;
  $n++;
}
$n = 0;
foreach my $key (sort { $queensSkewed{$b} <=> $queensSkewed{$a}} keys %queensSkewed) {
  print "Most skewed Queens complaint is: $key at $queensSkewed{$key} vs $complaint_ratio{$key}\n" if $n < 1;
  $n++;
}
$n = 0;
foreach my $key (sort { $manhattanSkewed{$b} <=> $manhattanSkewed{$a}} keys %manhattanSkewed) {
  print "Most skewed Manhattan complaint is: $key at $manhattanSkewed{$key} vs $complaint_ratio{$key}\n" if $n < 1;
  $n++;
}

my %time;
my @epoch;
my $created_time;
my $str = 'Created Date';

my $dt;
foreach my $key (sort keys %master) {

  $created_time = $master{$key}{$str}; ##  10/29/2015 02:13:06 AM 
  last if (!($created_time));
  #print "created time is $created_time\n";
  if ( $created_time =~ /(\d\d)\/(\d+)\/(\d\d\d\d) (\d+):(\d\d):(\d\d) (\w\w)/ ) {
    #print "$1, $2, $3, $4, $5, $6, $7\n";
    my $sec = $6;
    my $min = $5;
    my $hours = $4;
    my $mday = $2;
    my $mon = $1;
    my $year = $3;
    my $ampm = $7;
    #print "sec is $sec\tmin is $min\thours is $hours\nmday is $mday\tmon is $mon\tyear is $year\tampm is $ampm\n";

    $dt = DateTime->new( year => $year, month => $mon, day => $mday, 
                         hour => $hours, minute => $min, second => $sec,);
                           

    my $epoch_time  = $dt->epoch;
    #print "Epoch time is: $epoch_time\n";

    push(@epoch, $epoch_time);
    if ( $created_time =~ /AM/ && $hours == 12 ) { $hours = 0; }
    if ( $created_time =~ /PM/ && $hours != 12 ) { $hours += 12; }
    if ( $time{$hours} ) {
      $time{$hours}++;
    } else {
      $time{$hours} = 1;
    }  
  }
  
}
my @sorted_epoch = sort @epoch;
my @diff_epoch;
my $arr = scalar(@sorted_epoch);
print "Array size is: $arr\n";
for (my $i=0; $i <= scalar(@sorted_epoch)-2; $i++) {
   push(@diff_epoch, abs($sorted_epoch[$i] - $sorted_epoch[$i+1]));
}
my $average = average(@diff_epoch);
my $std_dev = std_dev($average, @ diff_epoch);

printf "avg=%.2f, st. dev=%.7f\n", $average, $std_dev;

sub average {
        my (@values) = @_;

        my $count = scalar @values;
        my $total = 0; 
        $total += $_ for @values; 

        return $count ? $total / $count : 0;
}

sub std_dev {
        my ($average, @values) = @_;

        my $count = scalar @values;
        my $std_dev_sum = 0;
        $std_dev_sum += ($_ - $average) ** 2 for @values;

        return $count ? sqrt($std_dev_sum / $count) : 0;
}

my @times;
foreach my $e (sort { $time{$b} <=> $time{$a}} keys %time) {
  push(@times, $time{$e})
}
print "Difference from most to least common hours is: ", $times[0] - $times[-1], "\n";
print "First itme is: $times[0] and the last is: $times[01]\n";
