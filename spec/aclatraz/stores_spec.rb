require 'spec_helper'

COMMON_STORE_SPECS = proc do
  it "should assign roles to owner and properly check permissions" do
    subject.clear
    subject.set("admin", owner)
    subject.set("manager", owner, StubTarget)
    subject.set("creator", owner, target)
    
    subject.check("admin", owner).should be_true
    subject.check("manager", owner, StubTarget).should be_true
    subject.check("creator", owner, target).should be_true

    subject.check("owner", owner, target).should be_false
    subject.check("tester", owner, StubTarget).should be_false
    subject.check("waiter", owner).should be_false
  end
  
  it "should delete given permission" do
    subject.clear
    subject.set("admin", owner)
    subject.set("manager", owner, StubTarget)
    subject.set("creator", owner, target)
    
    subject.delete("admin", owner)
    subject.delete("manager", owner, StubTarget)
    subject.delete("creator", owner, target)
    
    subject.check("admin", owner).should be_false
    subject.check("manager", owner, StubTarget).should be_false
    subject.check("creator", owner, target).should be_false
  end
  
  it "should allow to fetch list of all roles" do 
    subject.clear
    subject.set("waiter", owner)
    subject.set("cooker", owner)
    subject.set("worker", owner)
    
    (subject.roles - ["waiter", "cooker", "worker"]).should be_empty 
  end
  
  it "should allow to fetch list of roles for specified member" do 
    subject.clear
    subject.set("waiter", owner)
    subject.set("cooker", owner)
    subject.set("worker", owner)
    
    (subject.roles(owner) - ["waiter", "cooker", "worker"]).should be_empty
  end
end

describe "Aclatraz" do
  let(:owner) { StubOwner.new }
  let(:target) { StubTarget.new }
  
  context "for Redis store" do 
    subject { Aclatraz.init(:redis, "redis://localhost:6379/0") }
    class_eval(&COMMON_STORE_SPECS)
    
    it "should respect persistent connection given on initalize" do 
      Aclatraz.instance_variable_set("@store", nil)
      Aclatraz.init(:redis, Redis.new("redis://localhost:6379/0"))
      Aclatraz.store.instance_variable_get('@backend').should be_kind_of(Redis)
      Aclatraz.store.instance_variable_get('@backend').ping.should be_true
    end
    
    it "shouls respect redis hash options given in init" do 
      Aclatraz.instance_variable_set("@store", nil)
      Aclatraz.init(:redis, :url => "redis://localhost:6379/2")
      Aclatraz.store.instance_variable_get('@backend').ping.should be_true
    end 
  end

  context "for Riak store" do 
    subject { Aclatraz.init(:riak, "roles") }
    class_eval(&COMMON_STORE_SPECS)
    
    it "should respect persistent connection given on initalize" do 
      Aclatraz.instance_variable_set("@store", nil)
      Aclatraz.init(:riak, "roles", Riak::Client.new)
      Aclatraz.store.instance_variable_get('@backend').should be_kind_of(Riak::Bucket)
    end
  end
  
  context "for Cassandra store" do 
    subject { Aclatraz.init(:cassandra, "Super1", "Keyspace1") }
    class_eval(&COMMON_STORE_SPECS)
  
    it "should respect persistent connection given on initialize" do 
      Aclatraz.instance_variable_set("@store", nil)
      Aclatraz.init(:cassandra, "Super1", Cassandra.new("Keyspace1"))
      Aclatraz.store.instance_variable_get('@backend').should be_kind_of(Cassandra)
    end
  end
  
  context "for MongoDB store" do
    subject do
      require 'mongo'
      @mongo ||= Mongo::Connection.new.db("aclatraz_test")
      Aclatraz.init(:mongo, "roles", @mongo)
    end
    class_eval(&COMMON_STORE_SPECS)
  end
end
