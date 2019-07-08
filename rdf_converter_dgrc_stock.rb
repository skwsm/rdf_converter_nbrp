#!/usr/bin/env ruby
require 'optparse'


module DGRC

  def prefixes
    ["nbrp: <http://nbrp.jp/>",
     "nbrp_dggr: <http://nbrp.jp/dggr/>",
     "dggr: <https://kyotofly.kit.jp/cgi-bin/stocks/search_res_det.cgi?DB_NUM=1&DG_NUM=>",
     "faldo: <http://biohackathon.org/resource/faldo#>",
     "rdfs: <http://www.w3.org/2000/01/rdf-schema#>",
     "dcterms: <http://purl.org/dc/terms/>",
     "identifiers: <http://identifiers.org/>",
     "obo: <http://purl.obolibrary.org/obo/>",
     "taxon: <http://identifiers.org/taxonomy/>",
     "ncbigene: <http://identifiers.org/ncbigene:>",
     "so: <http://purl.obolibrary.org/obo/so#>",
     "sio: <http://semanticscience.org/resource/>"
    ].each {|uri| print "@prefix #{uri} .\n"}
    print "\n"
  end
  module_function :prefixes

  class DGGR

    def initialize(file_name)
      @strains = {}
      @keys = []
      @f = open(file_name)
      @keys = set_keys(@f.gets)
      parse_table(@f)
    end
    attr_reader :strains

    def set_keys(line)
      ary = line.chomp.split("\t") 
      ary.map! do |c|
        c.gsub(/[\#\.]/, "").gsub(/[\s-]/, "_").downcase.to_sym
      end
    end

    def parse_table(fh)
      fh.each do |line|
        ary = line.scrub.chomp.split("\t", -1)
        strain_number = ary[0]
        ary.map!{|e| e == "" ? e = nil : e}
        @strains[strain_number] = Hash[@keys.zip(ary)]
      end
    end

    def rdf
      @strains.each do |strain_number, h|
        print "nbrp_dggr:#{strain_number}\n"
        print "  dcterms:identifier \"#{strain_number}\";\n"
        print "  rdfs:seeAlso dggr:#{strain_number};\n"
        print "  nbrp:synonym \"#{h[:synonym]}\";\n" unless h[:synonym] == nil
        print "  nbrp:dataset nbrp:KyotoDGGR;\n"
        print "  obo:RO_0002162 taxon:7227;\n"
        print "  nbrp:genotype \"#{h[:genotype]}\";\n" unless h[:genotype] == nil
        print "  nbrp:cytolocation \"#{h[:cytolocation]}\";\n" unless h[:cytolocation] == nil
        print "  nbrp:subcategory \"#{h[:subcategory]}\";\n" unless h[:subcategory] == nil
        print "  rdfs:comment \"#{h[:comments]}\";\n" unless h[:comments] == nil
        print "  nbrp:balancer \"#{h[:balancer]}\";\n" unless h[:balancer] == nil
        print "  nbrp:cluster_id \"#{h[:cluster_id]}\";\n" unless h[:cluster_id] == nil
        print "  nbrp:original_number \"#{h[:original_number]}\";\n" unless h[:original_number] == nil
        print "  nbrp:received_date \"#{h[:received_date]}\";\n" unless h[:received_date] == nil
        print "  nbrp:additional_original_info \"#{h[:additional_original_info]}\";\n" unless h[:additional_original_info] == nil
        print "  nbrp:date_added_at_bloomington \"#{h[:date_added_at_bloomington]}\";\n" unless h[:date_added_at_bloomington] == nil
        print "  nbrp:original_source \"#{h[:original_source]}\";\n" unless h[:original_source] == nil
        unless h[:related_gene] == nil
          related_genes = parse_related_gene(h[:related_gene])
          if related_genes.key?(:NCBI)
            related_genes[:NCBI].each do |geneid|
              print "  nbrp:related_gene ncbigene:#{geneid}; \n"
            end
          end
        end
        print "  nbrp:original_comments \"#{h[:original_comments]}\";\n" unless h[:original_comments] == nil
        print "  nbrp:lethality \"#{h[:lethality]}\";\n" unless h[:lethality] == nil
        print "  nbrp:related_accession_no \"#{h[:related_accession_no]}\";\n" unless h[:related_accession_no] == nil
        print "  nbrp:embryonic_expression \"#{h[:embryonic_expression]}\";\n" unless h[:embryonic_expression] == nil
        print "  nbrp:larval_gfp \"#{h[:larval_gfp]}\";\n" unless h[:larval_gfp] == nil
        print "  nbrp:larval_x_gal \"#{h[:larval_x_gal]}\";\n" unless h[:larval_x_gal] == nil
        print "  nbrp:adult_gfp \"#{h[:adult_gfp]}\";\n" unless h[:adult_gfp] == nil
        print "  nbrp:lethal_phase \"#{h[:lethal_phase]}\";\n" unless h[:lethal_phase] == nil
        print "  nbrp:adult_phenotype \"#{h[:adult_phenotype]}\";\n" unless h[:adult_phenotype] == nil
#        print "  nbrp: \"#{h[:]}\";\n" unless h[:] == nil
        print "  a nbrp:BioResource .\n"
        print "\n"
      end
    end

    def parse_related_gene(related_gene)
      hash = Hash.new
      if related_gene.match(/CG/)
        hash[:NCBI] = related_gene.scan(/CG\d+/)
      end
      hash
    end
  end
end


if $0 == __FILE__ 

  params = ARGV.getopts('df:p', 'prefixes', 'dggr')

  if params["dggr"]
    dggr = DGRC::DGGR.new(params["f"])
    DGRC.prefixes
    dggr.rdf
  end

end


