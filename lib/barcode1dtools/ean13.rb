#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::EAN_13 - Create pattern for EAN-13 barcodes.
  # The value encoded is an
  # integer, and a checksum digit will be added.  You can add the option
  # :checksum_included => true when initializing to specify that you
  # have already included a checksum.
  #
  # == Example
  #  # Note that this number is a UPC-A, with the number system of 08,
  #  # manufacturer's code of "28999", product code of "00682", and a
  #  # checksum of "3" (not included)
  #  num = '082899900682'
  #  bc = Barcode1DTools::EAN13.new(num)
  #  pattern = bc.bars
  #  rle_pattern = bc.rle
  #  width = bc.width
  #  check_digit = Barcode1DTools::EAN13.generate_check_digit_for(num)
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
  # Unlike some of the other barcodes, e.g. Code 3 of 9, there is no "w/n" format for
  # EAN & UPC style barcodes because the bars and spaces are variable width from
  # 1 to 4 units.
  # 
  # == Miscellaneous Information
  # 
  # An EAN-13 with an initial "number system" digit of "0" is a UPC-A.
  # The BarcodeTools::UPC_A module actually just uses this EAN13 module.
  # 
  # An EAN-13 barcode has 4 elements:
  # 1. A two-digit "number system" designation
  # 2. A 5-digit manufacturer's code
  # 3. A 5-digit product code
  # 4. A single digit checksum
  # 
  # There is some flexibility in EAN-13 on the digit layout.  Sometimes,
  # the first three digits indicate numbering system, i.e. some number
  # systems are further split up.  An example is "74", which is used for
  # Central America with "740" for Guatemala, "741" for El Salvador, etc.
  # 
  # Note that JAN codes (Japanese) are simply EAN-13's, and they always start with
  # "49".  The table below shows "49" to be "Japan".
  # 
  # Also note that many books use a "bookland" code, perhaps along with a UPC
  # Supplemental.  The bookland code is really an EAN-13 with the initial 3 digits
  # of "978".  The next 9 digits are the first 9 digits of the ISBN, and of course
  # we still include the final check digit.  An ISBN is 10 digits, however, the
  # final digit is also a check digit, so it is not necessary.
  # 
  # Here is the complete table from www.barcodeisland.com:
  # 
  #  00-13: USA & Canada          590: Poland               780: Chile
  #  20-29: In-Store Functions    594: Romania              784: Paraguay
  #  30-37: France                599: Hungary              785: Peru
  #  40-44: Germany               600 & 601: South Africa   786: Ecuador
  #  45:  Japan (also 49)         609: Mauritius            789: Brazil
  #  46:  Russian Federation      611: Morocco              80 - 83: Italy
  #  471: Taiwan                  613: Algeria              84: Spain
  #  474: Estonia                 619: Tunisia              850: Cuba
  #  475: Latvia                  622: Egypt                858: Slovakia
  #  477: Lithuania               625: Jordan               859: Czech Republic
  #  479: Sri Lanka               626: Iran                 860: Yugloslavia
  #  480: Philippines             64:  Finland              869: Turkey
  #  482: Ukraine                 690-692: China            87:  Netherlands
  #  484: Moldova                 70:  Norway               880: South Korea
  #  485: Armenia                 729: Israel               885: Thailand
  #  486: Georgia                 73:  Sweden               888: Singapore
  #  487: Kazakhstan              740: Guatemala            890: India
  #  489: Hong Kong               741: El Salvador          893: Vietnam
  #  49:  Japan (JAN-13)          742: Honduras             899: Indonesia
  #  50:  United Kingdom          743: Nicaragua            90 & 91: Austria
  #  520: Greece                  744: Costa Rica           93:  Australia
  #  528: Lebanon                 746: Dominican Republic   94:  New Zealand
  #  529: Cyprus                  750: Mexico               955: Malaysia
  #  531: Macedonia               759: Venezuela            977: ISSN
  #  535: Malta                   76:  Switzerland          978: ISBN
  #  539: Ireland                 770: Colombia             979: ISMN
  #  54:  Belgium & Luxembourg    773: Uruguay              980: Refund receipts
  #  560: Portugal                775: Peru                 981 & 982: CCC
  #  569: Iceland                 777: Bolivia              99:  Coupons
  #  57:  Denmark                 779: Argentina
  #
  # ISSN:: International Standard Serial Number for Periodicals
  # ISBN:: International Standard Book Numbering
  # ISMN:: International Standard Music Number
  # CCC:: Common Currency Coupons
  # 
  # == Rendering
  # 
  # When rendered, the initial digit of the number system is shown to the
  # left and above the rest of the digits.  The other two sets of six
  # digits each are shown at the bottom of the code, aligned with the
  # bottom of the code, and with the middle guard pattern bars extending
  # down between them.  The lower digits may be aligned flush with the
  # bottom of the barcode, or the center of the text may be aligned with the
  # bottom of the barcode.  Typically, the barcode is 1-1.5" across and 60%
  # or more of the width in height.  There should be at least 10 units of
  # quiet space on each side.

  class EAN13 < Barcode1D

    # Patterns for the left side, split between odd and even parity
    LEFT_PATTERNS = {
      '0' => { 'o' => '0001101', 'e' => '0100111'},
      '1' => { 'o' => '0011001', 'e' => '0110011'},
      '2' => { 'o' => '0010011', 'e' => '0011011'},
      '3' => { 'o' => '0111101', 'e' => '0100001'},
      '4' => { 'o' => '0100011', 'e' => '0011101'},
      '5' => { 'o' => '0110001', 'e' => '0111001'},
      '6' => { 'o' => '0101111', 'e' => '0000101'},
      '7' => { 'o' => '0111011', 'e' => '0010001'},
      '8' => { 'o' => '0110111', 'e' => '0001001'},
      '9' => { 'o' => '0001011', 'e' => '0010111'},
    }

    # Patterns for the left side, split between odd and even parity, in
    # RLE format.  Note that all left side patterns start with a space
    # and end with a bar.
    LEFT_PATTERNS_RLE = {
      '0' => { 'o' => '3211', 'e' => '1123'},
      '1' => { 'o' => '2221', 'e' => '1222'},
      '2' => { 'o' => '2122', 'e' => '2212'},
      '3' => { 'o' => '1411', 'e' => '1141'},
      '4' => { 'o' => '1132', 'e' => '2311'},
      '5' => { 'o' => '1231', 'e' => '1321'},
      '6' => { 'o' => '1114', 'e' => '4111'},
      '7' => { 'o' => '1312', 'e' => '2131'},
      '8' => { 'o' => '1213', 'e' => '3121'},
      '9' => { 'o' => '3112', 'e' => '2113'},
    }

    # Left parity patterns.  An extra digit is encoded in the parity.
    LEFT_PARITY_PATTERNS = {
      '0' => 'oooooo',
      '1' => 'ooeoee',
      '2' => 'ooeeoe',
      '3' => 'ooeeeo',
      '4' => 'oeooee',
      '5' => 'oeeooe',
      '6' => 'oeeeoo',
      '7' => 'oeoeoe',
      '8' => 'oeoeeo',
      '9' => 'oeeoeo',
    }

    # Bar patterns for right side.
    RIGHT_PATTERNS = {
      '0' => '1110010',
      '1' => '1100110',
      '2' => '1101100',
      '3' => '1000010',
      '4' => '1011100',
      '5' => '1001110',
      '6' => '1010000',
      '7' => '1000100',
      '8' => '1001000',
      '9' => '1110100',
    }

    # Bar patterns for right side as RLE.  Note that on the right
    # side each pattern starts with a bar and ends with a space.
    RIGHT_PATTERNS_RLE = {
      '0' => '3211',
      '1' => '2221',
      '2' => '2122',
      '3' => '1411',
      '4' => '1132',
      '5' => '1231',
      '6' => '1114',
      '7' => '1312',
      '8' => '1213',
      '9' => '3112',
    }

    # AAAAHHHHHHHHH side + middle + side is 666, the number of the beast
    SIDE_GUARD_PATTERN='101';
    MIDDLE_GUARD_PATTERN='01010';

    # Side guard pattern - Starts with bar
    SIDE_GUARD_PATTERN_RLE='111';
    # Middle guard pattern - Starts with space
    MIDDLE_GUARD_PATTERN_RLE='11111';

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0'
    }

    # Specific for EAN - the number system part of the payload
    attr_reader :number_system
    # Specific for EAN - the manufacturer's code part of the payload
    attr_reader :manufacturers_code
    # Specific for EAN - the product code part of the payload
    attr_reader :product_code

    class << self
      # Returns true if value can be encoded.  Must be 12 or 13 digits.
      def can_encode?(value, options = nil)
        if !options
          value.to_s =~ /^[0-9]{12,13}$/
        elsif (options[:checksum_included])
          value.to_s =~ /^[0-9]{13}$/
        else
          value.to_s =~ /^[0-9]{12}$/
        end
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".
      def generate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value, :checksum_included => false)
        mult = 3
        value = value.split('').inject(0) { |a,c| mult = 4 - mult ; a + c.to_i * mult }
        (10 - (value % 10)) % 10
      end

      # Validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value, :checksum_included => true)
        md = value.match(/^(\d{12})(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

      # Decode a string representing an rle or bar pattern EAN-13.
      # Note that the string might be backward or forward.  This
      # will return an EAN13 object.
      def decode(str)
        if str.length == 95
          # bar pattern
          str = bars_to_rle(str)
        elsif str.length == 59
          # rle
        else
          raise UnencodableCharactersError, "Pattern must be 95 unit bar pattern or 59 character rle."
        end

        # Check the guard patterns
        unless str[0..2] == SIDE_GUARD_PATTERN_RLE && str[56..58] == SIDE_GUARD_PATTERN_RLE && str[27..31] == MIDDLE_GUARD_PATTERN_RLE
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
        right_initial_offset = SIDE_GUARD_PATTERN_RLE.length + (4*6) + MIDDLE_GUARD_PATTERN_RLE.length

        # Decode the left side
        (0..5).each do |left_offset|
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
        (0..5).each do |right_offset|
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

        # If left parity sequence is 'eeeeee', the string is reversed
        if left_parity_sequence == 'eeeeee'
          left_digits, right_digits, left_parity_sequence = right_digits.reverse, left_digits.reverse, right_parity_sequence.reverse.tr('eo','oe')
        end

        # Now, find the parity digit
        parity_digit = nil
        ('0'..'9').each do |x|
          if LEFT_PARITY_PATTERNS[x] == left_parity_sequence
            parity_digit = x
            break
          end
        end

        raise UndecodableCharactersError, "Weird parity: #{left_parity_sequence}" unless parity_digit

        # Debugging
        #puts "Left digits: #{left_digits} Left parity: #{left_parity_sequence}"
        #puts "Right digits: #{right_digits} Right parity: #{right_parity_sequence}"
        #puts "Parity: #{parity_digit}"

        EAN13.new(parity_digit + left_digits + right_digits, :checksum_included => true)
      end
    end

    # Create a new EAN-13 barcode object.
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
        @value, @check_digit = md[1], md[2].to_i
      else
        # need to add a checksum
        @value = value.to_s
        @check_digit = self.class.generate_check_digit_for(@value)
        @encoded_string = "#{@value}#{@check_digit}"
      end

      md = @value.match(/^(\d{2})(\d{5})(\d{5})/)
      @number_system, @manufacturers_code, @product_code = md[1], md[2], md[3]
    end

    # Note that EANs cannot produce a w/n string, so this
    # will raise an error.
    def wn
      raise NotImplementedError
    end

    # Returns a run-length-encoded string representation
    def rle
      if @rle
        @rle
      else
        md = @encoded_string.match(/^(\d)(\d{6})(\d{6})/)
        @rle = gen_rle(md[1], md[2], md[3])
      end
    end

    # Returns 1s and 0s (for "black" and "white")
    def bars
      @bars ||= self.class.rle_to_bars(self.rle, @options)
    end

    # Returns the total unit width of the bar code
    def width
      @width ||= rle.split('').inject(0) { |a,c| a + c.to_i }
    end

    private

    def gen_rle(parity_digit, left_half, right_half)
      (SIDE_GUARD_PATTERN_RLE + (0..5).collect { |n| LEFT_PATTERNS_RLE[left_half[n,1]][LEFT_PARITY_PATTERNS[parity_digit][n,1]] }.join('') + MIDDLE_GUARD_PATTERN_RLE + right_half.split('').collect { |c| RIGHT_PATTERNS_RLE[c] }.join('') + SIDE_GUARD_PATTERN_RLE)
    end

  end
end
