require 'gepub'
require 'uri'

module GenerateBookHelper
  def generate_epub(title, title_image, author, chapters)
    book_file = generate_epub_file(title, title_image, author, chapters)
    contents = IO.read(book_file)
    File.delete(book_file)
    contents
  end

  def generate_mobi(title, title_image, author, chapters)
    epub_file = generate_epub_file(title, title_image, author, chapters)
    mobi_title = "#{SecureRandom.uuid}.mobi"
    mobi_file = File.join(Rails.root, mobi_title)
    kindlegen = File.join(Rails.root, 'bin', 'kindleGen')

    Kernel::system("#{kindlegen} '#{epub_file}' -c2 -o '#{mobi_title}'")
    contents = IO.read(mobi_file)
    File.delete(epub_file)
    File.delete(mobi_file)
    contents
  end

  private

  def generate_epub_file(title, title_image, author, chapters)
    book = GEPUB::Book.new
    book.identifier = SecureRandom.uuid
    book.title = title
    book.creator = author

    unless title_image.nil?
      book.add_item('img/title', StringIO.new(title_image)).cover_image
    end

    book.add_item('text/stylesheet.css', StringIO.new(stylesheet)).add_property('stylesheet')
    book.add_ordered_item('text/title_page.xhtml', StringIO.new(title_string(title, author)), 'title_page').add_property('title_page')
    book.language = 'en'

    required_zeros = Math.log10(chapters.length).ceil

    chapters.each.with_index do |chapter, index|
      chapter_title = chapter[:title]
      chapter_text = chapter[:content]
      chapter_number_string = "%0#{required_zeros}d" % (index + 1)
      item = book.add_ordered_item("text/ch_#{chapter_number_string}.html")
      item.content = chapter_content(chapter_title, chapter_text)
      item.toc_text chapter_title
      item.set_media_type 'text/html'
    end

    book_file = File.join(Rails.root, "#{SecureRandom.uuid}.epub")
    book.generate_epub(book_file)
    book_file
  end

  def title_string(title, author)
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
<section epub:type="titlepage">
  <h1 class="title">#{title}</h1>
  <h2 class="author">#{author}</h2>
</section>
</body>
</html>
EOF
  end

  def stylesheet
    <<EOF
/* This defines styles and classes used in the book */
body { margin: 5%; text-align: justify; font-size: medium; }
code { font-family: monospace; }
h1 { text-align: left; }
h2 { text-align: left; }
h3 { text-align: left; }
h4 { text-align: left; }
h5 { text-align: left; }
h6 { text-align: left; }
h1.title { }
h2.author { }
h3.date { }
ol.toc { padding: 0; margin-left: 1em; }
ol.toc li { list-style-type: none; margin: 0; padding: 0; }
a.footnoteRef { vertical-align: super; }
em, em em em, em em em em em { font-style: italic;}
em em, em em em em { font-style: normal; }
EOF
  end

  def chapter_content(chapter_title, chapter_text)
    <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="autonoe" />
  <title>#{chapter_title}</title>
  <link rel="stylesheet" type="text/css" href="stylesheet.css" />
</head>
<body>
<section id="#{chapter_title}" class="level2">
<h2>#{chapter_title}</h2>
#{chapter_text}
</section>
</body>
</html>
EOF
  end
end