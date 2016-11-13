require 'rails_helper'
require 'rest-client'
require 'generate_book_helper'
include GenerateBookHelper

RSpec.describe Api::V1::GeneratorController, type: :controller do
  describe 'POST #epub' do
    before do
      allow(GenerateBookHelper).to receive(:generate_epub).and_return('my great epub')

      allow(RestClient).to receive(:get)
    end
    describe 'happy path' do
      let(:image_response) do
        instance_double('RestClient::Response', code: 200, body: 'image_response')
      end

      before do
        allow(RestClient).to receive(:get)
          .with('https://example.com/image.png')
          .and_return(image_response)

        post :epub, params: {
          title: 'my title',
          title_image_url: 'https://example.com/image.png',
          author: 'Nicole',
          chapter_html: JSON.dump([{'chapter 1': '<h1>GREAT CHAPTER</h1>'}])
        }
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'makes a request for the title image' do
        expect(RestClient).to have_received(:get).with('https://example.com/image.png')
      end

      it 'makes an epub' do
        expect(GenerateBookHelper).to have_received(:generate_epub).with(
          'my title',
          'image_response',
          'Nicole',
          [{'chapter 1': '<h1>GREAT CHAPTER</h1>'}]
        )
      end

      it 'returns the epub as the result' do
        expect(response.body).to eq('my great epub')
      end

      it 'sets the filename header' do
        expect(response.headers['Content-Disposition']).to eq('inline; filename="my title.epub"')
      end

      it 'sets the content type header' do
        expect(response.headers['Content-Type']).to eq('application/epub+zip')
      end
    end

    describe 'and title_image_url is not specified' do
      before do
        post :epub, params: {
          title: 'my title',
          author: 'Nicole',
          chapter_html: JSON.dump([{'chapter 1': '<h1>GREAT CHAPTER</h1>'}])
        }
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not try to grab the image' do
        expect(RestClient).to_not have_received(:get)
      end

      it 'makes an epub' do
        expect(GenerateBookHelper).to have_received(:generate_epub).with(
          'my title',
          nil,
          'Nicole',
          [{'chapter 1': '<h1>GREAT CHAPTER</h1>'}]
        )
      end

      it 'returns the epub as the result' do
        expect(response.body).to eq('my great epub')
      end

      it 'sets the filename header' do
        expect(response.headers['Content-Disposition']).to eq('inline; filename="my title.epub"')
      end

      it 'sets the content type header' do
        expect(response.headers['Content-Type']).to eq('application/epub+zip')
      end
    end

    describe 'and the title image does not exist' do
      let(:image_response) do
        instance_double('RestClient::Response', code: 404, body: 'nope')
      end

      before do
        allow(RestClient).to receive(:get)
          .with('https://example.com/image.png')
          .and_return(image_response)

        post :epub, params: {
          title: 'my title',
          title_image_url: 'https://example.com/image.png',
          author: 'Nicole',
          chapter_html: JSON.dump([{'chapter 1': '<h1>GREAT CHAPTER</h1>'}])
        }
      end

      it 'returns 400' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'makes a request for the title image' do
        expect(RestClient).to have_received(:get).with('https://example.com/image.png')
      end

      it 'does not make an epub' do
        expect(GenerateBookHelper).to_not have_received(:generate_epub)
      end

      it 'returns the epub as the result' do
        expect(response.body).to eq('title_image does not exist')
      end

      it 'does not set a filename header' do
        expect(response.headers['Content-Disposition']).to be_nil
      end
    end
  end
end
