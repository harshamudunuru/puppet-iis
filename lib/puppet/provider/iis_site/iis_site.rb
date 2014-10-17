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

	def self.extract_item(item_xml)
		hash = {}

		item_xml.each_element("descendant-or-self::*") do |element|
			element.attributes.each do |key, attribute|
				key = "#{element.xpath}/#{key}".gsub(/\/appcmd\/[^\/]+\/([^\/]+\/)?/, "").gsub("/", "_").downcase
				case key
				when "application_virtualdirectory_physicalpath" # physical path
					hash[:physicalpath] = attribute
				else
					hash[key.to_sym] = attribute if resource_type.validproperty? key
				end
			end
		end
		hash.merge! extract_complex_properties(item_xml)
		hash
	end

  def self.extract_complex_properties(item_xml)
    bindings = []

    item_xml.each_element("bindings/binding") do |binding_xml|
      bindings << "#{binding_xml.attributes["protocol"]}/#{binding_xml.attributes["bindingInformation"]}"
    end

    { :bindings => bindings }
  end

	def get_complex_property_arg(name, value)
		args = nil
		case name
		when :bindings
			(args ||= []) << "/bindings:#{resource[:bindings].join(',')}"
		end
		args
	end

  def get_flush_args
		args = []
		self.class.resource_type.validproperties.each do |name|
			value = resource[name.to_sym] unless name == :ensure

			case name
			when :physicalpath
				args << "/[path='/'].[path='/'].physicalPath:#{value}"

			when :bindings
				value ||= []
				initial_value = @initial_properties[name] || []

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

	def execute_create
		appcmd *(['add', self.class.iis_type()] + get_name_arg + get_property_args)
	end

	def execute_flush
		if @resource[:ensure] != :absent
			appcmd *(['set', self.class.iis_type(), resource[:name]] + get_flush_args) unless get_flush_args.empty?
		end
	end

	def get_name_arg
		["/site.name:#{resource[:name]}"]
	end

end
