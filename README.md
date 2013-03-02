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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
