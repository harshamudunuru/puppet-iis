require File.join(File.dirname(__FILE__), '../iis/iis_object')

Puppet::Type.type(:iis_app).provide(:iis_app, :parent => Puppet::Provider::IISObject) do
	desc "IIS App"

  confine :operatingsystem => :windows
  defaultfor  :operatingsystem => :windows

  commands :appcmd => File.join(ENV['SystemRoot'] || 'c:/windows', 'system32/inetsrv/appcmd.exe')

  mk_resource_methods

  private
  def self.iis_type
    "app"
  end

	def self.extract_item(item_xml)
		hash = {}

		item_xml.each_element("descendant-or-self::*") do |element|
			element.attributes.each do |key, attribute|
				key = "#{element.xpath}/#{key}".gsub(/\/appcmd\/[^\/]+\/([^\/]+\/)?/, "").gsub("/", "_").downcase
				case key
				when "virtualdirectory_physicalpath" # physical path
					hash[:physicalpath] = attribute
				else
					hash[key.to_sym] = attribute if resource_type.validproperty? key
				end
			end
		end
		hash.merge! extract_complex_properties(item_xml)
		hash
	end

	def execute_flush
		if @resource[:ensure] != :absent
			args = get_property_args()
			if @resource[:physicalpath]
				appcmd *(['set', self.class.iis_type()] + get_name_args_for_set)
			else
				appcmd *(['set', self.class.iis_type()] + get_name_args_for_set_no_physical_path + args)
			end
		end
	end

  def get_name_args
    site_name, path = name.split('/', 2)
    path = "/#{path}"
    ["/site.name:#{site_name}", "/path:#{path}"]
  end

  def get_name_args_for_set
    site_name, path = name.split('/', 2)
    path = "/#{path}"
    ["/app.name:#{name}", "/[path='/'].physicalpath:#{physicalpath}", "/applicationpool:#{applicationpool}", "/enabledprotocols:#{enabledprotocols}"]
  end

  def get_name_args_for_set_no_physical_path
    site_name, path = name.split('/', 2)
    path = "/#{path}"
    ["/app.name:#{name}", "/path:#{path}"]
  end
end
