require 'barcode1dtools/upc_a'

module Barcode1DTools

  # Barcode1DTools::UPC_E - Create pattern for UPC-A barcodes
  #
  # The value encoded is an 6-digit integer, and a checksum digit
  # will be added.  You can add the option :checksum_included => true
  # when initializing to specify that you have already included a
  # checksum.
  #
  # num = '394932'
  # bc = Barcode1DTools::UPC_E.new(num)
  # pattern = bc.bars
  # rle_pattern = bc.rle
  # width = bc.width
  # check_digit = Barcode1DTools::UPC_E.generate_check_digit_for(num)
  #
  # A UPC-E barcode is an abbreviated form of UPC-A, but can encode
  # only a few codes.  The checksum is derived from the full UPC-A
  # digit sequence rather than the 6 digits of the UPC-E.  The checksum
  # is encoded as the parity, with the bar patterns the same as the left
  # side of a standard UPC-A.
  #
  # The last digit of the UPC-E determines the pattern used to convert
  # to a UPC-A.
  #
  # UPC-E      UPC-A equivalent
  # 2 digits for manufacturer code (plus last digit), 3 digits for product
  # XXNNN0     0XX000-00NNN
  # XXNNN1     0XX100-00NNN
  # XXNNN2     0XX200-00NNN
  # 3 digits for manufacturer code, 2 digits for product
  # XXXNN3     0XXX00-000NN
  # 4 digits for manufacturer code, 1 digit for product
  # XXXXN4     0XXXX0-0000N
  # 5 digits for manufacturer code, 1 digit for product (5-9)
  # XXXXX5     0XXXXX-00005
  # XXXXX6     0XXXXX-00006
  # XXXXX7     0XXXXX-00007
  # XXXXX8     0XXXXX-00008
  # XXXXX9     0XXXXX-00009
  #
  #== Rendering
  #
  # The UPC-E is made for smaller items.  Generally, they are rendered
  # with the number system digit (0) on the left of the bars and the
  # checksum on the right.  The 6-digit payload is shown below the bars
  # with the end guard bars extending half-way down the digits.  The
  # number system and check digit might be rendered in a slightly smaller
  # font size.  The UPC-E uses the same bar patterns as the left half of
  # a regular UPC-A, but there is no middle pattern and the right guard
  # pattern has an extra line/space pair.

  class UPC_E < Barcode1D

    LEFT_PATTERNS = UPC_A::LEFT_PATTERNS
    LEFT_PATTERNS_RLE = UPC_A::LEFT_PATTERNS_RLE

    PARITY_PATTERNS = {
      '0' => 'eeeooo',
      '1' => 'eeoeoo',
      '2' => 'eeooeo',
      '3' => 'eeoooe',
      '4' => 'eoeeoo',
      '5' => 'eooeeo',
      '6' => 'eoooee',
      '7' => 'eoeoeo',
      '8' => 'eoeooe',
      '9' => 'eooeoe',
    };

    LEFT_GUARD_PATTERN = '101'
    RIGHT_GUARD_PATTERN = '010101'
    LEFT_GUARD_PATTERN_RLE = '111'
    RIGHT_GUARD_PATTERN_RLE = '111111'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0'
    }

    # For UPC-E
    attr_reader :number_system
    attr_reader :manufacturers_code
    attr_reader :product_code
    attr_reader :upca_value

    class << self
      # Returns true or false - must be 6-8 digits.  This
      # also handles the case where the leading 0 is added.
      def can_encode?(value, options = nil)
        if !options
          value.to_s =~ /^0?[0-9]{6,7}$/
        elsif (options[:checksum_included])
          value.to_s =~ /^0?[0-9]{7}$/
        else
          value.to_s =~ /^0?[0-9]{6}$/
        end
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".
      def generate_check_digit_for(value)
        UPC_A.generate_check_digit_for(self.upce_value_to_upca_value(value))
      end

      # validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value, :checksum_included => true)
        md = value.match(/^(0?\d{6})(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

      def decode(str)
        if str.length == 51
          # bar pattern
          str = bars_to_rle(str)
        elsif str.length == 33 && str =~ /^[1-9]+$/
          # rle
        else
          raise UnencodableCharactersError, "Pattern must be 95 unit bar pattern or 39 character rle."
        end

        # See if the string is reversed
        if str[0..5] == RIGHT_GUARD_PATTERN_RLE && str[30..32] == LEFT_GUARD_PATTERN_RLE
          str.reverse!
        end

        # Check the guard patterns
        unless (str[0..2] == LEFT_GUARD_PATTERN_RLE && str[27..32] == RIGHT_GUARD_PATTERN_RLE)
          raise UnencodableCharactersError, "Missing or incorrect guard patterns"
        end

        parity_sequence = ''
        digits = ''
        initial_offset = LEFT_GUARD_PATTERN_RLE.length

        # Decode
        (0..5).each do |offset|
          found = false
          digit_rle = str[(initial_offset + offset*4),4]
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

        UPC_E.new('0' + digits + parity_digit, :checksum_included => true)
      end

      def upce_value_to_upca_value(value, options = {})
        raise UnencodableCharactersError unless self.can_encode?(value, options)
        # remove the check digit if it was included
        value = value.to_i % 10 if options[:checksum_included]
        value = sprintf('%06d', value.to_i)
        if value =~ /(\d\d)(\d\d\d)([012])/
          upca_value = "0#{$1}#{$3}0000#{$2}"
        elsif value =~ /(\d\d\d)(\d\d)(3)/
          upca_value = "0#{$1}00000#{$2}"
        elsif value =~ /(\d\d\d\d)(\d)(4)/
          upca_value = "0#{$1}00000#{$2}"
        elsif value =~ /(\d\d\d\d\d)([5-9])/
          upca_value = "0#{$1}0000#{$2}"
        else
          raise UnencodableCharactersError, "Cannot change UPC-E #{value} to UPC-A"
        end
        upca_value
      end

      def upca_value_to_upce_value(value, options = {})
        raise UnencodableCharactersError unless UPC_A.can_encode?(value, options)
        value = value % 10 if options[:checksum_included]
        value = sprintf('%011d', value.to_i)
        if value =~ /^0(\d\d\d\d[1-9])0000([5-9])/
          upce_value = "0#{$1}#{$2}"
        elsif value =~ /^0(\d\d\d[1-9])00000(\d)/
          upce_value = "0#{$1}#{$2}4"
        elsif value =~ /^0(\d\d)([012])0000(\d\d\d)/
          upce_value = "0#{$1}#{$3}#{$2}"
        elsif value =~ /^0(\d\d[3-9])00000(\d\d)/
          upce_value = "0#{$1}#{$2}3"
        else
          raise UnencodableCharactersError, "Cannot change UPC-A #{value} to UPC-E"
        end
        upce_value
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
        @encoded_string = "#{@value}#{@check_digit}"
      end

      @upca_value = self.class.upce_value_to_upca_value(@value)
      md = @upca_value.match(/^(\d)(\d{5})(\d{5})/)
      @number_system, @manufacturers_code, @product_code = md[1], md[2], md[3]
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
        md = @encoded_string.match(/(\d{6})(\d)$/)
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
      (LEFT_GUARD_PATTERN_RLE + (0..5).collect { |n| LEFT_PATTERNS_RLE[payload[n,1]][PARITY_PATTERNS[parity_digit][n,1]] }.join('') + RIGHT_GUARD_PATTERN_RLE)
    end

  end
end
