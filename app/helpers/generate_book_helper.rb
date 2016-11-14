require 'gepub'

module GenerateBookHelper
  def generate_epub(title, title_image, author, chapters)
    book = GEPUB::Book.new
    book.identifier = SecureRandom.uuid
    book.title = title
    book.creator = author

    unless title_image.nil?
      book.add_item('img/title', StringIO.new(title_image)).cover_image
    end

    chapters.each do |chapter|
      chapter_title = chapter.keys.first
      book.add_ordered_item(chapter_title.to_s).content = chapter[chapter_title]
    end
    book_file = File.join(Rails.root, "#{title}.epub")
    book.generate_epub(book_file)
    contents = IO.read(book_file)
    File.unlink(book_file)
    contents
  end
end