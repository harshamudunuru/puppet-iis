require File.join(File.dirname(__FILE__), '../iis/iis_object')

Puppet::Type.type(:iis_site).provide(:iis_site, :parent => Puppet::Provider::IISObject) do
	desc "IIS Site"

  confine     :operatingsystem => :windows
  defaultfor  :operatingsystem => :windows

  commands :appcmd => File.join(ENV['SystemRoot'] || 'c:/windows', 'system32/inetsrv/appcmd.exe')

  mk_resource_methods

  private
  def self.iis_type
    "site"
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
			command_and_args = [command(:appcmd), 'list', iis_type(), name, '/xml', '/config:*']
			command_line = command_and_args.flatten.map(&:to_s).join(" ")

			output = execute(command_and_args, :failonfail => false)
			raise Puppet::ExecutionFailure, "Execution of '#{command_line}' failed" if output.nil? or output.length == 0
			hash = extract_items(output)
			resources_list << hash unless hash.empty?
		end
		resources_list
	end

	def self.extract_items(xml)
		hash = {}

		REXML::Document.new(xml).each_element("descendant-or-self::*") do |element|
			element.attributes.each do |key, attribute|
				key = "#{element.xpath}/#{key}".gsub(/\/appcmd\/[^\/]+\/([^\/]+\/)?/, "").gsub("/", "_").downcase
				case key

				when "name"
					hash[:name] = attribute
					hash[:provider] = self.name
					hash[:ensure] = :present

				when /application.*_virtualdirectory.*_physicalpath/
					hash[:physicalpath] = attribute if (element.attributes["path"] == '/') and (element.parent.attributes["path"] == '/')

				when "bindings"
					hash[:bindings] = attribute.split(',')

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
		when :bindings
			(args ||= []) << "/bindings:#{resource[:bindings].join(',')}"
		end
		args
	end

  def get_args
		args = []
		self.class.resource_type.validproperties.each do |name|
			value = resource[name.to_sym] unless name == :ensure

			case name
			when :physicalpath
				args << "/[path='/'].[path='/'].physicalPath:#{value}"

			when :bindings
				value ||= []
				initial_value = @initial_properties[name] ||= []

				unchanged_bindings = value & initial_value
				bindings_to_add = value - unchanged_bindings
				bindings_to_remove = initial_value - unchanged_bindings

				bindings_to_add.collect do |binding|
					parts = binding.split('/', 2)
					args << "/+bindings.[protocol='#{parts[0]}',bindingInformation='#{parts[1]}']"
				end

				bindings_to_remove.collect do |binding|
					parts = binding.split('/', 2)
					args << "/-bindings.[protocol='#{parts[0]}',bindingInformation='#{parts[1]}']"
				end
			end
		end
		args
  end

	def execute_flush
		if @resource[:ensure] != :absent
			appcmd *(['set', self.class.iis_type(), resource[:name]] + get_args) unless get_args.empty?
		end
	end

end
