class User
  include Mongoid::Document
  field :username, type: String
  field :token, type: String

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.uuid
  end
end
