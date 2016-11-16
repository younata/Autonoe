require 'uri'
require 'generate_book_helper'
include GenerateBookHelper

class Api::V1::GeneratorController < ApplicationController
  def epub
    generate_book(params, 'epub')
  end

  def mobi
    generate_book(params, 'mobi')
  end

  private

  def generate_book(params, book_type)
    image_url = params['title_image_url']
    image = nil
    unless image_url.nil?
      unless valid_url? image_url
        return render plain: "invalid url: #{image_url}", status: 400
      end

      image_response = RestClient.get image_url
      unless image_response.code == 200
        return render plain: 'title_image does not exist', status: image_response.code
      end
      image = image_response.body
    end

    params['chapters'].each do |chapter|
      url = chapter['url']
      if url and !valid_url?(url)
        return render plain: "invalid url: #{url}", status: 400
      elsif chapter['url'].nil? and chapter['html'].nil?
        return render plain: 'chapters must include either a url or html key', status: 400
      end
    end

    chapters = params['chapters'].map do |chapter|
      if chapter['url']
        content = download_web_page(chapter['url'])
      elsif chapter['html']
        content = chapter['html']
      end
      {title: chapter['title'], content: content}
    end

    title = params['title']

    if book_type == 'epub'
      response.headers['Content-Type'] = 'application/epub+zip'
      response.headers['Content-Disposition'] = "attachment; filename=\"#{title}.epub\""

      render body: GenerateBookHelper::generate_epub(title, image, params['author'], chapters)
    elsif book_type == 'mobi'
      response.headers['Content-Type'] = 'application/vnd.amazon.mobi8-ebook'
      response.headers['Content-Disposition'] = "attachment; filename=\"#{title}.mobi\""

      render body: GenerateBookHelper::generate_mobi(title, image, params['author'], chapters)
    end
  end

  def valid_url?(url)
    ['http', 'https'].include?(URI(url).scheme)
  end

  def download_web_page(url)
    mercury_key = ENV['POSTLIGHT_KEY']
    response = RestClient.get "https://mercury.postlight.com/parser?url=#{url}", {'x-api-key': mercury_key}

    body = JSON.parse(response.body)

    body['content']
  end
end
