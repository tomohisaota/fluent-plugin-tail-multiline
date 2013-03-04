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
format_firstline      | string(default = format)        | RegEx to detect first line of multiple line log, no name capture required
rawdata_key           | string(default = null)          | Store raw data with given key

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

