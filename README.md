# Fluent::Plugin::Tail-Multiline

Tail-Multiline plugin extends built-in tail plugin with following features
+ Support log with multiple line output such as stacktrace
+ RegEx parameter to detect first line
+ Save raw log data

**built-in templates are not supported. It does not support multiple line log anyway**

## Installation

Use ruby gem as :

    gem 'fluent-plugin-tail-multiline'

Or, if you're using td-client, you can call td-client's gem

    $ /usr/lib64/fluent/ruby/bin/gem install fluent-plugin-tail-multiline

## Base Configuration
Tail-Multiline extends [tail plugin](http://docs.fluentd.org/categories/in_tail).  

## Configuration
### Additional Parameters
 name                 | type                            | description
----------------------|---------------------------------|---------------------------
type                  | string (required)               | type of plugin should be **tail_multiline**
format_firstline      | string(default = format)        | RegEx to detect first line of multiple line log, no name capture required
rawdata_key           | string(default = null)          | Store raw data with given key
format{1..20}         | string(default = null)          | The substitute for too long `format`

## Examples
### Java log with exception
#### Input
```
2013-3-03 14:27:33 [main] INFO  Main - Start
2013-3-03 14:27:33 [main] ERROR Main - Exception
javax.management.RuntimeErrorException: null
    at Main.main(Main.java:16) ~[bin/:na]
2013-3-03 14:27:33 [main] INFO  Main - End
```
#### Parameters
```
tag test
format /^(?<time>\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}) \[(?<thread>.*)\] (?<level>[^\s]+)(?<message>.*)/
```
#### Output
```
2013-03-03 14:27:33 +0900 test: {"thread":"main","level":"INFO","message":"  Main - Start"}
2013-03-03 14:27:33 +0900 test: {"thread":"main","level":"ERROR","message":" Main - Exception\njavax.management.RuntimeErrorException: null\n\tat Main.main(Main.java:16) ~[bin/:na]"}
2013-03-03 14:27:33 +0900 test: {"thread":"main","level":"INFO","message":"  Main - End\n"}
```

### Case where first line does not have any name capture
#### Input
```
----
time=2013-3-03 14:27:33 
message=test1
----
time=2013-3-03 14:27:34
message=test2
```

#### Parameters
```
tag test
format /time=(?<time>\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}).*message=(?<message>.*)/
format_firstline /----/
```

#### Output
```
2013-03-03 14:27:33 +0900 test: {"message":"test1"}
2013-03-03 14:27:34 +0900 test: {"message":"test2"}
```

### Case where too long regexp is required
#### Input
```
Started GET "/users/" for 127.0.0.1 at 2013-06-14 12:00:04 +0900
Processing by UsersController#index as HTML
  Rendered users/index.html.erb within layouts/application (0.5ms)
Completed 200 OK in 821ms (Views: 819.5ms | ActiveRecord: 0.0ms)


Started GET "/users/123/" for 127.0.0.1 at 2013-06-14 12:00:11 +0900
Processing by UsersController#show as HTML
  Parameters: {"user_id"=>"123"}
  Rendered users/show.html.erb within layouts/application (0.3ms)
Completed 200 OK in 4ms (Views: 3.2ms | ActiveRecord: 0.0ms)
```

#### Parameters
```
tag test
format_firstline /^Started/
format /Started (?<method>[^ ]+) "(?<path>[^"]+)" for (?<host>[^ ]+) at (?<time>[^ ]+ [^ ]+ [^ ]+)\nProcessing by (?<controller>[^\u0023]+)\u0023(?<controller_method>[^ ]+) as (?<format>[^ ]+?)\n(  Parameters: (?<parameters>[^ ]+)\n)?  Rendered (?<template>[^ ]+) within (?<layout>.+) \([\d\.]+ms\)\nCompleted (?<code>[^ ]+) [^ ]+ in (?<runtime>[\d\.]+)ms \(Views: (?<view_runtime>[\d\.]+)ms \| ActiveRecord: (?<ar_runtime>[\d\.]+)ms\)/
```

It's too long format. You can rewrite above parameters with `format{1..20}`.

```
tag test
format_firstline /^Started/
format1 /Started (?<method>[^ ]+) "(?<path>[^"]+)" for (?<host>[^ ]+) at (?<time>[^ ]+ [^ ]+ [^ ]+)\n/
format2 /Processing by (?<controller>[^\u0023]+)\u0023(?<controller_method>[^ ]+) as (?<format>[^ ]+?)\n/
format3 /(  Parameters: (?<parameters>[^ ]+)\n)?/
format4 /  Rendered (?<template>[^ ]+) within (?<layout>.+) \([\d\.]+ms\)\n/
format5 /Completed (?<code>[^ ]+) [^ ]+ in (?<runtime>[\d\.]+)ms \(Views: (?<view_runtime>[\d\.]+)ms \| ActiveRecord: (?<ar_runtime>[\d\.]+)ms\)/
```

#### Output
```
2013-06-14 12:00:04 +0900 test: {"method":"GET","path":"/users/","host":"127.0.0.1","controller":"UsersController","controller_method":"index","format":"HTML","template":"users/index.html.erb","layout":"layouts/application","code":"200","runtime":"821","view_runtime":"819.5","ar_runtime":"0.0"}
2013-06-14 12:00:11 +0900 test: {"method":"GET","path":"/users/123/","host":"127.0.0.1","controller":"UsersController","controller_method":"show","format":"HTML","parameters":"{\"user_id\"=>\"123\"}","template":"users/show.html.erb","layout":"layouts/application","code":"200","runtime":"4","view_runtime":"3.2","ar_runtime":"0.0"}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

