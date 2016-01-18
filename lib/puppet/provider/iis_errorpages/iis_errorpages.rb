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

  def get_complex_property_arg(name, error_pages_to_add)
    args = nil

    case name
    when :error_pages
	  stringify_statuscode!(error_pages_to_add)
	  strinfiy_substatuscode!(error_pages_to_add)
	  stringify_statuscode!(@initial_properties[:error_pages])
	  strinfiy_substatuscode!(@initial_properties[:error_pages])
	  
	  to_remove = @initial_properties[:error_pages].select do |existing_error_page| 
		error_page_for_statuscode_exists = found_error_page_with_same_statuscode_as_we_are_adding(error_pages_to_add, existing_error_page)
		existing_error_page_not_same = !error_pages_to_add.include?(existing_error_page)
		
		error_page_for_statuscode_exists && existing_error_page_not_same
	  end

      to_add = error_pages_to_add.reject{|x| if @initial_properties[:error_pages].include?(x); x end}

      to_remove.map do |page|
        (args ||= []) << "\"/-[" + page.map{|k,v| "#{k}='#{v}'" if k =~ /statusCode/i}.join('') + "]\""
      end unless to_remove.empty?

      to_add.map do |page|
        (args ||= []) << "\"/+[" + page.map{|k,v| "#{k}='#{v}'"}.join(',') + "]\""
      end
    end

    args
  end
  
  # On subsequent runs, after the custom error pages have been added, 
  # get_complex_property_arg will return an empty array and this method 
  # will be called by the parent class. In that case, it should do nothing.
  def get_simple_property_arg(name, error_pages_to_add)
  end

  def execute_flush
    commit = resource[:commit] ? resource[:commit] : "apphost"
    appcmd *(['set', 'config', @resource[:name], "/commit:#{commit}", "/section:system.webServer/httpErrors"] + get_property_args)
  end

 def execute_delete
   appcmd 'clear', 'config', @resource[:name], "/section:system.webServer/httpErrors"
 end
 
 #-----------Private Methods-----------------
  private
  # The statusCode can come over as an integer. Convert it to a string 
  # so that when comparing, we know we're comparing apples to apples.
  # [error_pages] The array of hashes where each hash is the custom error page
  def stringify_statuscode!(error_pages)
    return if error_pages.nil?
	error_pages.each { |error_page| error_page['statusCode'] = error_page['statusCode'].to_s }
  end
  
  # The subStatusCode can come over as an integer. Convert it to a string 
  # so that when comparing, we know we're comparing apples to apples.
  # [error_pages] The array of hashes where each hash is the custom error page
  def strinfiy_substatuscode!(error_pages)
    return if error_pages.nil?
    error_pages.each do |error_page| 
	  if !error_page['subStatusCode'].nil?
	    error_page['subStatusCode'] = error_page['subStatusCode'].to_s 
	  end
	end
  end
  
  # Gets a value indicating whether there is an existing custom error page with the same 
  # statusCode and subStatusCode as the one we're trying to add
  # [error_pages_to_add] Array of error page hashes to add
  # [existing_error_page] Existing error page to compare to
  def found_error_page_with_same_statuscode_as_we_are_adding(error_pages_to_add, existing_error_page)
    error_pages_to_add.any? do |error_page| 
	  if (!error_page['subStatusCode'].nil?)
	    error_page['statusCode'] == existing_error_page['statusCode'] && error_page['subStatusCode'] == existing_error_page['subStatusCode']
	  else
	    error_page['statusCode'] == existing_error_page['statusCode'] 
	  end
	end
  end

end
