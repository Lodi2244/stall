module Stall
  module Models
    module Customer
      extend ActiveSupport::Concern

      included do
        self.table_name = 'stall_customers'

        include Stall::Addressable

        belongs_to :user, polymorphic: true, inverse_of: :customer
        accepts_nested_attributes_for :user
      end
    end
  end
end
