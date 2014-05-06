class Api::BooksController < ApiController

  def index
    query = params[:search]
    # logger.info "======== query: #{params[:search]}"

    @books = Book.search(query).limit(4)

    render json: @books
  end

  def show
    @book = Book.find params[:id].to_i

    render json: @book
  end

end
