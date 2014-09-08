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

  def self.extract_item(item_xml)
    hash = {}

    item_xml.each_element("descendant-or-self::*") do |element|
      element.attributes.each do |key, attribute|
        key = "#{element.xpath}/#{key}".gsub(/\/appcmd\/[^\/]+\/([^\/]+\/)?/, "").gsub("/", "_").downcase
        if key =~ /^files_add\[\d+\]_value$/
          hash[:default_documents] || = []
          hash[:default_documents] << attribute
        else
          hash[key.to_sym] = attribute if resource_type.validproperty? key
        end
      end
    end
    hash.merge! extract_complex_properties(item_xml)
    hash
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

  def get_complex_property_arg(name, value)
    case name
    when :documents
      args = []
      @initial_properties[:documents].each do |doc|
        args << "\"/-files.[value='#{doc}']\""
      end
      value.each do |doc|
        args << "\"/+files.[@end,value='#{doc}']\""
      end
      args
    end
  end

   def execute_flush
    args = get_property_args()

    if args.is_a?(Array)
      args.each {|arg| appcmd 'set', self.class.iis_type(), "-section:#{resource[:name]}", arg}
    else
      appcmd 'set', self.class.iis_type(), "-section:#{resource[:name]}", args
    end
  end

  def execute_delete
    appcmd 'clear', self.class.iis_type(), "-section:#{resource[:name]}"
  end

end
