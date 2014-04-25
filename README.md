## REST API

The simple ways to think of an API is:

1. share DATA with my application
1. share DATA with world

Zaczynamy:

* [Aplikacja Rails 4](Rails4+Mongoid_App.md)

TODO:

* [rails-api](https://github.com/rails-api/rails-api)
* [rack-cors](https://github.com/cyu/rack-cors)
* [HTTP authentications](http://guides.rubyonrails.org/action_controller_overview.html#http-authentications)
* [force HTTPS protocol](http://guides.rubyonrails.org/action_controller_overview.html#force-https-protocol)


## JSONs sharing

Poniżej skorzystamy z danych zapisanych w kolekcji
*books* w bazie *my_apis_development*:

```ruby
class BooksController < ApplicationController
  def index
    ...
    respond_to do |format|
      format.html
      format.json { render json: @books }
    end
  end
  def show
   ...
   respond_to do |format|
      format.html
      format.json { render json: @book }
    end
  end
end
```

Request:
```
curl -s localhost:3000/books/8.json
```
Response:
```
{
  "_id":0,
  "c":"An Anonymous Volunteer, and David Widger",
  "t":"war and peace"
}
```

## NO: tweaking json response

Przechodzimy na gałąź `add_metadata_to_json`:

```sh
git co add_metadata_to_json
```

Tweaking code in [BooksController](app/controllers/books_controller.rb).

But often, we don't want to just have only the data from our model, we
want to add some metadata. So you need to include a root element to
scope the data with, *config/mongoid.yml*:

```yaml
  # Configure Mongoid specific options. (optional)
  options:
    # Includes the root model name in json serialization. (default: false)
    include_root_in_json: true
```
Teraz:

```
curl -s localhost:3000/books/0.json | jq .
{
  "book": {
    "_id": 0,
    "c": "An Anonymous Volunteer, and David Widger",
    "t": "war and peace"
  }
}

curl -s localhost:3000/books.json | jq .
{
  "books": [
    {
      "books": {
        "_id": 0,
        "c": "An Anonymous Volunteer, and David Widger",
        "t": "war and peace"
      }
    },
    ...
```

Dlaczego nie jest to dobre rozwiązanie.
Jakie problemy mogą się pojawić?
