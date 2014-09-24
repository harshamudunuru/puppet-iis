puppet-iis
==========

Puppet module for configuring IIS.  Currently it can configure app pools, sites, applications, virtual directories, settings and custom error pages.

The module is available from: http://forge.puppetlabs.com/mirdhyn/iis

## Pre-requisites

- Windows
- IIS installed (use [opentable/windowsfeature](https://forge.puppetlabs.com/opentable/windowsfeature) for that matter)

The module works with IIS 7 and 7.5.  It does not work with IIS 6 or earlier as those versions of IIS did not include the appcmd tool.

## Example Usage
```puppet

      windowsfeature { 'Web-Server':
        installsubfeatures => true
      }

      file {'c:/puppet_iis_demo':
        ensure          => directory,
      }

      file {'c:/puppet_iis_demo/default.aspx':
        content         =>
'<%@ Page Language="C#" %>
<!DOCTYPE html>
<html>
<head>
    <title>Managed by Puppet</title>
</head>
<body>
    <h1>Managed by Puppet</h1>

    <strong>Time:</strong> <%= DateTime.UtcNow.ToString("s") + "Z" %>
</body>
</html>'
      }

      iis_apppool {'PuppetIisDemo':
        ensure                => present,
        managedpipelinemode   => 'Integrated',
        managedruntimeversion => 'v2.0',
      }

      iis_site {'PuppetIisDemo':
        ensure          => present,
        bindings        => ["http/*:25999:"],
      }

      iis_app {'PuppetIisDemo/':
        ensure          => present,
        applicationpool => 'PuppetIisDemo',
      }

      iis_vdir {'PuppetIisDemo/':
        ensure          => present,
        iis_app         => 'PuppetIisDemo/',
        physicalpath    => 'c:\puppet_iis_demo'
      }

      iis_config { 'system.webServer/caching':
        enabled           => true,
        enablekernelcache => true
      }

        iis_config { 'system.webServer/asp':
        cache_maxdisktemplatecachefiles => 4000,
        cache_scriptfilecachesize       => 4500,
        cache_scriptenginecachemax      => 1000,
        limits_processorthreadmax       => 100
      }

      iis_errorpages {'PuppetIisDemo/':
        error_pages => [{ statusCode   => 404,
                          path         => '/err/404.asp',
                          responseMode => 'ExecuteURL' },
                        { statusCode    => 500,
                          subStatusCode => 100,
                          path          => '/err/500.100.asp',
                          responseMode  => 'ExecuteURL'}]
      }
```


## Testing
TODO

## Tested on:
- Windows 7 64bit
- Windows Server 2008 R2 64bit.  

If using the rake build scipt, you need to use Ruby >= 1.9.2
