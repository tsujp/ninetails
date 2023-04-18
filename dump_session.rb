#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'extlz4'
require 'json'

# Mozilla JSONLZ4 total header size is 12 bytes:
#   - 8 byte magic number
#   - 4 byte size of decompressed output (used for their C library memory allocation)
#
# Data from byte 12 onwards is an LZ4 block

# 8 magic bytes (in big endian), is string "mozLz4\0"
magic_bytes = %w(6D6F7A4C7A343000).pack('H*')

File.open('/Users/tsujp/Library/Application Support/Firefox/Profiles/bne467mg.default-release/sessionstore-backups/recovery.jsonlz4', 'rb') do |f|
  unless f.read(8) == magic_bytes
    puts 'Given file is not a Mozilla session LZ4 file.'
    exit 1
  end

  puts "Data payload: #{f.read(4).unpack('V*').first} bytes"

  # Schema: https://wiki.mozilla.org/Firefox/session_restore#The_structure_of_sessionstore.js
  # Useful configuration options: https://wiki.mozilla.org/Firefox/session_restore
  data = JSON.parse(LZ4.block_decode(f.read))

  data['windows'].each do |w|
    w['tabs'].each do |t|
      [t['entries'].last].each do |e|
        puts "-> #{e['url']} <> #{e['title']}"
      end
    end
  end
end
