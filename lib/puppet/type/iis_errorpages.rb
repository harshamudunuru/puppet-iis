Puppet::Type.newtype(:iis_errorpages) do
  @doc = "IIS Error Pages configuration"

  ensurable

  newparam(:name) do
    desc "Site, app, vdir or directory name"
  end

  newproperty(:error_pages, :array_matching => :all, :parent => Puppet::Property) do
    desc """
      Array of hashes containing list of error pages.
      Each hash must contain following keys: statusCode, path and responseMode.
      Optional keys are subStatusCode,:prefixLanguageFilePath.
      Possible values for responseMode are 'File', 'ExecuteURL' and 'Redirect'.
      Example:
        iis_errorpages {'Default Web Site/test':
          error_pages => [{statusCode => 404, prefixLanguageFilePath => '/lang/', path => '/errors/404.html', responseMode => 'ExecuteURL'},
                          {statusCode => 500, subStatusCode => 100, path => 'C:\mywebsite\err\500.100.html', responseMode => 'File'}]
        }
      """
  end
end
