Gem::Specification.new do |s|
  s.name        = 'barcode1dtools'
  s.version     = '1.0.0.0'
  s.licenses    = ['MIT', 'GPL-2']
  s.platform    = Gem::Platform::RUBY
  s.date        = '2012-09-27'
  s.summary     = "Pattern generators for 1D barcodes"
  s.description = <<-EOF
	 Barcode1D is a small library for handling many kinds of
	 1-dimensional barcodes.  Currently implemented are Code 128, Code 3
	 of 9, Code 93, Code 11, Codabar, Interleaved 2 of 5, COOP 2 of 5,
	 Matrix 2 of 5, Industrial 2 of 5, IATA 2 of 5, PostNet, Plessey, MSI
	 (Modified Plessey), EAN-13, EAN-8, UPC-A, UPC-E, UPC Supplemental 2,
	 and UPC Supplemental 5.  Patterns are created in either a simple
	 format of bars and spaces or as a run-length encoded string.  This
	 only generates and decodes the patterns; actual display or reading
	 from a device must be implemented by the programmer.
  EOF
  s.author      = "Michael Chaney"
  s.email       = 'mdchaney@michaelchaney.com'
  s.homepage    = 'http://rubygems.org/gems/barcode1dtools'
  s.required_ruby_version = '>= 1.8.6'
  s.files       = Dir["{lib}/**/*.rb", "MIT-LICENSE", "GPLv2", "test"]
  s.require_path = 'lib'
  s.test_files  = Dir.glob('test/*.rb')
end
