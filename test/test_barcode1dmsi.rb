#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsMSITest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_msi_value(len)
    (1..1+rand(len)).collect { "0123456789"[rand(11),1] }.join
  end

  def test_checksum_generation
    assert_equal '4', Barcode1DTools::MSI.generate_check_digit_for('1234567', :check_digit => 'mod 10')
  end

  def test_checksum_validation
    assert Barcode1DTools::MSI.validate_check_digit_for('12345674', :check_digit => 'mod 10')
  end

  def test_attr_readers
    msi = Barcode1DTools::MSI.new('1234567', :check_digit => 'mod 10', :checksum_included => false)
    assert_equal '4', msi.check_digit
    assert_equal '1234567', msi.value
    assert_equal '12345674', msi.encoded_string
  end

  def test_checksum_error
    # proper checksum is 5
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::MSI.new('12345671', :check_digit => 'mod 10', :checksum_included => true) }
  end

  def test_skip_checksum
    msi = Barcode1DTools::MSI.new('12345', :skip_checksum => true)
    assert_nil msi.check_digit
    assert_equal '12345', msi.value
    assert_equal '12345', msi.encoded_string
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::MSI.new('thisisnotgood', :checksum_included => false) }
  end

  # Only need to test wn, as bars and rle are based on wn
  def test_barcode_generation
    msi = Barcode1DTools::MSI.new('12345674', :skip_checksum => true, :line_character => '#', :space_character => ' ')
    assert_equal "## #  #  #  ## #  #  ## #  #  #  ## ## #  ## #  #  #  ## #  ## #  ## ## #  #  ## ## ## #  ## #  #  #  #", msi.bars
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::MSI.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::MSI.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::MSI.decode('nnwwnnnnnnnnnnnwwn') }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::MSI.decode('nwwnwnwnwnwnwnw') }
  end

  def test_decoding
    random_msi_num=random_msi_value(10)
    msi = Barcode1DTools::MSI.new(random_msi_num, :skip_checksum => true)
    msi2 = Barcode1DTools::MSI.decode(msi.wn)
    assert_equal msi.value, msi2.value
    # Should also work in reverse
    msi4 = Barcode1DTools::MSI.decode(msi.wn.reverse)
    assert_equal msi.value, msi4.value
  end
end
