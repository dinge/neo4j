$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/extensions/exportable'
require 'spec_helper'


class Movie
  include Neo4j::NodeMixin
  include Neo4j::Exportable

  has_n :influenced_by
  has_n :supported_by

  property :title
  property :year
  property :created_at, :type => Date
end


describe Neo4j::Exportable do

  before(:each) do
    @fixed_date = Date.new(2000, 01, 01)
    start
    Neo4j::Transaction.new

    @matrix = Movie.new :title => 'Matrix'
    @matrix.created_at = @fixed_date

    @welt_am_draht = Movie.new :title => 'Welt am Draht'
    @welt_am_draht[:special] = 'good thing'

    @matrix.influenced_by << @welt_am_draht
    @matrix.supported_by  << @welt_am_draht

    @matrix_as_hash = {
      'title' => 'Matrix', '_classname' => 'Movie',
      '_neo_id' => @matrix.neo_id, 'created_at' => @fixed_date
    }.merge(
      '__outgoing_rels' => [ { "_neo_id" => 3 }, { "_neo_id" => 4 } ]
    )

    @welt_am_draht_as_hash = {
      'title' => 'Welt am Draht', '_classname' => 'Movie',
      '_neo_id' => @welt_am_draht.neo_id, 'special' => 'good thing'
    }.merge(
      '__outgoing_rels' => [ ]
    )
  end

  after(:all) do
    stop
  end


  context "Classmethods" do

    it "the class should have some new class method" do
      Movie.should respond_to(:export_to_yaml)
      Movie.should respond_to(:import_from_yaml)
    end

    it "should export all nodes as yaml" do
      from_neo = YAML.load(Movie.export_to_yaml)
      from_neo['Movie_2'].should == @matrix_as_hash
      from_neo['Movie_3'].should == @welt_am_draht_as_hash
    end


    describe "importing of nodes" do

      before(:each) do
        yaml = Movie.export_to_yaml
        Movie.all.nodes.each { |node| node.del }
        Movie.all.nodes.to_a.size.should be 0

        Movie.import_from_yaml(yaml)
        @movies = Movie.all.nodes.to_a
      end

      it "should import nodes from yaml" do
        @movies.size.should be 2

        # movies.each { |node| puts node.props.inspect  }
        matrix = @movies.find { |movie| movie.title == 'Matrix' }
        matrix.title.should == @matrix.title
        matrix.created_at.should == @matrix.created_at
        matrix['_classname'].should == 'Movie'
        matrix['_neo_id'].should == @matrix.neo_id

        welt_am_draht = @movies.find { |movie| movie.title == 'Welt am Draht' }
        welt_am_draht['_neo_id'].should == @welt_am_draht.neo_id
        welt_am_draht['special'].should == @welt_am_draht['special']
      end

      it "should import the relatationships" do
        pending
      end
      
    end


  end


  context "Instancemethods" do

    it "instances should have some new methods" do
      @matrix.should respond_to(:export_to_yaml)
      @matrix.should respond_to(:import_from_yaml)
    end

    it "an instance should export it's properties as hash" do
      @matrix.export_to_hash.should == @matrix_as_hash
    end

    it "an instance should export it's properties as yaml" do
      from_neo  = YAML.load(@matrix.export_to_yaml)
      from_neo.should == @matrix_as_hash
    end

    # it "an instance should by init" do
    #   
    # end

  end



end
