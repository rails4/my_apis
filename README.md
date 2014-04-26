## RESTful JSON API in Rails 4 + MongoDB

The simple ways to think of an API is **share application DATA with world**.

Zaczynamy:

* [Aplikacja Rails 4](Rails4+Mongoid_App.md)

Dokumentacja:

* [active_model_serializers](https://github.com/rails-api/rails-api) –
  ActiveModel::Serializer implementation and Rails hooks
* [rack-cors](https://github.com/cyu/rack-cors) –
  Rack Middleware for handling Cross-Origin Resource Sharing (CORS), which makes cross-origin AJAX possible
* [HTTP authentications](http://guides.rubyonrails.org/action_controller_overview.html#http-authentications)
* [force HTTPS protocol](http://guides.rubyonrails.org/action_controller_overview.html#force-https-protocol)
* [rails-api](https://github.com/rails-api/rails-api) –
  Rails for API only applications


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

Przechodzimy na gałąź `ams`:

```sh
git co ams
```

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

Zamieniamy atrybut `:c` na `:para` oraz usuwamy atrybut `:t`:

```ruby
class BookSerializer < ActiveModel::Serializer
  attributes :id, :para

  def para
    object.c
  end
end
```

### Sprawdzamy jak to działa na konsoli przeglądarki

Instalujemy rozszerzenie FireQuery

* [Firefox](http://firequery.binaryage.com/)


```
http://localhost:3000/books

http://localhost:3000/books.json
http://localhost:3000/books.json?search=Anna
```

Firebug console: zakładka Net:
```
http://localhost:3000/books/4.json
```
