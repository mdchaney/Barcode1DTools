#!/usr/bin/env ruby

require 'rubygems'
require 'pdf/writer'
require 'barcode1dtools'

# The quiet zone should be 10x the bar width.  This is a generic renderer
# for barcodes.
def render_barcode(pdf, barcode, x, y, width, height, options = {})
  pdf.fill_color(Color::RGB::White)
  pdf.stroke_color(Color::RGB::Black)
  pdf.rectangle(x, y, width, height).fill
  #pdf.rectangle(x, y, width, height).stroke

  x = x.to_f
  y = y.to_f
  width = width.to_f
  height = height.to_f

  if options[:no_guard]
    bar_width = width / barcode.width.to_f
  else
    bar_width = width / (barcode.width.to_f + 20.0)
  end

  # leave 2 units at the top, 8 units at the bottom
  bar_height = height - 14.0

  # Assuming point units
  y_offset = y + 12.0

  # Now render the barcode
  count = 1
  x_offset = x + (options[:no_guard] ? 0 : bar_width * 10.0)
  barcode.rle.split('').each do |unit_width|
    box_width = unit_width.to_f * bar_width
    pdf.fill_color(count.odd? ? Color::RGB::Black : Color::RGB::White)
    pdf.rectangle(x_offset,y_offset,box_width,bar_height).fill
    x_offset += box_width.to_f
    count += 1
  end

  pdf.select_font "Times-Roman"
  font_size = 10
  pdf.fill_color(Color::RGB::Black)
  pdf.add_text_wrap(x, y+2.0, width, barcode.value.to_s, font_size, :center, 0)
end

def render_postnet(pdf, barcode, x, y, width, height)
  pdf.fill_color(Color::RGB::White)
  pdf.stroke_color(Color::RGB::Black)
  pdf.rectangle(x, y, width, height).fill
  #pdf.rectangle(x, y, width, height).stroke

  x = x.to_f
  y = y.to_f
  width = width.to_f
  height = height.to_f

  bar_width = width / barcode.wn.size.to_f

  # leave 2 units at the top, 8 units at the bottom
  bar_height = height

  # Assuming point units
  y_offset = y

  # Now render the barcode
 pdf.fill_color(Color::RGB::Black)
  count = 1
  x_offset = x
  barcode.wn.split('').each do |item|
    pdf.rectangle(x_offset,y_offset,1.0,item=='w' ? bar_height : bar_height/2.0).fill
    x_offset += bar_width
    count += 1
  end
end

pdf = PDF::Writer.new

# row 1
upc_a = Barcode1DTools::UPC_A.new('636920922865', :checksum_included => true)
pdf.add_text_wrap(100, 162, 100, "UPC-A", 10, :left, 0)
render_barcode(pdf, upc_a, 100, 100, 100, 60)

ean_13 = Barcode1DTools::EAN13.new('007820601001', :checksum_included => false)
pdf.add_text_wrap(250, 162, 100, "EAN-13", 10, :left, 0)
render_barcode(pdf, ean_13, 250, 100, 100, 60)

upc_e = Barcode1DTools::UPC_E.new('333333', :checksum_included => false)
pdf.add_text_wrap(400, 162, 100, "UPC-E", 10, :left, 0)
render_barcode(pdf, upc_e, 400, 100, 80, 60)

ean_8 = Barcode1DTools::EAN8.new('9638507', :checksum_included => false)
pdf.add_text_wrap(500, 162, 100, "EAN-8", 10, :left, 0)
render_barcode(pdf, ean_8, 500, 100, 80, 60)

# row 2
upc_a = Barcode1DTools::UPC_A.new('636920922865', :checksum_included => true)
pdf.add_text_wrap(100, 262, 100, "UPC-A", 10, :left, 0)
render_barcode(pdf, upc_a, 100, 200, 95, 60, :no_guard => true)

