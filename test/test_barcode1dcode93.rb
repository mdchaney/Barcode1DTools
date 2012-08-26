#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsCode93Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  # Creates a random number from 1 to 10 digits long
  def random_x_character_string(x)
    num_chars = Barcode1DTools::Code93::CHAR_SEQUENCE.size - 4
    (0..x-1).inject('') { |a,c| a + Barcode1DTools::Code93::CHAR_SEQUENCE[rand(num_chars),1] }
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
    encoded1 = Barcode1DTools::Code93.encode_full_ascii(random_string)
    assert_equal random_string, Barcode1DTools::Code93.decode_full_ascii(encoded1)
    big_random_string = all_ascii_random_order
    assert_equal big_random_string, Barcode1DTools::Code93.decode_full_ascii(Barcode1DTools::Code93.encode_full_ascii(big_random_string))
  end

  def test_checksum_generation
    assert_equal '6$', Barcode1DTools::Code93.generate_check_digit_for('WIKIPEDIA')
  end

  def test_checksum_validation
    assert Barcode1DTools::Code93.validate_check_digit_for('WIKIPEDIA6$')
  end

  def test_attr_readers
    c3of9 = Barcode1DTools::Code93.new('WIKIPEDIA')
    assert_equal '6$', c3of9.check_digit
    assert_equal 'WIKIPEDIA', c3of9.value
    assert_equal 'WIKIPEDIA6$', c3of9.encoded_string
  end

  def test_checksum_error
    # proper checksum is 6$
    assert_raise(Barcode1DTools::ChecksumError) { Barcode1DTools::Code93.new('WIKIPEDIA$$', :checksum_included => true) }
  end

  # Test promotion to full ascii
  def test_promotion_to_full_ascii
    assert Barcode1DTools::Code93.requires_full_ascii?('This is a test')
    assert !Barcode1DTools::Code93.requires_full_ascii?('THIS IS A TEST')
    assert Barcode1DTools::Code93.new('This is a test').full_ascii
    assert !Barcode1DTools::Code93.new('THIS IS A TEST').full_ascii
  end

  # Test force promotion to full ascii
  def test_force_promotion_to_full_ascii
    bc = Barcode1DTools::Code93.new('THIS IS A TEST!', :force_full_ascii => true)
    assert bc.full_ascii
    assert_equal 'THIS IS A TEST' + Barcode1DTools::Code93::FULL_ASCII_LOOKUP['!'.bytes.first], bc.full_ascii_value
  end

  # Only need to test rle
  def test_barcode_generation
    c3of9 = Barcode1DTools::Code93.new('WIKIPEDIA')
    assert_equal "1111411121221123111321111123111311212212112211121123112111131213113211111111411", c3of9.rle
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code93.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code93.decode('x'*60) }
    # proper start & stop, but crap in middle
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code93.decode(Barcode1DTools::Code93::LEFT_GUARD_PATTERN_RLE + '11111' + Barcode1DTools::Code93::RIGHT_GUARD_PATTERN_RLE) }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code93.decode('22222222222222222') }
  end

  def test_decoding
    random_c3of9_str=random_x_character_string(rand(10)+5)
    c3of9 = Barcode1DTools::Code93.new(random_c3of9_str)
    c3of92 = Barcode1DTools::Code93.decode(c3of9.rle)
    assert_equal c3of9.value, c3of92.value
    # Should also work in reverse
    c3of94 = Barcode1DTools::Code93.decode(c3of9.rle.reverse)
    assert_equal c3of9.value, c3of94.value
  end
end
