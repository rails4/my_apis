## Rails 4 + Mongoid Application

Zaczynamy od wygenerowania rusztowania aplikacji:

    rails new my_apis --skip-bundle --skip-test-unit --skip-active-record

i edycji pliku [Gemfile](Gemfile).

Linki do dokumentacji gemów:

* [mongoid](http://mongoid.org/en/mongoid/index.html)
* [active_model_serializers](https://github.com/rails-api/active_model_serializers)


### Post Install

RSpec and Mongoid:

```sh
rails g rspec:init
rails g mongoid:config
```

Makes *mongoid* and *active_model_serializers* to play nicely together:

```ruby
# config/initializers/active_model_serializers.rb
Mongoid::Document.send(:include, ActiveModel::SerializerSupport)
Mongoid::Criteria.delegate(:active_model_serializer, :to => :to_a)
```

### Importujemy akapity z „War and Peace” do MongoDB

Akapity z książki „Wojna i pokój” są zapisane w pliku w formacie:

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
Pominiemy `_id` i użyjemy numeru akapitu `p` jako nowego `_id`:

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
  mongoimport -d my_apis_development -c books
```
Na koniec uaktualniamy plik konfiguracyjny [mongoid.yml](config/mongoid.yml).


### Model

Generujemy model *Book*:

```sh
rails g model Book c:string t:string    # paragraph, title
  invoke  mongoid
  create    app/models/book.rb
  invoke    rspec
  create      spec/models/book_spec.rb
```

Dodajemy indeks i definiujemy metodę klasy *search*:

```ruby
class Book
  include Mongoid::Document
  field :c, type: String
  field :t, type: String

  index c: 1

  def self.search(query)
    if query
      search = Regexp.new(query, Regexp::IGNORECASE)
      asc(:id).where(c: search)
    else
      asc(:id)
    end
  end
end
```

### Widoki

Formularz z widoku *books/index.html.erb*:

```rhtml
<%= form_for(:books, method: :get) do -%>
<p>
  <%= text_field_tag :search, params[:search] %>
  <%= submit_tag "Search", name: nil %>
</p>
<% end -%>
```

### Kontroler

Generujemy kontroller *BooksController*:

```sh
rails g controller Books index show
```

Poprawiamy routing w pliku *config/routes.rb*:

```ruby
resources :books, only: [:index, :show]
```

Implementujemy metody *index* and *show*:

```ruby
class BooksController < ApplicationController
  def index
    query = params[:search]
    @books = Book.search(query).limit(4)

    respond_to do |format|
      format.html
      format.json { render json: @books }
    end
  end

  def show
    @book = Book.find params[:id].to_i

    # render HTML and JSON
    respond_to do |format|
      format.html
      format.json { render json: @book }
    end
  end
end
```

## Uruchamianie aplikacji

Uruchamiamy bazę MongoDB:

```sh
bin/mongod.sh  # z moimi ścieżkami do mongod
```

Uruchamiamy serwer www (*thin*):

```sh
rails s -p 3000
```

### HTML

Wchodzimy na strony:

```
localhost:3000/books
localhost:3000/books/4
```

### JSON

```
curl -si localhost:3000/books/0.json
  HTTP/1.1 200 OK
  X-Frame-Options: SAMEORIGIN
  X-XSS-Protection: 1; mode=block
  X-Content-Type-Options: nosniff
  Content-Type: application/json; charset=utf-8
  ETag: "e5f612e82df8251d610bb4629a9f4abb"
  Cache-Control: max-age=0, private, must-revalidate
  X-Request-Id: 7ad38d1e-07cb-4c61-ac99-d344794026ef
  X-Runtime: 0.204584
  Connection: close
  Server: thin 1.6.2 codename Doc Brown

  {
    "_id":0,
    "c":"An Anonymous Volunteer, and David Widger",
    "t":"war and peace"
  }

curl -si localhost:3000/books.json
```
