#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsCode11Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_code11_value(len)
    (1..1+rand(len)).collect { "0123456789-"[rand(11),1] }.join
  end

  def test_checksum_generation
    assert_equal '5', Barcode1DTools::Code11.generate_check_digit_for('123-45')
  end

  def test_checksum_validation
    assert Barcode1DTools::Code11.validate_check_digit_for('123-455')
  end

  def test_attr_readers
    code11 = Barcode1DTools::Code11.new('123-45', :checksum_included => false)
    assert_equal '5', code11.check_digit
    assert_equal '123-45', code11.value
    assert_equal '123-455', code11.encoded_string
  end

  def test_checksum_error
    # proper checksum is 5
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::Code11.new('123-451', :checksum_included => true) }
  end

  def test_skip_checksum
    code11 = Barcode1DTools::Code11.new('123-45', :skip_checksum => true)
    assert_nil code11.check_digit
    assert_equal '123-45', code11.value
    assert_equal '123-45', code11.encoded_string
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code11.new('thisisnotgood', :checksum_included => false) }
  end

  # Only need to test wn, as bars and rle are based on wn
  def test_barcode_generation
    code11 = Barcode1DTools::Code11.new('123-455', :skip_checksum => true)
    assert_equal "nnwwnnwnnnwnnwnnwnwwnnnnnnwnnnnnwnwnwnwnnnwnwnnnnnwwn", code11.wn
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code11.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code11.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code11.decode('nnwwnnnnnnnnnnnwwn') }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code11.decode('nwwnwnwnwnwnwnw') }
  end

  def test_decoding
    random_code11_num=random_code11_value(10)
    code11 = Barcode1DTools::Code11.new(random_code11_num, :skip_checksum => true)
    code112 = Barcode1DTools::Code11.decode(code11.wn)
    assert_equal code11.value, code112.value
    # Should also work in reverse
    code114 = Barcode1DTools::Code11.decode(code11.wn.reverse)
    assert_equal code11.value, code114.value
  end
end
