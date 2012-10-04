#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Codabar - Create and decode bar patterns for
  # Codabar.  The value encoded is a string which may contain the
  # digits 0-9 and the symbols dash "-", dollar sign "$", plus
  # sign "+", colon ":", forward slash "/", and dot ".".  There are
  # four start/stop characters which are A, B, C, and D or T, N,
  # asterisk "*", and E.  Note that A and T are equivalent, as are
  # B and N, C and asterisk, and D and E.  Any may be used as start
  # and stop characters giving 16 possible combinations.
  #
  # Because there is no standard for check digits, we implement
  # neither generation nor checking of one.  It is up to the caller
  # to present a check digit if it is part of the payload.
  #
  # Additionally, the caller must present the start and stop
  # characters as part of the value.  When decoding, the start/stop
  # characters will be presented as A, B, C, or D.  
  #
  # == Example
  #   val = "A29322930C"
  #   bc = Barcode1DTools::Codabar.new(val)
  #   pattern = bc.bars
  #   rle_pattern = bc.rle
  #   width = bc.width
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Codabar creates the patterns that you need to
  # display Codabar barcodes.  It can also decode a simple w/n
  # string.
  #
  # Codabar characters consist of 4 bars and 3 spaces, with a narrow
  # space between them.  The main characters (0-9, dash, and dollar
  # sign) each have one wide bar and one wide space (hence the
  # alternate name "code 2 of 7").  The start/stop codes have one
  # wide bar and two adjacent wide spaces.  The extended characters
  # (dot, forward slash, colon, and plus sign) each have three wide
  # bars and all narrow spaces.
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
  # The original Codabar specification actually included a varied
  # w/n ratio depending on whether there were two or three wide
  # elements in a character.  Those with two wide elements used a 3:1
  # ratio while those with three wide elements used a 2:1 ratio.  In
  # that way, the characters were consistently 10 units wide.
  #
  # Our default ratio is 3:1 for the entire code, but if you include
  # :varied_wn_ratio => true in the options the rle and bars strings
  # will have variable ratio that shifts between 2:1 and 3:1 and the
  # "wn_ratio" option will be ignored.

  class Codabar < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number
    CHAR_SEQUENCE = "0123456789-$:/.+ABCD"

    # Patterns for making bar codes
    PATTERNS = {
      '0'=> {'val'=>0 ,'wn'=>'nnnnnww'},
      '1'=> {'val'=>1 ,'wn'=>'nnnnwwn'},
      '2'=> {'val'=>2 ,'wn'=>'nnnwnnw'},
      '3'=> {'val'=>3 ,'wn'=>'wwnnnnn'},
      '4'=> {'val'=>4 ,'wn'=>'nnwnnwn'},
      '5'=> {'val'=>5 ,'wn'=>'wnnnnwn'},
      '6'=> {'val'=>6 ,'wn'=>'nwnnnnw'},
      '7'=> {'val'=>7 ,'wn'=>'nwnnwnn'},
      '8'=> {'val'=>8 ,'wn'=>'nwwnnnn'},
      '9'=> {'val'=>9 ,'wn'=>'wnnwnnn'},
      '-'=> {'val'=>10 ,'wn'=>'nnnwwnn'},
      '$'=> {'val'=>11 ,'wn'=>'nnwwnnn'},
      ':'=> {'val'=>12 ,'wn'=>'wnnnwnw'},
      '/'=> {'val'=>13 ,'wn'=>'wnwnnnw'},
      '.'=> {'val'=>14 ,'wn'=>'wnwnwnn'},
      '+'=> {'val'=>15 ,'wn'=>'nnwnwnw'},

      'A'=> {'val'=>16 ,'wn'=>'nnwwnwn'},
      'B'=> {'val'=>17 ,'wn'=>'nwnwnnw'},
      'C'=> {'val'=>18 ,'wn'=>'nnnwnww'},
      'D'=> {'val'=>19 ,'wn'=>'nnnwwwn'},

      'T'=> {'val'=>16 ,'wn'=>'nnwwnwn'},
      'N'=> {'val'=>17 ,'wn'=>'nwnwnnw'},
      '*'=> {'val'=>18 ,'wn'=>'nnnwnww'},
      'E'=> {'val'=>19 ,'wn'=>'nnnwwwn'}
    }

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0',
      :w_character => 'w',
      :n_character => 'n',
      :wn_ratio => '3',
      :varied_wn_ratio => false
    }

    # Holds the start character
    attr_reader :start_character
    # Holds the stop character
    attr_reader :stop_character
    # The actual payload (between start/stop characters)
    attr_reader :payload

    class << self

      # Returns true if the value presented can be encoded in a
      # Codabar barcode.  Codabar can encode digits, dash,
      # dollar, colon, forward slash, dot, and plus.  The string
      # must start and stop with start/stop characters.
      def can_encode?(value)
        value.to_s =~ /\A[ABCD][0-9\$:\/\.\+\-]*[ABCD]\z/ || value.to_s =~ /\A[TN\*E][0-9\$:\/\.\+\-]*[TN\*E]\z/
      end

      # Generate a check digit.  For Codabar, this
      # will raise a NotImplementedError.
      def generate_check_digit_for(value)
        raise NotImplementedError
      end

      # Validate the check digit.  For Codabar, this
      # will raise a NotImplementedError.
      def validate_check_digit_for(value)
        raise NotImplementedError
      end

      # Decode a string in rle format.  This will return a Codabar
      # object.
      def decode(str, options = {})
        if str =~ /[^1-3]/ && str =~ /[^wn]/
          raise UnencodableCharactersError, "Pattern must be rle or wn"
        end

        # ensure a wn string
        if str =~ /[1-3]/
          str = str.tr('123','nww')
        end

        start_stop_pattern_match = Regexp.new(['A','B','C','D'].collect { |c| PATTERNS[c]['wn'] }.join('|'))

        if str.reverse =~ /\A#{start_stop_pattern_match}n.*?#{start_stop_pattern_match}\z/
          str.reverse!
        end

        unless str =~ /\A(#{start_stop_pattern_match}n.*?#{start_stop_pattern_match})\z/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

        # Adding an "n" to make it easier to scan
        wn_pattern = $1 + 'n'

        # Each pattern is 4 bars and 3 spaces, with a space between.
        unless wn_pattern.size % 8 == 0
          raise UnencodableCharactersError, "Wrong number of bars."
        end

        decoded_string = ''

        wn_pattern.scan(/(.{7})n/).each do |chunk|

          chunk = chunk.first
          found = false

          PATTERNS.each do |char,hsh|
            if !['T', 'E', '*', 'N'].include?(char) && chunk == hsh['wn']
              decoded_string += char
              found = true
              break;
            end
          end

          raise UndecodableCharactersError, "Invalid sequence: #{chunk}" unless found

        end

        Codabar.new(decoded_string)
      end

    end

    # Create a new Codabar object.  Options are :line_character,
    # :space_character, :w_character, :n_character, and :varied_wn_ratio.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value)

      @value = value.to_s
      @check_digit = nil

      @encoded_string = @value
      md = @value.match(/\A([ABCDTNE\*])(.*?)([ABCDTNE\*])\z/)
      @start_character, @payload, @stop_character = md[1], md[2], md[3]
    end

    # Returns a string of "w" or "n" ("wide" and "narrow")
    def wn
      @wn ||= wn_str.tr('wn', @options[:w_character].to_s + @options[:n_character].to_s)
    end

    # Returns a run-length-encoded string representation
    def rle
      if @options[:varied_wn_ratio]
        @rle ||= @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.collect { |p| p.tr('wn',(p=~/.*w.*w.*w/ ? '21' : '31')) }.join('1')
      else
        @rle ||= self.class.wn_to_rle(self.wn, @options)
      end
    end

    # Returns the bar pattern
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
      @wn_str ||= @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] }.join('n')
    end

  end
end
