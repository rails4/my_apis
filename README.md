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

## No: Tweaking json response

Przechodzimy na gałąź `add_metadata_to_json`:

```sh
git co add_metadata_to_json
```

Tweaking code in [BooksController](app/controllers/books_controller.rb).


## Yes: ActiveModel::Serializers

Generujemy serializer:

```
rails g serializer book
```

Dopisujemy do wygenerowanego pliku *app/serializers/book_serializer.rb*
pozostałe atrybuty:

```ruby
class BookSerializer < ActiveModel::Serializer
  attributes :id, :c, :t
end
```

Dlaczego takie rozwiązanie jest lepsze?
