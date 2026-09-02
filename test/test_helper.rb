ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "zip"

# Helpers shared by unit, integration and system tests to assert on the text
# content of exported binaries (PDF glyph streams and xlsx shared strings).
module ExportTestHelpers
  # Prawn writes text as hex-encoded strings inside uncompressed content
  # streams. When DejaVu Sans is embedded those are subset glyph ids that only
  # the font's ToUnicode CMap can resolve, so collect the CMap first.
  def pdf_to_unicode_cmap(raw)
    cmap = {}
    raw.scan(/beginbfchar\n(.*?)\nendbfchar/m).each do |block|
      block[0].scan(/<([0-9A-Fa-f]+)><([0-9A-Fa-f]+)>/).each do |code, uni|
        cmap[code.to_i(16)] = [ uni ].pack("H*").force_encoding("UTF-16BE").encode("UTF-8")
      end
    end
    raw.scan(/beginbfrange\n(.*?)\nendbfrange/m).each do |block|
      block[0].scan(/<([0-9A-Fa-f]+)><([0-9A-Fa-f]+)><([0-9A-Fa-f]+)>/).each do |lo, hi, uni|
        lo_i = lo.to_i(16)
        hi_i = hi.to_i(16)
        uni_i = uni.to_i(16)
        (lo_i..hi_i).each_with_index { |code, i| cmap[code] = [ uni_i + i ].pack("U") }
      end
    end
    cmap
  end

  # Turns one hex string from a `Tj`/`TJ` operator into readable text. Without
  # a CMap the document is on the Helvetica fallback path (Prawn's built-in
  # AFM fonts embed no ToUnicode), where the bytes are literal WinAnsi code
  # points -- which is where the pt-BR accents of "Início" and "Duração" live.
  def decode_pdf_hex(hex, cmap)
    codes = hex.scan(/../).map { |byte| byte.to_i(16) }
    return codes.map { |code| cmap[code] || code.chr }.join if cmap.any?

    codes.pack("C*").encode("UTF-8", "Windows-1252", invalid: :replace, undef: :replace)
  end

  def pdf_text(pdf)
    raw = pdf.b
    cmap = pdf_to_unicode_cmap(raw)

    raw.scan(/BT(.*?)ET/m).flat_map do |block|
      block[0].scan(/<([0-9A-Fa-f]+)>/).map { |(hex)| decode_pdf_hex(hex, cmap) }
    end.join
  end

  # Concatenates every XML part of the workbook so assertions can grep for
  # shared-string content (caxlsx stores cell text in sharedStrings.xml).
  def xlsx_text(binary)
    text = +""
    Zip::File.open_buffer(binary) do |zip|
      zip.entries.select { |entry| entry.name.end_with?(".xml") }.each do |entry|
        # XLSX XML parts are UTF-8; rubyzip reads raw bytes.
        text << entry.get_input_stream.read.force_encoding(Encoding::UTF_8)
      end
    end
    text
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include ExportTestHelpers

    # Add more helper methods to be used by all tests here...
  end
end
