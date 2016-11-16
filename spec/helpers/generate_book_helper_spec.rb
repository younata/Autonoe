require 'rails_helper'
require 'gepub'

def expected_chapter_content(title, text)
  <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="autonoe" />
  <title>#{title}</title>
  <link rel="stylesheet" type="text/css" href="stylesheet.css" />
</head>
<body>
<section id="#{title}" class="level2">
<h2>#{title}</h2>
#{text}
</section>
</body>
</html>
EOF
end

RSpec.describe GenerateBookHelper, type: :helper do
  describe 'generate_epub' do
    let!(:image_double) do
      image = double
      allow(image).to receive(:cover_image)
      image
    end

    let!(:stylesheet_double) do
      stylesheet = double
      allow(stylesheet).to receive(:add_property)
      stylesheet
    end

    let!(:chapter_item) do
      chapter = double
      allow(chapter).to receive(:content=)
      allow(chapter).to receive(:add_property)
      allow(chapter).to receive(:toc_text)
      allow(chapter).to receive(:set_media_type)
      chapter
    end

    let!(:book_double) do
      book = double
      allow(book).to receive(:identifier=)
      allow(book).to receive(:title=)
      allow(book).to receive(:creator=)
      allow(book).to receive(:language=)
      allow(book).to receive(:generate_epub)
      allow(book).to receive(:add_item).with('img/title', any_args).and_return(image_double)
      allow(book).to receive(:add_item).with('text/stylesheet.css', any_args).and_return(stylesheet_double)
      allow(book).to receive(:add_ordered_item).and_return(chapter_item)
      book
    end

    let!(:filename) { File.join(Rails.root, 'uuid.epub') }

    before do
      allow(GEPUB::Book).to receive(:new).and_return(book_double)
      allow(SecureRandom).to receive(:uuid).and_return('uuid')

      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with(filename).and_return('an amazing book')

      allow(File).to receive(:delete).and_call_original
      allow(File).to receive(:delete).with(filename)
    end

    describe 'with an image' do
      let(:result) do
        generate_epub('a title', 'image', 'an author', [{title: 'chapter 1 title', 'content': 'chapter 1 contents'}])
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
        expect(book_double).to have_received(:add_ordered_item).with('text/ch_1.html')
        expect(chapter_item).to have_received(:content=).with(expected_chapter_content('chapter 1 title', 'chapter 1 contents'))
        expect(chapter_item).to have_received(:toc_text).with('chapter 1 title')
        expect(chapter_item).to have_received(:set_media_type).with('text/html')
      end
    end

    describe 'without an image' do
      let(:result) { generate_epub('a title', nil, 'an author', [{title: 'chapter 1 title', 'content': 'chapter 1 contents'}]) }

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
        expect(book_double).to have_received(:add_ordered_item).with('text/ch_1.html')
        expect(chapter_item).to have_received(:content=).with(expected_chapter_content('chapter 1 title', 'chapter 1 contents'))
        expect(chapter_item).to have_received(:toc_text).with('chapter 1 title')
        expect(chapter_item).to have_received(:set_media_type).with('text/html')
      end
    end
  end

  describe 'generate_mobi' do
    let!(:image_double) do
      image = double
      allow(image).to receive(:cover_image)
      image
    end

    let!(:stylesheet_double) do
      stylesheet = double
      allow(stylesheet).to receive(:add_property)
      stylesheet
    end

    let!(:chapter_item) do
      chapter = double
      allow(chapter).to receive(:content=)
      allow(chapter).to receive(:add_property)
      allow(chapter).to receive(:toc_text)
      allow(chapter).to receive(:set_media_type)
      chapter
    end

    let!(:book_double) do
      book = double
      allow(book).to receive(:identifier=)
      allow(book).to receive(:title=)
      allow(book).to receive(:creator=)
      allow(book).to receive(:language=)
      allow(book).to receive(:generate_epub)
      allow(book).to receive(:add_item).with('img/title', any_args).and_return(image_double)
      allow(book).to receive(:add_item).with('text/stylesheet.css', any_args).and_return(stylesheet_double)
      allow(book).to receive(:add_ordered_item).and_return(chapter_item)
      book
    end

    let!(:epub_filename) { File.join(Rails.root, 'uuid.epub') }
    let!(:mobi_filename) { File.join(Rails.root, 'uuid.mobi') }

    before do
      allow(GEPUB::Book).to receive(:new).and_return(book_double)
      allow(SecureRandom).to receive(:uuid).and_return('uuid')

      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with(epub_filename).and_return('an amazing book (epub)')
      allow(IO).to receive(:read).with(mobi_filename).and_return('an amazing book (mobi)')

      allow(File).to receive(:delete).and_call_original
      allow(File).to receive(:delete).with(epub_filename)
      allow(File).to receive(:delete).with(mobi_filename)

      allow(Kernel).to receive(:system).and_return(true)
    end

    describe 'with an image' do
      let(:result) do
        generate_mobi('a title', 'image', 'an author', [{title: 'chapter 1 title', 'content': 'chapter 1 contents'}])
      end

      before do
        expect(result).to_not be_nil
      end

      it 'returns a book' do
        expect(result).to eq('an amazing book (mobi)')
      end

      it 'creates an epub first' do
        expect(book_double).to have_received(:generate_epub).with(epub_filename)
      end

      it 'then calls bin/kindlegen to convert that epub to mobi' do
        kindlegen = File.join(Rails.root, 'bin', 'kindleGen')

        expect(Kernel).to have_received(:system)
          .with("#{kindlegen} '#{epub_filename}' -c2 -o 'uuid.mobi'")
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
        expect(book_double).to have_received(:add_ordered_item).with('text/ch_1.html')
        expect(chapter_item).to have_received(:content=).with(expected_chapter_content('chapter 1 title', 'chapter 1 contents'))
        expect(chapter_item).to have_received(:toc_text).with('chapter 1 title')
        expect(chapter_item).to have_received(:set_media_type).with('text/html')
      end
    end
  end
end