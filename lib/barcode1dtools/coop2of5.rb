#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Coop2of5 - Create and decode bar patterns for
  # COOP 2 of 5.  The value encoded is a number with digits 0-9.
  # Internally, the value is treated as a string to preserve
  # leading zeroes.
  #
  # Use :checksum_included => true if you have already added a
  # checksum and wish to have it validated, or :skip_checksum =>
  # true if you don't wish to add one or have it validated.
  #
  # *Note:* COOP 2 of 5 is low-density and limited.  It should not be
  # used in any new applications.
  #
  # == Example
  #  val = "3423"
  #  bc = Barcode1DTools::Coop2of5.new(val)
  #  pattern = bc.bars
  #  rle_pattern = bc.rle
  #  width = bc.width
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Coop2of5 creates the patterns that you need to
  # display COOP 2 of 5 barcodes.  It can also decode a simple w/n
  # string.
  #
  # Coop2of5 characters consist of 3 bars and 2 spaces, with a narrow
  # space between them.  2 of the bars/spaces in each symbol are wide.
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

  class Coop2of5 < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number.
    CHAR_SEQUENCE = "0123456789"

    # Patterns for making bar codes.  Note that the position
    # weights are 7, 4, 2, 1 and the last bit is parity.
    # Each letter is an alternating bar then space, and there
    # is a narrow space between each character.
    PATTERNS = {
      '0'=> {'val'=>0 ,'wn'=>'wwnnn'},
      '1'=> {'val'=>1 ,'wn'=>'nnnww'},
      '2'=> {'val'=>2 ,'wn'=>'nnwnw'},
      '3'=> {'val'=>3 ,'wn'=>'nnwwn'},
      '4'=> {'val'=>4 ,'wn'=>'nwnnw'},
      '5'=> {'val'=>5 ,'wn'=>'nwnwn'},
      '6'=> {'val'=>6 ,'wn'=>'nwwnn'},
      '7'=> {'val'=>7 ,'wn'=>'wnnnw'},
      '8'=> {'val'=>8 ,'wn'=>'wnnwn'},
      '9'=> {'val'=>9 ,'wn'=>'wnwnn'}
    }

    # Left guard pattern
    GUARD_PATTERN_LEFT_WN = 'wnw'
    # Right guard pattern
    GUARD_PATTERN_RIGHT_WN = 'nww'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0',
      :w_character => 'w',
      :n_character => 'n',
      :wn_ratio => '2'
    }

    class << self
      # Coop2of5 can encode digits.  This will return
      # true given a string of digits.
      def can_encode?(value)
        value.to_s =~ /\A[0-9]+\z/
      end

      # Generates a check digit for a given value.  This uses a Luhn
      # algorithm.
      def generate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        mult = 3
        value = value.reverse.split('').inject(0) { |a,c| mult = 4 - mult ; a + c.to_i * mult }
        (10 - (value % 10)) % 10
      end

      # Validates a check digit given a string of digits.  It is assumed
      # that the last digit is the check digit.  Returns "true" if
      # the check digit is correct.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        md = value.match(/^(\d+?)(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

      # Decode a string in rle or w/n format.  This will return a Coop2of5
      # object.
      def decode(str, options = {})
        if str =~ /[^1-3]/ && str =~ /[^wn]/
          raise UnencodableCharactersError, "Pattern must be rle or wn"
        end

        # ensure a wn string
        if str =~ /[1-3]/
          str = str.tr('123','nww')
        end

        if str.reverse =~ /\A#{GUARD_PATTERN_LEFT_WN}n.*?#{GUARD_PATTERN_RIGHT_WN}\z/
          str.reverse!
        end

        unless str =~ /\A#{GUARD_PATTERN_LEFT_WN}n(.*?)#{GUARD_PATTERN_RIGHT_WN}\z/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

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

        Coop2of5.new(decoded_string, options)
      end

    end

    # Create a new Coop2of5 object with a given value.
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
        @encoded_string = value.to_s
        raise ChecksumError unless self.class.validate_check_digit_for(@encoded_string)
        md = @encoded_string.match(/^(\d+?)(\d)$/)
        @value, @check_digit = md[1], md[2].to_i
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
      @wn_str ||= GUARD_PATTERN_LEFT_WN + 'n' + @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.join('n') + 'n' + GUARD_PATTERN_RIGHT_WN
    end

  end
end
