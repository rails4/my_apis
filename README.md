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
curl -si localhost:3000/books/8.json
```
Response:
```
{
  "_id":0,
  "c":"An Anonymous Volunteer, and David Widger",
  "t":"war and peace"
}
```
