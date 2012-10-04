#--
# Copyright 2012 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

module Barcode1DTools

  # Barcode1DTools::Code93 - Create and decode bar patterns for
  # Code93.  The value encoded is a string, and two checksum "digits"
  # (actually characters) will be added to the end before encoding.
  # You may use the option :checksum_included => true when
  # initializing to specify that you have already included a
  # checksum, A ChecksumError will be raised if
  # :checksum_included => true and the checksum is invalid.
  #
  # Code 93 can encode any ascii character (0-127) but will be most
  # efficient for those characters that may be natively encoded as
  # a single character: digits, uppercase letters, and the symbols
  # dash "-", period ".", dollar sign "$", forward slash "/", plus
  # sign "+", percent sign "%", as well as a space " ".
  #
  # == Example
  #  val = "THIS IS A TEST"
  #  bc = Barcode1DTools::Code93.new(val)
  #  pattern = bc.bars
  #  rle_pattern = bc.rle
  #  width = bc.width
  #  # Note that the check digits are actually two of the characters.
  #  check_digit = Barcode1DTools::Code93.generate_check_digit_for(num)
  #
  # The object created is immutable.
  #
  # Barcode1DTools::Code93 creates the patterns that you need to
  # display Code 93 barcodes.  It can also decode a simple rle
  # string.
  #
  # Code 93 barcodes consist of lines and spaces that are from
  # one to four units wide each.  A particular character has 3 bars
  # and 3 spaces.
  #
  # == Formats
  # There are two formats for the returned pattern:
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
  # The "width" method will tell you the total end-to-end width, in
  # units, of the entire barcode.  Note that the w/n format is
  # unavailable for this symbology.
  #
  # == Miscellaneous Information
  #
  # Code 93 can encode any ascii character from 0 to 127.  The design
  # is identical to Code 3 of 9 in most respects, with the main
  # difference being that the "shift" characters are separate from the
  # regular encoded characters and it is thus possible to tell if a
  # particular code is "regular" or "full ascii".  This symbology is
  # most efficient if only the native characters are used.
  #
  # This module will automatically promote the code to "full ascii"
  # only if it is needed.  In practical terms that means that a dollar
  # sign, for instance, may be rendered one of two ways.  If the
  # payload contains only "native" characters, it will be encoded
  # normally.  But if any "extended" characters are used, such as a
  # lowercase letter, the dollar sign will be likewise encoded as
  # "(/)D".  You can use the accessor "full_ascii" to see if full
  # ascii mode is in effect.  The option :force_full_ascii will
  # cause that mode to be used whether needed or not.
  #
  # Internally, the four shift characters are represented as characters
  # 128 "($)", 129 "(%)", 130 "(/)", and 131 "(+)".
  #
  # == Rendering
  #
  # Code 93 may be rendered however the programmer wishes.  Since
  # there is a simple mapping between number of characters and length of
  # code, a variable length code should be allowed to grow and shrink to
  # assure the bars are neither too large or too small.  Code 93 is
  # often implemented as a font.
  #
  # There is no standard for human-readable text associated with the
  # code, and in fact some applications leave out the human-readable
  # element altogether.  The text is typically shown below the barcode
  # where applicable.

  class Code93 < Barcode1D

    # Character sequence - 0-based offset in this string is character
    # number
    CHAR_SEQUENCE = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%\x80\x81\x82\x83"

    # Patterns for making bar codes
    PATTERNS = {
      '0'=> {'position' => 0,  'display' => '0', 'rle' => '131112', 'bars' => '100010100'}, 
      '1'=> {'position' => 1,  'display' => '1', 'rle' => '111213', 'bars' => '101001000'}, 
      '2'=> {'position' => 2,  'display' => '2', 'rle' => '111312', 'bars' => '101000100'}, 
      '3'=> {'position' => 3,  'display' => '3', 'rle' => '111411', 'bars' => '101000010'}, 
      '4'=> {'position' => 4,  'display' => '4', 'rle' => '121113', 'bars' => '100101000'}, 
      '5'=> {'position' => 5,  'display' => '5', 'rle' => '121212', 'bars' => '100100100'}, 
      '6'=> {'position' => 6,  'display' => '6', 'rle' => '121311', 'bars' => '100100010'}, 
      '7'=> {'position' => 7,  'display' => '7', 'rle' => '111114', 'bars' => '101010000'}, 
      '8'=> {'position' => 8,  'display' => '8', 'rle' => '131211', 'bars' => '100010010'}, 
      '9'=> {'position' => 9,  'display' => '9', 'rle' => '141111', 'bars' => '100001010'}, 
      'A' => {'position' => 10, 'display' => 'A', 'rle' => '211113', 'bars' => '110101000'}, 
      'B' => {'position' => 11, 'display' => 'B', 'rle' => '211212', 'bars' => '110100100'}, 
      'C' => {'position' => 12, 'display' => 'C', 'rle' => '211311', 'bars' => '110100010'}, 
      'D' => {'position' => 13, 'display' => 'D', 'rle' => '221112', 'bars' => '110010100'}, 
      'E' => {'position' => 14, 'display' => 'E', 'rle' => '221211', 'bars' => '110010010'}, 
      'F' => {'position' => 15, 'display' => 'F', 'rle' => '231111', 'bars' => '110001010'}, 
      'G' => {'position' => 16, 'display' => 'G', 'rle' => '112113', 'bars' => '101101000'}, 
      'H' => {'position' => 17, 'display' => 'H', 'rle' => '112212', 'bars' => '101100100'}, 
      'I' => {'position' => 18, 'display' => 'I', 'rle' => '112311', 'bars' => '101100010'}, 
      'J' => {'position' => 19, 'display' => 'J', 'rle' => '122112', 'bars' => '100110100'}, 
      'K' => {'position' => 20, 'display' => 'K', 'rle' => '132111', 'bars' => '100011010'}, 
      'L' => {'position' => 21, 'display' => 'L', 'rle' => '111123', 'bars' => '101011000'}, 
      'M' => {'position' => 22, 'display' => 'M', 'rle' => '111222', 'bars' => '101001100'}, 
      'N' => {'position' => 23, 'display' => 'N', 'rle' => '111321', 'bars' => '101000110'}, 
      'O' => {'position' => 24, 'display' => 'O', 'rle' => '121122', 'bars' => '100101100'}, 
      'P' => {'position' => 25, 'display' => 'P', 'rle' => '131121', 'bars' => '100010110'}, 
      'Q' => {'position' => 26, 'display' => 'Q', 'rle' => '212112', 'bars' => '110110100'}, 
      'R' => {'position' => 27, 'display' => 'R', 'rle' => '212211', 'bars' => '110110010'}, 
      'S' => {'position' => 28, 'display' => 'S', 'rle' => '211122', 'bars' => '110101100'}, 
      'T' => {'position' => 29, 'display' => 'T', 'rle' => '211221', 'bars' => '110100110'}, 
      'U' => {'position' => 30, 'display' => 'U', 'rle' => '221121', 'bars' => '110010110'}, 
      'V' => {'position' => 31, 'display' => 'V', 'rle' => '222111', 'bars' => '110011010'}, 
      'W' => {'position' => 32, 'display' => 'W', 'rle' => '112122', 'bars' => '101101100'}, 
      'X' => {'position' => 33, 'display' => 'X', 'rle' => '112221', 'bars' => '101100110'}, 
      'Y' => {'position' => 34, 'display' => 'Y', 'rle' => '122121', 'bars' => '100110110'}, 
      'Z' => {'position' => 35, 'display' => 'Z', 'rle' => '123111', 'bars' => '100111010'}, 
      '-' => {'position' => 36, 'display' => '-', 'rle' => '121131', 'bars' => '100101110'}, 
      '.' => {'position' => 37, 'display' => '.', 'rle' => '311112', 'bars' => '111010100'}, 
      ' ' => {'position' => 38, 'display' => ' ', 'rle' => '311211', 'bars' => '111010010'}, 
      '$' => {'position' => 39, 'display' => '$', 'rle' => '321111', 'bars' => '111001010'}, 
      '/' => {'position' => 40, 'display' => '/', 'rle' => '112131', 'bars' => '101101110'}, 
      '+' => {'position' => 41, 'display' => '+', 'rle' => '113121', 'bars' => '101110110'}, 
      '%' => {'position' => 42, 'display' => '%', 'rle' => '211131', 'bars' => '110101110'}, 
      "\x80" => {'position' => 43, 'display' => '($)', 'rle' => '121221', 'bars' => '100100110'}, 
      "\x81" => {'position' => 44, 'display' => '(%)', 'rle' => '312111', 'bars' => '111011010'}, 
      "\x82" => {'position' => 45, 'display' => '(/)', 'rle' => '311121', 'bars' => '111010110'}, 
      "\x83" => {'position' => 46, 'display' => '(+)', 'rle' => '122211', 'bars' => '100110010'}, 
    }

    # Left guard pattern
    LEFT_GUARD_PATTERN = '101011110'
    # Left guard pattern as an RLE string
    LEFT_GUARD_PATTERN_RLE = '111141'
    # Right guard pattern - just the left pattern with another bar
    RIGHT_GUARD_PATTERN = LEFT_GUARD_PATTERN + '1'
    # Right guard pattern as RLE - just the left pattern with another bar
    RIGHT_GUARD_PATTERN_RLE = LEFT_GUARD_PATTERN_RLE + '1'

    # This is a lookup table for the full ASCII mode.  Index this with an ascii
    # codepoint to get a one or two character representation of any character.
    FULL_ASCII_LOOKUP = [
      "\x81U", "\x80A", "\x80B", "\x80C", "\x80D", "\x80E", "\x80F", "\x80G", "\x80H", "\x80I",
      "\x80J", "\x80K", "\x80L", "\x80M", "\x80N", "\x80O", "\x80P", "\x80Q", "\x80R", "\x80S",
      "\x80T", "\x80U", "\x80V", "\x80W", "\x80X", "\x80Y", "\x80Z", "\x81A", "\x81B", "\x81C",
      "\x81D", "\x81E", " ", "\x82A", "\x82B", "\x82C", "\x82D", "\x82E", "\x82F", "\x82G",
      "\x82H", "\x82I", "\x82J", "\x82K", "\x82L", "-", ".", "\x82O", "0", "1", "2",
      "3", "4", "5", "6", "7", "8", "9", "\x82Z", "\x81F", "\x81G", "\x81H",
      "\x81I", "\x81J", "\x81V", "A", "B", "C", "D", "E", "F", "G", "H",
      "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
      "U", "V", "W", "X", "Y", "Z", "\x81K", "\x81L", "\x81M", "\x81N", "\x81O",
      "\x81W", "\x83A", "\x83B", "\x83C", "\x83D", "\x83E", "\x83F", "\x83G", "\x83H", "\x83I",
      "\x83J", "\x83K", "\x83L", "\x83M", "\x83N", "\x83O", "\x83P", "\x83Q", "\x83R", "\x83S",
      "\x83T", "\x83U", "\x83V", "\x83W", "\x83X", "\x83Y", "\x83Z", "\x81P", "\x81Q", "\x81R",
      "\x81S", "\x81T"
    ]

    # This is the reverse lookup.  Given a character or character pair you
    # can find the ascii value.
    FULL_ASCII_REVERSE_LOOKUP = {
      "\x81U" => { 'position' => 0,  'name' => '<NUL>' },
      "\x80A" => { 'position' => 1,  'name' => '<SOH>' },
      "\x80B" => { 'position' => 2,  'name' => '<STX>' },
      "\x80C" => { 'position' => 3,  'name' => '<ETX>' },
      "\x80D" => { 'position' => 4,  'name' => '<EOT>' },
      "\x80E" => { 'position' => 5,  'name' => '<ENQ>' },
      "\x80F" => { 'position' => 6,  'name' => '<ACK>' },
      "\x80G" => { 'position' => 7,  'name' => '<BEL>' },
      "\x80H" => { 'position' => 8,  'name' => '<BS>' },
      "\x80I" => { 'position' => 9,  'name' => '<HT>' },
      "\x80J" => { 'position' => 10, 'name' => '<LF>' },
      "\x80K" => { 'position' => 11, 'name' => '<VT>' },
      "\x80L" => { 'position' => 12, 'name' => '<FF>' },
      "\x80M" => { 'position' => 13, 'name' => '<CR>' },
      "\x80N" => { 'position' => 14, 'name' => '<SO>' },
      "\x80O" => { 'position' => 15, 'name' => '<SI>' },
      "\x80P" => { 'position' => 16, 'name' => '<DLE>' },
      "\x80Q" => { 'position' => 17, 'name' => '<DC1>' },
      "\x80R" => { 'position' => 18, 'name' => '<DC2>' },
      "\x80S" => { 'position' => 19, 'name' => '<DC3>' },
      "\x80T" => { 'position' => 20, 'name' => '<DC4>' },
      "\x80U" => { 'position' => 21, 'name' => '<NAK>' },
      "\x80V" => { 'position' => 22, 'name' => '<SYN>' },
      "\x80W" => { 'position' => 23, 'name' => '<ETB>' },
      "\x80X" => { 'position' => 24, 'name' => '<CAN>' },
      "\x80Y" => { 'position' => 25, 'name' => '<EM>' },
      "\x80Z" => { 'position' => 26, 'name' => '<SUB>' },
      "\x81A" => { 'position' => 27, 'name' => '<ESC>' },
      "\x81B" => { 'position' => 28, 'name' => '<FS>' },
      "\x81C" => { 'position' => 29, 'name' => '<GS>' },
      "\x81D" => { 'position' => 30, 'name' => '<RS>' },
      "\x81E" => { 'position' => 31, 'name' => '<US>' },
      " "  => { 'position' => 32, 'name' => ' ' },
      "\x82A" => { 'position' => 33, 'name' => '!' },
      "\x82B" => { 'position' => 34, 'name' => '"' },
      "\x82C" => { 'position' => 35, 'name' => '#' },
      "\x82D" => { 'position' => 36, 'name' => '$' },
      "\x82E" => { 'position' => 37, 'name' => '%' },
      "\x82F" => { 'position' => 38, 'name' => '&' },
      "\x82G" => { 'position' => 39, 'name' => "'" },
      "\x82H" => { 'position' => 40, 'name' => '(' },
      "\x82I" => { 'position' => 41, 'name' => ')' },
      "\x82J" => { 'position' => 42, 'name' => '*' },
      "\x82K" => { 'position' => 43, 'name' => '+' },
      "\x82L" => { 'position' => 44, 'name' => ',' },
      "-"  => { 'position' => 45, 'name' => '-' },
      "."  => { 'position' => 46, 'name' => '.' },
      "\x82O" => { 'position' => 47, 'name' => '/' },
      "0"  => { 'position' => 48, 'name' => '0' },
      "1"  => { 'position' => 49, 'name' => '1' },
      "2"  => { 'position' => 50, 'name' => '2' },
      "3"  => { 'position' => 51, 'name' => '3' },
      "4"  => { 'position' => 52, 'name' => '4' },
      "5"  => { 'position' => 53, 'name' => '5' },
      "6"  => { 'position' => 54, 'name' => '6' },
      "7"  => { 'position' => 55, 'name' => '7' },
      "8"  => { 'position' => 56, 'name' => '8' },
      "9"  => { 'position' => 57, 'name' => '9' },
      "\x82Z" => { 'position' => 58, 'name' => ':' },
      "\x81F" => { 'position' => 59, 'name' => ';' },
      "\x81G" => { 'position' => 60, 'name' => '<' },
      "\x81H" => { 'position' => 61, 'name' => '=' },
      "\x81I" => { 'position' => 62, 'name' => '>' },
      "\x81J" => { 'position' => 63, 'name' => '?' },
      "\x81V" => { 'position' => 64, 'name' => '@' },
      "A"  => { 'position' => 65, 'name' => 'A' },
      "B"  => { 'position' => 66, 'name' => 'B' },
      "C"  => { 'position' => 67, 'name' => 'C' },
      "D"  => { 'position' => 68, 'name' => 'D' },
      "E"  => { 'position' => 69, 'name' => 'E' },
      "F"  => { 'position' => 70, 'name' => 'F' },
      "G"  => { 'position' => 71, 'name' => 'G' },
      "H"  => { 'position' => 72, 'name' => 'H' },
      "I"  => { 'position' => 73, 'name' => 'I' },
      "J"  => { 'position' => 74, 'name' => 'J' },
      "K"  => { 'position' => 75, 'name' => 'K' },
      "L"  => { 'position' => 76, 'name' => 'L' },
      "M"  => { 'position' => 77, 'name' => 'M' },
      "N"  => { 'position' => 78, 'name' => 'N' },
      "O"  => { 'position' => 79, 'name' => 'O' },
      "P"  => { 'position' => 80, 'name' => 'P' },
      "Q"  => { 'position' => 81, 'name' => 'Q' },
      "R"  => { 'position' => 82, 'name' => 'R' },
      "S"  => { 'position' => 83, 'name' => 'S' },
      "T"  => { 'position' => 84, 'name' => 'T' },
      "U"  => { 'position' => 85, 'name' => 'U' },
      "V"  => { 'position' => 86, 'name' => 'V' },
      "W"  => { 'position' => 87, 'name' => 'W' },
      "X"  => { 'position' => 88, 'name' => 'X' },
      "Y"  => { 'position' => 89, 'name' => 'Y' },
      "Z"  => { 'position' => 90, 'name' => 'Z' },
      "\x81K" => { 'position' => 91, 'name' => '[' },
      "\x81L" => { 'position' => 92, 'name' => '\\' },
      "\x81M" => { 'position' => 93, 'name' => ']' },
      "\x81N" => { 'position' => 94, 'name' => '^' },
      "\x81O" => { 'position' => 95, 'name' => '_' },
      "\x81W" => { 'position' => 96, 'name' => '`' },
      "\x83A" => { 'position' => 97, 'name' => 'a' },
      "\x83B" => { 'position' => 98, 'name' => 'b' },
      "\x83C" => { 'position' => 99, 'name' => 'c' },
      "\x83D" => { 'position' => 100, 'name' => 'd' },
      "\x83E" => { 'position' => 101, 'name' => 'e' },
      "\x83F" => { 'position' => 102, 'name' => 'f' },
      "\x83G" => { 'position' => 103, 'name' => 'g' },
      "\x83H" => { 'position' => 104, 'name' => 'h' },
      "\x83I" => { 'position' => 105, 'name' => 'i' },
      "\x83J" => { 'position' => 106, 'name' => 'j' },
      "\x83K" => { 'position' => 107, 'name' => 'k' },
      "\x83L" => { 'position' => 108, 'name' => 'l' },
      "\x83M" => { 'position' => 109, 'name' => 'm' },
      "\x83N" => { 'position' => 110, 'name' => 'n' },
      "\x83O" => { 'position' => 111, 'name' => 'o' },
      "\x83P" => { 'position' => 112, 'name' => 'p' },
      "\x83Q" => { 'position' => 113, 'name' => 'q' },
      "\x83R" => { 'position' => 114, 'name' => 'r' },
      "\x83S" => { 'position' => 115, 'name' => 's' },
      "\x83T" => { 'position' => 116, 'name' => 't' },
      "\x83U" => { 'position' => 117, 'name' => 'u' },
      "\x83V" => { 'position' => 118, 'name' => 'v' },
      "\x83W" => { 'position' => 119, 'name' => 'w' },
      "\x83X" => { 'position' => 120, 'name' => 'x' },
      "\x83Y" => { 'position' => 121, 'name' => 'y' },
      "\x83Z" => { 'position' => 122, 'name' => 'z' },
      "\x81P" => { 'position' => 123, 'name' => '{' },
      "\x81Q" => { 'position' => 124, 'name' => '|' },
      "\x81R" => { 'position' => 125, 'name' => '}' },
      "\x81S" => { 'position' => 126, 'name' => '~' },
      "\x81T" => { 'position' => 127, 'name' => '<DEL>' },
      "\x81X" => { 'position' => 127, 'name' => '<DEL>' },
      "\x81Y" => { 'position' => 127, 'name' => '<DEL>' },
      "\x81Z" => { 'position' => 127, 'name' => '<DEL>' }
    }

    DEFAULT_OPTIONS = {
      :line_character => '1',
      :space_character => '0',
      :force_full_ascii => false
    }

    # Set to true if the string is using the "full ascii" representation.
    attr_accessor :full_ascii
    # If full_ascii is true, this is the encoded string including the
    # shift characters.  Otherwise, it is the same as "value".
    attr_accessor :full_ascii_value

    class << self
      # Code 93 can technically encode anything 0-127
      def can_encode?(value)
        value.to_s =~ /\A[\x00-\x7f]*\z/
      end

      # Returns true if the given value has characters that
      # fall outside the native range.
      def requires_full_ascii?(value)
        value.to_s !~ /\A[0-9A-Z\-\. \$\/\+%]*\z/
      end

      # Generates check digit given a string to encode.  It assumes there
      # is no check digit on the "value".  The check "digit" is
      # actually two characters, and the "position" value in PATTERNS can
      # be used to find the numeric value.  Note that the string must
      # already be promoted to full ascii before sending it here.
      def generate_check_digit_for(value)
        mult = 0
        sum_c = value.to_s.reverse.split('').inject(0) { |a,c| mult = (mult == 20 ? 1 : mult + 1); a + mult * PATTERNS[c]['position'] }
        check_c = CHAR_SEQUENCE[sum_c % 47,1]
        mult = 0
        sum_k = (value.to_s + check_c).reverse.split('').inject(0) { |a,c| mult = (mult == 15 ? 1 : mult + 1); a + mult * PATTERNS[c]['position'] }
        check_k = CHAR_SEQUENCE[sum_k % 47,1]
        "#{check_c}#{check_k}"
      end

      # Validates the check digit given a string - assumes check digit
      # is last digit of string.
      def validate_check_digit_for(value)
        md = value.to_s.match(/^(.*)(..)$/)
        self.generate_check_digit_for(md[1]) == md[2]
      end

      # Decode a string in wn format.  This will return a Code93
      # object.
      def decode(str, options = {})
        if str =~ /[^1-4]/
          raise UnencodableCharactersError, "Pattern must be rle"
        end

        if str.reverse =~ /^#{LEFT_GUARD_PATTERN_RLE}.*?#{RIGHT_GUARD_PATTERN_RLE}$/
          str.reverse!
        end

        unless str =~ /^#{LEFT_GUARD_PATTERN_RLE}(.*?)#{RIGHT_GUARD_PATTERN_RLE}$/
          raise UnencodableCharactersError, "Start/stop pattern is not detected."
        end

        rle_pattern = $1

        unless rle_pattern.size % 6 == 0
          raise UnencodableCharactersError, "Wrong number of bars."
        end

        decoded_string = ''

        rle_pattern.scan(/.{6}/).each do |chunk|

          found = false

          PATTERNS.each do |char,hsh|
            if chunk == hsh['rle']
              decoded_string += char
              found = true
              break;
            end
          end

          raise UndecodableCharactersError, "Invalid sequence: #{chunk}" unless found

        end

        # assume the last two characters are a checksum
        raise ChecksumError unless self.validate_check_digit_for(decoded_string)

        md = decoded_string.match(/\A(.*?)(..)\z/)
        payload, checksum = md[1], md[2]

        decoded_string = decode_full_ascii(payload)

        Code93.new(decoded_string, options.merge(:checksum_included => false))
      end

      # Provide encoding into the "full ascii" format.  This
      # allows us to encode any ascii character (0-127) in a
      # Code 93.
      def encode_full_ascii(str)
        str.bytes.collect { |c| FULL_ASCII_LOOKUP[c] }.join
      end

      # Decodes a "full ascii" string from Code 93 into standard
      # ascii.  Note that this will silently fail if a string is
      # malformed.
      def decode_full_ascii(str)
        if str =~ /[\x80-\x83]/
          str.scan(/[\x80-\x83]?[A-Z0-9 \.\-]/).collect { |c| FULL_ASCII_REVERSE_LOOKUP[c]['position'] }.pack('C*')
        else
          str
        end
      end
    end

    # Create a new Code93 barcode object.
    # Options are :line_character, :space_character, :force_full_ascii,
    # and :checksum_included.
    def initialize(value, options = {})

      @options = DEFAULT_OPTIONS.merge(options)

      # Can we encode this value?
      raise UnencodableCharactersError unless self.class.can_encode?(value)

      value = value.to_s

      if @options[:checksum_included]
        raise ChecksumError unless self.class.validate_check_digit_for(value)
        @encoded_string = value
        md = value.match(/\A(.*?)(..)\z/)
        @value, @check_digit = md[1], md[2]
      else
        @value = value
        if @options[:force_full_ascii] || self.class.requires_full_ascii?(value)
          @full_ascii_value = self.class.encode_full_ascii(value)
          @full_ascii = true
          @check_digit = self.class.generate_check_digit_for(@full_ascii_value)
          @encoded_string = "#{@full_ascii_value}#{@check_digit}"
        else
          @full_ascii = false
          @full_ascii_value = @value
          @check_digit = self.class.generate_check_digit_for(@value)
          @encoded_string = "#{@value}#{@check_digit}"
        end
      end
    end

    # Returns a string of "w" or "n" ("wide" and "narrow").  For Code93 this
    # simply raises a NotImplementedError.
    def wn
      raise NotImplementedError
    end

    # Returns a run-length-encoded string representation
    def rle
      @rle ||= gen_rle(@encoded_string)
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

    # Creates the actual rle pattern.
    def gen_rle(str)
      @rle_str ||=
        ([LEFT_GUARD_PATTERN_RLE] +
        str.split('').collect { |c| PATTERNS[c]['rle'] } +
        [RIGHT_GUARD_PATTERN_RLE]).join
    end

  end
end
