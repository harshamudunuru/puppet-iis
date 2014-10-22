require File.join(File.dirname(__FILE__), '../iis/iis_object')
require 'pathname'

Puppet::Type.type(:iis_config).provide(:iis_config, :parent => Puppet::Provider::IISObject) do
  desc "IIS Config"

  confine     :operatingsystem => :windows
  defaultfor  :operatingsystem => :windows

  commands :appcmd => File.join(ENV['SystemRoot'] || 'c:/windows', 'system32/inetsrv/appcmd.exe')

  mk_resource_methods

  private
  def self.iis_type
    "config"
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

			if resource[:mimetypes] and resource[:use_defaults]
				resource[:mimetypes].merge!(YAML.load_file(Pathname.new(__FILE__).dirname + 'mimetypes.yml'))
			end
		end
	end

	def self.list(resources)
    resources_list = []

		resources.each do |name, resource|
			section = resource[:config_section] ? resource[:config_section] : resource[:name]
			command_and_args = [command(:appcmd), 'list', iis_type(), '/xml', '/config:*', "/section:#{section}"]
			command_and_args << resource[:path] unless resource[:path] == nil
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

  def self.extract_item(xml)
    hash = {}

    REXML::Document.new(xml).each_element("descendant-or-self::*") do |element|
      element.attributes.each do |key, attribute|
        key = "#{element.xpath}/#{key}".gsub(/\/appcmd\/[^\/]+\/([^\/]+\/)?/, "").gsub("/", "_").downcase

        case key

        when /^files_add\[\d+\]_value$/ # default documents
          hash[:default_documents] ||= []
          hash[:default_documents] << attribute

        when /mimemap.+_fileextension/ # mimetypes (phase 1)
          hash[:mimetypes] ||= {}
          hash[:mimetypes].store attribute, nil

        when /mimemap.+_mimetype/      # mimetypes (phase 2)
          id = key[/mimemap\[(\d+)\]_mimetype/, 1].to_i - 1
          hash[:mimetypes][hash[:mimetypes].keys[id]] = attribute

        else
          hash[key.to_sym] = attribute if resource_type.validproperty? key
        end
      end
    end
    hash
  end

  def get_complex_property_arg(name, value)
    args = nil

    case name
      
    when :default_documents
      (args ||= []) << @initial_properties[:default_documents].map do |doc|
        "\"/-files.[value='#{doc}']\""
      end unless @initial_properties[:default_documents].nil?

      (args ||= []) << value.map do |doc|
        "\"/+files.[@end,value='#{doc}']\""
      end

    when :mimetypes
      args = []

      current = @initial_properties[:mimetypes].to_a
  	  future = value.to_a

      to_remove = current.reject{|x| if future.include?(x); x end}
	    to_add = future.reject{|x| if current.include?(x); x end}

      (args ||= []) << Hash[*to_remove.flatten].map do |ext,type|
        "\"/-[fileextension='#{ext}']\""
      end

      (args ||= []) << Hash[*to_add.flatten].map do |ext,type|
        "\"/+[fileextension='#{ext}',mimetype='#{type.gsub(/\+/, "%2b")}']\""
      end
    end
    args
  end

  def execute_create
    # Only set is available for configs, even if the config doesn't exist yet
    execute_flush
  end

  def execute_flush
    args = Array(get_property_args)
    section, path = get_section_and_path
    commit = resource[:commit] ? resource[:commit] : "apphost"
    appcmd *(['set', self.class.iis_type(), path, "/commit:#{commit}", "/section:#{section}"] + args ) unless args.empty?
  end

  def execute_delete
    section, path = get_section_and_path
    appcmd 'clear', self.class.iis_type(), path, "/section:#{section}"
  end

  def get_section_and_path
    section = resource[:config_section] ? resource[:config_section] : resource[:name]
    path = resource[:path] ? resource[:path] : ""
    return section, path
  end

end
