#!/usr/bin/env ruby

require 'rubygems'
require 'pdf/writer'
require 'barcode1dtools'

# The quiet zone should be 9x the bar width.  The UPC-A is 95 units wide, so
# all together we should have 113 units of width.  The guard bars extend down
# the equivalent of 5 x units.  The guard bars are in positions 0-2, 27-31,
# and 56-58.  Of the height, 12 pts will be for the letters.
def render_upca(pdf, upc_a, x, y, width, height)
  pdf.fill_color(Color::RGB::White)
  pdf.stroke_color(Color::RGB::Black)
  pdf.rectangle(x, y, width, height).fill
  pdf.rectangle(x, y, width, height).stroke

  x = x.to_f
  y = y.to_f
  width = width.to_f
  height = height.to_f

  # This is 9 units (quiet space) + 95 units (bars) + 9 units (quiet space)
  bar_width = width / 113.0

  pdf.select_font "Times-Roman"

  # Note that the space under the bars on each side is 42 units (bar_width)
  # wide.  We can calculate from there what size font to use.  I want the
  # text width to be around 35 bar_width units wide but it cannot be over 40.
  font_size = nil
  1.upto(72) do |size_try|
    this_width = pdf.text_line_width('55555', size_try)
    if this_width < bar_width * 36.0
      font_size = size_try
    elsif this_width >= bar_width * 36.0
      break
    end
  end

  # leave 2 units at the top, 8 units at the bottom
  bar_height = height - bar_width * 10.0

  # Assuming point units
  y_offset = y + bar_width * 8.0

  # Now render the barcode
  count = 1
  x_offset = x + bar_width * 9.0
  upc_a.rle.split('').each do |unit_width|
    box_width = unit_width.to_f * bar_width
    pdf.fill_color(count.odd? ? Color::RGB::Black : Color::RGB::White)
    pdf.rectangle(x_offset,y_offset,box_width,bar_height).fill
    x_offset += box_width.to_f
    count += 1
  end

  # make space for text underneath bars
  pdf.fill_color(Color::RGB::White)
  pdf.rectangle(x + bar_width * 12.0, y_offset - bar_width, bar_width * 43.0, bar_width * 6.0).fill
  pdf.rectangle(x + bar_width * 58.0, y_offset - bar_width, bar_width * 43.0, bar_width * 6.0).fill

  small_font_size = font_size * 5 / 6
  pdf.fill_color(Color::RGB::Black)

  pdf.add_text_wrap(x + bar_width * 12.0, y + bar_width * 2.0, bar_width * 42.0, upc_a.manufacturers_code, font_size, :center)
  pdf.add_text_wrap(x + bar_width * 61.0, y + bar_width * 2.0, bar_width * 42.0, upc_a.product_code, font_size, 0)
  pdf.add_text_wrap(x + bar_width * 2.0, y + bar_width * 4.0, bar_width * 7.0, upc_a.number_system, small_font_size, 0)
  pdf.add_text_wrap(x + bar_width * 106.0, y + bar_width * 4.0, bar_width * 7.0, upc_a.check_digit.to_s, small_font_size, 0)
end

pdf = PDF::Writer.new

upc_a = Barcode1DTools::UPC_A.new('636920922865', :checksum_included => true)

render_upca(pdf, upc_a, 100, 600, 50, 30)
render_upca(pdf, upc_a, 100, 400, 100, 60)
render_upca(pdf, upc_a, 100, 100, 300, 180)

pdf.save_as "upc_a.pdf"
