module Spree
  BaseHelper.class_eval do
    def display_price(product)
      product.price_for(current_price_list).display_price.to_html
    end
  end
end