#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::PostNet - Create and decode bar patterns for
  # PostNet.  The value encoded is a zip code, which may be 5,
  # 9, or 11 digits long.
  #
  # Use :checksum_included => true if you have already added a
  # checksum and wish to have it validated, or :skip_checksum =>
  # true if you don't wish to add one or have it validated.
  #
  # PostNet is used by the USPS for mail sorting, although it
  # is technically deprecated.
  #
  # val = "37211"
  # bc = Barcode1DTools::PostNet.new(val)
  # pattern = bc.bars
  # rle_pattern = bc.rle
  # width = bc.width
  #
  # The object created is immutable.
  #
  # Barcode1DTools::PostNet creates the patterns that you need to
  # display PostNet barcodes.  It can also decode a simple w/n
  # string.  In this symbology, "wide" means "tall" and "narrow"
  # means "short".
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
  # See USPS documentation for exact specifications for display.

  class PostNet < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number
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

    GUARD_PATTERN_LEFT_WN = 'w'
    GUARD_PATTERN_RIGHT_WN = 'w'

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0',
      :w_character => 'w',
      :n_character => 'n'
    }

    class << self
      # PostNet can encode 5, 9, or 11 digits, plus a check digit.
      def can_encode?(value)
        value.to_s =~ /\A\d{5}(\d{4})?(\d{2})?\d?\z/
      end

      def generate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        value = value.split('').collect { |c| c.to_i }.inject(0) { |a,c| a + c }
        (10 - (value % 10)) % 10
      end

      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        md = value.match(/^(\d+?)(\d)$/)
        self.generate_check_digit_for(md[1]) == md[2].to_i
      end

      # Decode a string in rle format.  This will return a PostNet
      # object.
      def decode(str, options = {})
        if str =~ /[^1-3]/ && str =~ /[^wn]/
          raise UnencodableCharactersError, "Pattern must be rle or wn"
        end

        # ensure a wn string
        if str =~ /[1-3]/
          str = str.tr('123','nww')
        end

        unless str =~ /\A#{GUARD_PATTERN_LEFT_WN}(.*?)#{GUARD_PATTERN_RIGHT_WN}\z/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

        wn_pattern = $1

        # Each pattern is 5 bars
        unless wn_pattern.size % 5 == 0
          raise UnencodableCharactersError, "Wrong number of bars."
        end

        decoded_string = ''

        wn_pattern.scan(/.{5}/).each do |chunk|

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

        PostNet.new(decoded_string, options)
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
      else
        # Need to guess whether we need a checksum.  If there
        # are 5, 9, or 11 digits, we need one.  If there are 6,
        # 10, or 12 digits, then it's included.  Otherwise it's
        # not a valid number.

        @value = value.to_s

        if @options[:checksum_included] || [6,10,12].include?(@value.size)
          @options[:checksum_included] = true
          @encoded_string = value.to_s
          raise ChecksumError unless self.class.validate_check_digit_for(@encoded_string)
          md = @encoded_string.match(/^(\d+?)(\d)$/)
          @value, @check_digit = md[1], md[2].to_i
        elsif [5,9,11].include?(@value.size)
          @check_digit = self.class.generate_check_digit_for(@value)
          @encoded_string = "#{@value}#{@check_digit}"
        else
          # should be redundant
          raise UnencodableCharactersError
        end
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
      @wn_str ||= GUARD_PATTERN_LEFT_WN + @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.join + GUARD_PATTERN_RIGHT_WN
    end

  end
end
