#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsEAN8Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random EAN-8 sans checksum
  def random_7_digit_number
    sprintf('%07d',rand(10000000))
  end

  def test_checksum_generation
    assert_equal 4, Barcode1DTools::EAN8.generate_check_digit_for('9638507')
  end

  def test_checksum_validation
    assert Barcode1DTools::EAN8.validate_check_digit_for('96385074')
  end

  def test_attr_readers
    ean = Barcode1DTools::EAN8.new('9638507', :checksum_included => false)
    assert_equal 4, ean.check_digit
    assert_equal '9638507', ean.value
    assert_equal '96385074', ean.encoded_string
    assert_equal '963', ean.number_system
    assert_equal '8507', ean.product_code
  end

  def test_checksum_error
    # proper checksum is 4
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::EAN8.new('96385070', :checksum_included => true) }
  end

  def test_value_length_errors
    # One digit too short
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.new('123456', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.new('1234567', :checksum_included => true) }
    # One digit too long
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.new('12345678', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.new('123456789', :checksum_included => true) }
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.new('thisisnotgood', :checksum_included => false) }
  end

  def test_width
    ean = Barcode1DTools::EAN8.new(random_7_digit_number)
    assert_equal 67, ean.width
  end

  def test_barcode_generation
    ean = Barcode1DTools::EAN8.new('96385074', :checksum_included => true)
    assert_equal "1010001011010111101111010110111010101001110111001010001001011100101", ean.bars

    assert_equal "1113112111414111213111111231321113121132111", ean.rle
  end

  def test_wn_raises_error
    ean = Barcode1DTools::EAN8.new(random_7_digit_number)
    assert_raise(Barcode1DTools::NotImplementedError) { ean.wn }
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.decode('x'*60) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.decode('x'*96) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.decode('x'*94) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN8.decode('111000011111000011111') }
  end

  def test_decoding
    random_ean_num=random_7_digit_number
    ean = Barcode1DTools::EAN8.new(random_ean_num)
    ean2 = Barcode1DTools::EAN8.decode(ean.bars)
    assert_equal ean.value, ean2.value
    ean3 = Barcode1DTools::EAN8.decode(ean.rle)
    assert_equal ean.value, ean3.value
    # Should also work in reverse
    ean4 = Barcode1DTools::EAN8.decode(ean.bars.reverse)
    assert_equal ean.value, ean4.value
  end
end
