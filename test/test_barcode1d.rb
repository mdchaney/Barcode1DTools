require 'test/unit'
require 'barcode1dtools'

class Barcode1DToolsTest < Test::Unit::TestCase
  def setup
    @options = {}
  end

  def teardown
  end

  def test_rle_to_bars
    assert_equal '111001', Barcode1DTools::Barcode1D.rle_to_bars('321', @options)
    assert_equal '10011100001', Barcode1DTools::Barcode1D.rle_to_bars('12341', @options)
  end

  def test_bars_to_rle
    assert_equal '321', Barcode1DTools::Barcode1D.bars_to_rle('111001', @options)
    assert_equal '12341', Barcode1DTools::Barcode1D.bars_to_rle('10011100001', @options)
  end

  def test_back_and_forth
    random_rle = (0..19).collect { |x| (rand * 4 + 1).to_int.to_s }.join
    random_bars = '1' + (0..99).collect { |x| (rand * 2).to_int.to_s }.join + '1'
    assert_equal random_rle, Barcode1DTools::Barcode1D.bars_to_rle(Barcode1DTools::Barcode1D.rle_to_bars(random_rle, @options), @options)
    assert_equal random_bars, Barcode1DTools::Barcode1D.rle_to_bars(Barcode1DTools::Barcode1D.bars_to_rle(random_bars, @options), @options)
  end
end
