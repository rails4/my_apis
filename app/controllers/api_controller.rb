class ApiController < ActionController::Base

  before_action :authenticate #, except: [ :index ]

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, options|
      User.where(token: token)
    end
  end

end
