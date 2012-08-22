require 'barcode1dtools/upc_a'

module Barcode1DTools

  # Barcode1DTools::UPC_Supplemental_5 - Create pattern for UPC
  # Supplemental 5 barcodes
  #
  # The value encoded is an 5-digit integer, and a checksum digit
  # will be added.  You can add the option :checksum_included => true
  # when initializing to specify that you have already included a
  # checksum.  The bar patterns are the same as the left
  # half of a standard UPC-A.
  #
  # num = '53999'  # book price is US$39.99
  # bc = Barcode1DTools::UPC_Supplemental_5.new(num)
  # pattern = bc.bars
  # rle_pattern = bc.rle
  # bc.price   # returns the "price" part as 4 digits
  # bc.currency  # returns the first digit currency code
  # width = bc.width
  # check_digit = Barcode1DTools::UPC_Supplemental_5.generate_check_digit_for(num)
  #
  # This type of barcode consists of 5 digits, and a check digit
  # (a modulus 10 of the sum of the digits with weights of 3 and
  # 9) that is encoded in the "parity" of the two barcode
  # digits.  It is positioned to the right of a UPC-A or EAN-13
  # to create a "Bookland" code.
  #
  # The two are scanned together, and typically the scanner will
  # return the five digits of the supplemental barcode
  # immediately following the check digit from the main barcode.
  # You will likely need to use the Barcode::UPC_A or
  # Barcode::EAN_13 module in addition to this one to create the
  # full code.
  #
  # The 5-digit supplement is generally used on literature, and
  # represents a type-indicator digit followed by a 4-digit
  # MSRP.  The type is "0" for British Pound units, "5" for US
  # Dollar units, and 9 for extra information.  A code of
  # "90000" means "no MSRP", "99991" indicates a complimentary
  # copy, "99990" is used to mark used books (by college
  # bookstores), and "90001" through "98999" are used internally
  # by some publishers.
  #
  #== Rendering
  #
  # The 5-digit supplement is positioned to the right of the
  # main UPC code, and the human-readable digits are usually
  # printed above the supplemental barcode.
  #
  # A UPC-A is generally rendered at one inch across, then
  # there's a 1/8th inch gap, then the supplemental.  A UPC-A is
  # 95 units wide, so the gap is 24 units wide.  The 5-digit
  # supplemental barcode is 47 units wide, essentially half an
  # inch at this scale.  Note that regardless of scale, the gap
  # should be at least the smaller of 1/8th inch or 10 units.


  class UPC_Supplemental_5 < Barcode1D

    LEFT_PATTERNS = UPC_A::LEFT_PATTERNS
    LEFT_PATTERNS_RLE = UPC_A::LEFT_PATTERNS_RLE

    # parity patterns, essentially binary counting where "e" is "1"
    # and "o" is "0"
    PARITY_PATTERNS = {
      '0' => 'eeooo',
      '1' => 'eoeoo',
      '2' => 'eooeo',
      '3' => 'eoooe',
      '4' => 'oeeoo',
      '5' => 'ooeeo',
      '6' => 'oooee',
      '7' => 'oeoeo',
      '8' => 'oeooe',
      '9' => 'ooeoe'
    };

    LEFT_GUARD_PATTERN = '1011'
    MIDDLE_GUARD_PATTERN = '01'
    LEFT_GUARD_PATTERN_RLE = '112'
    MIDDLE_GUARD_PATTERN_RLE = '11'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0'
    }

    attr_reader :currency_code
    attr_reader :price

    class << self
      # Returns true or false - must be 5 or 6 digits.  This
      # also handles the case where the leading 0 is added.
      def can_encode?(value, options = nil)
        if !options
          value.to_s =~ /^\d{5,6}$/
        elsif (options[:checksum_included])
          value.to_s =~ /^\d{6}$/
        else
          value.to_s =~ /^\d{5}$/
        end
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".
      def generate_check_digit_for(value)
        mult = 9  # alternates 3 and 9
        sprintf('%05d',value.to_i).reverse.chars.inject(0) { |a,c| mult = 12 - mult; a + c.to_i * mult } % 10
      end

      # validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value, :checksum_included => true)
        md = value.match(/^(\d{5})(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

      def decode(str)
        if str.length == 47
          # bar pattern
          str = bars_to_rle(str)
        elsif str.length == 31 && str =~ /^[1-9]+$/
          # rle
        else
          raise UnencodableCharactersError, "Pattern must be 47 unit bar pattern or 31 character rle."
        end

        # This string is "aaabbbb(ccdddd)" where "aaa" is the left
        # guard pattern, "bbbb" is the first digit, "cc" is the
        # intra-digit guard pattern, and "dddd" is the second
        # digit.  (ccdddd) occurs 4 times.

        # See if the string is reversed
        if str[28..30] == LEFT_GUARD_PATTERN_RLE.reverse && [7,13,19,25].all? { |x| str[29-x,2] == MIDDLE_GUARD_PATTERN_RLE.reverse }
          str.reverse!
        end

        # Check the guard patterns
        unless (str[0..2] == LEFT_GUARD_PATTERN_RLE && [7,13,19,25].all? { |x| str[x,2] == MIDDLE_GUARD_PATTERN_RLE.reverse })
          raise UnencodableCharactersError, "Missing or incorrect guard patterns"
        end

        parity_sequence = ''
        digits = ''
        left_initial_offset = LEFT_GUARD_PATTERN_RLE.length

        # Decode
        (0..4).each do |left_offset|
          found = false
          digit_rle = str[(left_initial_offset + left_offset*6),4]
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
        ('0'..'9').each do |x|
          if PARITY_PATTERNS[x] == parity_sequence
            parity_digit = x
            break
          end
        end

        raise UndecodableCharactersError, "Weird parity: #{parity_sequence}" unless parity_digit

        UPC_Supplemental_5.new(digits + parity_digit, :checksum_included => true)
      end

    end

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
        @encoded_string = sprintf('%05d%1d',@value,@check_digit)
      end

      md = @value.match(/^(\d)(\d{4})/)
      @currency_code, @price = md[1], md[2]
    end

    # not usable with EAN-style codes
    def wn
      raise NotImplementedError
    end

    # returns a run-length-encoded string representation
    def rle
      if @rle
        @rle
      else
        md = @encoded_string.match(/(\d{5})(\d)$/)
        @rle = gen_rle(md[1], md[2])
      end
    end

    # returns 1s and 0s (for "black" and "white")
    def bars
      @bars ||= self.class.rle_to_bars(self.rle, @options)
    end

    # returns the total unit width of the bar code
    def width
      @width ||= rle.split('').inject(0) { |a,c| a + c.to_i }
    end

    private

    def gen_rle(payload, parity_digit)
      LEFT_GUARD_PATTERN_RLE + (0..4).collect { |n| LEFT_PATTERNS_RLE[payload[n,1]][PARITY_PATTERNS[parity_digit][n,1]] }.join(MIDDLE_GUARD_PATTERN_RLE)
    end

  end
end
