#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsPostNetTest < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_postnet_value(len)
    (1..len).collect { "0123456789"[rand(10),1] }.join
  end

  def test_checksum_generation
    assert_equal 5, Barcode1DTools::PostNet.generate_check_digit_for('12345')
  end

  def test_checksum_validation
    assert Barcode1DTools::PostNet.validate_check_digit_for('123455')
  end

  def test_attr_readers
    postnet = Barcode1DTools::PostNet.new('12345', :checksum_included => false)
    assert_equal 5, postnet.check_digit
    assert_equal '12345', postnet.value
    assert_equal '123455', postnet.encoded_string
  end

  def test_checksum_error
    # proper checksum is 5
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::PostNet.new('123451', :checksum_included => true) }
  end

  def test_skip_checksum
    postnet = Barcode1DTools::PostNet.new('12345', :skip_checksum => true)
    assert_nil postnet.check_digit
    assert_equal '12345', postnet.value
    assert_equal '12345', postnet.encoded_string
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::PostNet.new('thisisnotgood', :checksum_included => false) }
  end

  # Only need to test wn, as bars and rle are based on wn
  def test_barcode_generation
    postnet = Barcode1DTools::PostNet.new('555551237')
    assert_equal "wnwnwnnwnwnnwnwnnwnwnnwnwnnnnwwnnwnwnnwwnwnnnwnnwnww", postnet.wn
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::PostNet.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::PostNet.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UndecodableCharactersError) { Barcode1DTools::PostNet.decode('wnwnnnnnnnww') }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::PostNet.decode('nwwnwnwnwnwnwnw') }
  end

  def test_auto_add_checksum
    postnet = Barcode1DTools::PostNet.new(random_postnet_value(5))
    assert !postnet.check_digit.nil?
  end

  def test_auto_check_checksum
    postnet = Barcode1DTools::PostNet.new('372116')
    assert_equal 6, postnet.check_digit
    assert postnet.options[:checksum_included]
  end

  def test_decoding
    random_postnet_num=random_postnet_value(11)
    postnet = Barcode1DTools::PostNet.new(random_postnet_num)
    postnet2 = Barcode1DTools::PostNet.decode(postnet.wn)
    assert_equal postnet.value, postnet2.value
  end
end
