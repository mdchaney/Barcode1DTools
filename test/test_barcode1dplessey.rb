#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsPlesseyTest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_plessey_value(len)
    rand(10**len).to_s
  end

  def test_attr_readers
    plessey = Barcode1DTools::Plessey.new('12345')
    assert_nil plessey.check_digit
    assert_equal '12345', plessey.value
    assert_equal '12345', plessey.encoded_string
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Plessey.new('thisisnotgood', :checksum_included => false) }
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Plessey.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Plessey.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Plessey.decode('nnwwnnnnnnnnnnnwwn') }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Plessey.decode('nwwnwnwnwnwnwnw') }
  end

  def test_decoding
    random_plessey_num=random_plessey_value(10)
    plessey = Barcode1DTools::Plessey.new(random_plessey_num)
    plessey2 = Barcode1DTools::Plessey.decode(plessey.wn)
    assert_equal plessey.value, plessey2.value
    # Should also work in reverse
    plessey4 = Barcode1DTools::Plessey.decode(plessey.wn.reverse)
    assert_equal plessey.value, plessey4.value
  end
end
