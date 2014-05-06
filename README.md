## RESTful JSON API

```
                        START     <---- aplikacja Rails 4 + MongoDB,
                          |             lub aplikacja Sinatra lub – Express,
                          |             albo jakaś inna plikacja www
                   No     |
        /-----------------•
        |                 | Yes
        v                 |
       HTML             JSON            /books,   /books.json
 zwykła aplikacja www     |             /books/4, /books/4.json
                          |
                   No     |
        /-----------------•             dodajemy metadane – root element
        |                 | Yes
        v                 |
  modyfikujemy:           |
    render json: ...      |
                          |
                       /-----\
                       | API |          np. ActiveModel::Serializers
                       \-----/
                          ^    \
                          |     \
                   No     |      \
        /-------------- CORS      \
        |                 |        \  Authenticate requests
        v                 | Yes     \
     DATA lokalne         |          \
     dla aplikacji:       |           \       No
       no_cors.html   share DATA       \----------- http request
                      with World:       \     No
                        cors.html        \--------- http digest
                                          \   Yes
                                           \------- tokens
                                                      model User
                                                      with attrs: email and token
```

Dokumentacja:

* [active_model_serializers](https://github.com/rails-api/rails-api) –
  ActiveModel::Serializer implementation and Rails hooks
* [HTTP authentications](http://guides.rubyonrails.org/action_controller_overview.html#http-authentications)
* [force HTTPS protocol](http://guides.rubyonrails.org/action_controller_overview.html#force-https-protocol)
* [Rails with SSL in Development The Simple Way](http://www.napcsweb.com/blog/2013/07/21/rails_ssl_simple_wa/)
* [rails-api](https://github.com/rails-api/rails-api) –
  Rails for API only applications


## Sharing JSONs only!

Dodajemy *namespace*:

```ruby
Rails.application.routes.draw do
  namespace :api do
    resources :books, only: [:index, :show]
  end
```

```sh
rails g controller Api::Books index show -p
    create  app/controllers/api/books_controller.rb
    invoke  rspec
    create    spec/controllers/api/books_controller_spec.rb
```

Poprawiamy routing:

```ruby
Rails.application.routes.draw do
  # get 'books/index'
  # get 'books/show'
  resources :books, only: [:index, :show]

  # namespace :api do
  #   get 'books/index'
  # end
  # namespace :api do
  #   get 'books/show'
  # end
  namespace :api do
    resources :books, only: [:index, :show]
  end
```

Kontroler *app/controllers/api/books_controller.rb*:

```ruby
class Api::BooksController < ApiController
  def index
    query = params[:search]
    @books = Book.search(query).limit(4)

    render json: @books
  end

  def show
    @book = Book.find params[:id].to_i

    render json: @book
  end
end
```

oraz dodajemy użyty powyżej *app/controllers/api_controller.rb*:

```ruby
class ApiController < ActionController::Base
end
```

Sprawdzamy jak to działa na konsoli:

```sh
curl -s localhost:3000/api/books/0.json
curl -s localhost:3000/api/books.json | jq .
```






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

Formularz wygenerowany przez *form_tag*:

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

```js
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
rails s -p 3000
```

Lokalnie uruchamiamy serwer WWW, na przykład Node.js *serve*:
```sh
cd public/
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

Do odblokowania żądań *Cross-Origin* użyjemy gemu *rack-cors*.
Tak jak to opisano
w [README](https://github.com/cyu/rack-cors#configuration)
dopisujemy do *config/application.rb*:

```ruby
module CorsDataServer
  class Application < Rails::Application
    ...
    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :options]
      end
    end
  end
end
```
A tak sprawdzamy czy to działa:

    curl \
      --verbose \
      --request OPTIONS \
      http://localhost:3000/books.json \
      --header 'Origin: http://localhost' \
      --header 'Access-Control-Request-Headers: Origin, Accept, Content-Type' \
      --header 'Access-Control-Request-Method: GET'

Response:

    * About to connect() to localhost port 3000 (#0)
    *   Trying ::1... Połączenie odrzucone
    *   Trying 127.0.0.1... connected
    * Connected to localhost (127.0.0.1) port 3000 (#0)
    > OPTIONS /books.json HTTP/1.1
    > User-Agent: curl/7.21.7 libcurl/7.21.7 NSS/3.13.5.0 zlib/1.2.5 libidn/1.22 libssh2/1.2.7
    > Host: localhost:3000
    > Accept: */*
    > Origin: http://localhost
    > Access-Control-Request-Headers: Origin, Accept, Content-Type
    > Access-Control-Request-Method: GET
    >
    < HTTP/1.1 200 OK
    < Content-Type: text/plain
    < Access-Control-Allow-Origin: http://localhost
    < Access-Control-Allow-Methods: GET, POST, OPTIONS
    < Access-Control-Max-Age: 1728000
    < Access-Control-Allow-Credentials: true
    < Access-Control-Allow-Headers: Origin, Accept, Content-Type
    < Cache-Control: no-cache
    < X-Request-Id: dce09c04-5fc2-47d7-b6be-946f8ab2fde5
    < X-Runtime: 0.001727
    < Connection: close
    < Server: thin 1.6.2 codename Doc Brown
    <
    * Closing connection #0

Jak widać po nagłówkach *Origin* CORS działa!

Daltego, teraz po wejściu na stronę

    localhost:3000/cors.html

powinno wszystko działać.
