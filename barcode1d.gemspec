Gem::Specification.new do |s|
  s.name        = 'barcode1d'
  s.version     = '0.9.0'
  s.licenses    = ['MIT', 'GPL-2']
  s.platform    = Gem::Platform::RUBY
  s.date        = '2012-08-05'
  s.summary     = "Pattern generators for 1D barcodes"
  s.description = <<-EOF
    Barcode1D is a small library of generators for many kinds of
    1-dimensional barcodes.  Currently implemented are
    Interleaved 2 of 5 and EAN-13.  Patterns are created in
    either a simple format of 1s and 0s or as a run-length encoded
    string.  This only generates the patterns; actual display must be
    implemented by the programmer.
  EOF
  s.author      = "Michael Chaney"
  s.email       = 'mdchaney@michaelchaney.com'
  s.files       = ["lib/barcode1d.rb"]
  s.homepage    = 'http://rubygems.org/gems/barcode1d'
  s.required_ruby_version = '>= 1.8.6'
  s.files       = Dir["{lib}/**/*.rb", "LICENSE", "test"]
  s.require_path = 'lib'
  s.test_files  = Dir.glob('test/*.rb')
end
