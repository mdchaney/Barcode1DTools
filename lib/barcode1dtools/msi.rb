#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::MSI - Create and decode bar patterns for
  # MSI.  The value encoded is a string which may contain the
  # digits 0-9.
  #
  # There are four possible check digit calculations, and you
  # may use the option :check_digit => 'x' to choose which
  # one to use.  "x" may be one of "mod 10", "mod 11",
  # "mod 1010", or "mod 1110".  The default is "mod 10".
  # For a mod 11 check digit, you may use :check_style =>
  # 'ibm' or 'ncr'.
  #
  # MSI is a terrible symbology in modern terms and should
  # not be used in any new applications.
  #
  # == Example
  #  val = "2898289238"
  #  bc = Barcode1DTools::MSI.new(val)
  #  pattern = bc.bars
  #  rle_pattern = bc.rle
  #  width = bc.width
  #
  # The object created is immutable.
  #
  # Barcode1DTools::MSI creates the patterns that you need to
  # display MSI barcodes.  It can also decode a simple w/n
  # string.
  #
  # MSI characters consist of 4 bars and 4 spaces.  The
  # representation is simply binary where a binary "0" is
  # represented as a narrow bar followed by a wide space and
  # a binary "1" is a wide bar followed by a narrow space.
  # The bits are ordered descending, so 9 is 1001 binary,
  # "wn nw nw wn" in w/n format.
  #
  # == Formats
  # There are three formats for the returned pattern:
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
  # *wn* - The native format for this barcode type.  The string
  # consists of a series of "w" and "n" characters.  The first
  # item is always a black line, with subsequent characters
  # alternating between spaces and lines.  A "wide" item
  # is twice the width of a "narrow" item.
  #
  # The "width" method will tell you the total end-to-end width, in
  # units, of the entire barcode.
  #
  # == Rendering
  #
  # The author is aware of no standards for display.

  class MSI < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number
    CHAR_SEQUENCE = "0123456789"

    # Patterns for making bar codes
    PATTERNS = {
      '0'=> {'val'=>0 ,'wn'=>'nwnwnwnw'},
      '1'=> {'val'=>1 ,'wn'=>'nwnwnwwn'},
      '2'=> {'val'=>2 ,'wn'=>'nwnwwnnw'},
      '3'=> {'val'=>3 ,'wn'=>'nwnwwnwn'},
      '4'=> {'val'=>4 ,'wn'=>'nwwnnwnw'},
      '5'=> {'val'=>5 ,'wn'=>'nwwnnwwn'},
      '6'=> {'val'=>6 ,'wn'=>'nwwnwnnw'},
      '7'=> {'val'=>7 ,'wn'=>'nwwnwnwn'},
      '8'=> {'val'=>8 ,'wn'=>'wnnwnwnw'},
      '9'=> {'val'=>9 ,'wn'=>'wnnwnwwn'}
    }

    # Left guard pattern
    GUARD_PATTERN_LEFT_WN = 'wn'
    # Right guard pattern
    GUARD_PATTERN_RIGHT_WN = 'nwn'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0',
      :w_character => 'w',
      :n_character => 'n',
      :wn_ratio => '2',
      :check_digit => 'mod 10',
      :check_style => 'ibm'
    }

    class << self
      # MSI can encode digits - returns true if given a string of digits.
      def can_encode?(value)
        value.to_s =~ /\A\d+\z/
      end

      # Generates a check digit using one of four algorithms.  The algorithm
      # must be specified in the second parameter (the options hash).
      def generate_check_digit_for(value, options = {})
        if options[:check_digit] == 'mod 10'
          generate_mod10_check_digit_for(value).to_s
        elsif options[:check_digit] == 'mod 11'
          generate_mod11_check_digit_for(value, options[:check_style]).to_s
        elsif options[:check_digit] == 'mod 1010'
          mod10 = generate_mod10_check_digit_for(value)
          mod10_2 = generate_mod10_check_digit_for(value + mod10.to_s)
          "#{mod10}#{mod10_2}"
        elsif options[:check_digit] == 'mod 1110'
          mod11 = generate_mod11_check_digit_for(value, options[:check_style])
          mod10_2 = generate_mod10_check_digit_for(value + mod11.to_s)
          "#{mod11}#{mod10_2}"
        end
      end

      # Validates the check digit(s) for a given string.
      def validate_check_digit_for(value, options = {})
        payload, check_digits = split_payload_and_check_digits(value, options)
        self.generate_check_digit_for(payload, options) == check_digits
      end

      # Splits payload and check digit(s) given a check_digit option.
      def split_payload_and_check_digits(value, options = {})
        if options[:check_digit] == 'mod 1010' || options[:check_digit] == 'mod 1110'
          md = value.to_s.match(/\A(.*?)(..)\z/)
        else
          md = value.to_s.match(/\A(.*?)(.)\z/)
        end
        [md[1], md[2]]
      end

      # Generates a mod 10 check digit.
      def generate_mod10_check_digit_for(value)
        value = value.to_s
        valarr = value.scan(/\d\d?/)
        if value.size.odd?
          odd = valarr.collect { |c| c[0,1] }
          even = valarr.collect { |c| c[1,1] }
        else
          odd = valarr.collect { |c| c[1,1] }
          even = valarr.collect { |c| c[0,1] }
        end
        odd = (odd.join.to_i * 2).to_s.split('').inject(0) { |a,c| a + c.to_i }
        even = even.inject(0) { |a,c| a + c.to_i }
        (10 - ((odd + even) % 10)) % 10
      end

      # Generates a mod 11 check digit.
      def generate_mod11_check_digit_for(value, style)
        max = (style == 'ncr' ? 9 : 7)
        value = value.to_s
        weight = 1
        sum = value.split('').reverse.inject(0) { |a,c| weight = (weight == max ? 2 : weight + 1); a + weight * c.to_i }
        (11 - (sum % 11)) % 11
      end

      # Decode a string in rle format.  This will return a MSI
      # object.
      def decode(str, options = {})
        if str =~ /[^1-3]/ && str =~ /[^wn]/
          raise UnencodableCharactersError, "Pattern must be rle or wn"
        end

        # ensure a wn string
        if str =~ /[1-3]/
          str = str.tr('123','nww')
        end

        if str.reverse =~ /\A#{GUARD_PATTERN_LEFT_WN}.*?#{GUARD_PATTERN_RIGHT_WN}\z/
          str.reverse!
        end

        unless str =~ /\A#{GUARD_PATTERN_LEFT_WN}(.*?)#{GUARD_PATTERN_RIGHT_WN}\z/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

        wn_pattern = $1

        # Each pattern is 4 bars and 4 spaces, with a space between.
        unless wn_pattern.size % 8 == 0
          raise UnencodableCharactersError, "Wrong number of bars."
        end

        decoded_string = ''

        wn_pattern.scan(/.{8}/).each do |chunk|

          found = false

          PATTERNS.each do |char,hsh|
            if chunk == hsh['wn']
              decoded_string += char
              found = true
              break;
            end
          end

          raise UndecodableCharactersError, "Invalid sequence: #{chunk}" unless found

        end

        MSI.new(decoded_string, options)
      end

    end

    # Create a new MSI object with a given value.
    # Options are :line_character, :space_character, :w_character,
    # :n_character, :check_digit, :checksum_included, and
    # :skip_checksum.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value)

      if @options[:skip_checksum]
        @encoded_string = value.to_s
        @value = value.to_s
        @check_digit = nil
      elsif @options[:checksum_included]
        raise ChecksumError unless self.class.validate_check_digit_for(value, @options)
        @encoded_string = value.to_s
        @value, @check_digit = self.class.split_payload_and_check_digits(value, @options)
      else
        @value = value.to_s
        @check_digit = self.class.generate_check_digit_for(@value, @options)
        @encoded_string = "#{@value}#{@check_digit}"
      end
    end

    # Returns a string of "w" or "n" ("wide" and "narrow")
    def wn
      @wn ||= wn_str.tr('wn', @options[:w_character].to_s + @options[:n_character].to_s)
    end

    # Returns a run-length-encoded string representation
    def rle
      @rle ||= self.class.wn_to_rle(self.wn, @options)
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

    # Creates the actual w/n pattern.  Note that there is a narrow space
    # between each character.
    def wn_str
      @wn_str ||= GUARD_PATTERN_LEFT_WN + @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.join + GUARD_PATTERN_RIGHT_WN
    end

  end
end
