require File.join(File.dirname(__FILE__), 'iis/iis_property')

Puppet::Type.newtype(:iis_config) do
  @doc = "IIS Config"

  newparam(:name) do
    desc "Config name"
  end

  newproperty(:enabled, :parent => Puppet::IisProperty) do
  	desc ""
  end

  newproperty(:enablenagling, :parent => Puppet::IisProperty) do
  	desc ""
  end

  newproperty(:enablekernelcache, :parent => Puppet::IisProperty) do
    desc ""
  end

  newproperty(:percentagephysicalmemoryusedlimit, :parent => Puppet::IisProperty) do
    desc ""
  end

  newproperty(:cache_scriptenginecachemax, :parent => Puppet::IisProperty) do
	   desc ""
  end

  newproperty(:cache_maxdisktemplatecachefiles, :parent => Puppet::IisProperty) do
     desc ""
  end

  newproperty(:cache_scriptfilecachesize, :parent => Puppet::IisProperty) do
     desc ""
  end

  newproperty(:limits_processorthreadmax, :parent => Puppet::IisProperty) do
     desc ""
  end

  newproperty(:allowkeepalive, :parent => Puppet::IisProperty) do
     desc ""
  end


end
