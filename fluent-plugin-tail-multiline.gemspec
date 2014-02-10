# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-tail-multiline"
  gem.version       = "0.1.5"
  gem.authors       = ["Tomohisa Ota"]
  gem.email         = ["tomohisa.ota+github@gmail.com"]
  gem.description   = "Extend tail plugin to support log with multiple line"
  gem.summary       = gem.description
  gem.homepage      = "http://github.com/tomohisaota/fluent-plugin-tail-multiline"

  gem.files         = `git ls-files`.split($/)
  gem.files.reject! { |fn| fn.include? "doc/" }
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluentd"
  
  gem.add_development_dependency 'rake', '~> 0.9.2.2'
  gem.add_development_dependency 'rdoc', '~> 3.12'
end
