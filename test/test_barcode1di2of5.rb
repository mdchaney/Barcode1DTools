#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsInterleaved2of5Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_x_digit_number
    (rand*10000000000).to_int
  end

  def test_checksum_generation
    assert_equal 5, Barcode1DTools::Interleaved2of5.generate_check_digit_for(123456789)
  end

  def test_checksum_validation
    assert Barcode1DTools::Interleaved2of5.validate_check_digit_for(1234567895)
  end

  def test_attr_readers
    i2of5 = Barcode1DTools::Interleaved2of5.new(123456789, :checksum_included => false)
    assert_equal 5, i2of5.check_digit
    assert_equal 123456789, i2of5.value
    assert_equal '1234567895', i2of5.encoded_string
  end

  def test_checksum_error
    # proper checksum is 5
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::Interleaved2of5.new(1234567890, :checksum_included => true) }
  end

  def test_skip_checksum
    i2of5 = Barcode1DTools::Interleaved2of5.new(1234567890, :skip_checksum => true)
    assert_nil i2of5.check_digit
    assert_equal 1234567890, i2of5.value
    assert_equal '1234567890', i2of5.encoded_string
  end

  def test_add_leading_zero
    i2of5 = Barcode1DTools::Interleaved2of5.new(123, :skip_checksum => true)
    assert_equal '0123', i2of5.encoded_string
    i2of5 = Barcode1DTools::Interleaved2of5.new(12)
    assert_equal '0123', i2of5.encoded_string
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Interleaved2of5.new('thisisnotgood', :checksum_included => false) }
  end

  # Only need to test wn, as bars and rle are based on wn
  def test_barcode_generation
    i2of5 = Barcode1DTools::Interleaved2of5.new(602003, :skip_checksum => true)
    assert_equal "nnnnnnwnwwnwnnnnwnnwnwwnnwnwwnwnnnwnn", i2of5.wn
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Interleaved2of5.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Interleaved2of5.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Interleaved2of5.decode('nnnnwwwwnn') }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Interleaved2of5.decode('nwwnwnwnwnwnwnw') }
  end

  def test_decoding
    random_i2of5_num=random_x_digit_number
    i2of5 = Barcode1DTools::Interleaved2of5.new(random_i2of5_num, :skip_checksum => true)
    i2of52 = Barcode1DTools::Interleaved2of5.decode(i2of5.wn)
    assert_equal i2of5.value, i2of52.value
    # Should also work in reverse
    i2of54 = Barcode1DTools::Interleaved2of5.decode(i2of5.wn.reverse)
    assert_equal i2of5.value, i2of54.value
  end
end
