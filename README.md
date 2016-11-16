# Autonoe - eBook Generation as a service

[![Concourse](https://ci.younata.com/api/v1/pipelines/tethys/jobs/autonoe_tests/badge)](https://ci.younata.com/)

Autonoe is a microservice that'll generate an ebook for you.

Named after the [Moon of Jupiter](https://en.wikipedia.org/wiki/Autonoe_(moon)).

License: [MIT](LICENSE)

## Using

Autonoe can currently generate only 1 type of ebook.

### ePub v3

Make a POST request to `/api/v1/generate/epub` with the following schema as the body:

```json
{
    "title": "string",
    "title_image_url": "url_string",
    "author": "string",
    "chapters": [{"title": "chapter title", "html": "chapter contents"}]
}
```

You can also specify a url to download chapter information from, e.g.

```json
{
    "title": "string",
    "title_image_url": "url_string",
    "author": "string",
    "chapters": [{"title": "chapter title", "url": "https://example.com/chapter_1"}]
}
```

The API should return to you an ePub file in response.

### Mobi

Make a POST request to `/api/v1/generate/mobi` with the following schema as the body:

```json
{
    "title": "string",
    "title_image_url": "url_string",
    "author": "string",
    "chapters": [{"title": "chapter title", "html": "chapter contents"}]
}
```

You can also specify a url to download chapter information from, e.g.

```json
{
    "title": "string",
    "title_image_url": "url_string",
    "author": "string",
    "chapters": [{"title": "chapter title", "url": "https://example.com/chapter_1"}]
}
```

The API should return to you an mobi file in response.

This works by first making an epub of the passed-in data, then running that through kindleGen. This project includes a rake task that runs on deploy which downloads a copy of kindleGen to bin so that it can be used for this.
