require File.join(File.dirname(__FILE__), '../iis/iis_object')

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

  def self.extract_items(items_xml)
    items = []

    REXML::Document.new(items_xml).each_element("/appcmd/#{iis_type().upcase}") do |item_xml|
      hash = extract_item(item_xml.elements[1])

      hash[:name] = item_xml.attributes["CONFIG.SECTION"]
      hash[:provider] = self.name
      hash[:ensure] = :present
      items << hash
    end

    items
  end

   def execute_flush
    args = get_property_args()
    appcmd *(['set', self.class.iis_type(), "-section:#{resource[:name]}"] + args) if args.length > 0
  end
end
