class BookSerializer < ActiveModel::Serializer
  # attributes :id, :c, :t
  attributes :id, :para

  def para
    object.c
  end
end
