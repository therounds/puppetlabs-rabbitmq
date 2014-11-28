Puppet::Type.newtype(:rabbitmq_policy) do
  desc 'Type for managing rabbitmq policies'

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  autorequire(:service) { 'rabbitmq-server' }

  newparam(:name, :namevar => true) do
    desc 'combination of policy_name@vhost to create'
    newvalues(/^\S+@\S+$/)
  end

  newproperty(:pattern) do
    desc 'regexp representing rabbitmq entities to apply to'
    validate do |value|
      resource.validate_permissions(value)
    end
  end

  newproperty(:policy) do
    desc 'string representing policy definition'
    validate do |value|
      resource.validate_policy(value)
    end
  end

  autorequire(:rabbitmq_vhost) do
    [self[:name].split('@')[1]]
  end

  def validate_policy(value)
    raise ArgumentError, "Invalid policy #{value}" unless /^\{.*\}$/ =~ value
  end

  # I may want to dissalow whitespace
  def validate_permissions(value)
    begin
      Regexp.new(value)
    rescue RegexpError
      raise ArgumentError, "Invalid regexp #{value}"
    end
    raise ArgumentError, "Cannot use blank regex" if value.nil? or value.length == 0
  end

end
