## REST API

Zaczynamy:

* [Aplikacja Rails 4](Rails4+Mongoid_App.md)


TODO:

* [rails-api](https://github.com/rails-api/rails-api)
* [rack-cors](https://github.com/cyu/rack-cors)



## Designing an API

Poniżej skorzystamy z danych zapisanych w kolekcji
*books* w bazie *my_apis_development*.

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


### TODO: authentication
