require File.join(File.dirname(__FILE__), '../iis/iis_object')

Puppet::Type.type(:iis_errorpages).provide(:iis_errorpages, :parent => Puppet::Provider::IISObject) do
  desc "IIS Error Pages"

  confine     :operatingsystem => :windows
  defaultfor  :operatingsystem => :windows

  commands :appcmd => File.join(ENV['SystemRoot'] || 'c:/windows', 'system32/inetsrv/appcmd.exe')

  mk_resource_methods

  private
  def self.iis_type
    'errorpages'
  end

  def self.instances(resources)
    list(resources).map do |hash|
      hash[:ensure] = :present
      new(hash)
    end
  end

  # Match resources to providers where the resource name matches the provider name
  def self.prefetch(resources)
    providers = Hash[instances(resources).map { |provider| [provider.name, provider] }]

    resources.each do |name, resource|
      provider = providers[name]

      if provider
        resource.provider = provider
      else
        resource.provider = new(:ensure => :absent)
      end
    end
  end
  def self.list(resources)
    res = []
    resources.each do |name, resource|
      command_and_args = [command(:appcmd), 'list', 'config', name, '/section:system.webServer/httpErrors']
      command_line = command_and_args.flatten.map(&:to_s).join(" ")

      output = execute(command_and_args, :failonfail => false)
      raise Puppet::ExecutionFailure, "Execution of '#{command_line}' failed" if output.nil? or output.length == 0
      res << extract_item(output).merge({:name => name})
    end
    res
  end

  def self.extract_item(items_xml)
    hash = {}
    REXML::Document.new(items_xml).each_element("/system.webServer/httpErrors/error") do |item_xml|
      item_xml.each_element("descendant-or-self::*") do |element|
        (hash[:error_pages] ||= []) << Hash[element.attributes.map{|k,v| [k,v]}]
      end
      hash[:provider] = self.name
      hash[:ensure] = :present
    end
    hash
  end

  def get_complex_property_arg(name, value)
    args = nil

    case name
    when :error_pages
      args = []
      @initial_properties[:error_pages].each do |page|
        args << "\"/-[" + page.map{|k,v| "#{k}='#{v}'"}.join(',') + "]\""
      end unless @initial_properties[:error_pages].nil?
      
      value.each do |page|
        args << "\"/+[" + page.map{|k,v| "#{k}='#{v}'"}.join(',') + "]\""
      end
    end

    args
  end

  def execute_flush
    get_property_args.each do |arg|
      appcmd 'set', 'config', @resource[:name], "/section:system.webServer/httpErrors", arg
    end
  end

 def execute_delete
   appcmd 'clear', 'config', @resource[:name], "/section:system.webServer/httpErrors"
 end

end