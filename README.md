## API – Mongoid + AMS

Zaczynamy od wygenerowania rusztowania aplikacji:

    rails new my_apis --skip-bundle --skip-test-unit --skip-active-record

i edycji pliku [Gemfile](Gemfile).

Podręczne linki:

* [rails-api](https://github.com/rails-api/rails-api)
* [rack-cors](https://github.com/cyu/rack-cors)
* [mongoid](http://mongoid.org/en/mongoid/index.html)

### Post Install

```sh
rails-api g rspec:init
rails-api g mongoid:config
```

### Mongoid + Active Model Serializers

Makes *mongoid* and *active_model_serializers* to play nicely together:

```ruby
# config/initializers/active_model_serializers.rb
Mongoid::Document.send(:include, ActiveModel::SerializerSupport)
Mongoid::Criteria.delegate(:active_model_serializer, :to => :to_a)
```

### Import paragraphs from „War and Peace” into MongoDB

Akapity z książki „Wojna i pokój” mam zapisane w takim formacie:

```js
{
  "_id": {
    "$oid": "5356b2c7e1382350df000001"
  },
  "c": "An Anonymous Volunteer, and David Widger",
  "p": 0,
  "t": "war and peace"
}
```

Do bazy zaimportujemy dane w wygodniejszym formacie.
Pominiemy `_id` i użyjemy numeru akapitu (`p`) jako nowego `_id`:

```json
{
  "_id": 0,
  "c": "An Anonymous Volunteer, and David Widger",
  "t": "war and peace"
}
```

Konwersję wykonamy za pomocą programu [jq](http://stedolan.github.io/jq/):

```sh
< war_and_peace.json jq -c '. | {_id: .p, c, t}' | \
  mongoimport -d test -c books
```


### TODO: Implementacja API w wersji v1

Format zwracanych danych, którego oczekuje adapter REST frameworka Ember.js
jest opisany w samouczku [The REST Adapter](http://emberjs.com/guides/models/the-rest-adapter/)
(tylko dla obiektów):

Tablica, [Ember.ArrayController](http://emberjs.com/api/classes/Ember.ArrayController.html):
```json
{
  "names": [
    { "id": 1, "first": "Ala" },
    { "id": 2, "first": "Jan" },
    { "id": 3, "first": "Ola" }
  ]
}
```
**TODO:** format bez *object root*?

Obiekt [Ember.ObjectController](http://emberjs.com/api/classes/Ember.ObjectController.html):
```json
{
  "name": {
    "id": 2, "first": "Jan"
  }
}
```

Do testowania użyjemy danych z przykładu powyżej.

Zaczniemy od dodania do routingu zasobu *names*
oraz wygenerowania kodu dla modelu *Name*:
```
rails g api_resource_route api/v1/names
  route  namespace :api do namespace :v1 do resources :names, except: :edit end end
rails g model name first:string
  create  app/models/name.rb
```
Do wygenerowanego routingu dopisujemy jeszcze *:new*, ponieważ
obie metody powinny być zdefiniowane przez klienta, na przykład
aplikację Ember.js lub Rails.

Do wersjonowanie API będziemy korzystać z *namespaces*.
Nieco poprawiamy wygenerowany routing:
```ruby
namespace :api do
  namespace :v1 do
    resources :names, except: [ :edit, :new ], defaults: { format: 'json' }
  end
end
```

Dane zapiszemy w bazie, korzystając z *db/seeds.rb*:
```
rake db:seed
```

Teraz kolej na „wersjonowany” kontroler:
```
rails g controller api/v1/names index create show update destroy --skip-assets
  create  app/controllers/api/v1/names_controller.rb
   route  get "names/destroy"
   route  get "names/update"
   route  get "names/show"
   route  get "names/create"
   route  get "names/index"
```
i od razu usuwamy dodane *route*s.

Dodajemy plik *app/controllers/api/v1/application_controller.rb* o zawartości
(zob. dokumentacja Rails API):
```ruby
class Api::V1::ApplicationController < ActionController::API
  include ActionController::MimeResponds # support for respond_to and respond_with
  respond_to :json
end
```
i zmieniamy kod wygenerowanym kontrolerze:
```ruby
class Api::V1::NamesController < Api::V1::ApplicationController
  def index
    @names = Name.all
    respond_with(@names)
  end
  def show
    @name = Name.find(params[:id])
    respond_with(@name)
  end
end
```

Uruchamiamy aplikację:
```
rails s -p 3000
```
i na konsoli wykonujemy polecenie:
```
curl -# localhost:3000/api/v1/names.json
curl -# localhost:3000/api/v1/names      # można też tak
[
   { "first" : "Ala", "_id" : "5103ef9fe13823798b000001" },
   { "first" : "Jan", "_id" : "5103ef9fe13823798b000002" },
   { "first" : "Ola", "_id" : "5103ef9fe13823798b000003" }
]
```
Zwracana jest tablica a nie obiekt. Musimy to zmienić!


## Zmieniamy format zwracanych danych za pomocą RABL

W tym celu skorzystamy z szablonów RABL dla widoków:
„output is described within a view template using a simple ruby DSL”.

Dodajemy brakujące katalogi:
```
mkdir -p app/views/api/v1
```
oraz szablon widoku tablicy *app/views/index.json.rabl*:
```ruby
collection @names, root: "names", object_root: false # object assignment
attributes :id, :first # attributes to be included in response
```
i szablon widoku elementu *app/views/show.json.rabl*:
```ruby
object @name            # object assignment
attributes :id, :first  # attributes to be included in response
```

Sprawdzamy jak to działa. Uruchamiamy aplikację i pobieramy JSON-y:

```
curl localhost:3000/names.json
{
   "names" : [
      { "first" : "Ala", "id" : "5103ef9fe13823798b000001" },
      { "first" : "Jan", "id" : "5103ef9fe13823798b000002" },
      { "first" : "Ola", "id" : "5103ef9fe13823798b000003" }
   ]
}

curl localhost:3000/names/5103ef9fe13823798b000001.json
{
   "name" : {
      "first" : "Ala", "id" : "5103ef9fe13823798b000001"
    }
}
```
Teraz jest dobrze!

## Nieistniejące dokumenty

Próba pobrania nieistniejącego dokumentu kończy się błędem.
Zmienimy to zachowanie przechwytując wyjątek:

```ruby
class Api::V1::NamesController < Api::V1::ApplicationController
  before_filter :find_name, only: [ :show ]
  def show
    respond_with(@name)
  end
private
  def find_name
    @name = Name.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    error = { error: "The name you were looking for could not be found." }
    respond_with(error, status: :not_found)
  end
end
```

A tak możemy sprawdzić, jak to działa:
```
curl -I localhost:3000/api/v1/names/1.json
  HTTP/1.1 404 Not Found
  Content-Type: application/json; charset=utf-8
  Cache-Control: no-cache
  X-Request-Id: 7456b98eb510f7a494bc4d6e1ab2d69d
```


## Implementujemy metodę *create*

Na początek cytat za „Rails 4 in Action”:
On the final line of this action, you manually set the *location* key
in the headers by passing through the `:location` option so that it points to
the correct URL of something such as

    http://localhost:3000/api/v1/names/1.json

rather than the Rails default of

    http://localhost:3000/projects/1.json

People who are using your API can then store this location and reference
it later on when they wish to retrieve information about the project.
The URL that Rails defaults to goes to the user-facing version
of this resource */names/1.json*, which is incorrect.
```ruby
def create
  name = Project.new(params[:name])
  if name.save
    respond_with(name, location: api_v1_project_path(name)) # returns status: 201
  else
    respond_with(name) # return a Rails response with errors
  end
end
```

Szablon *app/views/create.json.rabl* zostanie użyty w funkcji zwrotnej
„success” w żądaniu ajax wywoływanym z formularza
dla utworzenia nowego elementu.
W funkcji zwrotnej oczekujemy JSON-a z zapisanym w kolekcji elementem,
aby umieścić go w DOM:
```ruby
object @name            # object assignment
attributes :id, :first  # attributes to be included in response
```


## Implementujemy metody *update* i *delete*

Standard:
```ruby
class Api::V1::NamesController < Api::V1::ApplicationController
  before_filter :find_name, only: [ :show, :update, :destroy ]

  def update
    @name.update_attributes(params[:name]) # success: returns status 204
    respond_with(@name)                    # failure: returns status 422
  end
  def destroy
    @name.destroy       # success: returns status 204
    respond_with(@name) # failure: returns status ???
  end
```


## curl – sprawdzamy jak to działa

Pobieramy wszystko, jeden dokument:
```
curl -#v localhost:3000/api/v1/names
curl -#v localhost:3000/api/v1/names/5103ef9fe13823798b000001
```
Dodajemy nowy dokument:
```
curl -X POST localhost:3000/api/v1/names -H "Content-Type: application/json" -d '{
  "name" : { "first": "Ewa" }
}'

    { "_id":"5106c4afe138234f48000004", "first": "Ewa" }

curl -X GET localhost:3000/api/v1/names
```

Uaktualniamy dopiero co dodany dokument (*id* kopiujemy z odpowiedzi powyżej):
```
curl -X PUT localhost:3000/api/v1/names/5106c4afe138234f48000004 \
      -H "Content-Type: application/json" -d '{
 "name" : { "first": "Iwo" }
}'
curl -X GET localhost:3000/api/v1/names
```

Usuwamy uaktualniony dokument:
```
curl -X DELETE localhost:3000/api/v1/names/5106c4afe138234f48000004
curl -X GET localhost:3000/api/v1/names
```

## Strona *cors.html*

*public/cors.html* – przykładowa strona korzystająca z tego API.


# Konfiguracja *Rack::Cors*

Dopisujemy w *config/application.rb*:

```ruby
module CorsDataServer
  class Application < Rails::Application
    ...
    config.middleware.use Rack::Cors do
      allow do
        # regular expressions can be used here
        # origins 'localhost:3000', /http:\/\/192\.168\.0\.\d{1,3}(:\d+)?/
        origins '*'
        # resource %r{/names/\d+.json},
        # resource '*', :headers => :any, :methods => [:get, :options]
        resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
      end
    end
  end
end
```

Sprawdzamy czy to działa:

```sh
curl \
  --verbose \
  --request OPTIONS \
  http://localhost:3000/api/v1/names.json \
  --header 'Origin: http://localhost' \
  --header 'Access-Control-Request-Headers: Origin, Accept, Content-Type' \
  --header 'Access-Control-Request-Method: GET'
```

Response:

    * About to connect() to localhost port 3000 (#0)
    *   Trying 127.0.0.1... connected
    * Connected to localhost (127.0.0.1) port 3000 (#0)
    > OPTIONS /api/v1/names.json HTTP/1.1
    > User-Agent: curl/7.21.7
    > Host: localhost:3000
    > Accept: */*
    > Origin: http://localhost
    > Access-Control-Request-Headers: Origin, Accept, Content-Type
    > Access-Control-Request-Method: GET
    >
    < HTTP/1.1 200 OK
    < Content-Type: text/plain
    < Access-Control-Allow-Origin: http://localhost
    < Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
    < Access-Control-Max-Age: 1728000
    < Access-Control-Allow-Credentials: true
    < Access-Control-Allow-Headers: Origin, Accept, Content-Type
    < Cache-Control: no-cache
    < X-Request-Id: a244fbcf16b779202c975555a9e0ca52
    < X-Runtime: 0.025061
    < Connection: close
    < Server: thin 1.5.0 codename Knife
    <
    * Closing connection #0

Jak widać po nagłówkach *Origin* CORS działa!


## Pobieramy dane korzystając z CORS

Będziemy potrzebować prostego serwera stron HTML.
Zainstalujemy [Node.js](http://nodejs.org/download/)
i użyjemy servera *serve* z pakietu NPM o tej samej nazwie:
```
npm install -g serve
```

Następnie w pliku *cors.html* wpisujemy w znaczniku *script*:
```js
$(function() {
  console.log('is CORS supported?', $.support.cors);

  $.getJSON('http://sigma.ug.edu.pl:4444/api/v1/names', function(data) {
    console.log(JSON.stringify(data));
    var list = data.names;
    $.each(list, function() {
      console.log(this);
    });
  });
});
```
Uruchamiamy aplikację na Sigmie na porcie 4444:
```
rails s -p 4444
```
Następnie, lokalnie z katalogu *public*, uruchamiamy serwer HTML:
```
cd public/
serve -p 3000
```
Dopiero teraz możemy sprawdzić czy CORS działa. Wchodzimy na stronę:
```
http://localhost:3000/cors.html
```
i podglądamy na konsoli co zostało zapisane.
Jeśli wszystko jest OK, to dopisujemy nieco kodu który wypisze
nam zawartość wczytanego JSON-a.



# Przykładowe bazy danych

DONE:

1. names (*cors.html*)
2. books (*books.html*)
3. imieniny (*imieniny.html*)

CORS DATA SERVER:

1\. Na Sigmie uruchamiamy demona MongoDB:
```
mongod.sh
```
2\. Uruchamiamy aplikację *cors-data-server* na porcie 4444:
```
cd Bitbucket/cors-data-server/
rails s -p 4444
```

KLIENT:

1\. Klonujemy to repo i w katalogu *public/* uruchamiamy serwer HTTP:
```
serve -p 3000
```
2\. Wchodzimy na stronę:
```
localhost:3000
```
gdzie klikamy w jeden z plików HTML wymienionych na liście DONE powyżej.


## books (books from the *gutenberg* server)

Zaczniemy od książki „War and Peace” Lwa Tołstoja.
W kolekcji *books* zapiszemy jako oddzielne dokumenty (prawie) wszystkie
akapity tej książki:
```sh
script/gutenberg2mongo.rb war-and-peace.txt \
    -c books \
    -d cors_data_server_development \
  http://www.gutenberg.org/cache/epub/2600/pg2600.txt
```

Przykładowy zapisany w bazie dokument:
```json
{
  "_id": ObjectId("5107bc3fe1382358cf000014"),
  "c": "Prince Vasili wished to obtain this post for his son, […]",
  "p": 19,
  "t": "war and peace"
}
```

Generujemy wersjonowany routing:
```
rails g api_resource_route api/v1/books
  route  namespace :api do  namespace :v1 do resources :books, except: :edit end end
```
i od razu nieco poprawiamy wygenrowany kod (wstawiamy nowy routing
do już istniejących *namespacs*s)
```ruby
namespace :api do
  namespace :v1 do
    resources :names, except: [ :edit, :new ], defaults: { format: 'json' }
    resources :books, only: :index, defaults: { format: 'json' }
  end
end
```
Myślę tylko o wyszukiwaniu z *infinite scroll*.

Teraz kolej na model:
```ruby
rails g model book c:text p:integer t:string
  invoke  mongoid
  create    app/models/book.rb
```
Następnie – na kontroller:
```
rails g controller api/v1/books index --skip-assets
  create  app/controllers/api/v1/books_controller.rb
   route  get "books/index"
```
i od razu usuwamy dodany routing i sprawdzamy czy w katalogu
*controllers/api/v1/* istnieje utworzony wcześniej plik
*application_controller.rb*. Teraz dopisujemy poprawiamy kod wygenerowanego
kontrolera *books_controller.rb*:
```ruby
class Api::V1::BooksController < Api::V1::ApplicationController
  def index
    @books = Book.limit(4) # temporarily
    respond_with(@books)
  end
end
```
Wreszcie możemy uruchomic aplikację i sprawdzić czy wpisany kod działa:
```
curl -# localhost:3000/api/v1/books
```
Dostajemy komunikat, że brakuje szablonu. Tworzymy brakujący szablon
*views/api/v1/books/index.json.rabl*:
```ruby
collection @books, root: "books", object_root: false
attribute p: :id   # ustaw _id na numer akapitu
attributes :c, :t
```
Sprawdzamy jeszcze raz czy wszystko działa. Teraz powinno być OK.

Na koniec dodajemy metodę *search* do modelu *Book*:
```ruby
def self.search(query)
  if query
    search = Regexp.new(query, Regexp::IGNORECASE)
    asc(:id).where(c: search)
  else
    asc(:id)
  end
end
```
i implementujemy paginację w kontrolerze:
```ruby
class Api::V1::BooksController < Api::V1::ApplicationController
  def index
    page     = (params[:page].to_i - 1) * params[:per_page].to_i
    per_page = params[:per_page].to_i
    query    = params[:query]

    @books = Book.search(query).skip(page).limit(per_page)
    respond_with(@books)
  end
end
```


### Strona *books.html*

Tworzymy stronę z wyszukiwarką po akapitach z kolekcji *books*.

W wyszukiwarkę wpisujemy napis, który zostanie zamieniony na wyrażenie
regularne. Dlatego nasza wyszukiwarka będzie wyszukiwać akapity pasujące
do wpisanego wyrażenia regularnego.

Paginację łączymy z [infinite-scroll](http://www.infinite-scroll.com/infinite-scroll-jquery-plugin/).
Informację o wyświetlanej stronie będziemy zapisywać w atrybucie *data*:
```html
<body> pagination=Object { page=1, per_page=50, query="^Anna" }
```
Kod strony *books.html* jest w repo w katalogu *public/*.


## imieniny (*name-days*)

Plik *imieniny.csv* zawiera dane w następującym formacie:
```csv
day,month,names
01,01,Mieszka Mieczysława Marii
02,01,Izydora Bazylego Grzegorza
...
```
Będziemy potrzebować pliku JSON z danymi w następującym formacie:
```js
{ "day" : 1, "month" : 1, "names" : [ "Mieszka", "Mieczysława", "Marii" ] }
{ "day" : 2, "month" : 1, "names" : [ "Izydora", "Bazylego", "Grzegorza" ] }
```

Zamianę formatu zrealizuję w trzech krokach.

1\. Importujemy plik *imieniny.csv*:
```
mongoimport -d test -c names --type csv --drop --headerline imieniny.csv
```

2\. Wchodzimy na konsolę *mongo* gdzie wykonujemy:
```js
var cursor = db.names.find().snapshot();
cursor.forEach(function(obj) {
  db.names.update({ _id: obj._id }, { $set: {names: obj.names.split(" ")} });
});
db.names.find({day: 16, month: 1}).pretty();
```

3\. Exportujemy dane do pliku *imieniny.json* w formacie JSON:
```
mongoexport -d test -c names -o imieniny.json
```

Do importu danych użyjemy pliku *imieniny.json*:
```
mongoimport -d cors_data_server_development -c imieniny \
  --drop < imieniny.json
```
*Querying arrays*, czyli wyszukiwanie w tablicy.
Na konsoli *mongo* wpisujemy:
```js
db.imieniny.find({names: "Szymona"}, {_id:0})
db.imieniny.find({names: /^Szym/  }, {_id:0})
db.imieniny.find({names: { $size: 1 } }, {_id:0})
db.imieniny.find({names: { $size: 4 } }, {_id:0})
```

Tak jak poprzednio, zaczynamy od wygenerowania wersjonowanego routingu:
```
rails g api_resource_route api/v1/imieniny
```
i poprawek w wygenerowanym kodzie:
```ruby
namespace :api do
  namespace :v1 do
    resources :names,    except: [ :edit, :new ], defaults: { format: 'json' }
    resources :books,      only: :index,          defaults: { format: 'json' }
    resources :imieniny,   only: :index,          defaults: { format: 'json' }
  end
end
```
Oczywiście prościej byłoby od razu wpisać routing.

**Plural v. singular**: tak będziemy odmieniać „imieniny”,
*initializers/inflections.rb*:
```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'imienin', 'imieniny'
end
```

Generujemy model *Imienin*:
```
rails g model imienin day:String month:String names:Array
  invoke  mongoid
  create    app/models/imienin.rb
```

Generujemy kontroller:
```
rails g controller api/v1/imieniny index --skip-assets
  create  app/controllers/api/v1/imieniny_controller.rb
   route  get "imieniny/index"
```
i usuwamy dodany routing.

Poprawiamy kod wygenerowanego kontrolera:
```ruby
class Api::V1::ImieninyController < Api::V1::ApplicationController
  def index
    @imieniny = Imienin.search(params[:query])
    respond_with(@imieniny)
  end
end
```
i dopisujemy metodę klasową *search* do modelu *Imienin*:
```ruby
def self.search(query)
  if query
    search = Regexp.new(query, Regexp::IGNORECASE)
    asc(:month).asc(:day).where(names: search)
  else
    asc(:month).asc(:day)
  end
end
```
Na koniec dodajemy szablon RABL, *views/api/v1/imieniny/index.json.rabl*:
```ruby
collection @imieniny, root: "imieniny", object_root: false
attributes :id, :day, :month, :names
```

Sprawdzamy jak to działa na konsoli:
```
curl -# localhost:3000/api/v1/imieniny
```
i na konsoli *Rails* też:
```
Imienin.search("Sylwestra").to_a
+--------------------------+-------+-----+-------+------------------------------+
| _id                      | _type | day | month | names                        |
+--------------------------+-------+-----+-------+------------------------------+
| 5106ee6ff71fe4f74ede57d0 |       | 26  | 11    | Delfiny, Sylwestra, Konrada  |
| 5106ee6ff71fe4f74ede57f3 |       | 31  | 12    | Sylwestra, Melanii, Mariusza |
+--------------------------+-------+-----+-------+------------------------------+
2 rows in set
```


### Strona *imieniny.html*

Prosta wyszukiwarka imienin. Wyszukujemy imiona pasujące do wpisanego
wyrażenia regularnego.
Kod strony *imieniny.html* jest w katalogu *public/*.


## fortunes

*TODO:* Użyć *db/seed.rb* do zapisania fortunek w bazie.
