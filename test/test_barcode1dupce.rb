#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsUPC_ETest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random UPC-E sans checksum and initial "0"
  def random_upce_number(type = rand(4))
    if type == 0
      # manufacturer # is xx000, xx100, or xx200, with a 3-digit
      # product number.  The manufacturer # is split between the
      # first two digits and the final digit.
      sprintf('%02d%03d%1d', rand(100), rand(1000), rand(3))
    elsif type == 1
      # manufacturer # is xx300, xx400, xx500, xx600, xx700, xx800,
      # or xx900, with a 2-digit item number.  The final digit is 3.
      sprintf('%02d%1d%02d3', rand(100), rand(7)+3, rand(100))
    elsif type == 2
      # manufacturer # is xxx10, xxx20, xxx30, xxx40, xxx50, xxx60,
      # xxx70, xxx80, or xxx90, with a single-digit item number.
      # The final digit is 4.
      sprintf('%03d%1d%1d4', rand(1000), rand(9)+1, rand(10))
    else
      # manufacturer # is xxxx1, xxxx2, xxxx3, xxxx4, xxxx5, xxxx6,
      # xxxx7, xxxx8, or xxxx9, and the single-digit item number
      # is between 5 and 9.
      sprintf('%04d%1d%1d', rand(10000), rand(9)+1, rand(5)+5)
    end
  end

  def test_checksum_generation
    assert_equal 3, Barcode1DTools::UPC_E.generate_check_digit_for('333333')
  end

  def test_checksum_validation
    assert Barcode1DTools::UPC_E.validate_check_digit_for('03333333')
  end

  def test_upc_a_upc_e_conversion
    assert_equal '03330000033', Barcode1DTools::UPC_E.upce_value_to_upca_value('0333333')
    upce_value_0 = '0' + random_upce_number(0)
    assert_equal upce_value_0, Barcode1DTools::UPC_E.upca_value_to_upce_value(Barcode1DTools::UPC_E.upce_value_to_upca_value(upce_value_0))
    upce_value_1 = '0' + random_upce_number(1)
    assert_equal upce_value_1, Barcode1DTools::UPC_E.upca_value_to_upce_value(Barcode1DTools::UPC_E.upce_value_to_upca_value(upce_value_1))
    upce_value_2 = '0' + random_upce_number(2)
    assert_equal upce_value_2, Barcode1DTools::UPC_E.upca_value_to_upce_value(Barcode1DTools::UPC_E.upce_value_to_upca_value(upce_value_2))
    upce_value_3 = '0' + random_upce_number(3)
    assert_equal upce_value_3, Barcode1DTools::UPC_E.upca_value_to_upce_value(Barcode1DTools::UPC_E.upce_value_to_upca_value(upce_value_3))
  end

  def test_attr_readers
    upc_e = Barcode1DTools::UPC_E.new('333333', :checksum_included => false)
    assert_equal 3, upc_e.check_digit
    assert_equal '333333', upc_e.value
    assert_equal '3333333', upc_e.encoded_string
    assert_equal '0', upc_e.number_system
    assert_equal '33300', upc_e.manufacturers_code
    assert_equal '00033', upc_e.product_code
    assert_equal '03330000033', upc_e.upca_value
  end

  def test_checksum_error
    # proper checksum is 3
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::UPC_E.new('3333331', :checksum_included => true) }
  end

  def test_value_length_errors
    # One digit too short
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.new('33333', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.new('333333', :checksum_included => true) }
    # One digit too long
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.new('03333333', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.new('033333332', :checksum_included => true) }
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.new('thisisnotgood', :checksum_included => false) }
  end

  def test_width
    upc_e = Barcode1DTools::UPC_E.new(random_upce_number)
    assert_equal 51, upc_e.width
  end

  def test_barcode_generation
    upc_e = Barcode1DTools::UPC_E.new('01245714', :checksum_included => true)
    assert_equal "101011001100100110011101011100101110110011001010101", upc_e.bars
    assert_equal "111122221222311132113122221111111", upc_e.rle
  end

  def test_wn_raises_error
    upc_e = Barcode1DTools::UPC_E.new(random_upce_number)
    assert_raise(Barcode1DTools::NotImplementedError) { upc_e.wn }
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.decode('x'*60) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.decode('x'*96) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.decode('x'*94) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_E.decode('111000011111000011111') }
  end

  def test_decoding
    random_upce_num=random_upce_number
    upce = Barcode1DTools::UPC_E.new('0'+random_upce_num)
    upce2 = Barcode1DTools::UPC_E.decode(upce.bars)
    assert_equal upce.value, upce2.value
    upce3 = Barcode1DTools::UPC_E.decode(upce.rle)
    assert_equal upce.value, upce3.value
    # Should also work in reverse
    upce4 = Barcode1DTools::UPC_E.decode(upce.bars.reverse)
    assert_equal upce.value, upce4.value
  end
end
