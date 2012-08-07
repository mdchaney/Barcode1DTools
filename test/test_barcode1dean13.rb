require 'test/unit'
require 'barcode1d'

class Barcode1DEAN13Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_checksum_generation
    assert_equal 7, Barcode1D::EAN13.generate_check_digit_for('007820601001')
  end

  def test_checksum_validation
    assert Barcode1D::EAN13.validate_check_digit_for('0884088516338')
  end

  def test_attr_readers
    ean = Barcode1D::EAN13.new('088408851633', :checksum_included => false)
    assert_equal 8, ean.check_digit
    assert_equal '088408851633', ean.value
    assert_equal '0884088516338', ean.encoded_string
    assert_equal '08', ean.number_system
    assert_equal '84088', ean.manufacturers_code
    assert_equal '51633', ean.product_code
  end

  def test_value_fixup
    ean = Barcode1D::EAN13.new('88408851633', :checksum_included => false)
    assert_equal 8, ean.check_digit
    assert_equal '088408851633', ean.value
    assert_equal '0884088516338', ean.encoded_string
  end

  def test_rle_to_bars
    assert_equal '111001', Barcode1D::EAN13.rle_to_bars('321')
  end

  def test_checksum_error
    # proper checksum is 8
    assert_raise(Barcode1D::ChecksumError) { Barcode1D::EAN13.new('0884088516331', :checksum_included => true) }
  end

  def test_barcode_generation
    ean = Barcode1D::EAN13.new('0012676510226', :checksum_included => true)
    assert_equal "10100011010011001001001101011110111011010111101010100111011001101110010110110011011001010000101", ean.bars
    assert_equal "11132112221212211141312111411111123122213211212221221114111", ean.rle
  end
end