upc_supp_2 = Barcode1DTools::UPC_Supplemental_2.new('23')
pdf.add_text_wrap(195, 262, 100, "UPC-Supp-2", 10, :left, 0)
render_barcode(pdf, upc_supp_2, 205, 200, 20, 50, :no_guard => true)

upc_a = Barcode1DTools::EAN13.new('9781591844921', :checksum_included => true)
pdf.add_text_wrap(300, 262, 100, "EAN-13", 10, :left, 0)
render_barcode(pdf, upc_a, 300, 200, 95, 60, :no_guard => true)

upc_supp_5 = Barcode1DTools::UPC_Supplemental_5.new('52595')
pdf.add_text_wrap(395, 262, 100, "UPC-Supp-5", 10, :left, 0)
render_barcode(pdf, upc_supp_5, 405, 200, 47, 50, :no_guard => true)

# row 3
codabar = Barcode1DTools::Codabar.new('A29322930C')
pdf.add_text_wrap(100, 362, 100, "Codabar", 10, :left, 0)
render_barcode(pdf, codabar, 100, 300, 100, 60)

code11 = Barcode1DTools::Code11.new('23934-23')
pdf.add_text_wrap(250, 362, 100, "Code 11", 10, :left, 0)
render_barcode(pdf, code11, 250, 300, 100, 60)

code128 = Barcode1DTools::Code128.new('Hello, World!')
pdf.add_text_wrap(400, 362, 100, "Code 128", 10, :left, 0)
render_barcode(pdf, code128, 400, 300, 100, 60)

# row 4
code3of9 = Barcode1DTools::Code3of9.new('THIS IS A TEST')
pdf.add_text_wrap(100, 462, 100, "Code 3 of 9", 10, :left, 0)
render_barcode(pdf, code3of9, 100, 400, 150, 60)

code93 = Barcode1DTools::Code93.new('This is a test!')
pdf.add_text_wrap(300, 462, 100, "Code 93", 10, :left, 0)
render_barcode(pdf, code93, 300, 400, 200, 60)

# row 5
coop2of5 = Barcode1DTools::Coop2of5.new('1234567')
pdf.add_text_wrap(100, 562, 100, "Coop 2 of 5", 10, :left, 0)
render_barcode(pdf, coop2of5, 100, 500, 100, 60)

iata2of5 = Barcode1DTools::IATA2of5.new('1234567')
pdf.add_text_wrap(250, 562, 100, "IATA 2 of 5", 10, :left, 0)
render_barcode(pdf, iata2of5, 250, 500, 120, 60)

industrial2of5 = Barcode1DTools::Industrial2of5.new('1234567')
pdf.add_text_wrap(400, 562, 100, "Industrial 2 of 5", 10, :left, 0)
render_barcode(pdf, industrial2of5, 400, 500, 120, 60)

# row 6
interleaved2of5 = Barcode1DTools::Interleaved2of5.new('1234567890')
pdf.add_text_wrap(100, 662, 100, "Interleaved 2 of 5", 10, :left, 0)
render_barcode(pdf, interleaved2of5, 100, 600, 100, 60)

matrix2of5 = Barcode1DTools::Matrix2of5.new('1234567')
pdf.add_text_wrap(250, 662, 100, "Matrix 2 of 5", 10, :left, 0)
render_barcode(pdf, matrix2of5, 250, 600, 100, 60)

# row 7
plessey = Barcode1DTools::Plessey.new('1234567890')
pdf.add_text_wrap(100, 762, 100, "Plessey", 10, :left, 0)
render_barcode(pdf, plessey, 100, 700, 150, 60)

msi = Barcode1DTools::MSI.new('1234567')
pdf.add_text_wrap(300, 762, 100, "MSI", 10, :left, 0)
render_barcode(pdf, msi, 300, 700, 120, 60)

# row 8
postnet = Barcode1DTools::PostNet.new('370134460')
pdf.add_text_wrap(100, 62, 100, "PostNet", 10, :left, 0)
render_postnet(pdf, postnet, 100, 40, 400, 18)

pdf.save_as "sample.pdf"
