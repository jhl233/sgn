use strict;

use CXGN::Page;

use CXGN::Chado::Organism;
use CXGN::DB::DBICFactory;


# Script to display the major data content of sgn
# Naama Menda, April 2010
#


my $page = CXGN::Page->new("SGN data overview page", "Naama");
#my ($force) = $page->get_encoded_arguments("force");


my $schema = CXGN::DB::DBICFactory
    ->open_schema( 'Bio::Chado::Schema',
                                  search_path => ['public'],
    );



my $type = 'web visible'; # we want only the leaf organisms with 'web visible' organismprop
my $cvterm = $schema->resultset("Cv::Cvterm")->search( { name => $type } )->first();


my $sol=();
my $rub=();
my $planta=();


if ($cvterm) {
    my $cvterm_id = $cvterm->get_column('cvterm_id');

    my @organisms= $schema->resultset("Organism::Organismprop")->search(
	{ type_id => $cvterm_id } )->search_related('organism');
   
    foreach my $organism(@organisms) {

	my $species = $organism->get_column('species');
	my $genus= $organism->get_column('genus');
	my $organism_id = $organism->get_column('organism_id');
	my $o=CXGN::Chado::Organism->new($schema, $organism_id);
	my $root_tax=$o->get_organism_by_tax('family');
	if ($root_tax) {
	    my $family = $root_tax->species();
	    $sol->{$species}= $organism_id if $family eq 'Solanaceae' ;
	    $rub->{$species}= $organism_id if $family eq  'Rubiaceae' ;
	    $planta->{$species}= $organism_id if $family eq  'Plantaginaceae' ;
	}
    }
}
##########

$c->forward_to_mason_view("/content/sgn_data.mas" , schema=>$schema, sol=>$sol, rub=>$rub, planta=>$planta );

	
