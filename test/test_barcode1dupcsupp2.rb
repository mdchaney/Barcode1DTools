#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsUPC_Supp2Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random 2-digit number
  def random_2_digit_number
    rand(100)
  end

  def test_checksum_generation
    assert_equal 3, Barcode1DTools::UPC_Supplemental_2.generate_check_digit_for('23')
  end

  def test_checksum_validation
    assert Barcode1DTools::UPC_Supplemental_2.validate_check_digit_for('233')
  end

  def test_attr_readers
    upc_supp_2 = Barcode1DTools::UPC_Supplemental_2.new('23', :checksum_included => false)
    assert_equal 3, upc_supp_2.check_digit
    assert_equal 23, upc_supp_2.value
    assert_equal '233', upc_supp_2.encoded_string
  end

  def test_checksum_error
    # proper checksum is 3
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::UPC_Supplemental_2.new('231', :checksum_included => true) }
  end

  def test_value_length_errors
    # One digit too long
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.new('233', :checksum_included => false) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.new('2333', :checksum_included => true) }
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.new('thisisnotgood', :checksum_included => false) }
  end

  def test_width
    upc_supp_2 = Barcode1DTools::UPC_Supplemental_2.new(random_2_digit_number)
    assert_equal 20, upc_supp_2.width
  end

  def test_barcode_generation
    upc_supp_2 = Barcode1DTools::UPC_Supplemental_2.new('233', :checksum_included => true)
    assert_equal "10110011011010100001", upc_supp_2.bars
    assert_equal "1122212111141", upc_supp_2.rle
  end

  def test_wn_raises_error
    upc_supp_2 = Barcode1DTools::UPC_Supplemental_2.new(random_2_digit_number)
    assert_raise(Barcode1DTools::NotImplementedError) { upc_supp_2.wn }
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.decode('x'*60) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.decode('x'*96) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.decode('x'*94) }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::UPC_Supplemental_2.decode('11100001111100001111') }
  end

  def test_decoding
    random_upcsupp2_num=random_2_digit_number
    upcsupp2 = Barcode1DTools::UPC_Supplemental_2.new(random_upcsupp2_num)
    upcsupp22 = Barcode1DTools::UPC_Supplemental_2.decode(upcsupp2.bars)
    assert_equal upcsupp2.value, upcsupp22.value
    upcsupp23 = Barcode1DTools::UPC_Supplemental_2.decode(upcsupp2.rle)
    assert_equal upcsupp2.value, upcsupp23.value
    # Should also work in reverse
    upcsupp24 = Barcode1DTools::UPC_Supplemental_2.decode(upcsupp2.bars.reverse)
    assert_equal upcsupp2.value, upcsupp24.value
  end
end
