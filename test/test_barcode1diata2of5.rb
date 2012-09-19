#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsIATA2of5Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_iata2of5_value(len)
    (1..1+rand(len)).collect { "0123456789"[rand(10),1] }.join
  end

  def test_checksum_generation
    assert_equal 2, Barcode1DTools::IATA2of5.generate_check_digit_for('1234')
  end

  def test_checksum_validation
    assert Barcode1DTools::IATA2of5.validate_check_digit_for('12342')
  end

  def test_attr_readers
    iata2of5 = Barcode1DTools::IATA2of5.new('1234', :skip_checksum => false)
    assert_equal 2, iata2of5.check_digit
    assert_equal '1234', iata2of5.value
    assert_equal '12342', iata2of5.encoded_string
  end

  def test_checksum_error
    # proper checksum is 2
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::IATA2of5.new('12345', :checksum_included => true, :skip_checksum => false) }
  end

  def test_skip_checksum
    iata2of5 = Barcode1DTools::IATA2of5.new('1234', :skip_checksum => true)
    assert_nil iata2of5.check_digit
    assert_equal '1234', iata2of5.value
    assert_equal '1234', iata2of5.encoded_string
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::IATA2of5.new('thisisnotgood', :checksum_included => false) }
  end

  # Only need to test wn, as bars and rle are based on wn
  def test_barcode_generation
    iata2of5 = Barcode1DTools::IATA2of5.new('1234', :skip_checksum => true)
    assert_equal "nnnnwnnnnnnnwnnnwnnnnnwnwnwnnnnnnnnnnnwnnnwnwnn", iata2of5.wn
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::IATA2of5.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::IATA2of5.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::IATA2of5.decode('nnnnwwwwwwwwwwnwnn') }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::IATA2of5.decode('nwwnwnwnwnwnwnw') }
  end

  def test_decoding
    random_iata2of5_num=random_iata2of5_value(10)
    iata2of5 = Barcode1DTools::IATA2of5.new(random_iata2of5_num, :skip_checksum => true)
    iata2of52 = Barcode1DTools::IATA2of5.decode(iata2of5.wn)
    assert_equal iata2of5.value, iata2of52.value
    # Should also work in reverse
    iata2of54 = Barcode1DTools::IATA2of5.decode(iata2of5.wn.reverse)
    assert_equal iata2of5.value, iata2of54.value
  end
end
