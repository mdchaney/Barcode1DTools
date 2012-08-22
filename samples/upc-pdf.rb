#!/usr/bin/env ruby

require 'rubygems'
require 'pdf/writer'
require 'barcode1dtools'

pdf = PDF::Writer.new
pdf.select_font "Times-Roman"
upc_a = Barcode1DTools::UPC_A.new('636920922865', :checksum_included => true)

x = 100
y = 100

pdf.fill_color(Color::RGB::White)
pdf.stroke_color(Color::RGB::Black)
pdf.rectangle(x-10, y-10, 95+10, 72+10).fill.stroke

# Now render the barcode - units are points so the barcode will be about 1.3"
# Going to start at bottom left 100,100.
count = 1
upc_a.rle.split('').each do |box_width|
  pdf.fill_color(count.odd? ? Color::RGB::Black : Color::RGB::White)
  pdf.rectangle(x,y,box_width.to_i,72).fill
  x += box_width.to_i
  count += 1
end

# make space for text underneath bars
pdf.fill_color(Color::RGB::White)
pdf.rectangle(100+3, 100-6, 42, 12).fill
pdf.rectangle(100+3+42+4, 100-6, 42, 12).fill

# now put the numbers
pdf.fill_color(Color::RGB::Black)
pdf.add_text(100+3+6, 100-5, upc_a.manufacturers_code, 12, 0)
pdf.add_text(100+3+42+5+6, 100-5, upc_a.product_code, 12, 0)
pdf.add_text(100-7, 100, upc_a.number_system, 10, 0)
pdf.add_text(100+95+2, 100, upc_a.check_digit, 10, 0)
#pdf.move_to 100+3+42/2, 100-6
#pdf.text upc_a.manufacturers_code, :font_size => 12, :justification => :center
#pdf.move_to 100+3+42+5+42/2, 100-6
#pdf.text upc_a.product_code, :font_size => 12, :justification => :center

pdf.save_as "upc_a.pdf"
