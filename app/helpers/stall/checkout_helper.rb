module Stall
  module CheckoutHelper
    def step_path(*args)
      checkout_step_path(*([current_cart.identifier] + args))
    end

    def available_shipping_methods_for(cart)
      ShippingMethod.active.ordered.select do |shipping_method|
        calculator_class = Stall::Shipping::Calculator.for(shipping_method)

        unless calculator_class
          raise Stall::Shipping::CalculatorNotFound, <<-MSG.squish
            No calculator found for the shipping method : #{ shipping_method.name }
            (#{ shipping_method.identifier }).
            Please remove the Stall::ShippingMethod with id #{ shipping_method.id }
            or create the associated calculator with
            `rails g stall:shipping:calculator #{ shipping_method.identifier }`
          MSG
        end

        calculator = calculator_class.new(cart, shipping_method)
        calculator.available?
      end
    end
  end
end
