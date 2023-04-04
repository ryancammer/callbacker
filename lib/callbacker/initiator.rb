# frozen_string_literal: true

module Callbacker
  # The Initiator class is used to create a callback that can be attached to
  # a class that includes the Callbackable module.
  class Initiator
    class << self
      def call
        ->(**args) { new(**args).initiate }
      end
    end

    # Initializes an instance of the class with the arguments that will be
    # passed to the callback.
    # @param args [Hash] the arguments that will be passed to the callback.
    # @return [Initiator] a new instance of WorkOrderCreator.
    def initialize(**args)
      @args = args
    end

    # Performs the initiation of the callback.
    def initiate
      raise NotImplementedError 'You must implement the #initiate method.'
    end

    protected

    attr_reader :args
  end
end
