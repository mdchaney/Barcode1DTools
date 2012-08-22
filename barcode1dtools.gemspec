Gem::Specification.new do |s|
  s.name        = 'barcode1dtools'
  s.version     = '0.9.2'
  s.licenses    = ['MIT', 'GPL-2']
  s.platform    = Gem::Platform::RUBY
  s.date        = '2012-08-05'
  s.summary     = "Pattern generators for 1D barcodes"
  s.description = <<-EOF
    Barcode1D is a small library of generators for many kinds of
    1-dimensional barcodes.  Currently implemented are
    Interleaved 2 of 5, EAN-13, and UPC-A.  Patterns are created in
    either a simple format of 1s and 0s or as a run-length encoded
    string.  This only generates the patterns; actual display must be
    implemented by the programmer.
  EOF
  s.author      = "Michael Chaney"
  s.email       = 'mdchaney@michaelchaney.com'
  s.homepage    = 'http://rubygems.org/gems/barcode1dtools'
  s.required_ruby_version = '>= 1.8.6'
  s.files       = Dir["{lib}/**/*.rb", "MIT-LICENSE", "GPLv2", "test"]
  s.require_path = 'lib'
  s.test_files  = Dir.glob('test/*.rb')
end
