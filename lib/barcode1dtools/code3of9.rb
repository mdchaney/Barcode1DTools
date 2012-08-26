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
  # Note:
  # Please note that Code 3 of 9 is not suggested for new applications
  # due to the fact that the code is sparse and doesn't encode a full
  # range of characters without using the "full ascii extensions",
  # which cause it to be even more sparse.  For newer 1D applications
  # use Code 128.
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

    FULL_ASCII_LOOKUP = [
      '%U', '$A', '$B', '$C', '$D', '$E', '$F', '$G', '$H', '$I',
      '$J', '$K', '$L', '$M', '$N', '$O', '$P', '$Q', '$R', '$S',
      '$T', '$U', '$V', '$W', '$X', '$Y', '$Z', '%A', '%B', '%C',
      '%D', '%E', ' ', '/A', '/B', '/C', '/D', '/E', '/F', '/G',
      '/H', '/I', '/J', '/K', '/L', '-', '.', '/O', '0', '1', '2',
      '3', '4', '5', '6', '7', '8', '9', '/Z', '%F', '%G', '%H',
      '%I', '%J', '%V', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
      'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
      'U', 'V', 'W', 'X', 'Y', 'Z', '%K', '%L', '%M', '%N', '%O',
      '%W', '+A', '+B', '+C', '+D', '+E', '+F', '+G', '+H', '+I',
      '+J', '+K', '+L', '+M', '+N', '+O', '+P', '+Q', '+R', '+S',
      '+T', '+U', '+V', '+W', '+X', '+Y', '+Z', '%P', '%Q', '%R',
      '%S', '%T'
    ]

    FULL_ASCII_REVERSE_LOOKUP = {
      '%U' => { 'position' => 0,  'name' => '<NUL>' },
      '$A' => { 'position' => 1,  'name' => '<SOH>' },
      '$B' => { 'position' => 2,  'name' => '<STX>' },
      '$C' => { 'position' => 3,  'name' => '<ETX>' },
      '$D' => { 'position' => 4,  'name' => '<EOT>' },
      '$E' => { 'position' => 5,  'name' => '<ENQ>' },
      '$F' => { 'position' => 6,  'name' => '<ACK>' },
      '$G' => { 'position' => 7,  'name' => '<BEL>' },
      '$H' => { 'position' => 8,  'name' => '<BS>' },
      '$I' => { 'position' => 9,  'name' => '<HT>' },
      '$J' => { 'position' => 10, 'name' => '<LF>' },
      '$K' => { 'position' => 11, 'name' => '<VT>' },
      '$L' => { 'position' => 12, 'name' => '<FF>' },
      '$M' => { 'position' => 13, 'name' => '<CR>' },
      '$N' => { 'position' => 14, 'name' => '<SO>' },
      '$O' => { 'position' => 15, 'name' => '<SI>' },
      '$P' => { 'position' => 16, 'name' => '<DLE>' },
      '$Q' => { 'position' => 17, 'name' => '<DC1>' },
      '$R' => { 'position' => 18, 'name' => '<DC2>' },
      '$S' => { 'position' => 19, 'name' => '<DC3>' },
      '$T' => { 'position' => 20, 'name' => '<DC4>' },
      '$U' => { 'position' => 21, 'name' => '<NAK>' },
      '$V' => { 'position' => 22, 'name' => '<SYN>' },
      '$W' => { 'position' => 23, 'name' => '<ETB>' },
      '$X' => { 'position' => 24, 'name' => '<CAN>' },
      '$Y' => { 'position' => 25, 'name' => '<EM>' },
      '$Z' => { 'position' => 26, 'name' => '<SUB>' },
      '%A' => { 'position' => 27, 'name' => '<ESC>' },
      '%B' => { 'position' => 28, 'name' => '<FS>' },
      '%C' => { 'position' => 29, 'name' => '<GS>' },
      '%D' => { 'position' => 30, 'name' => '<RS>' },
      '%E' => { 'position' => 31, 'name' => '<US>' },
      ' '  => { 'position' => 32, 'name' => ' ' },
      '/A' => { 'position' => 33, 'name' => '!' },
      '/B' => { 'position' => 34, 'name' => '"' },
      '/C' => { 'position' => 35, 'name' => '#' },
      '/D' => { 'position' => 36, 'name' => '$' },
      '/E' => { 'position' => 37, 'name' => '%' },
      '/F' => { 'position' => 38, 'name' => '&' },
      '/G' => { 'position' => 39, 'name' => "'" },
      '/H' => { 'position' => 40, 'name' => '(' },
      '/I' => { 'position' => 41, 'name' => ')' },
      '/J' => { 'position' => 42, 'name' => '*' },
      '/K' => { 'position' => 43, 'name' => '+' },
      '/L' => { 'position' => 44, 'name' => ',' },
      '-'  => { 'position' => 45, 'name' => '-' },
      '.'  => { 'position' => 46, 'name' => '.' },
      '/O' => { 'position' => 47, 'name' => '/' },
      '0'  => { 'position' => 48, 'name' => '0' },
      '1'  => { 'position' => 49, 'name' => '1' },
      '2'  => { 'position' => 50, 'name' => '2' },
      '3'  => { 'position' => 51, 'name' => '3' },
      '4'  => { 'position' => 52, 'name' => '4' },
      '5'  => { 'position' => 53, 'name' => '5' },
      '6'  => { 'position' => 54, 'name' => '6' },
      '7'  => { 'position' => 55, 'name' => '7' },
      '8'  => { 'position' => 56, 'name' => '8' },
      '9'  => { 'position' => 57, 'name' => '9' },
      '/Z' => { 'position' => 58, 'name' => ':' },
      '%F' => { 'position' => 59, 'name' => ';' },
      '%G' => { 'position' => 60, 'name' => '<' },
      '%H' => { 'position' => 61, 'name' => '=' },
      '%I' => { 'position' => 62, 'name' => '>' },
      '%J' => { 'position' => 63, 'name' => '?' },
      '%V' => { 'position' => 64, 'name' => '@' },
      'A'  => { 'position' => 65, 'name' => 'A' },
      'B'  => { 'position' => 66, 'name' => 'B' },
      'C'  => { 'position' => 67, 'name' => 'C' },
      'D'  => { 'position' => 68, 'name' => 'D' },
      'E'  => { 'position' => 69, 'name' => 'E' },
      'F'  => { 'position' => 70, 'name' => 'F' },
      'G'  => { 'position' => 71, 'name' => 'G' },
      'H'  => { 'position' => 72, 'name' => 'H' },
      'I'  => { 'position' => 73, 'name' => 'I' },
      'J'  => { 'position' => 74, 'name' => 'J' },
      'K'  => { 'position' => 75, 'name' => 'K' },
      'L'  => { 'position' => 76, 'name' => 'L' },
      'M'  => { 'position' => 77, 'name' => 'M' },
      'N'  => { 'position' => 78, 'name' => 'N' },
      'O'  => { 'position' => 79, 'name' => 'O' },
      'P'  => { 'position' => 80, 'name' => 'P' },
      'Q'  => { 'position' => 81, 'name' => 'Q' },
      'R'  => { 'position' => 82, 'name' => 'R' },
      'S'  => { 'position' => 83, 'name' => 'S' },
      'T'  => { 'position' => 84, 'name' => 'T' },
      'U'  => { 'position' => 85, 'name' => 'U' },
      'V'  => { 'position' => 86, 'name' => 'V' },
      'W'  => { 'position' => 87, 'name' => 'W' },
      'X'  => { 'position' => 88, 'name' => 'X' },
      'Y'  => { 'position' => 89, 'name' => 'Y' },
      'Z'  => { 'position' => 90, 'name' => 'Z' },
      '%K' => { 'position' => 91, 'name' => '[' },
      '%L' => { 'position' => 92, 'name' => '\\' },
      '%M' => { 'position' => 93, 'name' => ']' },
      '%N' => { 'position' => 94, 'name' => '^' },
      '%O' => { 'position' => 95, 'name' => '_' },
      '%W' => { 'position' => 96, 'name' => '`' },
      '+A' => { 'position' => 97, 'name' => 'a' },
      '+B' => { 'position' => 98, 'name' => 'b' },
      '+C' => { 'position' => 99, 'name' => 'c' },
      '+D' => { 'position' => 100, 'name' => 'd' },
      '+E' => { 'position' => 101, 'name' => 'e' },
      '+F' => { 'position' => 102, 'name' => 'f' },
      '+G' => { 'position' => 103, 'name' => 'g' },
      '+H' => { 'position' => 104, 'name' => 'h' },
      '+I' => { 'position' => 105, 'name' => 'i' },
      '+J' => { 'position' => 106, 'name' => 'j' },
      '+K' => { 'position' => 107, 'name' => 'k' },
      '+L' => { 'position' => 108, 'name' => 'l' },
      '+M' => { 'position' => 109, 'name' => 'm' },
      '+N' => { 'position' => 110, 'name' => 'n' },
      '+O' => { 'position' => 111, 'name' => 'o' },
      '+P' => { 'position' => 112, 'name' => 'p' },
      '+Q' => { 'position' => 113, 'name' => 'q' },
      '+R' => { 'position' => 114, 'name' => 'r' },
      '+S' => { 'position' => 115, 'name' => 's' },
      '+T' => { 'position' => 116, 'name' => 't' },
      '+U' => { 'position' => 117, 'name' => 'u' },
      '+V' => { 'position' => 118, 'name' => 'v' },
      '+W' => { 'position' => 119, 'name' => 'w' },
      '+X' => { 'position' => 120, 'name' => 'x' },
      '+Y' => { 'position' => 121, 'name' => 'y' },
      '+Z' => { 'position' => 122, 'name' => 'z' },
      '%P' => { 'position' => 123, 'name' => '{' },
      '%Q' => { 'position' => 124, 'name' => '|' },
      '%R' => { 'position' => 125, 'name' => '}' },
      '%S' => { 'position' => 126, 'name' => '~' },
      '%T' => { 'position' => 127, 'name' => '<DEL>' },
      '%X' => { 'position' => 127, 'name' => '<DEL>' },
      '%Y' => { 'position' => 127, 'name' => '<DEL>' },
      '%Z' => { 'position' => 127, 'name' => '<DEL>' }
    }

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

      # Provide encoding into the "full ascii" format.  This
      # allows us to encode any ascii character (0-127) in a Code 3
      # of 9, but it is up to the application to anticipate and
      # handle this.  In this encoding, four of the characters
      # ($, %, /, and +) are used as "shift" characters, paired
      # with a letter A-Z that encodes a character that's not
      # available in Code 3 of 9.  Because no special characters
      # are used, it's not possible to know if this encoding is
      # used.
      def encode_full_ascii(str)
        str.bytes.collect { |c| FULL_ASCII_LOOKUP[c] }.join
      end

      # Decodes a "full ascii" string from Code 3 of 9 into standard
      # ascii.  Note that this will silently fail if a string is
      # malformed.
      def decode_full_ascii(str)
        str.scan(/[\$%\/+]?[A-Z0-9 \.\-]/).collect { |c| FULL_ASCII_REVERSE_LOOKUP[c]['position'] }.pack('C*')
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
