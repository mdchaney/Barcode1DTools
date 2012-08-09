require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsEAN13Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random EAN-13 sans checksum
  def random_12_digit_number
    (0..11).collect { |x| ((rand * 10).to_i % 10).to_s }.join
  end

  def test_checksum_generation
    assert_equal 7, Barcode1DTools::EAN13.generate_check_digit_for('007820601001')
  end

  def test_checksum_validation
    assert Barcode1DTools::EAN13.validate_check_digit_for('0884088516338')
  end

  def test_attr_readers
    ean = Barcode1DTools::EAN13.new('088408851633', :checksum_included => false)
    assert_equal 8, ean.check_digit
    assert_equal '088408851633', ean.value
    assert_equal '0884088516338', ean.encoded_string
    assert_equal '08', ean.number_system
    assert_equal '84088', ean.manufacturers_code
    assert_equal '51633', ean.product_code
  end

  def test_value_fixup
    ean = Barcode1DTools::EAN13.new('088408851633', :checksum_included => false)
    assert_equal 8, ean.check_digit
    assert_equal '088408851633', ean.value
    assert_equal '0884088516338', ean.encoded_string
  end

  def test_checksum_error
    # proper checksum is 8
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::EAN13.new('0884088516331', :checksum_included => true) }
  end

  def test_value_length_errors
    # One digit too short
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.new('01234567890', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.new('012345678901', :checksum_included => true) }
    # One digit too long
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.new('0123456789012', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.new('01234567890123', :checksum_included => true) }
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.new('thisisnotgood', :checksum_included => false) }
  end

  def test_width
    ean = Barcode1DTools::EAN13.new('0041343005796', :checksum_included => true)
    assert_equal 95, ean.width
  end

  def test_barcode_generation
    ean = Barcode1DTools::EAN13.new('0012676510226', :checksum_included => true)
    assert_equal "10100011010011001001001101011110111011010111101010100111011001101110010110110011011001010000101", ean.bars
    assert_equal "11132112221212211141312111411111123122213211212221221114111", ean.rle
  end

  def test_wn_raises_error
    ean = Barcode1DTools::EAN13.new('0012676510226', :checksum_included => true)
    assert_raise(Barcode1DTools::NotImplementedError) { ean.wn }
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.decode('x'*60) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.decode('x'*96) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.decode('x'*94) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::EAN13.decode('111000011111000011111') }
  end

  def test_decoding
    random_ean_num=random_12_digit_number
    ean = Barcode1DTools::EAN13.new(random_ean_num)
    ean2 = Barcode1DTools::EAN13.decode(ean.bars)
    assert_equal ean.value, ean2.value
    ean3 = Barcode1DTools::EAN13.decode(ean.rle)
    assert_equal ean.value, ean3.value
    # Should also work in reverse
    ean4 = Barcode1DTools::EAN13.decode(ean.bars.reverse)
    assert_equal ean.value, ean4.value
  end
end
