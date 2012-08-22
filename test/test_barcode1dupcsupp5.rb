#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsUPC_Supp5Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random 2-digit number
  def random_5_digit_number
    sprintf('%05d',rand(100000))
  end

  def test_checksum_generation
    assert_equal 7, Barcode1DTools::UPC_Supplemental_5.generate_check_digit_for('53999')
  end

  def test_checksum_validation
    assert Barcode1DTools::UPC_Supplemental_5.validate_check_digit_for('539997')
  end

  def test_attr_readers
    upc_supp_5 = Barcode1DTools::UPC_Supplemental_5.new('53999', :checksum_included => false)
    assert_equal 7, upc_supp_5.check_digit
    assert_equal '53999', upc_supp_5.value
    assert_equal '539997', upc_supp_5.encoded_string
    assert_equal '5', upc_supp_5.currency_code
    assert_equal '3999', upc_supp_5.price
  end

  def test_checksum_error
    # proper checksum is 7
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::UPC_Supplemental_5.new('539990', :checksum_included => true) }
  end

  def test_value_length_errors
    # One digit too short
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.new('5399', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.new('53999', :checksum_included => true) }
    # One digit too long
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.new('539999', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.new('5399979', :checksum_included => true) }
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.new('thisisnotgood', :checksum_included => false) }
  end

  def test_width
    upc_supp_5 = Barcode1DTools::UPC_Supplemental_5.new(random_5_digit_number)
    assert_equal 47, upc_supp_5.width
  end

  def test_barcode_generation
    upc_supp_5 = Barcode1DTools::UPC_Supplemental_5.new('539997', :checksum_included => true)
    assert_equal "10110110001010100001010001011010010111010001011", upc_supp_5.bars
    assert_equal "1121231111141113112112113113112", upc_supp_5.rle
  end

  def test_wn_raises_error
    upc_supp_5 = Barcode1DTools::UPC_Supplemental_5.new(random_5_digit_number)
    assert_raise(Barcode1DTools::NotImplementedError) { upc_supp_5.wn }
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.decode('x'*60) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.decode('x'*96) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.decode('x'*94) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_5.decode('1110000111110000111110010101001') }
  end

  def test_decoding
    random_upcsupp5_num=random_5_digit_number
    upcsupp5 = Barcode1DTools::UPC_Supplemental_5.new(random_upcsupp5_num)
    upcsupp52 = Barcode1DTools::UPC_Supplemental_5.decode(upcsupp5.bars)
    assert_equal upcsupp5.value, upcsupp52.value
    upcsupp53 = Barcode1DTools::UPC_Supplemental_5.decode(upcsupp5.rle)
    assert_equal upcsupp5.value, upcsupp53.value
    # Should also work in reverse
    upcsupp54 = Barcode1DTools::UPC_Supplemental_5.decode(upcsupp5.bars.reverse)
    assert_equal upcsupp5.value, upcsupp54.value
  end
end
