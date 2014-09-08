require File.join(File.dirname(__FILE__), 'iis/iis_property')

Puppet::Type.newtype(:iis_config) do
  @doc = "IIS Config"

  ensurable

  newparam(:name) do
    desc "Config name"
  end

  properties = [ "enabled" => "Can be used in multiple configuration sections",
                 "enablekernelcache" => "system.webserver/caching",
                 "enablenagling" => "system.webServer/serverRuntime",
                 "percentagephysicalmemoryusedlimit" => "system.web/caching/cache",
                 "cache_scriptenginecachemax" => "system.webServer/asp",
                 "cache_maxdisktemplatecachefiles" => "system.webServer/asp" ,
                 "cache_scriptfilecachesize" => "system.webServer/asp",
                 "limits_processorthreadmax" => "system.webServer/asp",
                 "enableparentpath" => "system.webServer/asp",
                 "session_allowsessionstate" => "system.webServer/asp",
                 "allowkeepalive" => "system.webServer/httpProtocol",
                 "dostaticcompression" => "system.webServer/urlCompression",
                 "dodynamiccompression" => "system.webServer/urlCompression",
                 "directory" => "system.webServer/httpCompression",
                 "minfilesizeforcomp" => "system.webServer/httpCompression",
                 "maxdiskspaceusage" => "system.webServer/httpCompression",
                 "dontlog" => "system.webServer/httpLogging",
                 "applicationpooldefaults_autostart" => "system.applicationHost/applicationPools",
                 "applicationpooldefaults_managedruntimeversion" => "system.applicationHost/applicationPools",
                 "applicationpooldefaults_managedpipelinemode" => "system.applicationHost/applicationPools",
                 "applicationpooldefaults_processmodel_identitytype" => "system.applicationHost/applicationPools
                 (value can be SpecificUser, NetworkService, LocalService or LocalSystem)",
                 "applicationpooldefaults_processmodel_username" => "system.applicationHost/applicationPools",
                 "applicationpooldefaults_processmodel_password" => "system.applicationHost/applicationPools",

               ]

  properties.each do |property, description|
    eval "newproperty(:#{property}, :parent => Puppet::IisProperty) { desc #{description} }"
  end

  newproperty(:default_documents, :array_matching => :all, :parent => Puppet::IisProperty) do
	   desc "List of defaultDocuments in order of priority (system.webserver/defaultDocument)"
  end
end
