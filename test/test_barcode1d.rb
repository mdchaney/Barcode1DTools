require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsTest < Test::Unit::TestCase
  def setup
    @options = { :line_character => "1", :space_character => "0" }
  end

  def teardown
  end

  def test_rle_to_bars
    assert_equal '111001', Barcode1DTools::Barcode1D.rle_to_bars('321', @options)
    assert_equal '10011100001', Barcode1DTools::Barcode1D.rle_to_bars('12341', @options)
  end
end
