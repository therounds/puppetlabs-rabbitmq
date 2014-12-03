Puppet::Type.type(:rabbitmq_policy).provide(:rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  defaultfor :feature=> :posix

  # cache policies permissions
  def self.policies(name, vhost)
    @policies = {} unless @policies
    unless @policies[vhost]
      @policies[vhost] = {}
      rabbitmqctl('list_policies', '-p', vhost).split(/\n/)[1..-2].each do |line|
        if line =~ /^(\S+)\s+(\S*)\s+(\S*)\s+(\S*)\s+(\S*)$/
          @policies[vhost][$2] =
            {:pattern => $3, :policy => $4}
        else
          raise Puppet::Error, "cannot parse line from list_policies:#{line}"
        end
      end
    end
    @policies[vhost][name]
  end

  def policies(name, vhost)
    self.class.policies(name, vhost)
  end

  def should_policy_name
    if @should_policy_name
      @should_policy_name
    else
      @should_policy_name = resource[:name].split('@')[0]
    end
  end

  def should_vhost
    if @should_vhost
      @should_vhost
    else
      @should_vhost = resource[:name].split('@')[1]
    end
  end

  def create
    rabbitmqctl('set_policy', '-p', should_vhost, should_policy_name, resource[:pattern], resource[:policy])
  end

  def destroy
    rabbitmqctl('clear_policy', '-p', should_vhost, should_policy_name)
  end

  # I am implementing prefetching in exists b/c I need to be sure
  # that the rabbitmq package is installed before I make this call.
  def exists?
    policies(should_policy_name, should_vhost)
  end

  def pattern
    policies(should_policy_name, should_vhost)[:pattern]
  end

  def pattern=(perm)
    set_permissions
  end

  def policy
    policies(should_policy_name, should_vhost)[:policy]
  end

  def policy=(perm)
    set_permissions
  end

  # implement memoization so that we only call set_permissions once
  def set_permissions
    unless @permissions_set
      @permissions_set = true
      resource[:pattern]     ||= pattern
      resource[:policy]      ||= policy
      rabbitmqctl('set_policy', '-p', should_vhost, should_policy_name,
        resource[:pattern], resource[:policy]
      )
    end
  end

end
