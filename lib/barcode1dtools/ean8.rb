#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'barcode1dtools/ean13'

module Barcode1DTools

  # Barcode1DTools::EAN_8 - Create pattern for EAN-8 barcodes.
  # The value encoded is a 7-digit number, and a checksum digit will
  # be added.  You can add the option # :checksum_included => true
  # when initializing to specify that you have already included a
  # checksum.
  #
  # == Example
  #  num = '96385074'
  #  bc = Barcode1DTools::EAN8.new(num)
  #  pattern = bc.bars
  #  rle_pattern = bc.rle
  #  width = bc.width
  #  check_digit = Barcode1DTools::EAN83.generate_check_digit_for(num)
  #
  # == Other Information
  #
  # The object created is immutable.
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
  # Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "wnstr" for
  # EAN & UPC style barcodes because the bars and spaces are variable width from
  # 1 to 4 units.
  # 
  # An EAN-8 barcode has 3 elements:
  # 1. A 2 or 3 digit "number system" designation
  # 2. A 4 or 5 digit manufacturer's code
  # 3. A single digit checksum
  # 
  # Note than an EAN-8 is not analogous to a UPC-E.  In particular, there
  # is no way to create an EAN-13 from and EAN-8 and vice versa.  The
  # numbers are assigned within EAN-8 by a central authority.
  #
  # The bar patterns are the same as EAN-13, with nothing encoded in the
  # parity.  All bars on the left use the "odd" parity set.
  # 
  # == Rendering
  # 
  # When rendered, two sets of four digits are shown at the bottom of the
  # code, aligned with the bottom of the code, and with the middle guard
  # pattern bars extending down between them.  A supplemental 2 or 5 may
  # be used.

  class EAN8 < Barcode1D

    # Left patterns from EAN-13
    LEFT_PATTERNS = EAN13::LEFT_PATTERNS
    # Left rle patterns from EAN-13
    LEFT_PATTERNS_RLE = EAN13::LEFT_PATTERNS_RLE
    # Right patterns from EAN-13
    RIGHT_PATTERNS = EAN13::RIGHT_PATTERNS
    # Right rle patterns from EAN-13
    RIGHT_PATTERNS_RLE = EAN13::RIGHT_PATTERNS_RLE

    # Guard pattern from EAN-13
    SIDE_GUARD_PATTERN=EAN13::SIDE_GUARD_PATTERN
    # Middle Guard pattern from EAN-13
    MIDDLE_GUARD_PATTERN=EAN13::MIDDLE_GUARD_PATTERN
    # Guard pattern from EAN-13 as an rle
    SIDE_GUARD_PATTERN_RLE=EAN13::SIDE_GUARD_PATTERN_RLE
    # Middle Guard pattern from EAN-13 as an rle
    MIDDLE_GUARD_PATTERN_RLE=EAN13::MIDDLE_GUARD_PATTERN_RLE

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0'
    }

    # Specific for EAN-8 - the number system part of the payload
    attr_reader :number_system
    # Specific for EAN-8 - the product code part of the payload
    attr_reader :product_code

    class << self
      # Returns true if value can be encoded in EAN-8 - must be 7-8 digits.
      def can_encode?(value, options = nil)
        if !options
          value.to_s =~ /^\d{7,8}$/
        elsif (options[:checksum_included])
          value.to_s =~ /^\d{8}$/
        else
          value.to_s =~ /^\d{7}$/
        end
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".
      def generate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value, :checksum_included => false)
        mult = 1
        value = value.split('').inject(0) { |a,c| mult = 4 - mult ; a + c.to_i * mult }
        (10 - (value % 10)) % 10
      end

      # Validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value, :checksum_included => true)
        md = value.match(/^(\d{7})(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

      # Decode a string representing an rle or bar pattern EAN-13.
      # Note that the string might be backward or forward.  This
      # will return an EAN8 object.
      def decode(str)
        if str.length == 67
          # bar pattern
          str = bars_to_rle(str)
        elsif str.length == 43
          # rle
        else
          raise UnencodableCharactersError, "Pattern must be 67 unit bar pattern or 43 character rle."
        end

        # Check the guard patterns
        unless str[0..2] == SIDE_GUARD_PATTERN_RLE && str[40..42] == SIDE_GUARD_PATTERN_RLE && str[19..23] == MIDDLE_GUARD_PATTERN_RLE
          raise UnencodableCharactersError, "Missing or incorrect guard patterns"
        end

        # Now I have an rle pattern, simply need to decode
        # according to the LEFT_PATTERNS_RLE, keeping track
        # of the parity for each position.

        # Set up the decoder
        left_parity_sequence = ''
        left_digits = ''
        right_parity_sequence = ''
        right_digits = ''
        left_initial_offset = SIDE_GUARD_PATTERN_RLE.length
        right_initial_offset = SIDE_GUARD_PATTERN_RLE.length + (4*4) + MIDDLE_GUARD_PATTERN_RLE.length

        # Decode the left side
        (0..3).each do |left_offset|
          found = false
          digit_rle = str[(left_initial_offset + left_offset*4),4]
          ['o','e'].each do |parity|
            ('0'..'9').each do |digit|
              if LEFT_PATTERNS_RLE[digit][parity] == digit_rle
                left_parity_sequence += parity
                left_digits += digit
                found = true
                break
              end
            end
          end
          raise UndecodableCharactersError, "Invalid sequence: #{digit_rle}" unless found
        end

        # Decode the right side
        (0..3).each do |right_offset|
          found = false
          digit_rle = str[(right_initial_offset + right_offset*4),4]
          ['o','e'].each do |parity|
            ('0'..'9').each do |digit|
              if LEFT_PATTERNS_RLE[digit][parity] == digit_rle
                right_parity_sequence += parity
                right_digits += digit
                found = true
                break
              end
            end
          end
          raise UndecodableCharactersError, "Invalid sequence: #{digit_rle}" unless found
        end

        # If left parity sequence is 'eeee', the string is reversed
        if left_parity_sequence == 'eeee'
          left_digits, right_digits, left_parity_sequence = right_digits.reverse, left_digits.reverse, right_parity_sequence.reverse.tr('eo','oe')
        end

        # Debugging
        #puts "Left digits: #{left_digits} Left parity: #{left_parity_sequence}"
        #puts "Right digits: #{right_digits} Right parity: #{right_parity_sequence}"

        EAN8.new(left_digits + right_digits, :checksum_included => true)
      end
    end

    # Create an EAN8 object with a given value.
    # Options are :line_character, :space_character, and
    # :checksum_included.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value, @options)

      if @options[:checksum_included]
        @encoded_string = sprintf('%08d', value.to_i)
        raise ChecksumError unless self.class.validate_check_digit_for(@encoded_string)
        md = @encoded_string.match(/^(\d+?)(\d)$/)
        @value, @check_digit = md[1], md[2].to_i
      else
        # need to add a checksum
        @value = sprintf('%07d', value.to_i)
        @check_digit = self.class.generate_check_digit_for(@value)
        @encoded_string = "#{@value}#{@check_digit}"
      end

      md = @value.match(/^(\d{3})(\d{4})/)
      @number_system, @product_code = md[1], md[2]
    end

    # EAN-based codes cannot create a w/n string, so this
    # will raise an error.
    def wn
      raise NotImplementedError
    end

    # returns a run-length-encoded string representation.
    def rle
      if @rle
        @rle
      else
        md = @encoded_string.match(/^(\d{4})(\d{4})/)
        @rle = gen_rle(md[1], md[2])
      end
    end

    # Returns 1s and 0s (for "black" and "white")
    def bars
      @bars ||= self.class.rle_to_bars(self.rle, @options)
    end

    # Returns the total unit width of the bar code.
    def width
      @width ||= rle.split('').inject(0) { |a,c| a + c.to_i }
    end

    private

    def gen_rle(left_half, right_half)
      (SIDE_GUARD_PATTERN_RLE + (0..3).collect { |n| LEFT_PATTERNS_RLE[left_half[n,1]]['o'] }.join + MIDDLE_GUARD_PATTERN_RLE + right_half.split('').collect { |c| RIGHT_PATTERNS_RLE[c] }.join + SIDE_GUARD_PATTERN_RLE)
    end

  end
end
