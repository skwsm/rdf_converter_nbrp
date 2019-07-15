#!/usr/bin/env ruby
require 'optparse'
require 'date'

module DGRC

  def prefixes
    ["nbrp: <http://nbrp.jp/>",
     "nbrp_dggr: <http://nbrp.jp/dggr/>",
     "nbrp_rnai: <http://nbrp.jp/rnai/>",
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

  def set_keys(line)
    ary = line.chomp.split("\t")
    ary.map! do |c|
      c.gsub(/[\#\.]/, "").gsub(/[\s-]/, "_").downcase.to_sym
    end
  end
  module_function :set_keys

  class DGGR

    MONTH = ['January', 'Feburary', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December',
             'Jan', 'Fe', 'Mar', 'Apr', 'May', 'Jun',
             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    def initialize(file_name)
      @strains = {}
      @keys = []
      @f = open(file_name)
      @keys = DGRC.set_keys(@f.gets)
      parse_table(@f)
    end
    attr_reader :strains

    def parse_table(fh)
      fh.each do |line|
        ary = line.scrub.chomp.split("\t", -1)
        strain_number = ary[0]
        ary.map!{|e| e == "" ? e = nil : e}
        h = Hash[@keys.zip(ary)]
        d = parse_received_date(h[:received_date]) if h[:received_date]
#        @strains[strain_number] = Hash[@keys.zip(ary)]
      end
    end

    def parse_received_date(received_date)
      begin
        Date.parse(received_date)
      rescue
#        STDERR.print "#{received_data}\n"
        parse_date(received_date)
      end
    end

    def parse_date(date)
      case date
      when /(\d+)\/(\d+)\/(\d\d)/
        month = $1.to_i; day = $2.to_i; year = $3.to_i;
#        return Date.new("20%02d".%(year).to_i, month, day) if year < 20
#        return Date.new("19%02d".%(year).to_i, month, day) if year >= 20
      when /(\d\d) (#{Regexp.new(MONTH.join('|'))}) (\d\d\d\d)/
        p date
        day = $1.to_i; month = $2; year = $3.to_i;
        return Date.new("20%02d".%(year).to_i, (MONTH.index?(month) + 1).modulo(12), day)
      when /(\d\d\d\d)/
#        return $1.to_i
      else
      end
    end

    def rdf
      @strains.each do |strain_number, h|
        print "nbrp_dggr:#{strain_number}\n"
        print "  dcterms:identifier \"#{strain_number}\";\n"
        print "  rdfs:seeAlso dggr:#{strain_number};\n"
        print "  nbrp:synonym \"#{h[:synonym]}\";\n" if h[:synonym]
        print "  nbrp:dataset nbrp:KyotoDGGR;\n"
        print "  obo:RO_0002162 taxon:7227;\n"
        print "  nbrp:genotype \"#{h[:genotype]}\";\n" if h[:genotype]
        print "  nbrp:cytolocation \"#{h[:cytolocation]}\";\n" if h[:cytolocation]
        print "  nbrp:subcategory \"#{h[:subcategory]}\";\n" if h[:subcategory]
        print "  rdfs:comment \"#{h[:comments]}\";\n" if h[:comments]
        print "  nbrp:balancer \"#{h[:balancer]}\";\n" if h[:balancer]
        print "  nbrp:cluster_id \"#{h[:cluster_id]}\";\n" if h[:cluster_id]
        print "  nbrp:original_number \"#{h[:original_number]}\";\n" if h[:original_number]
        print "  nbrp:received_date \"#{h[:received_date]}\";\n" if h[:received_date]
        print "  nbrp:additional_original_info \"#{h[:additional_original_info]}\";\n" if h[:additional_original_info]
        print "  nbrp:date_added_at_bloomington \"#{h[:date_added_at_bloomington]}\";\n" if h[:date_added_at_bloomington]
        print "  nbrp:original_source \"#{h[:original_source]}\";\n" if h[:original_source]
        unless h[:related_gene] == nil
          related_genes = parse_related_gene(h[:related_gene])
          if related_genes.key?(:NCBI)
            related_genes[:NCBI].each do |geneid|
              print "  nbrp:related_gene ncbigene:#{geneid}; \n"
            end
          end
        end
        print "  nbrp:original_comments \"#{h[:original_comments]}\";\n" if h[:original_comments]
        print "  nbrp:lethality \"#{h[:lethality]}\";\n" if h[:lethality]
        print "  nbrp:related_accession_no \"#{h[:related_accession_no]}\";\n" if h[:related_accession_no]
        print "  nbrp:embryonic_expression \"#{h[:embryonic_expression]}\";\n" if h[:embryonic_expression]
        print "  nbrp:larval_gfp \"#{h[:larval_gfp]}\";\n" if h[:larval_gfp]
        print "  nbrp:larval_x_gal \"#{h[:larval_x_gal]}\";\n" if h[:larval_x_gal]
        print "  nbrp:adult_gfp \"#{h[:adult_gfp]}\";\n" if h[:adult_gfp]
        print "  nbrp:lethal_phase \"#{h[:lethal_phase]}\";\n" if h[:lethal_phase]
        print "  nbrp:adult_phenotype \"#{h[:adult_phenotype]}\";\n" if h[:adult_phenotype]
#        print "  nbrp: \"#{h[:]}\";\n" unless h[:] == nil
        print "  a nbrp:BiologicalResource .\n"
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

  class NIGRNAi

    def initialize(file_name)
      @strains = {}
      @keys = []
      @f = open(file_name)
      @keys = DGRC.set_keys(@f.gets)
      p @keys
      parse_table(@f)
    end
    attr_reader :strains

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
        print "nbrp_rnai:#{strain_number}\n"
        print "  dcterms:identifier \"#{strain_number}\";\n"
        if h[:synonyms]
          print "  skos:altLabel "
          synonyms = h[:synonyms].chomp.split(",").select!{|e| !e.match(/#{h[:cg_no]}/)}
#          synonyms = h[:synonyms].chomp.split(",").map{|e| e.match(/#{h[:cg_no]}/) ? nil : e.strip}
#          print "#{synonyms.map{|e| "\"#{e}\"" if e}.join(", ")} ;\n"
          print "#{synonyms.map{|e| "\"#{e.strip}\""}.join(", ")};\n"
        end
        print "  rdfs:comment \"#{h[:comment]}\";\n" if h[:comment]
        print "  a nbrp:BiologicalResource .\n"
        print "\n"
      end
    end
  end
end


if $0 == __FILE__ 

  params = ARGV.getopts('di:p', 'prefixes', 'dggr', 'rnai')

  if params["dggr"]
    dggr = DGRC::DGGR.new(params["i"])
    DGRC.prefixes
#    dggr.rdf
  end
  if params["rnai"]
    rnai = DGRC::NIGRNAi.new(params["i"])
    DGRC.prefixes
    rnai.rdf
  end
end


