# Barcode1DTools is a library for generating and decoding
# 1-dimensional barcode patterns for various code types.  The
# library currently includes EAN-13, EAN-8, UPC-A, UPC-E, UPC
# Supplemental 2, UPC Supplemental 5, Interleaved 2 of 5 (I 2/5),
# COOP 2 of 5, Matrix 2 of 5, Industrial 2 of 5, IATA 2 of 5,
# PostNet, Plessey, MSI (Modified Plessey), Code 3 of 9, Code 93,
# Code 11, Code 128, and Codabar.
#
# Contact Michael Chaney Consulting Corporation for commercial
# support for this code: sales@michaelchaney.com
#
# Author::    Michael Chaney (mdchaney@michaelchaney.com)
# Copyright:: Copyright (c) 2012 Michael Chaney Consulting Corporation
# License::   Diestributed under the terms of the MIT License of the GNU General Public License v. 2
#
# == Example
#  ean13 = Barcode1DTools::EAN13.new('0012676510226', :line_character => 'x', :space_character => ' ')
#  => #<Barcode1DTools::EAN13:0x10030d670 @check_digit=10, @manufacturers_code="12676", @encoded_string="001267651022610", @number_system="00", @value="0012676510226", @product_code="51022", @options={:line_character=>"1", :space_character=>"0"}>
#  ean13.bars
#  "x x   xx x  xx  x  x  xx x xxxx xxx xx x xxxx x x x  xxx xx  xx xxx  x xx xx  xx xx  x x    x x"
#  ean13.rle
#  "11132112221212211141312111411111123122213211212221221114111"
#  another_ean = EAN.decode(ean13.rle)
#
# Note that the Barcode1D objects are immutable.
#
# == Barcode Symbology Overview
#
# There are two broad families of barcodes: 1-dimensional (also
# "1D" or "linear") and 2-dimensional ("2D").  Nowadays, 2D
# barcodes are desired for a variety of reasons:
#
# * They have the ability to store vastly more information
#   in the same space as most 1D barcodes
# * They use error correction - typically Reed-Solomon
#   interleaving - to allow even a damaged code to be read.
# * Modern technology (cheap CCD cameras particularly) has made
#   it easy to read them.
#
# Despite the advantages of 2D symbologies, 1D barcodes are
# still in wide use and likely will never go out of use.
#
# * There is still a huge installed base of dedicated scanners
#   and hardware for dealing with 1D barcodes.
# * They are easier to read at a really long distance.
# * There's also a huge installed base of software that can
#   generate such codes.
# * They encode enough information to be very useful.
#
# Within the 1D symbologies, there are some different
# classifications:
#
# 1. Continuous and Discrete - Any modern symbology is
#    "continuous", which simply means that every bar and space -
#    including inter-character spaces - are used to encode
#    information.  Discrete symbologies typically have characters
#    that begin and end with a bar and have a narrow space between
#    the characters.
#
# 2. Wide/Narrow (or "Two-width") and Many-width - Most modern
#    symbologies are "many-width", meaning that the width of
#    the bars and spaces has more than two varieties.  The best
#    symbologies - EAN/UPC and Code 128, use 4 widths for the
#    bars and spaces to encode information.  Many older
#    symbologies use simply 2 widths (the "2 of 5" family, for
#    instance, has 2 wide elements and 5 narrow elements for
#    each character).
#
# 3. Self-checking - Self-checking symbologies will cause a
#    mis-read if any single bar is misinterpreted.  In other
#    words, a single bar that is "wrong" can not cause the
#    character to be interpreted as another.
#
# 4. Interleaved - Interleaved 2 of 5 is probably the best
#    example - two characters are interleaved together with
#    one coded as bars and the other as spaces.
#
# 5. Check digit - Most symbologies include a check digit that
#    is generated based on the payload, although some, such as
#    Code 128, actually generate the check digit based on the
#    encoded information.  Additionally, some symbologies have
#    two check digits and some have multiple algorithms for
#    generating the digit or digits.
#
# Additionally, different symbologies encode a different
# subset of characters.  Some encode only digits, others encode
# digits plus a few symbols, some uppercase letters as well as
# digits and a few symbols, and some the full range of
# characters.  The symbology that you choose for a given
# application should take into account what information you
# need to store and how to best store it.
#
# There are some excellent 2D barcode gems for Ruby that cover
# some of the more popular symbologies (QR Code is currently
# the most popular).  This gem covers almost all 1D symbologies
# ever developed, and definitely all the most popular.
# 
# == Standard Options
#
# When creating a barcode, there are a number of options available:
#
# 1. checksum_included - The checksum is included in the value
#    and does not need to be generated.  This checksum will be
#    validated and an error raised if it is not proper.
#
# 2. skip_checksum - Do not include a checksum if it is optional.
#    This option is not applicable to most barcode types and
#    will be ignored unless it is applicable.
#
# 3. line_character, space_character - when generating a bar
#    pattern, determines the characters which will represent bars
#    and spaces in the pattern.  These default to "1" for lines and
#    "0" for spaces.
#
# 4. w_character, n_character - When generating a w/n pattern,
#    determines the characters to be used for wide and narrow
#    bars and spaces.  Defaults to "w" and "n".  Not applicable to
#    all barcode types.
#
# == Standard Object Accessors
#
# 1. Barcode1D#value - The actual value of the payload.  If there
#    is a checksum, it is not part of the value.  This may be a
#    string or an integer depending on the type of barcode.
#
# 2. Barcode1D#check_digit - The checksum digit (or digits).
#    This is usually an integer.
#
# 3. Barcode1D#encoded_string - The entire literal value that is
#    encoded, including check digit(s) and start/stop characters
#    for some symbologies.
#
# 4. Barcode1D#options - The options passed to the initializer.
#
# == Standard Object Methods
#
# 1. Barcode1D#width - The unit width of the entire barcode.
#    This is a summation of all of the digits in the rle string
#    (see below) and is the basis for determining an absolute
#    width for each particular element.
#
# 2. Barcode1D#rle - RLE (run-length encoded) is the base format
#    for many barcode symbologies.  This string is a series of
#    digits from 1 through 4 (depending on the symbology) that
#    encodes the relative width of each bar and space.  The first
#    and last digits are always bars and there must always be an
#    odd number of digits.
#
# 3. Barcode1D#wn - A wide/narrow representation is the base
#    format for most symbologies that don't have an rle string
#    as their base format.  This is also known as a "two-width"
#    code.  The "2 of 5" family of codes and Code 39 are
#    examples of wide/narrow codes.  In this code the bars and
#    spaces are either "wide" or "narrow", with "wide"
#    typically being 2 or 3 times the width of "narrow".  In
#    practice, then, this is similar to an rle string of 1s and
#    2s or 1s and 3s.  These objects all have an option of
#    "wn_ratio" that lets you set the ratio yourself, with a
#    default of "2".
#
# 4. Barcode1D#bars - A simple string of 1s and 0s (or whatever
#    characters were set by options) that represents the bars
#    (1s) and spaces (0s) of the barcode.  The length of this
#    string represents the unit width of the code.  Generally
#    speaking this is good for debugging but more difficult to
#    render than the rle representation.
module Barcode1DTools

  # Errors for barcodes
  class Barcode1DError < StandardError; end
  class UnencodableError < Barcode1DError; end
  class ValueTooLongError < UnencodableError; end
  class ValueTooShortError < UnencodableError; end
  class UnencodableCharactersError < UnencodableError; end
  class ChecksumError < Barcode1DError; end
  class NotImplementedError < Barcode1DError; end
  class UndecodableCharactersError < Barcode1DError; end

  # Base class for all barcode classes.
  class Barcode1D

    # The value that is encoded
    attr_reader :value
    # The check digit(s), if any - may be nil
    attr_reader :check_digit
    # The actual string that is encoded, including check digits
    attr_reader :encoded_string
    # Options, including defaults and those explicitly set
    attr_reader :options

    class << self

      # Generate bar pattern string from rle string
      def rle_to_bars(rle_str, options = {})
        str=0
        rle_str.split('').inject('') { |a,c| str = 1 - str; a + (str.to_s * c.to_i) }.tr('01', bar_pair(options))
      end

      # Generate rle pattern from bar string
      def bars_to_rle(bar_str, options = {})
        bar_str.scan(/(.)(\1*)/).collect { |char,rest| 1+rest.length }.join
      end

      # Generate rle pattern from wn string
      def wn_to_rle(wn_str, options = {})
        wn_str.tr(wn_pair(options), (options[:wn_ratio] || 2).to_s + '1')
      end

      # Generate wn pattern from rle string
      def rle_to_wn(rle_str, options = {})
        rle_str.tr('123456789', 'nwwwwwwww').tr('wn', wn_pair(options))
      end

      # Get an "wn" pair from the options
      def wn_pair(options = {})
        (options[:w_character] || 'w') + (options[:n_character] || 'n')
      end

      # Get a bar pair from the options
      def bar_pair(options = {})
        (options[:space_character] || '0').to_s + (options[:line_character] || '1').to_s
      end
    end
  end
end

$:.unshift(File.dirname(__FILE__))
require 'barcode1dtools/interleaved2of5'
require 'barcode1dtools/ean13'
require 'barcode1dtools/ean8'
require 'barcode1dtools/upc_a'
require 'barcode1dtools/upc_e'
require 'barcode1dtools/upc_supplemental_2'
require 'barcode1dtools/upc_supplemental_5'
require 'barcode1dtools/code3of9'
require 'barcode1dtools/code93'
require 'barcode1dtools/codabar'
require 'barcode1dtools/code11'
require 'barcode1dtools/coop2of5'
require 'barcode1dtools/industrial2of5'
require 'barcode1dtools/iata2of5'
require 'barcode1dtools/matrix2of5'
require 'barcode1dtools/postnet'
require 'barcode1dtools/plessey'
require 'barcode1dtools/msi'
require 'barcode1dtools/code128'
