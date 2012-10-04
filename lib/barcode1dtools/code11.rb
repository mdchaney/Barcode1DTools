#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Code11 - Create and decode bar patterns for
  # Code11.  The value encoded is a string which may contain the
  # digits 0-9 and the dash symbol "-".  The standard specifies
  # one or two check digits may be added depending on the length
  # of the payload.  Use :checksum_included => true if you have
  # already added a checksum and wish to have it validated, or
  # :skip_checksum => true if you don't wish to add one or have
  # it validated.
  #
  # Code 11 is used in the telecom industry for equipment
  # labeling.  It should not be used in any new applications.
  #
  # ==Example
  #  val = "29382-38"
  #  bc = Barcode1DTools::Code11.new(val)
  #  pattern = bc.bars
  #  rle_pattern = bc.rle
  #  width = bc.width
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Code11 creates the patterns that you need to
  # display Code11 barcodes.  It can also decode a simple w/n
  # string.
  #
  # Code11 characters consist of 3 bars and 2 spaces, with a narrow
  # space between them.  Three of the characters- 0, 9, and "-" -
  # are 6 units wide.  The rest are 7 units wide.
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
  # The standard w/n ratio seems to be 2:1.  There seem to be no real
  # standards for display.

  class Code11 < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number
    CHAR_SEQUENCE = "0123456789-"

    # Patterns for making bar codes
    PATTERNS = {
      '0'=> {'val'=>0 ,'wn'=>'nnnnw'},
      '1'=> {'val'=>1 ,'wn'=>'wnnnw'},
      '2'=> {'val'=>2 ,'wn'=>'nwnnw'},
      '3'=> {'val'=>3 ,'wn'=>'wwnnn'},
      '4'=> {'val'=>4 ,'wn'=>'nnwnw'},
      '5'=> {'val'=>5 ,'wn'=>'wnwnn'},
      '6'=> {'val'=>6 ,'wn'=>'nwwnn'},
      '7'=> {'val'=>7 ,'wn'=>'nnnww'},
      '8'=> {'val'=>8 ,'wn'=>'wnnwn'},
      '9'=> {'val'=>9 ,'wn'=>'wnnnn'},
      '-'=> {'val'=>10 ,'wn'=>'nnwnn'}
    }

    # Guard pattern for Code 11
    GUARD_PATTERN_WN = 'nnwwn'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0',
      :w_character => 'w',
      :n_character => 'n',
      :wn_ratio => '2'
    }

    class << self
      # Returns true if the value presented can be encoded in Code 11.
      # Code11 can encode digits and dashes.
      def can_encode?(value)
        value.to_s =~ /\A[0-9\-]+\z/
      end

      # Generates a check digit for the given value.  Note that Code 11
      # barcodes may have two check digits if the size of the value is
      # 10 or more characters.
      def generate_check_digit_for(value)
        mult = 0
        sum_c = value.to_s.reverse.split('').inject(0) { |a,c| mult = (mult == 11 ? 1 : mult + 1); a + mult * PATTERNS[c]['val'] }
        check_c = CHAR_SEQUENCE[sum_c % 11,1]
        if value.to_s.size > 9
          mult = 0
          sum_k = (value.to_s + check_c).reverse.split('').inject(0) { |a,c| mult = (mult == 10 ? 1 : mult + 1); a + mult * PATTERNS[c]['val'] }
          check_k = CHAR_SEQUENCE[sum_k % 9,1]
        else
          check_k = ''
        end
        "#{check_c}#{check_k}"
      end

      # Returns true if the given check digit(s) is correct.
      # The check digit is the last one or two characters of
      # the value that is passed.
      def validate_check_digit_for(value)
        payload, check_digits = split_payload_and_check_digits(value)
        self.generate_check_digit_for(payload) == check_digits
      end

      # Split the given value into a payload and check digit or
      # digits.
      def split_payload_and_check_digits(value)
        if value.to_s.size > 11
          # two check digits
          md = value.to_s.match(/\A(.*)(..)\z/)
        else
          md = value.to_s.match(/\A(.*)(.)\z/)
        end
        [md[1], md[2]]
      end

      # Decode a string in rle format.  This will return a Code11
      # object.
      def decode(str, options = {})
        if str =~ /[^1-3]/ && str =~ /[^wn]/
          raise UnencodableCharactersError, "Pattern must be rle or wn"
        end

        # ensure a wn string
        if str =~ /[1-3]/
          str = str.tr('123','nww')
        end

        if str.reverse =~ /\A#{GUARD_PATTERN_WN}n.*?#{GUARD_PATTERN_WN}\z/
          str.reverse!
        end

        unless str =~ /\A#{GUARD_PATTERN_WN}n(.*?)#{GUARD_PATTERN_WN}\z/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

        # Adding an "n" to make it easier to scan
        wn_pattern = $1

        # Each pattern is 3 bars and 2 spaces, with a space between.
        unless wn_pattern.size % 6 == 0
          raise UnencodableCharactersError, "Wrong number of bars."
        end

        decoded_string = ''

        wn_pattern.scan(/(.{5})n/).each do |chunk|

          chunk = chunk.first
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

        Code11.new(decoded_string, options)
      end

    end

    # Create a new Code 11 object with a value.
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

    # Returns a run-length-encoded string representation
    def rle
      @rle ||= self.class.wn_to_rle(self.wn, @options)
    end

    # Returns the bar/space pattern as 1s and 0s.
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
      @wn_str ||= GUARD_PATTERN_WN + 'n' + @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.join('n') + 'n' + GUARD_PATTERN_WN
    end

  end
end
