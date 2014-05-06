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
  resources :books, only: [:index, :show]

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

oraz definiujemy użyty powyżej *ApiController* w pliku
*app/controllers/api_controller.rb*:

```ruby
class ApiController < ActionController::Base
end
```

Sprawdzamy jak i czy to działa na konsoli:

```sh
curl -s localhost:3000/api/books/0.json
curl -s localhost:3000/api/books.json | jq .
```
