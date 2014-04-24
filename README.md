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


## Designing an API

Poniżej skorzystamy z danych zapisanych w kolekcji
*books* w bazie *test*.

Generujemy model *Book*:

```sh
rails g model Book c:string t:string
  invoke  mongoid
  create    app/models/book.rb
  invoke    rspec
  create      spec/models/book_spec.rb
```

Generujemy kontroller *BooksController*:

```sh
rails g controller Books index show
```

poprawiamy routing w pliku *config/routes.rb*:

```ruby
resources :books, only: [:index, :show]
```

i implementujemy metody *index* and *show*:

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

    respond_to do |format|
      format.html
      format.json { render json: @book }
    end
  end
end
```

Metodę *search* dopisujemy w modelu *Book*:

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


### TODO: authentication
