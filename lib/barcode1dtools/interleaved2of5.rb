module Barcode1DTools

  # Barcode1DTools::Interleaved2of5 - Create pattern for Interleaved 2 of 5
  # (also known as I 2/5 or ITF) barcodes.  The value encoded is an
  # integer, and a checksum digit will be added.  You can add the option
  # :checksum_included => true when initializing to specify that you
  # have already included a checksum, or :skip_checksum => true to
  # specify that no checksum should be added or checked.  A ChecksumError
  # will be raised if :checksum_included => true, :skip_checksum is
  # missing or false, and the last digit is invalid as a checksum.
  #
  # I 2/5 can only encode an even number of digits (including the
  # checksum), so a "0" will be prepended if there is an odd number of
  # digits.  The 0 has no effect on the checksum.
  #
  # num = 238982
  # bc = Barcode1DTools::Interleaved2of5.new(num)
  # pattern = bc.bars
  # rle_pattern = bc.rle
  # wn_pattern = bc.wn
  # width = bc.width
  # check_digit = Barcode1DTools::Interleaved2of5.generate_check_digit_for(num)
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Interleaved2of5 creates the patterns that you need to
  # display Interleaved 2 of 5 (also known as I 2/5) barcodes.
  #
  # I 2/5 barcodes consist of lines and spaces that are either "wide" or
  # "narrow", with "wide" lines or spaces being twice the width of
  # narrow lines or spaces.
  #
  # There are three formats for the returned pattern:
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
  #   wn -   The native format for this barcode type.  The string
  #          consists of a series of "w" and "n" characters.  The first
  #          item is always a black line, with subsequent characters
  #          alternating between spaces and lines.  A "wide" item
  #          is twice the width of a "narrow" item.
  #
  # The "width" method will tell you the total end-to-end width, in
  # units, of the entire barcode.
  #
  # In this encoding, pairs of digits are interleaved with each other,
  # so the first digit is the "bars" and the second digit is the
  # "spaces".  Each digit consists of 5 sets of wide or narrow bars or
  # spaces, with 2 of the 5 being wide.  The pattern can be calculated
  # by considering a "weight" for each position: 1, 2, 4, 7, and 0, with
  # "0" itself being represented by 4 + 7.  So, 3 is 1 + 2, or "wwnnn",
  # while 7 is "nnnww" (7 + 0).  More information is available on
  # Wikipedia.

  class Interleaved2of5 < Barcode1D

    # patterns and such go here
    PATTERNS = {
      'start' => 'nnnn',
      '0' => 'nnwwn',
      '1' => 'wnnnw',
      '2' => 'nwnnw',
      '3' => 'wwnnn',
      '4' => 'nnwnw',
      '5' => 'wnwnn',
      '6' => 'nwwnn',
      '7' => 'nnnww',
      '8' => 'wnnwn',
      '9' => 'nwnwn',
      'stop' => 'wnn'
    }

    WN_RATIO = 2

    DEFAULT_OPTIONS = {
      :w_character => 'w',
      :n_character => 'n',
      :line_character => '1',
      :space_character => '0'
    }

    class << self
      # returns true or false
      def can_encode?(value)
        value.is_a?(Integer) || value.to_s =~ /^[0-9]+$/
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".  Note that if value has an even
      # number of digits, a "0" will be prepended for this operation.
      def generate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        mult = 1
        value = value.to_s
        value = "0#{value}" if value.size.even?
        value = value.split('').inject(0) { |a,c| mult = 4 - mult ; a + c.to_i * mult }
        10 - (value % 10)
      end

      # validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        value = value.to_i.to_s
        value = "0#{value}" if value.size.odd?
        md = value.match(/^(\d(?:\d\d)+)(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

    end

    # Options are :line_character, :space_character, :w_character,
    # :n_character, :skip_checksum, and :checksum_included.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value)

      if @options[:skip_checksum]
        @encoded_string = value.to_s
        @value = value.to_i
        @check_digit = nil
      elsif @options[:checksum_included]
        raise ChecksumError unless self.class.validate_check_digit_for(value)
        @encoded_string = value.to_s
        @value = value.to_i / 10
        @check_digit = value % 10
      else
        # need to add a checksum
        @value = value.to_i
        @check_digit = self.class.generate_check_digit_for(@value)
        @encoded_string = "#{@value.to_s}#{@check_digit}"
      end

      @encoded_string = '0' + @encoded_string if @encoded_string.size.odd?
    end

    # Returns a string of "w" or "n" ("wide" and "narrow")
    def wn
      @wn ||= wn_str.tr('wn', @options[:w_character].to_s + @options[:n_character].to_s)
    end

    # returns a run-length-encoded string representation
    def rle
      @rle ||= self.wn.tr('nw','1'+WN_RATIO.to_s)
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

    def wn_str
      @wn_str ||=
        PATTERNS['start'] +
        @encoded_string.unpack('A2'*(@encoded_string.size/2)).inject('') { |a,str| a + interleave(str) } +
        PATTERNS['stop']
    end

    # Requires a two-digit string
    def interleave(two_digits)
      bars_pattern = PATTERNS[two_digits[0,1]]
      spaces_pattern = PATTERNS[two_digits[1,1]]
      (0..4).inject('') { |ret,x| ret + bars_pattern[x,1] + spaces_pattern[x,1] }
    end
  end
end
