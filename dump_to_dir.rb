#!/usr/bin/env ruby

require 'httparty'
require 'json'
require 'uri'

URL = "http://www.metmuseum.org/api/collection/collectionlisting?offset=%{offset}&perPage=%{perPage}&showOnly=%{showOnly}&sortBy=%{sortBy}&sortOrder=%{sortOrder}"
OUT_DIR = ARGV.first

if OUT_DIR.nil?
  STDERR.puts "must provide path to download dir"
  exit 1
end

def log msg=""
  puts msg
end

(1..1000).each do |offset|
  url = URL % {
    offset: offset,
    perPage: 100,
    showOnly: 'openaccess',
    sortBy: 'AccessionNumber',
    sortOrder: 'asc'
  }
  page_data = HTTParty.get(url).parsed_response
  log "getting offset #{offset}"
  page_data['results'].each do |image_details|
    log "found image: #{image_details['title']}"
    mobile_download_url = URI.escape image_details['image']
    original_download_url = mobile_download_url.gsub('mobile-large', 'original')
    image_key = Base64.urlsafe_encode64 original_download_url
    image_write_path = "#{OUT_DIR}/#{image_key}.jpg"
    meta_write_path = "#{OUT_DIR}/#{image_key}.meta.json"
    if File.exists? meta_write_path
      log "skipping, already exists"
      log
      next
    end
    log "downloading #{original_download_url}"
    image_data = HTTParty.get(original_download_url).parsed_response
    log "downloaded #{image_data.length} datas"
    log "writing to #{image_write_path}"
    File.write(image_write_path, image_data)
    log "writing to #{meta_write_path}"
    File.write(meta_write_path, image_details.to_json)
    log "done with image"
    log
  end
end
