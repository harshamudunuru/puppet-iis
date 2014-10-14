require File.join(File.dirname(__FILE__), 'iis/iis_property')

Puppet::Type.newtype(:iis_config) do
  @doc = "IIS Config"

  ensurable

  newparam(:name) do
    desc "Config section"
  end

  newparam(:config_section) do
    desc "Config section (if not used as name)"
  end

  newparam(:path) do
    desc "Used for controlling the location of configuration changes. If not specified, changes will be applied at server level."
  end

  newparam(:commit) do
    desc "Choose commit path. Default: APPHOST"
  end

  newproperty(:enabled, :parent => Puppet::IisProperty) do
    desc "Can be used in multiple configuration sections"
  end

  newproperty(:enablekernelcache, :parent => Puppet::IisProperty) do
    desc "system.webserver/caching"
  end

  newproperty(:enablenagling, :parent => Puppet::IisProperty) do
    desc "system.webServer/serverRuntime"
  end

  newproperty(:percentagephysicalmemoryusedlimit, :parent => Puppet::IisProperty) do
    desc "system.web/caching/cache"
  end

  newproperty(:cache_scriptenginecachemax, :parent => Puppet::IisProperty) do
    desc "system.webServer/asp"
  end

  newproperty(:cache_scriptfilecachesize, :parent => Puppet::IisProperty) do
    desc "system.webServer/asp"
  end

  newproperty(:cache_maxdisktemplatecachefiles, :parent => Puppet::IisProperty) do
    desc "system.webServer/asp"
  end

  newproperty(:enableparentpaths, :parent => Puppet::IisProperty) do
    desc "system.webServer/asp"
  end

  newproperty(:session_allowsessionstate, :parent => Puppet::IisProperty) do
    desc "system.webServer/asp"
  end

  newproperty(:limits_processorthreadmax, :parent => Puppet::IisProperty) do
    desc "system.webServer/asp"
  end

  newproperty(:allowkeepalive, :parent => Puppet::IisProperty) do
    desc "system.webServer/httpProtocol"
  end

  newproperty(:dostaticcompression, :parent => Puppet::IisProperty) do
    desc "system.webServer/urlCompression"
  end

  newproperty(:dodynamiccompression, :parent => Puppet::IisProperty) do
    desc "system.webServer/urlCompression"
  end

  newproperty(:directory, :parent => Puppet::IisProperty) do
    desc "system.webServer/httpCompression"
  end

  newproperty(:minfilesizeforcomp, :parent => Puppet::IisProperty) do
    desc "system.webServer/httpCompression"
  end

  newproperty(:maxdiskspaceusage, :parent => Puppet::IisProperty) do
    desc "system.webServer/httpCompression"
  end

  newproperty(:dontlog, :parent => Puppet::IisProperty) do
    desc "system.webServer/httpLogging"
  end

  newproperty(:applicationpooldefaults_autostart, :parent => Puppet::IisProperty) do
    desc "system.applicationHost/applicationPools"
  end

  newproperty(:applicationpooldefaults_managedruntimeversion, :parent => Puppet::IisProperty) do
    desc "system.applicationHost/applicationPools"
  end

  newproperty(:applicationpooldefaults_managedpipelinemode, :parent => Puppet::IisProperty) do
    desc "system.applicationHost/applicationPools"
  end

  newproperty(:applicationpooldefaults_processmodel_identitytype, :parent => Puppet::IisProperty) do
    desc "system.applicationHost/applicationPools (value can be SpecificUser, NetworkService, LocalService or LocalSystem)"
  end

  newproperty(:applicationpooldefaults_processmodel_username, :parent => Puppet::IisProperty) do
    desc "system.applicationHost/applicationPools"
  end

  newproperty(:applicationpooldefaults_processmodel_password, :parent => Puppet::IisProperty) do
    desc "system.applicationHost/applicationPools"
  end

  newproperty(:default_documents, :array_matching => :all, :parent => Puppet::Property) do
	   desc "List of defaultDocuments in order of priority (system.webserver/defaultDocument)"
  end

  newparam(:use_defaults, :parent => Puppet::IisProperty) do
    desc "system.webServer/staticContent -> use default mimetypes in addition to these manually defined. Default: false."
  end

  newproperty(:mimetypes, :parent => Puppet::Property) do
    desc "system.webServer/staticContent -> Hash of available mimetypes (ex: {'.html' => 'text/html'})"
  end

  newproperty(:clientcache_cachecontrolmode, :parent => Puppet::Iis Property) do
    desc "system.webServer/staticContent -> Possible values: NoControl, DisableCache, UseMaxAge and UseExpires"
    validate do |value|
      unless value =~ /^NoControl$|^DisableCache$|^UseMaxAge$|^UseExpires$/
        raise ArgumentError, "%s is not a valid value. Possible values are NoControl, DisableCache, UseMaxAge and UseExpires" % value
      end
    end
  end

  newproperty(:clientcache_cachecontrolmaxage, :parent => Puppet::IisProperty) do
    desc "system.webServer/staticContent"
  end

  newproperty(:clientcache_httpexpires, :parent => Puppet::IisProperty) do
    desc "system.webServer/staticContent"
  end

end
