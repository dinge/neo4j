$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'spec_helper'
require 'neo4j/extensions/meta_info'

describe 'metainfo extensions for a node' do
  before(:all) do
    start
  end

  before(:each) do
    undefine_class :SomeThing, :OtherThing#, :DingDong

    class SomeThing
      include Neo4j::NodeMixin
    end

    class OtherThing
      include Neo4j::NodeMixin
      include Neo4j::MetaInfo
    end

    Neo4j::Transaction.run do
      @something = SomeThing.new
      @otherthing = OtherThing.new
    end

    Neo4j::Transaction.new
  end

  after(:each) do
    Neo4j::Transaction.finish
  end

  after(:all) do
    stop
  end



  context 'without included Neo4j::MetaInfo' do
    it "should not have a created_at property" do
      lambda { @something.created_at }.should raise_error(NoMethodError)
    end

    it "should not have a updated_at property" do
      lambda { @something.updated_at }.should raise_error(NoMethodError)
    end

    it "should not have a version property" do
      lambda { @something.version }.should raise_error(NoMethodError)
    end

    it "should not have a uuid property" do
      lambda { @something.uuid }.should raise_error(NoMethodError)
    end
  end


  context "with included Neo4j::MetaInfo" do
    it "should have the property created_at returning a DateTime" do
      @otherthing.created_at.should be_an_instance_of DateTime
    end

    it "should return the DateTime it was created" do
      @otherthing.created_at.day.should == DateTime.now.day
      @otherthing.created_at.hour.should == DateTime.now.hour
    end

    it "should return the DateTime it was updated" do
      @otherthing.updated_at.should be_an_instance_of DateTime
    end

    it "should update and return the DateTime it was updated" do
      last_update_at = @otherthing.updated_at
      sleep 2
      @otherthing[:suppe] = "lecker"
      @otherthing.updated_at.should be_close(DateTime.now, 0.00002)
      @otherthing.updated_at.to_s.should_not == last_update_at.to_s
    end

    it "should return a integer as version" do
      @otherthing.should respond_to(:version)
      @otherthing.version.should be_a_kind_of(Integer)
    end

    it "should increment the version property with every update" do
      old_version = @otherthing.version
      @otherthing[:tieger] = "hungrig"
      @otherthing.version.should be old_version + 1
      @otherthing[:tieger] = "durstig"
      @otherthing.version.should be old_version + 2
    end

    it "should return it's uuid" do
      @otherthing.should respond_to(:uuid)
      old_uuid = @otherthing.uuid

      java.util.UUID.from_string( @otherthing.uuid ).version.should == 4

      @otherthing[:changes] = 'value'
      @otherthing.uuid.should == old_uuid
    end

  end






end
