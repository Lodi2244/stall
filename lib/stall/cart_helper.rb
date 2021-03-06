module Stall
  module CartHelper
    extend ActiveSupport::Concern

    included do
      include Stall::CustomersHelper

      if respond_to?(:helper_method)
        helper_method :current_cart, :current_cart_key, :current_customer
      end

      if respond_to?(:after_action)
        after_action :store_cart_to_cookies
      end
    end

    def current_cart
      RequestStore.store[cart_key] ||= load_current_cart
    end

    def current_customer
      @current_customer ||= if user_signed_in?
        if (customer = current_user.customer)
          customer
        else
          current_user.create_customer(email: current_user.email)
        end
      end
    end

    protected

    def current_cart_key
      params[:cart_key].try(:to_sym) || :default
    end

    def load_current_cart(identifier = current_cart_key)
      if (cart = find_cart(identifier))
        return prepare_cart(cart)
      end

      # If no token was stored or the token does not exist anymore, create a
      # new cart and store the new token
      #
      prepare_cart(cart_class.new(identifier: identifier))
    end

    def prepare_cart(cart)
      cart.tap do
        cart.customer = current_customer if current_customer
        # Keep track of potential customer locale switching to allow e-mailing
        # him in his last used locale
        #
        # Only applicable if the locale is an available locale to avoid strange
        # issues with some URL locale management systems that could set the
        # `assets` prefix as a locale, for instance.
        if cart.customer && I18n.locale.in?(I18n.available_locales)
          cart.customer.locale = I18n.locale
        end

        Stall.config.service_for(:product_list_staleness_handling).new(cart).call

        # Only update locale change for existing carts. New carts don't need
        # to be saved, avoiding each robot or simple visitors to create a
        # cart on large shops.
        cart.save unless cart.new_record?
      end
    end

    def find_cart(identifier, ensure_active_cart = true)
      if (cart_token = cookies.encrypted[cart_key(identifier)])
        if (current_cart = ProductList.find_by_token(cart_token)) &&
           (!ensure_active_cart || current_cart.active?)
        then
          return current_cart
        else
          # Remove any cart that can't be fetched, either because it's already
          # paid, or because it was cleaned out
          remove_cart_from_cookies(identifier)
          nil
        end
      end
    end

    def remove_cart_from_cookies(identifier = current_cart_key)
      cookies.delete(cart_key(identifier))
    end

    def cart_key(identifier = current_cart_key, namespace: nil)
      ['stall', 'cart', namespace, identifier.to_s].compact.join('.')
    end

    def cart_class
      Cart
    end

    def store_cart_to_cookies
      if current_cart.persisted? && current_cart.active?
        store_cart_cookie_for(current_cart.identifier, current_cart)
      end
    end

    def store_cart_cookie_for(identifier, cart, namespace: nil)
      cookies.encrypted.permanent[cart_key(identifier, namespace: namespace)] = cart.token
    end
  end
end
