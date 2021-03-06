#!usr/bin/perl -w

use strict;
use CXGN::Page;
use CXGN::VHost;
use File::Spec;
use CXGN::DB::Connection;
use CXGN::BlastWatch;
use CXGN::Page::FormattingHelpers qw/page_title_html modesel info_table_html hierarchical_selectboxes_html simple_selectbox_html/;

our $page = CXGN::Page->new( "BLAST watch submission", "Adri");

# get arguments from index.pl

#my $r = Apache->request();
my $r = Apache2::RequestUtil->request;
$r->content_type("text/html");

my $req = Apache2::Request->new($r);

my $params = $r->method eq 'POST' ? $req->body : &post_only;

# dehash, because it's easier later..
my $database = $params->{database};
my $program = $params->{program};
my $matrix = $params->{matrix};

# check evalue
my $evalue = $params->{evalue};
if (!$evalue) {
    &user_error("Please enter a valid expect value.\n");
}
elsif ($evalue !~ m/(e\-[0-9]+|[0-9]+e\-[0-9]+|[0-9]+\.[0-9]+)/ or $evalue <= 0.0) {
    &user_error("Invalid Expect value \"$evalue\". Please enter a valid expect value.\n");
}

# check sequence
my $sequence = $params->{sequence};
if (!$sequence or $sequence eq "") {
    &user_error("You must specify a sequence in FASTA format to perform a BLAST search");
}

if ($sequence =~ />.+>/ ) { }

my $seq_count = ($sequence =~ tr/>//);
if($seq_count > 1) {
    &user_error("Please submit only one query sequence at a time.");
}

if ($sequence !~ m/\s*>/) {
    $sequence = ">WEB-USER-SEQUENCE (Unknown)\n$sequence";
}

my $sp_person_id = $params->{sp_person_id};
if (!$sp_person_id) {
    &user_error("Please login first.");
}

my $dbh = CXGN::DB::Connection->new();

unless (my $flag = CXGN::BlastWatch::insert_query($dbh, $sp_person_id, $sequence, $program, $database, $matrix, $evalue)) {
    &user_error("You have already submitted this query!");
}

$dbh->disconnect(42);

&website;

#### ------------------------- ####

sub website {

    $page->header();
    print page_title_html('Success!');

    print <<EOF;
    <p>Your query has been added to SGN BLAST Watch.  You will receive an email when there are new results.</p>
EOF
	
    $page->footer();
    
}

sub post_only {
    
    $page->header();
    print page_title_html('SGN BLAST Watch Interface Error');
    
    print <<EOF;
    <p>BLAST subsystem can only accept HTTP POST requests</p>
EOF
	
    $page->footer();
    exit(0);
}


sub user_error {

    my $reason = shift;
    
    $page->header();
    print page_title_html('SGN BLAST Watch Error');

    print <<EOF;
    <p>$reason</p>
EOF

    $page->footer();
    exit(0);
}
