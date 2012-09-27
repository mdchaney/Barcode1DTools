#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Code128 - Create and decode bar patterns for
  # Code 128.  Code 128 is the king of 1D bar codes and should be
  # used for any alpha-numeric application.  Code 128 can encode
  # any character from 0 to 255, although it is most efficient
  # when using only 0 to 95 or 32 to 127.  It is also very
  # efficient at encoding only digits, although Interleaved 2 of 5
  # is also a good choice with potentially less overhead.
  #
  # Code 128 barcodes always include a checksum, and the checksum
  # is calculated from the encoded value rather than the payload.
  # Because of this, there are no options for including a check
  # digit or validating one.  It is always included.
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
  # display Code 128 barcodes.  It can also decode a simple rle or
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
  # The quiet zone on each side should be at least the greater of 10
  # unit widths or 6.4mm.  Typically a textual rendition of the
  # payload is shown underneath the bars.

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

    # For ease.  These can also be looked up in any
    # ASCII_TO_CODE_x hashes symbolically, e.g.
    # START_A == ASCII_TO_CODE_A[:start_a]
    START_A = 103
    START_B = 104
    START_C = 105
    SHIFT = 98
    CODE_A = 101
    CODE_B = 100
    CODE_C = 99
    STOP = 106
    FNC_1 = 102
    FNC_2 = 97
    FNC_3 = 96
    # Note that FNC_4 is 100 in set B and 101 in set A

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
    CODE_A_TO_ASCII = ((32..95).to_a + (0..31).to_a).collect { |c| [c].pack('C') } + [ :fnc_3, :fnc_2, :shift_b, :code_c, :code_b, :fnc_4, :fnc_1, :start_a, :start_b, :start_c, :stop ]
    ASCII_TO_CODE_A = (0..(CODE_A_TO_ASCII.length-1)).inject({}) { |a,c| a[CODE_A_TO_ASCII[c]] = c; a }
    CODE_A_TO_HIGH_ASCII = CODE_A_TO_ASCII.collect { |a| a.is_a?(Symbol) ? a : [a.unpack("C").first+128].pack("C") }.collect { |c| RUBY_VERSION < "1.9" || c.is_a?(Symbol) ? c : c.force_encoding('ISO-8859-1') }
    HIGH_ASCII_TO_CODE_A = (0..(CODE_A_TO_HIGH_ASCII.length-1)).inject({}) { |a,c| a[CODE_A_TO_HIGH_ASCII[c]] = c; a }

    # Code B encodes ASCII space (\x20, dec. 32) to DEL (\x7f,
    # dec. 127).  This is identical to Code A for the first 63
    # characters.  It also includes FNC 1-4 with FNC 4 in a
    # different position than in set A.
    CODE_B_TO_ASCII = (32..127).collect { |c| [c].pack('C') } + [ :fnc_3, :fnc_2, :shift_a, :code_c, :fnc_4, :code_a, :fnc_1, :start_a, :start_b, :start_c, :stop ]
    ASCII_TO_CODE_B = (0..(CODE_B_TO_ASCII.length-1)).inject({}) { |a,c| a[CODE_B_TO_ASCII[c]] = c; a }
    CODE_B_TO_HIGH_ASCII = CODE_B_TO_ASCII.collect { |a| a.is_a?(Symbol) ? a : [a.unpack("C").first+128].pack("C") }.collect { |c| RUBY_VERSION < "1.9" || c.is_a?(Symbol) ? c : c.force_encoding('ISO-8859-1') }
    HIGH_ASCII_TO_CODE_B = (0..(CODE_B_TO_HIGH_ASCII.length-1)).inject({}) { |a,c| a[CODE_B_TO_HIGH_ASCII[c]] = c; a }

    # Code C encodes digit pairs 00 to 99 as well as FNC 1.
    CODE_C_TO_ASCII = ("00".."99").to_a + [ :code_b, :code_a, :fnc_1, :start_a, :start_b, :start_c, :stop ]
    ASCII_TO_CODE_C = (0..(CODE_C_TO_ASCII.length-1)).inject({}) { |a,c| a[CODE_C_TO_ASCII[c]] = c; a }

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

      # Convert a code128 encoded string to an ASCII/Latin-1
      # representation.  The return value is an array if there
      # are any FNC codes included.  Use the option
      # :no_latin1 => true to simply return FNC 4 instead of
      # coding the following characters to the high Latin-1
      # range.  Use :raw_array => true if you wish to see an
      # array of the actual characters in the code.  It will
      # turn any ASCII/Latin-1 characters to their standard
      # representation, but it also includes all start, shift,
      # code change, etc. characters.  Useful for debugging.
      def code128_to_latin1(str, options = {})
        ret = []
        in_high_latin1 = false
        shift_codeset = nil
        shift_latin1 = false
        current_codeset = 'A'
        current_lookup = CODE_A_TO_ASCII
        md = parse_code128(str)
        raise UndecodeableCharactersError unless md
        start_item = CODE_A_TO_ASCII[md[1].unpack('C').first]
        if start_item == :start_a
          current_codeset = 'A'
          current_lookup = CODE_A_TO_ASCII
        elsif start_item == :start_b
          current_codeset = 'B'
          current_lookup = CODE_B_TO_ASCII
        elsif start_item == :start_c
          current_codeset = 'C'
          current_lookup = CODE_C_TO_ASCII
        end
        ret.push(start_item) if options[:raw_array]
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
              current_lookup = CODE_A_TO_ASCII
            elsif this_item == :code_b
              current_codeset = 'B'
              current_lookup = CODE_B_TO_ASCII
            elsif this_item == :code_c
              current_codeset = 'C'
              current_lookup = CODE_C_TO_ASCII
            elsif this_item == :shift_a
              shift_codeset = CODE_A_TO_ASCII
            elsif this_item == :shift_b
              shift_codeset = CODE_B_TO_ASCII
            elsif this_item == :fnc_4 && !options[:no_latin1]
              if shift_latin1
                in_high_latin1 = !in_high_latin1
                shift_latin1 = false
              else
                shift_latin1 = true
              end
            elsif !options[:raw_array]
              ret.push this_item
            end
            ret.push(this_item) if options[:raw_array]
          elsif in_high_latin1 && ['A', 'B'].include?(current_codeset)
            # Currently processing as latin-1.  If we find the shift,
            # handle as regular character.
            if shift_latin1
              ret.push this_item
              shift_latin1 = false
            else
              ret.push [this_item.unpack('C').first+128].pack('C')
            end
          elsif shift_latin1
            # One character as latin-1
            ret.push [this_item.unpack('C').first+128].pack('C')
            shift_latin1 = false
          else
            # regular character
            ret.push this_item
          end
        end
        unless options[:raw_array]
          ret = ret.inject([]) { |a,c| (a.size==0 || a.last.is_a?(Symbol) || c.is_a?(Symbol)) ? a.push(c) : (a[a.size-1] += c); a }
        end
        # Make sure it's Latin-1 for Ruby 1.9+
        if RUBY_VERSION >= "1.9"
          ret = ret.collect { |c| c.is_a?(Symbol) ? c : c.force_encoding('ISO-8859-1') }
        end
        if options[:raw_array]
          ret.push(md[2].unpack('C').first)
          ret.push(:stop)
        end
        ret
      end

      # Pass an array or string for encoding.  The result is
      # a string that is a Code 128 representation of the input.
      # We do optimize, but perhaps not perfectly.  The
      # optimization should cover 99% of cases very well,
      # although I'm sure an edge case could be created that
      # would be suboptimal.
      def latin1_to_code128(str, options = {})
        if str.is_a?(String)
          str = [str]
        elsif !str.is_a?(Array)
          raise UnencodableCharactersError
        end
        arr = str.inject([]) { |a,c| c.is_a?(Symbol) ? a.push(c) : a.push(c.to_s.split('')) ; a}.flatten
        # Now, create a set of maps to see how this will map to each
        # code set.
        map_a = arr.collect { |c| ASCII_TO_CODE_A[c] ? 'a' : HIGH_ASCII_TO_CODE_A[c] ? 'A' : '-' }
        map_b = arr.collect { |c| ASCII_TO_CODE_B[c] ? 'b' : HIGH_ASCII_TO_CODE_B[c] ? 'B' : '-' }
        last_is_digit=false
        map_c = arr.collect do |c|
          if c.is_a?(Symbol) && c == :fnc_1
            if last_is_digit
              last_is_digit = false
              ['-','-']
            else
              'c'
            end
          elsif c.is_a?(String) && c >= '0' && c <= '9'
            if last_is_digit
              last_is_digit = false
              ['c','C']
            else
              last_is_digit = true
              nil
            end
          elsif last_is_digit
            last_is_digit = false
            ['-','-']
          else
            '-'
          end
        end.flatten.compact
        map_c.push('-') if last_is_digit
        # Let's do it
        map_a = map_a.join + '-'
        map_b = map_b.join + '-'
        map_c = map_c.join
        codepoints = ''
        # Strategy - create an a/b map first.  We'll do this based on
        # the least switching required which can be determined via a
        # regexp ("aaa--aa" has two switches, for instance).  After
        # that is created, we can then go in and fill in runs from
        # C - runs of 6 or more in the middle or 4 or more at either
        # end.  "444a" would just be encoded in set B, for instance,
        # but "4444a" would be encoded in C then B.
        # In the real world, switching between A and B is rare so
        # we're not trying too hard to optimize it here.
        in_codeset = nil
        x = 0
        while x < map_a.length - 1 do
          map_a_len = map_a.index('-',x).to_i - x
          map_b_len = map_b.index('-',x).to_i - x
          if map_a_len==0 && map_b_len==0
            raise "Ack!  Bad mapping: #{map_a} & #{map_b}"
          end
          if map_a_len >= map_b_len
            codepoints += map_a[x,map_a_len]
            x += map_a_len
          else
            codepoints += map_b[x,map_b_len]
            x += map_b_len
          end
        end
        # Now, fix up runs of C.  Look for runs of 4+ at the ends
        # and 6+ in the middle.  The runs must have cC in them, as
        # there's no gains from changing FNC 1 to set C.
        runs = map_c.split(/(c[cC]+Cc*)/)
        offset = 0
        0.upto(runs.length-1) do |x|
          if x==0 || x==runs.length-1
            # only needs to be 4
            if runs[x] =~ /c[cC]+C/
              codepoints[offset,runs[x].length] = runs[x]
            end
            offset += runs[x].length
          else
            # must be 6+
            if runs[x] =~ /c[cC]{3,}C/
              codepoints[offset,runs[x].length] = runs[x]
            end
            offset += runs[x].length
          end
        end
        #{ :map_a => map_a, :map_b => map_b, :map_c => map_c, :codepoints => codepoints }
        # Now, create the string
        ret = []
        current_set = codepoints[0,1].downcase
        ret.push(current_set == 'a' ? START_A : current_set == 'b' ? START_B : START_C)
        0.upto(codepoints.length-1) do |x|
          if codepoints[x,1].downcase != current_set
            current_set = codepoints[x,1].downcase
            ret.push(current_set == 'a' ? CODE_A : current_set == 'b' ? CODE_B : CODE_C)
          end
          if current_set == 'c' && codepoints[x,1] == 'c'
            # ignore capital Cs
            if arr[x] == :fnc_1
              ret.push(FNC_1)
            else
              ret.push((arr[x]+arr[x+1]).to_i)
            end
          elsif ['A','B'].include?(codepoints[x,1])
            # Find FNC_4 and push it (101 in A and 100 in B)
            # now push the letter looked up in CODE_x_TO_HIGH_ASCII
            if codepoints[x,1] == 'A'
              ret.push(HIGH_ASCII_TO_CODE_A[:fnc_4])
              ret.push(HIGH_ASCII_TO_CODE_A[arr[x]])
            else
              ret.push(HIGH_ASCII_TO_CODE_B[:fnc_4])
              ret.push(HIGH_ASCII_TO_CODE_B[arr[x]])
            end
          elsif ['a','b'].include?(codepoints[x,1])
            # find the letter in CODE_x_TO_ASCII and push it
            if codepoints[x,1] == 'a'
              ret.push(ASCII_TO_CODE_A[arr[x]])
            else
              ret.push(ASCII_TO_CODE_B[arr[x]])
            end
          end
        end
        check_digit = generate_check_digit_for(ret.pack('C*'))
        ret.push(check_digit.unpack('C').first)
        ret.push(ASCII_TO_CODE_A[:stop])
        ret.pack('C*')
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
          elsif chunk == '233111'
            # stop
            points.push(STOP)
          else
            raise UndecodableCharactersError, "Invalid sequence: #{chunk}" unless found
          end

        end

        decoded_string = code128_to_latin1(points.pack('C*'), options)

        Code128.new(decoded_string, options)
      end

    end

    # Options are :line_character, :space_character, and
    # :raw_value.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      if options[:raw_value]
        @encoded_string = value
        @value = self.class.code128_to_latin1(value, options)
      else
        if value.is_a?(Array)
          @value = value
        else
          @value = [value.to_s]
        end
        # In ruby 1.9, change to Latin-1 if it's in another encoding.
        # Really, the caller needs to handle this.
        if RUBY_VERSION >= "1.9"
          @value = @value.collect do |item|
            if item.is_a?(Symbol)
              item
            else
              item = item.to_s
              if ['US-ASCII','ISO-8859-1'].include?(item.encoding)
                item
              else
                item.encode('ISO-8859-1')
              end
            end
          end
        end
        raise UnencodableCharactersError unless self.class.can_encode?(value)
        @encoded_string = self.class.latin1_to_code128(@value, options)
      end

      md = self.class.parse_code128(@encoded_string)
      @check_digit = md[3]
    end

    # variable bar width, no w/n string
    def wn
      raise NotImplementedError
    end

    # returns a run-length-encoded string representation
    def rle
      @rle ||= gen_rle(@encoded_string, @options)
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

    def gen_rle(encoded_string, options)
      @rle_str ||= @encoded_string.split('').collect { |c| PATTERNS[c.unpack('C').first] }.join
    end

  end
end
