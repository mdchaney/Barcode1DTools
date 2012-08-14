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
    random_wn = (0..19).collect { |x| rand < 0.5 ? 'w' : 'n' }.join
    assert_equal random_rle, Barcode1DTools::Barcode1D.bars_to_rle(Barcode1DTools::Barcode1D.rle_to_bars(random_rle, @options), @options)
    assert_equal random_bars, Barcode1DTools::Barcode1D.rle_to_bars(Barcode1DTools::Barcode1D.bars_to_rle(random_bars, @options), @options)
    assert_equal random_wn, Barcode1DTools::Barcode1D.rle_to_wn(Barcode1DTools::Barcode1D.wn_to_rle(random_wn, @options), @options)
  end

  def test_bar_pair
    assert_equal '01', Barcode1DTools::Barcode1D.bar_pair
    assert_equal '56', Barcode1DTools::Barcode1D.bar_pair({ :space_character => 5, :line_character => 6 })
  end

  def test_wn_to_rle
    assert_equal '12121211', Barcode1DTools::Barcode1D.wn_to_rle('nwnwnwnn')
  end

  def test_rle_to_wn
    assert_equal 'wnwnwnww', Barcode1DTools::Barcode1D.rle_to_wn('21212122')
    assert_equal 'wnwnwnww', Barcode1DTools::Barcode1D.rle_to_wn('31313133')
  end

  def test_wn_pair
    assert_equal 'wn', Barcode1DTools::Barcode1D.wn_pair
    assert_equal '65', Barcode1DTools::Barcode1D.wn_pair({ :n_character => '5', :w_character => '6' })
  end
end
