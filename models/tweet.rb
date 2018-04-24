class Tweet
  include Mongoid::Document
  include Mongoid::Timestamps

  field :contents, type: String
  field :date_posted, type: DateTime
  field :user, type: Hash
  field :date_posted, type: DateTime
  field :mentions, type: Array

  attr_readonly :user, :contents
  validates :user, presence: true
  index({contents: "text"})
  store_in collection: 'nt-tweets'
end
