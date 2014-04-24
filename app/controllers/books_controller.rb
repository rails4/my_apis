class BooksController < ApplicationController

  def index
    query = params[:search]
    # logger.info "======== query: #{params[:search]}"

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
