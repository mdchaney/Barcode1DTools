#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Code3of9 - Create and decode bar patterns for
  # Code 3 of 9 (also known as Code 39, USD-3, Alpha39, Code 3/9,
  # Type 39, or USS Code 39) barcodes.  The value encoded is a
  # string, and a checksum digit may be added.  You can add the
  # option :checksum_included => true when initializing to specify
  # that you have already included a checksum, or :skip_checksum =>
  # true to specify that no checksum should be added or checked.  A
  # ChecksumError will be raised if :checksum_included => true,
  # :skip_checksum is false, and the last digit is invalid as a
  # checksum.  Note that the default is "skip_checksum".
  #
  # Code 3 of 9 can encode digits, uppercase letters, and the symbols
  # dash "-", period ".", dollar sign "$", forward slash "/", plus
  # sign "+", percent sign "%", as well as a space " ".
  #
  # val = "THIS IS A TEST"
  # bc = Barcode1DTools::Code3of9.new(val)
  # pattern = bc.bars
  # rle_pattern = bc.rle
  # wn_pattern = bc.wn
  # width = bc.width
  # # Note that the check digit is actually one of the characters.
  # check_digit = Barcode1DTools::Code3of9.generate_check_digit_for(num)
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Code3of9 creates the patterns that you need to
  # display Code 3 of 9 barcodes.  It can also decode a simple w/n
  # string.
  #
  # Code 3 of 9 barcodes consist of lines and spaces that are either
  # "wide" or "narrow", with "wide" lines or spaces being twice the
  # width of narrow lines or spaces.
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
  #== Miscellaneous Information
  #
  # Code 3 of 9 can encode text and digits.  There is also a way to do
  # "full ascii" mode, but it's not recommended.  Full ascii mode uses
  # some of the characters as shift characters, e.g. "a" is encoded as
  # "+A".  There's no indication that full ascii mode is being used, so
  # it has to be handled by the application.  This has been fixed in
  # Code 93, by designation of four special characters which are used
  # only for shifting.  However, if you need to use a full character
  # set, Code 128 is probably a better choice.
  #
  #== Rendering
  #
  # Code 3 of 9 may be rendered however the programmer wishes.  Since
  # there is a simple mapping between number of characters and length of
  # code, a variable length code should be allowed to grow and shrink to
  # assure the bars are neither too large or too small.  Code 3 of 9 is
  # often implemented as a font.
  #
  # There is no standard for human-readable text associated with the
  # code, and in fact some applications leave out the human-readable
  # element altogether.  The text is typically shown below the barcode
  # where applicable.

  class Code3of9 < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number
    CHAR_SEQUENCE = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%'

    # Patterns for making bar codes
    PATTERNS = {
      '0' => { 'position' => 0,  'wn' => 'nnnwwnwnn' },
      '1' => { 'position' => 1,  'wn' => 'wnnwnnnnw' },
      '2' => { 'position' => 2,  'wn' => 'nnwwnnnnw' },
      '3' => { 'position' => 3,  'wn' => 'wnwwnnnnn' },
      '4' => { 'position' => 4,  'wn' => 'nnnwwnnnw' },
      '5' => { 'position' => 5,  'wn' => 'wnnwwnnnn' },
      '6' => { 'position' => 6,  'wn' => 'nnwwwnnnn' },
      '7' => { 'position' => 7,  'wn' => 'nnnwnnwnw' },
      '8' => { 'position' => 8,  'wn' => 'wnnwnnwnn' },
      '9' => { 'position' => 9,  'wn' => 'nnwwnnwnn' },
      'A' => { 'position' => 10, 'wn' => 'wnnnnwnnw' },
      'B' => { 'position' => 11, 'wn' => 'nnwnnwnnw' },
      'C' => { 'position' => 12, 'wn' => 'wnwnnwnnn' },
      'D' => { 'position' => 13, 'wn' => 'nnnnwwnnw' },
      'E' => { 'position' => 14, 'wn' => 'wnnnwwnnn' },
      'F' => { 'position' => 15, 'wn' => 'nnwnwwnnn' },
      'G' => { 'position' => 16, 'wn' => 'nnnnnwwnw' },
      'H' => { 'position' => 17, 'wn' => 'wnnnnwwnn' },
      'I' => { 'position' => 18, 'wn' => 'nnwnnwwnn' },
      'J' => { 'position' => 19, 'wn' => 'nnnnwwwnn' },
      'K' => { 'position' => 20, 'wn' => 'wnnnnnnww' },
      'L' => { 'position' => 21, 'wn' => 'nnwnnnnww' },
      'M' => { 'position' => 22, 'wn' => 'wnwnnnnwn' },
      'N' => { 'position' => 23, 'wn' => 'nnnnwnnww' },
      'O' => { 'position' => 24, 'wn' => 'wnnnwnnwn' },
      'P' => { 'position' => 25, 'wn' => 'nnwnwnnwn' },
      'Q' => { 'position' => 26, 'wn' => 'nnnnnnwww' },
      'R' => { 'position' => 27, 'wn' => 'wnnnnnwwn' },
      'S' => { 'position' => 28, 'wn' => 'nnwnnnwwn' },
      'T' => { 'position' => 29, 'wn' => 'nnnnwnwwn' },
      'U' => { 'position' => 30, 'wn' => 'wwnnnnnnw' },
      'V' => { 'position' => 31, 'wn' => 'nwwnnnnnw' },
      'W' => { 'position' => 32, 'wn' => 'wwwnnnnnn' },
      'X' => { 'position' => 33, 'wn' => 'nwnnwnnnw' },
      'Y' => { 'position' => 34, 'wn' => 'wwnnwnnnn' },
      'Z' => { 'position' => 35, 'wn' => 'nwwnwnnnn' },
      '-' => { 'position' => 36, 'wn' => 'nwnnnnwnw' },
      '.' => { 'position' => 37, 'wn' => 'wwnnnnwnn' },
      ' ' => { 'position' => 38, 'wn' => 'nwwnnnwnn' },
      '$' => { 'position' => 39, 'wn' => 'nwnwnwnnn' },
      '/' => { 'position' => 40, 'wn' => 'nwnwnnnwn' },
      '+' => { 'position' => 41, 'wn' => 'nwnnnwnwn' },
      '%' => { 'position' => 42, 'wn' => 'nnnwnwnwn' }
    }

    SIDE_GUARD_PATTERN = 'nwnnwnwnn'

    WN_RATIO = 2

    DEFAULT_OPTIONS = {
      :w_character => 'w',
      :n_character => 'n',
      :line_character => '1',
      :space_character => '0',
      :wn_ratio => WN_RATIO,
      :skip_checksum => true
    }

    class << self
      # returns true or false
      def can_encode?(value)
        value.to_s =~ /\A[0-9A-Z\-\. \$\/\+%]*\z/
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".  The check "digit" is
      # actually a character, and the "position" value in PATTERNS can
      # be used to find the numeric value.
      def generate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        mult = 1
        sum = value.to_s.split('').inject(0) { |a,c| a + PATTERNS[c]['position'] }
        CHAR_SEQUENCE[sum % 43,1]
      end

      # validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        raise UnencodableCharactersError unless self.can_encode?(value)
        md = value.to_s.match(/^(.*)(.)$/)
        self.generate_check_digit_for(md[1]) == md[2]
      end

      # Decode a string in wn format.  This will return a Code3of9
      # object.
      def decode(str, options = {})
        if str =~ /[^wn]/
          raise UnencodableCharactersError, "Pattern must contain only \"w\" and \"n\"."
        end

        if str.reverse =~ /^#{SIDE_GUARD_PATTERN}n.*?n#{SIDE_GUARD_PATTERN}$/
          str.reverse!
        end

        unless str =~ /^#{SIDE_GUARD_PATTERN}n(.*?)#{SIDE_GUARD_PATTERN}$/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

        wn_pattern = $1

        unless wn_pattern.size % 10 == 0
          raise UnencodableCharactersError, "Wrong number of bars."
        end

        decoded_string = ''

        wn_pattern.scan(/(.{9})n/).each do |chunk|

          chunk = chunk[0]

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

        Code3of9.new(decoded_string, options)
      end
    end

    # Options are :line_character, :space_character, :w_character,
    # :n_character, :skip_checksum, and :checksum_included.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value)

      value = value.to_s

      if @options[:skip_checksum] && !@options[:checksum_included]
        @encoded_string = value
        @value = value
        @check_digit = nil
      elsif @options[:checksum_included]
        @options[:skip_checksum] = nil
        raise ChecksumError unless self.class.validate_check_digit_for(value)
        @encoded_string = value
        md = value.match(/\A(.*?)(.)\z/)
        @value, @check_digit = md[1], md[2]
      else
        # need to add a checksum
        @value = value
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
      @wn_str ||=
        ([SIDE_GUARD_PATTERN] +
        @encoded_string.split('').collect { |c| PATTERNS[c]['wn'] } +
        [SIDE_GUARD_PATTERN]).join('n')
    end

  end
end
