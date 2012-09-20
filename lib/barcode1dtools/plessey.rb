#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Plessey - Create and decode bar patterns for
  # Plessey.  The value encoded is a string which may contain the
  # digits 0-9 and the letters A-F (0-15 hexadecimal).
  #
  # According to Wikipedia, a Plessey code should contain a two
  # digit CRC8 checksum.  This code does not provide checksum
  # generation or validation.
  #
  # Plessey is a terrible symbology in modern terms and should
  # not be used in any new applications.
  #
  # val = "2898289238AF"
  # bc = Barcode1DTools::Plessey.new(val)
  # pattern = bc.bars
  # rle_pattern = bc.rle
  # width = bc.width
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Plessey creates the patterns that you need to
  # display Plessey barcodes.  It can also decode a simple w/n
  # string.
  #
  # Plessey characters consist of 4 bars and 4 spaces.  The
  # representation is simply binary where a binary "0" is
  # represented as a narrow bar followed by a wide space and
  # a binary "1" is a wide bar followed by a narrow space.
  # The bits are ordered ascending, so 9 is 1001 binary,
  # "wn nw nw wn" in w/n format.
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
  #== Rendering
  #
  # The author is aware of no standards for display.

  class Plessey < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number
    CHAR_SEQUENCE = "0123456789ABCDEF"

    # Patterns for making bar codes
    PATTERNS = {
      '0'=> {'val'=>0 ,'wn'=>'nwnwnwnw'},
      '1'=> {'val'=>1 ,'wn'=>'wnnwnwnw'},
      '2'=> {'val'=>2 ,'wn'=>'nwwnnwnw'},
      '3'=> {'val'=>3 ,'wn'=>'wnwnnwnw'},
      '4'=> {'val'=>4 ,'wn'=>'nwnwwnnw'},
      '5'=> {'val'=>5 ,'wn'=>'wnnwwnnw'},
      '6'=> {'val'=>6 ,'wn'=>'nwwnwnnw'},
      '7'=> {'val'=>7 ,'wn'=>'wnwnwnnw'},
      '8'=> {'val'=>8 ,'wn'=>'nwnwnwwn'},
      '9'=> {'val'=>9 ,'wn'=>'wnnwnwwn'},
      'A'=> {'val'=>10 ,'wn'=>'nwwnnwwn'},
      'B'=> {'val'=>11 ,'wn'=>'wnwnnwwn'},
      'C'=> {'val'=>12 ,'wn'=>'nwnwwnwn'},
      'D'=> {'val'=>13 ,'wn'=>'wnnwwnwn'},
      'E'=> {'val'=>14 ,'wn'=>'nwwnwnwn'},
      'F'=> {'val'=>15 ,'wn'=>'wnwnwnwn'}
    }

    GUARD_PATTERN_LEFT_WN = 'wnwnnwwn'
    GUARD_PATTERN_RIGHT_WN = 'wnwnnwnw'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0',
      :w_character => 'w',
      :n_character => 'n',
      :wn_ratio => '2'
    }

    class << self
      # Plessey can encode digits and A-F.
      def can_encode?(value)
        value.to_s =~ /\A[0-9A-F]+\z/
      end

      def generate_check_digit_for(value)
        raise NotImplementedError
      end

      def validate_check_digit_for(value)
        raise NotImplementedError
      end

      # Decode a string in rle format.  This will return a Plessey
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

        Plessey.new(decoded_string, options)
      end

    end

    # Options are :line_character, :space_character, :w_character,
    # :n_character, :checksum_included, and :skip_checksum.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value)

      @value = value.to_s
      @encoded_string = value.to_s
      @check_digit = nil
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
      @wn_str ||= GUARD_PATTERN_LEFT_WN + @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.join + GUARD_PATTERN_RIGHT_WN
    end

  end
end
