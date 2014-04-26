## Wersjonowane RESTfull JSON API

Zwracane JSON-y powinny zawierać jakieś metadane.
Na przykład adapter REST [Ember.js](http://emberjs.com/guides/models/the-rest-adapter/)
oczekuje że [tablica](http://emberjs.com/api/classes/Ember.ArrayController.html)
będzie zwracana w postaci takiego JSON-a:
```json
{
  "names": [
    { "id": 1, "first": "Ala" },
    { "id": 2, "first": "Jan" },
    { "id": 3, "first": "Ola" }
  ]
}
```
Oczywiście można to zmienić, zob.
[Ember.ObjectController](http://emberjs.com/api/classes/Ember.ObjectController.html):
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
W tym celu poprawiamy wygenerowany routing:
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
