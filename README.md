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

Instalujemy rozszerzenie FireQuery, link do dokumentacji jQuery:

* [Firefox](http://firequery.binaryage.com/)
* [$.getJSON](http://api.jquery.com/jquery.getjson/) –
  shorthand for
```js
$.ajax({
  dataType: "json",
  url: url,
  data: data,
  success: success
});
```
Sprawdzamy czy aplikacja działa jak należy (powtórka):

```
http://localhost:3000/books

http://localhost:3000/books.json
http://localhost:3000/books.json?search=Anna
```

oraz na konsoli przeglądarki (Firebug: zakładka Net):
```
http://localhost:3000/books/4.json
```

Wpisujemy na konsoli:
```js
$.getJSON("http://localhost:3000/books/4.json", function(data) {
  console.log(JSON.stringify(data));
  // console.dir(data);
  // console.table(data);
});
```

Formularz wygenerowany prze *form_tag*:

```rhtml
<form accept-charset="UTF-8" action="/books" method="get">
  <div style="display:none">
    <input name="utf8" type="hidden" value="&#x2713;">
  </div>
  <div class="inputs">
    <input id="search" name="search" type="text">
    <input type="submit" value="Search">
  </div>
</form>
```

Wyszukiwanie:

```json
$.getJSON("http://localhost:3000/books.json",
    'utf8=%E2%9C%93&search=Anna', function(data) {
  console.log(JSON.stringify(data));
});
```

## CORS

Na Sigmie uruchamiamy mongod i aplikację:
```sh
mongod.sh
git co -b cors
rails s
```

Lokalnie uruchamiamy serwerw www, np. *serve*:
```sh
serve
```

Po wejściu na stronę *localhost:3000/cors.html* na konsoli
przeglądarki dostajemy następujący komunikat:
```
is CORS supported? true
GET http://sigma.ug.edu.pl:3000/books?utf8=%E2%9C%93&search=
Cross-Origin Request Blocked:
  The Same Origin Policy disallows reading the remote resource at
  http://sigma.ug.edu.pl:3000/books?utf8=%E2%9C%93&search=.
  This can be fixed by moving the resource to the same domain or enabling CORS.
```
