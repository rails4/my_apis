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


### Sharing JSONs only!

Dodajemy *namespace*:

```sh
rails g controller Api::Books index show -p
  create  app/controllers/api/books_controller.rb
  invoke  rspec
    create    spec/controllers/api/books_controller_spec.rb
```

i zmieniamy wygenerowany routing na:

```ruby
Rails.application.routes.draw do
  resources :books, only: [:index, :show]   # zostawiamy bez zmian (na razie?)

  namespace :api do
    resources :books, only: [:index, :show]
  end
```

W *app/controllers/api/books_controller.rb* definiujemy metody
*index* i *show*:

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


## Dodajemy Authorization (czy Authentication?)

> Digest auth, while being pretty okay in transit, has some flaws: it’s
> vulnerable to man-in-the-middle attacks, it is hard to use strong
> hashes such as *bcrypt*, and a few other details.<br>
> So, in the real world, people don't actually use Digest auth very often.<br>
>     R. Bigg, Y. Katz, S. Klabnik. *Rails 4 in Action*

### Token–based Authentication

Generate some sort of token for a user and then require
the client sends token in an HTTP header, like this:

```
Authorization: Token token="abcdef"
```

Then check this token against the tokens stored in app database.

Pro:

* it is possible to turn off someone’s API access by revoking their token
* generated tokens could be long and secure: passwords are sometimes weak

Cons:

* must configure (and use) SSL
