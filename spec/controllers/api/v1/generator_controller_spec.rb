require 'rails_helper'
require 'rest-client'
require 'generate_book_helper'
include GenerateBookHelper

RSpec.describe Api::V1::GeneratorController, type: :controller do
  describe 'POST #epub' do
    before do
      allow(GenerateBookHelper).to receive(:generate_epub).and_return(StringIO.new('my great epub'))

      allow(RestClient).to receive(:get)
    end
    describe 'with chapters including html and not url' do
      describe 'and title_image_url is a valid image url' do
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
            chapters: [{'title' => 'chapter 1', 'html' => '<h1>GREAT CHAPTER</h1>'}]
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
            [{title: 'chapter 1', content: '<h1>GREAT CHAPTER</h1>'}]
          )
        end

        it 'returns the epub as the result' do
          expect(response.body).to eq('my great epub')
        end

        it 'sets the filename header' do
          expect(response.headers['Content-Disposition']).to eq('attachment; filename="my title.epub"')
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
            chapters: [{'title' => 'chapter 1', 'html' => '<h1>GREAT CHAPTER</h1>'}]
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
            [{title: 'chapter 1', content: '<h1>GREAT CHAPTER</h1>'}]
          )
        end

        it 'returns the epub as the result' do
          expect(response.body).to eq('my great epub')
        end

        it 'sets the filename header' do
          expect(response.headers['Content-Disposition']).to eq('attachment; filename="my title.epub"')
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
            chapters: [{'title' => 'chapter 1', 'html' => '<h1>GREAT CHAPTER</h1>'}]
          }
        end

        it 'returns the image response code' do
          expect(response).to have_http_status(404)
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

      describe 'and the title image is not an http or https url' do
        before do
          post :epub, params: {
            title: 'my title',
            title_image_url: 'file:///etc/passwd',
            author: 'Nicole',
            chapters: [{'title' => 'chapter 1', 'html' => '<h1>GREAT CHAPTER</h1>'}]
          }
        end

        it 'returns bad request' do
          expect(response).to have_http_status(400)
        end

        it 'does not make a request for the title image' do
          expect(RestClient).to_not have_received(:get)
        end

        it 'does not make an epub' do
          expect(GenerateBookHelper).to_not have_received(:generate_epub)
        end

        it 'tells the caller that not to try that again' do
          expect(response.body).to eq('invalid url: file:///etc/passwd')
        end

        it 'does not set a filename header' do
          expect(response.headers['Content-Disposition']).to be_nil
        end
      end
    end

    describe 'with chapters including url and not html' do
      before do
        ENV['POSTLIGHT_KEY'] = 'my_api_key'
      end

      describe 'happy path' do
        let(:image_response) do
          instance_double('RestClient::Response', code: 200, body: 'image_response')
        end

        let(:chapter_1_response) do
          instance_double('RestClient::Response', code: 200, body: '{"content": "<div id=\"content\"><p>hello world</p></div><p>other content</p>"}')
        end

        let(:chapter_2_response) do
          instance_double('RestClient::Response', code: 200, body: '{"content": "<p>hello world</p><p>other content</p>"}')
        end

        before do
          allow(RestClient).to receive(:get)
            .with('https://example.com/image.png')
            .and_return(image_response)

          allow(RestClient).to receive(:get)
            .with('https://mercury.postlight.com/parser?url=https://example.com/1', {'x-api-key': 'my_api_key'})
            .and_return(chapter_1_response)

          allow(RestClient).to receive(:get)
            .with('https://mercury.postlight.com/parser?url=https://example.com/2', {'x-api-key': 'my_api_key'})
            .and_return(chapter_2_response)

          post :epub, params: {
            title: 'my title',
            title_image_url: 'https://example.com/image.png',
            author: 'Nicole',
            chapters: [
              {title: 'chapter 1', url: 'https://example.com/1'},
              {title: 'chapter 2', url: 'https://example.com/2'}
            ]
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
            [
              {title: 'chapter 1', content: '<div id="content"><p>hello world</p></div><p>other content</p>'},
              {title: 'chapter 2', content: '<p>hello world</p><p>other content</p>'}
            ]
          )
        end

        it 'returns the epub as the result' do
          expect(response.body).to eq('my great epub')
        end

        it 'sets the filename header' do
          expect(response.headers['Content-Disposition']).to eq('attachment; filename="my title.epub"')
        end

        it 'sets the content type header' do
          expect(response.headers['Content-Type']).to eq('application/epub+zip')
        end
      end

      describe 'and chapters contains a url that points to file://' do
        before do
          post :epub, params: {
            title: 'my title',
            author: 'Nicole',
            chapters: [
              {title: 'chapter 1', url: 'https://example.com/1'},
              {title: 'chapter 2', url: 'file:///etc/passwd'}
            ]
          }
        end

        it 'returns the bad request' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'does not make a request for any of the urls' do
          expect(RestClient).to_not have_received(:get)
        end

        it 'does not make an epub' do
          expect(GenerateBookHelper).to_not have_received(:generate_epub)
        end

        it 'lets the caller know what went wrong' do
          expect(response.body).to eq('invalid url: file:///etc/passwd')
        end

        it 'does not set a filename header' do
          expect(response.headers['Content-Disposition']).to be_nil
        end
      end
    end

    describe 'with chapters including neither html nor url' do
      before do
        post :epub, params: {
          title: 'my title',
          author: 'Nicole',
          chapters: [
            {title: 'chapter 1'},
            {title: 'chapter 2'}
          ]
        }
      end

      it 'returns the bad request' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'does not make a request for any of the urls' do
        expect(RestClient).to_not have_received(:get)
      end

      it 'does not make an epub' do
        expect(GenerateBookHelper).to_not have_received(:generate_epub)
      end

      it 'lets the caller know what went wrong' do
        expect(response.body).to eq('chapters must include either a url or html key')
      end

      it 'does not set a filename header' do
        expect(response.headers['Content-Disposition']).to be_nil
      end
    end
  end

  describe 'POST #mobi' do
    before do
      allow(GenerateBookHelper).to receive(:generate_mobi).and_return(StringIO.new('my great epub'))
      allow(RestClient).to receive(:get)

      ENV['POSTLIGHT_KEY'] = 'my_api_key'
    end

    let(:image_response) do
      instance_double('RestClient::Response', code: 200, body: 'image_response')
    end

    let(:chapter_1_response) do
      instance_double('RestClient::Response', code: 200, body: '{"content": "<div id=\"content\"><p>hello world</p></div><p>other content</p>"}')
    end

    let(:chapter_2_response) do
      instance_double('RestClient::Response', code: 200, body: '{"content": "<p>hello world</p><p>other content</p>"}')
    end

    before do
      allow(RestClient).to receive(:get)
        .with('https://example.com/image.png')
        .and_return(image_response)

      allow(RestClient).to receive(:get)
        .with('https://mercury.postlight.com/parser?url=https://example.com/1', {'x-api-key': 'my_api_key'})
        .and_return(chapter_1_response)

      allow(RestClient).to receive(:get)
        .with('https://mercury.postlight.com/parser?url=https://example.com/2', {'x-api-key': 'my_api_key'})
        .and_return(chapter_2_response)

      post :mobi, params: {
        title: 'my title',
        title_image_url: 'https://example.com/image.png',
        author: 'Nicole',
        chapters: [
          {title: 'chapter 1', url: 'https://example.com/1'},
          {title: 'chapter 2', url: 'https://example.com/2'}
        ]
      }
    end

    it 'returns ok' do
      expect(response).to have_http_status(:ok)
    end

    it 'makes a request for the title image' do
      expect(RestClient).to have_received(:get).with('https://example.com/image.png')
    end

    it 'makes an epub' do
      expect(GenerateBookHelper).to have_received(:generate_mobi).with(
        'my title',
        'image_response',
        'Nicole',
        [
          {title: 'chapter 1', content: '<div id="content"><p>hello world</p></div><p>other content</p>'},
          {title: 'chapter 2', content: '<p>hello world</p><p>other content</p>'}
        ]
      )
    end

    it 'returns the epub as the result' do
      expect(response.body).to eq('my great epub')
    end

    it 'sets the filename header' do
      expect(response.headers['Content-Disposition']).to eq('attachment; filename="my title.mobi"')
    end

    it 'sets the content type header' do
      expect(response.headers['Content-Type']).to eq('application/vnd.amazon.mobi8-ebook')
    end
  end
end
