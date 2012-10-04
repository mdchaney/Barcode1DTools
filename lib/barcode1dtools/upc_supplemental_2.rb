#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'barcode1dtools/upc_a'

module Barcode1DTools

  # Barcode1DTools::UPC_Supplemental_2 - Create pattern for UPC
  # Supplemental 2 barcodes.  The value encoded is an 2-digit
  # integer, and a checksum digit will be added.  You can add the
  # option :checksum_included => true when initializing to
  # specify that you have already included a checksum.
  #
  # == Example
  #  num = '24'
  #  bc = Barcode1DTools::UPC_Supplemental_2.new(num)
  #  pattern = bc.bars
  #  rle_pattern = bc.rle
  #  width = bc.width
  #  check_digit = Barcode1DTools::UPC_E.generate_check_digit_for(num)
  #
  # == Other Information
  # This type of barcode consists of 2 digits, and a check digit
  # (simply a modulus 4 of the number encoded) that is encoded in
  # the "parity" of the two barcode digits.  The bar patterns are the
  # same as the left half of a standard UPC-A.
  #
  # The 2-digit supplement is generally used on periodicals as an
  # "issue number", so that the UPC-A code may remain the same
  # across issues.  The two are scanned together, and typically the
  # scanner will return the two digits of the supplemental barcode
  # immediately following the check digit from the main UPC-A.  You
  # will likely need to use the Barcode::UPC_A module in addition
  # to this one to create the full code.
  #
  # == Formats
  # There are two formats for the returned pattern (wn format is
  # not available):
  #
  # *bars* - 1s and 0s specifying black lines and white spaces.  Actual
  # characters can be changed from "1" and 0" with options
  # :line_character and :space_character.
  #
  # *rle* - Run-length-encoded version of the pattern.  The first
  # number is always a black line, with subsequent digits
  # alternating between spaces and lines.  The digits specify
  # the width of each line or space.
  #
  # The "width" method will tell you the total end-to-end width, in
  # units, of the entire barcode.
  #
  # Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "w/n" format for
  # EAN & UPC style barcodes because the bars and spaces are variable width from
  # 1 to 4 units.
  # 
  # == Rendering
  #
  # The 2-digit supplement is positioned to the right of the main UPC
  # code, and the human-readable digits are usually printed above the
  # supplemental barcode.  UPC-A is generally rendered at one inch
  # across, then there's a 1/8th inch gap, then the supplemental.  A
  # UPC-A is 95 units wide, so the gap is 24 units wide.  The
  # supplemental barcode is 20 units wide.  The author hasn't viewed
  # the specification, but note that the UPC (and more generally EAN)
  # barcode system never a bar or space of more than four units
  # width.  Given that, the gap should likely be at last 10 units
  # wide.

  class UPC_Supplemental_2 < Barcode1D

    # The bar patterns are the left bar patterns of UPC-A/EAN-13
    LEFT_PATTERNS = UPC_A::LEFT_PATTERNS
    # The rle bar patterns are the left bar patterns of UPC-A/EAN-13
    LEFT_PATTERNS_RLE = UPC_A::LEFT_PATTERNS_RLE

    # Parity patterns, essentially binary counting where "e" is "1"
    # and "o" is "0".
    PARITY_PATTERNS = {
      '0' => 'oo',
      '1' => 'oe',
      '2' => 'eo',
      '3' => 'ee',
    };

    # Left guard pattern
    LEFT_GUARD_PATTERN = '1011'
    # Middle guard pattern
    MIDDLE_GUARD_PATTERN = '01'
    # Left guard pattern as an rle
    LEFT_GUARD_PATTERN_RLE = '112'
    # Middle guard pattern as an rle
    MIDDLE_GUARD_PATTERN_RLE = '11'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0'
    }

    class << self
      # Returns true or false - must be 1-3 digits.  This
      # also handles the case where the leading 0 is added.
      def can_encode?(value, options = nil)
        if !options
          value.to_s =~ /^\d{1,3}$/
        elsif (options[:checksum_included])
          value.to_s =~ /^\d\d\d?$/
        else
          value.to_s =~ /^\d\d?$/ && (0..99).include?(value.to_i)
        end
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".
      def generate_check_digit_for(value)
        value.to_i % 4
      end

      # Validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value, :checksum_included => true)
        md = value.match(/^(\d\d)(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

      # Decodes a bar or rle pattern and returns a
      # UPC_Supplemental_2 object.
      def decode(str)
        if str.length == 20
          # bar pattern
          str = bars_to_rle(str)
        elsif str.length == 13 && str =~ /^[1-9]+$/
          # rle
        else
          raise UnencodableCharactersError, "Pattern must be 20 unit bar pattern or 13 character rle."
        end

        # This string is "aaabbbbccdddd" where "aaa" is the left
        # guard pattern, "bbbb" is the first digit, "cc" is the
        # intra-digit guard pattern, and "dddd" is the second
        # digit.

        # Check the guard patterns
        unless (str[0..2] == LEFT_GUARD_PATTERN_RLE && str[7..8] == MIDDLE_GUARD_PATTERN_RLE)
          raise UnencodableCharactersError, "Missing or incorrect guard patterns"
        end

        parity_sequence = ''
        digits = ''

        # Decode
        [str[3..6], str[9..12]].each do |digit_rle|
          found = false
          ['o','e'].each do |parity|
            ('0'..'9').each do |digit|
              if LEFT_PATTERNS_RLE[digit][parity] == digit_rle
                parity_sequence += parity
                digits += digit
                found = true
                break
              end
            end
          end
          raise UndecodableCharactersError, "Invalid sequence: #{digit_rle}" unless found
        end

        # Now, find the parity digit
        parity_digit = nil
        ('0'..'3').each do |x|
          if PARITY_PATTERNS[x] == parity_sequence
            parity_digit = x
            break
          end
        end

        raise UndecodableCharactersError, "Weird parity: #{parity_sequence}" unless parity_digit

        UPC_Supplemental_2.new(digits + parity_digit, :checksum_included => true)
      end

    end

    # Create a new UPC_Supplemental_2 object from a given value.
    # Options are :line_character, :space_character, and
    # :checksum_included.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value, @options)

      if @options[:checksum_included]
        @encoded_string = value.to_s
        raise ChecksumError unless self.class.validate_check_digit_for(@encoded_string)
        md = @encoded_string.match(/^(\d+?)(\d)$/)
        @value, @check_digit = md[1].to_i, md[2].to_i
      else
        # need to add a checksum
        @value = value.to_i
        @check_digit = self.class.generate_check_digit_for(@value)
        @encoded_string = sprintf('%02d%1d',@value,@check_digit)
      end
    end

    # W/N patterns are not usable with EAN-style codes.  This
    # will raise an error.
    def wn
      raise NotImplementedError
    end

    # Returns a run-length-encoded string representation.
    def rle
      if @rle
        @rle
      else
        md = @encoded_string.match(/(\d\d)(\d)$/)
        @rle = gen_rle(md[1], md[2])
      end
    end

    # Returns a bar pattern.
    def bars
      @bars ||= self.class.rle_to_bars(self.rle, @options)
    end

    # Returns the total unit width of the bar code.
    def width
      @width ||= rle.split('').inject(0) { |a,c| a + c.to_i }
    end

    private

    def gen_rle(payload, parity_digit)
      LEFT_GUARD_PATTERN_RLE +
      LEFT_PATTERNS_RLE[payload[0,1]][PARITY_PATTERNS[parity_digit][0,1]] +
      MIDDLE_GUARD_PATTERN_RLE +
      LEFT_PATTERNS_RLE[payload[1,1]][PARITY_PATTERNS[parity_digit][1,1]]
    end

  end
end
