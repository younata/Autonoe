require 'rails_helper'
require 'gepub'

RSpec.describe GenerateBookHelper, type: :helper do
  describe 'generate_epub' do
    let!(:image_double) do
      image = double
      allow(image).to receive(:cover_image)
      image
    end

    let!(:chapter_item) do
      chapter = double
      allow(chapter).to receive(:content=)
      chapter
    end

    let!(:book_double) do
      book = double
      allow(book).to receive(:identifier=)
      allow(book).to receive(:title=)
      allow(book).to receive(:creator=)
      allow(book).to receive(:generate_epub)
      allow(book).to receive(:add_item).and_return(image_double)
      allow(book).to receive(:add_ordered_item).and_return(chapter_item)
      book
    end

    let!(:filename) { File.join(Rails.root, 'a title.epub') }

    before do
      allow(GEPUB::Book).to receive(:new).and_return(book_double)
      allow(SecureRandom).to receive(:uuid).and_return('a uuid')

      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with(filename).and_return('an amazing book')

      allow(File).to receive(:unlink).and_call_original
      allow(File).to receive(:unlink).with(filename)
    end

    describe 'with an image' do
      let(:result) do
        generate_epub('a title', 'image', 'an author', [{'chapter 1 title': 'chapter 1 contents'}])
      end

      before do

        expect(result).to_not be_nil
      end

      it 'returns a book' do
        expect(result).to eq('an amazing book')
        expect(book_double).to have_received(:generate_epub).with(filename)
      end

      it 'configures the title correctly' do
        expect(book_double).to have_received(:title=).with('a title')
      end

      it 'configures the author correctly' do
        expect(book_double).to have_received(:creator=).with('an author')
      end

      it 'configures the title image' do
        expect(book_double).to have_received(:add_item).with('img/title', any_args)
      end

      it 'sets chapters' do
        expect(book_double).to have_received(:add_ordered_item).with('chapter 1 title')
        expect(chapter_item).to have_received(:content=).with('chapter 1 contents')
      end
    end

    describe 'without an image' do
      let(:result) { generate_epub('a title', nil, 'an author', [{'chapter 1 title': 'chapter 1 contents'}]) }

      before do
        expect(result).to_not be_nil
      end

      it 'returns a book' do
        expect(result).to eq('an amazing book')
        expect(book_double).to have_received(:generate_epub).with(filename)
      end

      it 'configures the title correctly' do
        expect(book_double).to have_received(:title=).with('a title')
      end

      it 'configures the author correctly' do
        expect(book_double).to have_received(:creator=).with('an author')
      end

      it 'does not set title image' do
        expect(book_double).to_not have_received(:add_item).with('img/title', any_args)
        expect(image_double).to_not have_received(:cover_image)
      end

      it 'sets chapters' do
        expect(book_double).to have_received(:add_ordered_item).with('chapter 1 title')
        expect(chapter_item).to have_received(:content=).with('chapter 1 contents')
      end
    end
  end
end