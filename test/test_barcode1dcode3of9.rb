#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsCode3of9Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_x_character_string(x)
    num_chars = Barcode1DTools::Code3of9::CHAR_SEQUENCE.size
    (0..x-1).inject('') { |a,c| a + Barcode1DTools::Code3of9::CHAR_SEQUENCE[rand(num_chars),1] }
  end

  def random_x_character_full_ascii_string(x)
    (1..x).collect { rand(128) }.pack('C*')
  end

  def all_ascii_random_order
    arr = (0..127).to_a
    ret = []
    while arr.size > 0
      ret.push(arr.delete_at(rand(arr.size)))
    end
    ret.pack("C*")
  end

  def test_full_ascii
    random_string = random_x_character_full_ascii_string(rand(20) + 10)
    encoded1 = Barcode1DTools::Code3of9.encode_full_ascii(random_string)
    assert_equal random_string, Barcode1DTools::Code3of9.decode_full_ascii(encoded1)
    assert_equal "T+H+I+S +I+S +A +T+E+S+T/A", Barcode1DTools::Code3of9.encode_full_ascii("This is a test!")
    big_random_string = all_ascii_random_order
    assert_equal big_random_string, Barcode1DTools::Code3of9.decode_full_ascii(Barcode1DTools::Code3of9.encode_full_ascii(big_random_string))
  end

  def test_checksum_generation
    assert_equal 'I', Barcode1DTools::Code3of9.generate_check_digit_for('THIS IS A TEST')
  end

  def test_checksum_validation
    assert Barcode1DTools::Code3of9.validate_check_digit_for('THIS IS A TESTI')
  end

  def test_attr_readers
    c3of9 = Barcode1DTools::Code3of9.new('THIS IS A TEST', :skip_checksum => false)
    assert_equal 'I', c3of9.check_digit
    assert_equal 'THIS IS A TEST', c3of9.value
    assert_equal 'THIS IS A TESTI', c3of9.encoded_string
  end

  def test_checksum_error
    # proper checksum is I
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::Code3of9.new('THIS IS A TEST0', :checksum_included => true) }
  end

  def test_skip_checksum
    c3of9 = Barcode1DTools::Code3of9.new('THIS IS A TEST', :skip_checksum => true)
    assert_nil c3of9.check_digit
    assert_equal 'THIS IS A TEST', c3of9.value
    assert_equal 'THIS IS A TEST', c3of9.encoded_string
  end

  def test_bad_character_errors
    # Characters that cannot be encoded
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code3of9.new('thisisnotgood', :checksum_included => false) }
  end

  # Only need to test wn, as bars and rle are based on wn
  def test_barcode_generation
    c3of9 = Barcode1DTools::Code3of9.new('THIS IS A TEST')
    assert_equal "nwnnwnwnnnnnnnwnwwnnwnnnnwwnnnnnwnnwwnnnnnwnnnwwnnnwwnnnwnnnnnwnnwwnnnnnwnnnwwnnnwwnnnwnnnwnnnnwnnwnnwwnnnwnnnnnnnwnwwnnwnnnwwnnnnnnwnnnwwnnnnnnwnwwnnnwnnwnwnn", c3of9.wn
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code3of9.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code3of9.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code3of9.decode(Barcode1DTools::Code3of9::SIDE_GUARD_PATTERN + 'wwwwwww' + Barcode1DTools::Code3of9::SIDE_GUARD_PATTERN) }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code3of9.decode('nwwnwnwnwnwnwnw') }
  end

  def test_decoding
    random_c3of9_str=random_x_character_string(rand(10)+5)
    c3of9 = Barcode1DTools::Code3of9.new(random_c3of9_str, :skip_checksum => true)
    c3of92 = Barcode1DTools::Code3of9.decode(c3of9.wn)
    assert_equal c3of9.value, c3of92.value
    # Should also work in reverse
    c3of94 = Barcode1DTools::Code3of9.decode(c3of9.wn.reverse)
    assert_equal c3of9.value, c3of94.value
  end
end
