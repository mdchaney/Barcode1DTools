#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsCodabarTest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random Codabar string
  def random_codabar_value
    ['A','B','C','D'][rand(4)] + (1..5+rand(10)).collect { "0123456789-$:/.+"[rand(16),1] }.join + ['A','B','C','D'][rand(4)]
  end

  def test_no_check_digit
    assert_raise(Barcode1DTools::NotImplementedError) { Barcode1DTools::Codabar.generate_check_digit_for(random_codabar_value) }
    assert_raise(Barcode1DTools::NotImplementedError) { Barcode1DTools::Codabar.validate_check_digit_for(random_codabar_value) }
  end

  def test_attr_readers
    codabar = Barcode1DTools::Codabar.new('A12345678C')
    assert_nil codabar.check_digit
    assert_equal 'A12345678C', codabar.value
    assert_equal 'A12345678C', codabar.encoded_string
    assert_equal 'A', codabar.start_character
    assert_equal 'C', codabar.stop_character
    assert_equal '12345678', codabar.payload
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Codabar.new('thisisnotgood') }
  end

  # Only need to test wn, as bars and rle are based on wn
  def test_barcode_generation
    codabar = Barcode1DTools::Codabar.new('A1B')
    assert_equal "nnwwnwnnnnnnwwnnnwnwnnw", codabar.wn
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Codabar.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Codabar.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Codabar.decode('nnnnwwwwnn') }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Codabar.decode('nwwnwnwnwnwnwnw') }
  end

  def test_decoding
    random_codabar_num=random_codabar_value
    codabar = Barcode1DTools::Codabar.new(random_codabar_num)
    codabar2 = Barcode1DTools::Codabar.decode(codabar.wn)
    assert_equal codabar.value, codabar2.value
    # Should also work in reverse
    codabar4 = Barcode1DTools::Codabar.decode(codabar.wn.reverse)
    assert_equal codabar.value, codabar4.value
  end
end
