class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method def require_signin
    authenticate_or_request_with_http_digest do |username|
      if username == "admin"
        "sekret" # password
      end
    end
  end

  before_action :require_signin

end
