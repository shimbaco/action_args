module ActiveSupport
  module Callbacks
    class Callback
      if Rails.version > '4.1'
        # Extending AS::Callbacks::Callback's `make_lambda` not just to call specified
        # method but to call the method with method parameters taken from `params`.
        # This would happen only when
        # * the filter was defined in Symbol form
        # * the target object is_a ActionController object
        def make_lambda_with_method_parameters(filter)
          if Symbol === filter
            lambda do |target, _|
              if ActionController::Base === target
                meth = target.method filter
                method_parameters = meth.parameters
                ActionArgs::ParamsHandler.strengthen_params!(target.class, method_parameters, target.params)
                values = ActionArgs::ParamsHandler.extract_method_arguments_from_params method_parameters, target.params
                target.send filter, *values
              else
                target.send filter
              end
            end
          else
            make_lambda_without_method_parameters filter
          end
        end
        alias_method_chain :make_lambda, :method_parameters

      elsif Rails.version > '4.0'
        def apply_with_method_parameters(code)
          if Symbol === @filter
            method_body = <<-FILTER
              meth = method :#{@filter}
              method_parameters = meth.parameters
              ActionArgs::ParamsHandler.strengthen_params!(self.class, method_parameters, params)
              values = ActionArgs::ParamsHandler.extract_method_arguments_from_params method_parameters, params
              send :#{@filter}, *values
            FILTER
            if @kind == :before
              @filter = "begin\n#{method_body}\nend"
            else
              @filter = method_body.chomp
            end
          end
          apply_without_method_parameters code
        end
        alias_method_chain :apply, :method_parameters

      else  # Rails 3.2
        def start_with_method_parameters(key=nil, object=nil)
          if Symbol === @filter
            method_body = <<-FILTER
              meth = method :#{@filter}
              method_parameters = meth.parameters
              ActionArgs::ParamsHandler.strengthen_params!(self.class, method_parameters, params)
              values = ActionArgs::ParamsHandler.extract_method_arguments_from_params method_parameters, params
              send :#{@filter}, *values
            FILTER
            if @kind == :before
              @filter = "begin\n#{method_body}\nend"
            else
              @filter = method_body.chomp
            end
          end
          start_without_method_parameters key, object
        end
        alias_method_chain :start, :method_parameters
      end
    end
  end
end
