require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
describe 'Puppet::Type.type(:rabbitmq_policy).provider(:rabbitmqctl)' do
  before :each do
    @provider_class = Puppet::Type.type(:rabbitmq_policy).provider(:rabbitmqctl)
    @resource = Puppet::Type::Rabbitmq_policy.new(
      {:name => 'foo@bar'}
    )
    @provider = @provider_class.new(@resource)
  end
  after :each do
    @provider_class.instance_variable_set(:@policies, nil)
  end
  it 'should match policies from list' do
    @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
bar foo 2 {"key":"value"} 0
...done.
EOT
    @provider.exists?.should == {:pattern=>"2", :policy=>'{"key":"value"}' }
  end
  it 'should not match policies with more than 5 columns' do
    @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
bar 1 2 3 4 5
...done.
EOT
    expect { @provider.exists? }.to raise_error(Puppet::Error, /cannot parse line from list_policies/)
  end
  it 'should not match an empty list' do
    @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
...done.
EOT
    @provider.exists?.should == nil
  end
  it 'should destroy policies' do
    @provider.instance_variable_set(:@should_vhost, "bar")
    @provider.instance_variable_set(:@should_policy_name, "foo")
    @provider.expects(:rabbitmqctl).with('clear_policy', '-p', 'bar', 'foo')
    @provider.destroy 
  end
  {:pattern=> '2', :policy => '{"key":"value"}'}.each do |k,v|
    it "should be able to retrieve #{k}" do
      @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
bar foo 2 {"key":"value"} 0
...done.
EOT
      @provider.send(k).should == v
    end
  end
  {:pattern=> '2', :policy => '{"key":"value"}'}.each do |k,v|
    it "should be able to retrieve #{k} after exists has been called" do
      @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
bar foo 2 {"key":"value"} 0
...done.
EOT
      @provider.exists?
      @provider.send(k).should == v
    end
  end
  {:pattern => ['.*', '^.*$'],
   :policy   => ['{"key":"value"}', '{"key2":"value2"}']
  }.each do |perm, columns|
  end
  it "should be able to sync pattern" do
    @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
bar foo ^.*$ {"key":"value"} 0
...done.
EOT
    @provider.resource[:pattern] = '.*'
    @provider.expects(:rabbitmqctl).with('set_policy', '-p', 'bar', 'foo', '.*', '{"key":"value"}')
    @provider.send("pattern=".to_sym, '.*')
  end

  it "should be able to sync policy" do
    @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
bar foo ^.*$ {"key":"value"} 0
...done.
EOT
    @provider.resource[:policy] = '{"key":"value2"}'
    @provider.expects(:rabbitmqctl).with('set_policy', '-p', 'bar', 'foo', '^.*$', '{"key":"value2"}')
    @provider.send("policy=".to_sym, '{"key":"value2"}')
  end

  it 'should only call set_permissions once' do
    @provider.class.expects(:rabbitmqctl).with('list_policies', '-p', 'bar').returns <<-EOT
Listing policies ...
bar foo ^.*$ {"key":"value"} 0
...done.
EOT
    @provider.resource[:policy] = '{"key":"value2"}'
    @provider.expects(:rabbitmqctl).with('set_policy', '-p', 'bar', 'foo', '^.*$', '{"key":"value2"}').once
    @provider.policy='{"key":"value2"}'
  end
end

