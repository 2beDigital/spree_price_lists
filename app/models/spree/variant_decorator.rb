module Spree
  Variant.class_eval do
    after_save :add_product_price_to_lists

    has_one :default_price,
      -> { where price_list_id: Spree::PriceList.default.id },
      class_name: 'Spree::Price',
      dependent: :destroy,
      inverse_of: :variant

    def price_for(price_list)
      prices.select do |price|
        price.price_list_id == price_list.id
      end.first || Spree::Price.new(variant_id: self.id, currency: Spree::Config[:currency])
    end

    def self.active_for_price_list(price_list = nil)
      price_list_id = price_list ? price_list.id : Spree::PriceList.default.id
      joins(:prices).where(deleted_at: nil)
                    .where('spree_prices.price_list_id' => price_list_id)
                    .where('spree_prices.amount IS NOT NULL')
    end

    def to_hash
      actual_price  = self.price_for(variant_price_list).display_price
      {
        :id    => self.id,
        :in_stock => self.in_stock?,
        :can_supply => self.can_supply?,
        :price => actual_price
      }
    end

    # override this with custom logic
    def variant_price_list
      Spree::PriceList.default
    end

    private

    def add_product_price_to_lists
      price = Spree::Price.where(variant_id: self.id)
      lists = Spree::PriceList.all
      lists.each do |list|
        if price.count < lists.count && price.first.price_list_id != list.id
          new_price = price.first.dup
          new_price.price_list_id = list.id
          new_price.save!
        end
      end
    end
  end
end