require 'generate_book_helper'
include GenerateBookHelper

class Api::V1::GeneratorController < ApplicationController
  def epub
    image_url = params['title_image_url']
    image = nil
    unless image_url.nil?
      image_response = RestClient.get image_url
      unless image_response.code == 200
        return render plain: 'title_image does not exist', status: 400
      end
      image = image_response.body
    end

    title = params['title']
    response.headers['Content-Type'] = 'application/epub+zip'
    response.headers['Content-Disposition'] = "inline; filename=\"#{title}.epub\""
    render body: GenerateBookHelper::generate_epub(title, image, params['author'], JSON.parse(params['chapter_html'], :symbolize_names => true))
  end
end
