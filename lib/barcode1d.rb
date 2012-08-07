# Copyright 2012 Michael Chaney Consulting Corporation

# encoding: utf-8

$:.unshift(File.dirname(__FILE__))

module Barcode1D
  #= barcode1d.rb
  #
  # Barcode1D is a library for generating 1-dimensional barcode
  # patterns for various code types.  The library currently
  # includes EAN-13 and Interleaved 2 of 5 (I 2/5), but will
  # be expanded to include most 1D barcode types in the near
  # future.
  #
  #== Example
  #  ean13 = Barcode1D::EAN13.new('0012676510226', :line_character => 'x', :space_character => ' ')
  #  => #<Barcode1D::EAN13:0x10030d670 @check_digit=10, @manufacturers_code="12676", @encoded_string="001267651022610", @number_system="00", @value="0012676510226", @product_code="51022", @options={:line_character=>"1", :space_character=>"0"}>
  #  ean13.bars
  #  "x x   xx x  xx  x  x  xx x xxxx xxx xx x xxxx x x x  xxx xx  xx xxx  x xx xx  xx xx  x x    x x"
  #  ean13.rle
  #  "11132112221212211141312111411111123122213211212221221114111"

  # Errors for barcodes
  class Barcode1DError < StandardError; end
  class UnencodableError < Barcode1DError; end
  class ValueTooLongError < UnencodableError; end
  class ValueTooShortError < UnencodableError; end
  class UnencodableCharactersError < UnencodableError; end
  class ChecksumError < Barcode1DError; end
  class NotImplementedError < Barcode1DError; end

end

require 'barcode1d/interleaved2of5'
require 'barcode1d/ean13'
