require 'puppet'
require 'puppet/type/rabbitmq_policy'
describe Puppet::Type.type(:rabbitmq_policy) do
  before :each do
    @perms = Puppet::Type.type(:rabbitmq_policy).new(:name => 'ha_nodes@vhost1')
  end
  it 'should accept a valid hostname name' do
    @perms[:name] = 'dan@bar'
    @perms[:name].should == 'dan@bar'
  end
  it 'should require a name' do
    expect {
      Puppet::Type.type(:rabbitmq_policy).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  it 'should fail when names dont have a @' do
    expect {
      @perms[:name] = 'bar'
    }.to raise_error(Puppet::Error, /Valid values match/)
  end
  [:pattern].each do |param|
    it 'should not default to anything' do
       @perms[param].should == nil
    end
    it "should accept a valid regex for #{param}" do
      @perms[param] = '.*?'
      @perms[param].should == '.*?'  
    end
    it "should not accept an empty string for #{param}" do
      expect {
        @perms[param] = ''
      }.to raise_error(Puppet::Error, /.*/)
    end
    it "should not accept invalid regex for #{param}" do
      expect {
        @perms[param] = '*'
      }.to raise_error(Puppet::Error, /Invalid regexp/)
    end
  end
  [:policy].each do |param|
    it 'should not default to anything' do
       @perms[param].should == nil
    end
    it "should accept a string beginning with { and ending with } for #{param}" do
      @perms[param] = '{"ha-mode":"all"}'
      @perms[param].should == '{"ha-mode":"all"}'
    end
    it "should not accept an empty string for #{param}" do
      expect {
        @perms[param] = ''
      }.to raise_error(Puppet::Error, /.*/)
    end
    it "should not accept an arbitrary for #{param}" do
      expect {
        @perms[param] = 'arbitrary string'
      }.to raise_error(Puppet::Error, /Invalid policy/)
    end
  end
  {:rabbitmq_vhost => 'ha_nodes@test'}.each do |k,v|
    it "should autorequire #{k}" do
      vhost = Puppet::Type.type(k).new(:name => "test")
      pol   = Puppet::Type.type(:rabbitmq_policy).new(:name => v)
      config = Puppet::Resource::Catalog.new :testing do |conf|
        [vhost, pol].each { |resource| conf.add_resource resource }
      end
      rel = pol.autorequire[0]
      rel.source.ref.should == vhost.ref
      rel.target.ref.should == pol.ref
    end
  end
end
