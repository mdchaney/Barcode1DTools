# encoding: utf-8

module Barcode1D

  # Errors for barcodes
  class Barcode1DError < StandardError; end
  class UnencodableError < Barcode1DError; end
  class ValueTooLongError < UnencodableError; end
  class ValueTooShortError < UnencodableError; end
  class UnencodableCharactersError < UnencodableError; end
  class ChecksumError < Barcode1DError; end
  class NotImplementedError < Barcode1DError; end

end
