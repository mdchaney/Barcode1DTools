#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Code128 - Create and decode bar patterns for
  # Code128.
  #
  # val = "29382-38"
  # bc = Barcode1DTools::Code128.new(val)
  # pattern = bc.bars
  # rle_pattern = bc.rle
  # width = bc.width
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Code128 creates the patterns that you need to
  # display Code128 barcodes.  It can also decode a simple rle or
  # bar pattern string.
  #
  # Code128 characters consist of 3 bars and 3 spaces.
  #
  # There are two formats for the returned pattern:
  #
  #   bars - 1s and 0s specifying black lines and white spaces.  Actual
  #          characters can be changed from "1" and 0" with options
  #          :line_character and :space_character.
  #
  #   rle -  Run-length-encoded version of the pattern.  The first
  #          number is always a black line, with subsequent digits
  #          alternating between spaces and lines.  The digits specify
  #          the width of each line or space.
  #
  # The "width" method will tell you the total end-to-end width, in
  # units, of the entire barcode.
  #
  #== Rendering
  #

  class Code128 < Barcode1D

    # Patterns for making bar codes
    PATTERNS = [
      '212222', '222122', '222221', '121223', '121322', '131222',
      '122213', '122312', '132212', '221213', '221312', '231212',
      '112232', '122132', '122231', '113222', '123122', '123221',
      '223211', '221132', '221231', '213212', '223112', '312131',
      '311222', '321122', '321221', '312212', '322112', '322211',
      '212123', '212321', '232121', '111323', '131123', '131321',
      '112313', '132113', '132311', '211313', '231113', '231311',
      '112133', '112331', '132131', '113123', '113321', '133121',
      '313121', '211331', '231131', '213113', '213311', '213131',
      '311123', '311321', '331121', '312113', '312311', '332111',
      '314111', '221411', '431111', '111224', '111422', '121124',
      '121421', '141122', '141221', '112214', '112412', '122114',
      '122411', '142112', '142211', '241211', '221114', '413111',
      '241112', '134111', '111242', '121142', '121241', '114212',
      '124112', '124211', '411212', '421112', '421211', '212141',
      '214121', '412121', '111143', '111341', '131141', '114113',
      '114311', '411113', '411311', '113141', '114131', '311141',
      '411131', '211412', '211214', '211232',
      '2331112'
    ]

    # Quicker decoding
    PATTERN_LOOKUP = (0..106).inject({}) { |a,c| a[PATTERNS[c]] = c; a }

    START_A = 103
    START_B = 104
    START_C = 105
    STOP = 106

    GUARD_PATTERN_RIGHT_RLE = PATTERNS[STOP]
    START_A_RLE = PATTERNS[START_A]
    START_B_RLE = PATTERNS[START_B]
    START_C_RLE = PATTERNS[START_C]

    LOW_ASCII_LABELS = [
      'NUL', 'SOH', 'STX', 'ETX', 'EOT', 'ENQ', 'ACK', 'BEL',
      'BS', 'HT', 'LF', 'VT', 'FF', 'CR', 'SO', 'SI', 'DLE',
      'DC1', 'DC2', 'DC3', 'DC4', 'NAK', 'SYN', 'ETB', 'CAN',
      'EM', 'SUB', 'ESC', 'FS', 'GS', 'RS', 'US'
    ]

    # Code A encodes ASCII NUL (\x0) to _ (\x5f, dec. 95).  Note
    # that they are not sequential - it starts with space through
    # underscore, then has nul to \x1f.  Finally, it has FNC 1-4.
    CODE_A_LOOKUP = ((32..95).to_a + (0..31).to_a).collect { |c| [c].pack('C') } + [ :fnc_3, :fnc_2, :shift_b, :code_c, :code_b, :fnc_4, :fnc_1, :start_a, :start_b, :start_c, :stop ]
    # Code B encodes ASCII space (\x20, dec. 32) to DEL (\x7f,
    # dec. 127).  This is identical to Code A for the first 63
    # characters.  It also includes FNC 1-4 with FNC 4 in a
    # different position than in set A.
    CODE_B_LOOKUP = (32..127).collect { |c| [c].pack('C') } + [ :fnc_3, :fnc_2, :shift_a, :code_c, :fnc_4, :code_a, :fnc_1, :start_a, :start_b, :start_c, :stop ]
    # Code C encodes digit pairs 00 to 99 as well as FNC 1.
    CODE_C_LOOKUP = ("00".."99").to_a + [ :code_b, :code_a, :fnc_1, :start_a, :start_b, :start_c, :stop ]
    CODE_A_HIGH_LOOKUP = CODE_A_LOOKUP.collect { |a| a.is_a?(Symbol) ? a : [a.unpack("C").first+128].pack("C") }
    CODE_B_HIGH_LOOKUP = CODE_B_LOOKUP.collect { |a| a.is_a?(Symbol) ? a : [a.unpack("C").first+128].pack("C") }

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0'
    }

    class << self
      # Code128 can encode anything
      def can_encode?(value)
        true
      end

      def generate_check_digit_for(value)
        md = parse_code128(value)
        start = md[1].unpack('C')
        mult=0
        [md[2].unpack('C*').inject(start.first) { |a,c| (mult+=1)*c+a } % 103].pack('C')
      end

      def validate_check_digit_for(value)
        payload, check_digit = split_payload_and_check_digit(value)
        self.generate_check_digit_for(payload) == check_digit
      end

      def split_payload_and_check_digit(value)
        md = value.to_s.match(/\A(.*)(.)\z/)
        [md[1], md[2]]
      end

      # Returns match data - 1: start character 2: payload
      # 3: check digit 4: stop character
      def parse_code128(str)
        str.match(/\A([\x67-\x69])([\x00-\x66]*?)(?:([\x00-\x66])(\x6a))?\z/)
      end

      def code128_to_latin1(str, options = {})
        ret = []
        in_high_latin1 = false
        shift_codeset = nil
        shift_latin1 = false
        current_codeset = 'A'
        current_lookup = CODE_A_LOOKUP
        md = parse_code128(str)
        raise UndecodeableCharactersError unless md
        start_item = CODE_A_LOOKUP[md[1].unpack('C').first]
        if start_item == :start_a
          current_codeset = 'A'
          current_lookup = CODE_A_LOOKUP
        elsif start_item == :start_b
          current_codeset = 'B'
          current_lookup = CODE_B_LOOKUP
        elsif start_item == :start_c
          current_codeset = 'C'
          current_lookup = CODE_C_LOOKUP
        end
        md[2].unpack("C*").each do |char|
          if shift_codeset
            this_item = shift_codeset[char]
            shift_codeset = nil
          else
            this_item = current_lookup[char]
          end
          if this_item.is_a? Symbol
            # Symbols might be change code (code_a, code_b, code_c),
            # shift for a single item (shift_a, shift_b),
            # or an fnc 1-4.  If it's fnc_4, handle the high latin-1.
            # Might also be the start code.
            if this_item == :code_a
              current_codeset = 'A'
              current_lookup = CODE_A_LOOKUP
            elsif this_item == :code_b
              current_codeset = 'B'
              current_lookup = CODE_B_LOOKUP
            elsif this_item == :code_c
              current_codeset = 'C'
              current_lookup = CODE_C_LOOKUP
            elsif this_item == :shift_a
              shift_codeset = CODE_A_LOOKUP
            elsif this_item == :shift_b
              shift_codeset = CODE_B_LOOKUP
            elsif this_item == :fnc_4 && !options[:no_latin1]
              if shift_latin1
                in_high_latin1 = !in_high_latin1
                shift_latin1 = false
              else
                shift_latin1 = true
              end
            else
              ret.push this_item
            end
          elsif in_high_latin1 && ['A', 'B'].include?(current_codeset)
            # Currently processing as latin-1.  If we find the shift,
            # handle as regular character.
            if shift_latin1
              ret.push this_item
              shift_latin1 = false
            else
              ret.push [this_item.unpack('C')+128].pack('C')
            end
          elsif shift_latin1
            # One character as latin-1
            ret.push [this_item.unpack('C')+128].pack('C')
            shift_latin1 = false
          else
            # regular character
            ret.push this_item
          end
        end
        ret
      end

      def latin1_to_code128(str)
      end

      # Decode a string in rle format.  This will return a Code128
      # object.
      def decode(str, options = {})
        if str =~ /[^1-4]/ && str =~ /[^wn]/
          raise UnencodableCharactersError, "Pattern must be rle or bar pattern"
        end

        # ensure an rle string
        if str !~ /\A[1-4]+\z/
          str = bars_to_rle(str)
        end

        if str.reverse =~ /\A(#{START_A_RLE}|#{START_B_RLE}|#{START_C_RLE})(.*?)(#{GUARD_PATTERN_RIGHT_RLE})\z/
          str.reverse!
        end

        unless str =~ /\A(#{START_A_RLE}|#{START_B_RLE}|#{START_C_RLE})(.*?)(#{GUARD_PATTERN_RIGHT_RLE})\z/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

        # Each pattern is 3 bars and 3 spaces, with an extra bar
        # at the end.
        unless (str.size - 1) % 6 == 0
          raise UnencodableCharactersError, "Wrong number of bars."
        end

        points = []

        str.scan(/.{6}/).each do |chunk|

          found = false

          char = PATTERN_LOOKUP[chunk]
          if char
            points.push(char)
          elsif chunk == '2'
            # ignore
          elsif chunk == '233111'
            # stop
            points.push(STOP)
          else
            raise UndecodableCharactersError, "Invalid sequence: #{chunk}" unless found
          end

        end

        decoded_string = code128_to_latin1(points.pack('C*'))

        Code128.new(decoded_string, options)
      end

    end

    # Options are :line_character, :space_character, :w_character,
    # :n_character, :checksum_included, and :skip_checksum.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value)

      @value = value.to_s

      if @options[:skip_checksum]
        @encoded_string = value.to_s
        @value = value.to_s
        @check_digit = nil
      elsif @options[:checksum_included]
        raise ChecksumError unless self.class.validate_check_digit_for(value)
        @encoded_string = value.to_s
        @value, @check_digit = self.class.split_payload_and_check_digits(value)
      else
        @value = value.to_s
        @check_digit = self.class.generate_check_digit_for(@value)
        @encoded_string = "#{@value}#{@check_digit}"
      end
    end

    # Returns a string of "w" or "n" ("wide" and "narrow")
    def wn
      @wn ||= wn_str.tr('wn', @options[:w_character].to_s + @options[:n_character].to_s)
    end

    # returns a run-length-encoded string representation
    def rle
      @rle ||= self.class.wn_to_rle(self.wn, @options)
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

    # Creates the actual w/n pattern.  Note that there is a narrow space
    # between each character.
    def wn_str
      @wn_str ||= GUARD_PATTERN_WN + 'n' + @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.join('n') + 'n' + GUARD_PATTERN_WN
    end

  end
end
