class BooksController < ApplicationController

  def show
    @book = Book.find params[:id].to_i

    respond_to do |format|
      format.html
      format.json { render json: @book }
    end
  end

end
