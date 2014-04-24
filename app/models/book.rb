class Book

  include Mongoid::Document
  field :c, type: String
  field :t, type: String

  index c: 1

  def self.search(query)
    if query
      search = Regexp.new(query, Regexp::IGNORECASE)
      asc(:id).where(c: search)
    else
      asc(:id)
    end
  end

end
