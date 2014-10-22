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
    resources_list = []

    resources.each do |name, resource|
      command_and_args = [command(:appcmd), 'list', 'config', name, '/section:system.webServer/httpErrors']
      command_line = command_and_args.flatten.map(&:to_s).join(" ")

      output = execute(command_and_args, :failonfail => false)
      raise Puppet::ExecutionFailure, "Execution of '#{command_line}' failed" if output.nil? or output.length == 0
      resources_list << extract_item(output).merge(
        {:name     => name,
         :provider => self.name,
         :ensure   => :present }
      )
    end
    resources_list
  end

  def self.extract_item(items_xml)
    hash = {}
    REXML::Document.new(items_xml).each_element("/system.webServer/httpErrors/error") do |item_xml|
      item_xml.each_element("descendant-or-self::*") do |element|
        (hash[:error_pages] ||= []) << Hash[element.attributes.map{|k,v| [k,v]}]
      end
    end
    hash
  end

  def get_complex_property_arg(name, value)
    args = nil

    case name
    when :error_pages
      to_remove = @initial_properties[:error_pages].reject{|x| if value.include?(x); x end}
      to_add = value.reject{|x| if @initial_properties[:error_pages].include?(x); x end}

      to_remove.map do |page|
        (args ||= []) << "\"/-[" + page.map{|k,v| "#{k}='#{v}'" if k =~ /statusCode/i}.join(',') + "]\""
      end unless to_remove.empty?

      to_add.map do |page|
        (args ||= []) << "\"/+[" + page.map{|k,v| "#{k}='#{v}'"}.join(',') + "]\""
      end
    end

    args
  end

  def execute_flush
    commit = resource[:commit] ? resource[:commit] : "apphost"
    appcmd *(['set', 'config', @resource[:name], "/commit:#{commit}", "/section:system.webServer/httpErrors"] + get_property_args)
  end

 def execute_delete
   appcmd 'clear', 'config', @resource[:name], "/section:system.webServer/httpErrors"
 end

end
