# Fluent::Plugin::Tail-Multiline

Tail-Multiline plugin extends built-in tail plugin with following features
+ Additional RegEx parameter to detect first line
+ Option to save raw data

## Installation

Use ruby gem as :

    gem 'fluent-plugin-tail-multiline'

Or, if you're using td-client, you can call td-client's gem

    $ /usr/lib64/fluent/ruby/bin/gem install fluent-plugin-tail-multiline

## Base Configuration
Tail-Multiline extends [tail plugin](http://docs.fluentd.org/categories/in_tail).

## Configuration
### Parameters
 name                 | type                            | description
----------------------|---------------------------------|---------------------------
format_firstline      | string(default = format)        | RegEx to detect first line of multiple line log
rawdata_key           | string(default = null)          | Store raw data with given key

# Fluent::Plugin::Tail-Multiline

Tail-Multiline plugin extends built-in tail plugin with following features
+ Additional RegEx parameter to detect first line
+ Option to save raw data

## Installation

Use ruby gem as :

    gem 'fluent-plugin-tail-multiline'

Or, if you're using td-client, you can call td-client's gem

    $ /usr/lib64/fluent/ruby/bin/gem install fluent-plugin-tail-multiline

## Base Configuration
Tail-Multiline extends [tail plugin](http://docs.fluentd.org/categories/in_tail).

## Configuration
### Parameters
 name                 | type                            | description
----------------------|---------------------------------|---------------------------
format_firstline      | string(default = format)        | RegEx to detect first line of multiple line log
rawdata_key           | string(default = null)          | Store raw data with given key


## Examples
### Save rawdata of apache log
#### Input
```
127.0.0.1 - - [03/Mar/2013:23:01:45 +0900] "GET / HTTP/1.1" 200 460 "-" "curl/7.22.0 (x86_64-pc-linux-gnu) libcurl/7.22.0 OpenSSL/1.0.1 zlib/1.2.3.4 libidn/1.23 librtmp/2.3"
```
#### Options
Specify rawdata_key option
```
tag test
format apache2
rawdata_key rawdata
```
#### Output
```
test: {"host":"127.0.0.1","user":null,"method":"GET","path":"/","code":200,"size":460,"referer":null,"agent":"curl/7.22.0 (x86_64-pc-linux-gnu) libcurl/7.22.0 OpenSSL/1.0.1 zlib/1.2.3.4 libidn/1.23 librtmp/2.3","rawdata":"127.0.0.1 - - [03/Mar/2013:23:01:45 +0900] \"GET / HTTP/1.1\" 200 460 \"-\" \"curl/7.22.0 (x86_64-pc-linux-gnu) libcurl/7.22.0 OpenSSL/1.0.1 zlib/1.2.3.4 libidn/1.23 librtmp/2.3\""}
```

### Java log with exception
#### Input
```
2013-3-03 14:27:33 [main] INFO  Main - Start
2013-3-03 14:27:33 [main] ERROR Main - Exception
javax.management.RuntimeErrorException: null
    at Main.main(Main.java:16) ~[bin/:na]
2013-3-03 14:27:33 [main] INFO  Main - End
```
#### Options
```
tag test
format /^(?<time>\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}) \[(?<thread>.*)\] (?<level>[^\s]+)(?<message>.*)/
format_firstline /^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2} /
rawdata_key rawdata
```
Note : format_firstline is not necessary for this case
#### Output
```
2013-03-03 14:27:33 +0900 test: {"thread":"main","level":"INFO","message":"  Main - Start","rawdata":"2013-3-03 14:27:33 [main] INFO  Main - Start"}
2013-03-03 14:27:33 +0900 test: {"thread":"main","level":"ERROR","message":" Main - Exception","rawdata":"2013-3-03 14:27:33 [main] ERROR Main - Exception\njavax.management.RuntimeErrorException: null\n\tat Main.main(Main.java:16) ~[bin/:na]"}
2013-03-03 14:27:33 +0900 test: {"thread":"main","level":"INFO","message":"  Main - End","rawdata":"2013-3-03 14:27:33 [main] INFO  Main - End\n"}
```
Stacktrace is preserved in rawdata

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
