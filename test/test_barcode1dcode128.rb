#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsCode128Test < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def random_x_character_full_ascii_string(x)
    (1..x).collect { rand(128) }.pack('C*')
  end

  def random_x_character_latin1_string(x)
    str=(1..x).collect { rand(256) }.pack('C*')
    if RUBY_VERSION >= "1.9"
      str.force_encoding('ISO-8859-1')
    else
      str
    end
  end

  def random_crazy_code128_value(x)
    funcs = [ :fnc_1, :fnc_2, :fnc_3, :fnc_4 ]
    (1..x).collect { |y| y.odd? ? funcs[rand(funcs.length)] : random_x_character_full_ascii_string(rand(5)+5) }
  end

  # Test encode/decode
  def test_full_ascii
    random_string = random_x_character_full_ascii_string(rand(20) + 10)
    encoded1 = Barcode1DTools::Code128.latin1_to_code128(random_string)
    assert_equal [random_string], Barcode1DTools::Code128.code128_to_latin1(encoded1)
  end

  def test_latin1
    random_string = random_x_character_latin1_string(rand(20) + 10)
    encoded1 = Barcode1DTools::Code128.latin1_to_code128(random_string)
    assert_equal [random_string], Barcode1DTools::Code128.code128_to_latin1(encoded1)
  end

  def test_crazy_code128
    random_string = random_crazy_code128_value(rand(5) + 10)
    encoded1 = Barcode1DTools::Code128.latin1_to_code128(random_string, :no_latin1 => true)
    assert_equal random_string, Barcode1DTools::Code128.code128_to_latin1(encoded1, :no_latin1 => true)
  end

  def test_attr_readers
    c128 = Barcode1DTools::Code128.new('Hello!')
    assert_equal 'Hello!', c128.value
  end

  def test_decode_error
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code128.decode('x') }
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code128.decode('x'*60) }
    # wrong start/stop
    assert_raise(Barcode1DTools::UnencodableCharactersError) { Barcode1DTools::Code128.decode('22222222222222222') }
  end

  def test_decoding
    random_c128_str=random_x_character_latin1_string(rand(10)+5)
    c128 = Barcode1DTools::Code128.new(random_c128_str)
    c1282 = Barcode1DTools::Code128.decode(c128.rle)
    assert_equal c128.value, c1282.value
    # Should also work in reverse
    c1284 = Barcode1DTools::Code128.decode(c128.rle.reverse)
    assert_equal c128.value, c1284.value
  end
end
