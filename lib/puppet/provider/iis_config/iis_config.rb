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

  def self.prefetch(resources)
    providers = Hash[instances().map { |provider| [provider.name, provider] }]

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

  def self.extract_item(item_xml)
    hash = {}

    item_xml.each_element("descendant-or-self::*") do |element|
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
    args = nil

    case name
    when :documents
      (args ||= []) << @initial_properties[:documents].map do |doc|
        "\"/-files.[value='#{doc}']\""
      end unless @initial_properties[:documents].nil?

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

   def execute_flush
    args = Array(get_property_args())
    args.each do |arg|
      appcmd 'set', self.class.iis_type(), "/section:#{resource[:name]}", arg
    end
  end

  def execute_delete
    appcmd 'clear', self.class.iis_type(), "/section:#{resource[:name]}"
  end

end
