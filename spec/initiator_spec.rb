# frozen_string_literal: true

require 'workflow'
require 'callbacker'

module Callbacker
  class Mock
    include Callbackable
    include Workflow

    attr_accessor :initiated

    def initialize
      @initiated = false
    end

    workflow do
      state :open do
        event :close, transitions_to: :closed
      end

      state :closed

      before_transition do |from, to, triggering_event, args|
        event_args = to_event_args(
          from: from,
          to: to,
          triggering_event: triggering_event,
          args: args
        )

        execute_before_callbacks(triggering_event: triggering_event, **event_args)
      end

      after_transition do |from, to, triggering_event, args|
        execute_after_callbacks(
          triggering_event: triggering_event,
          **to_event_args(
            from: from,
            to: to,
            triggering_event: triggering_event,
            args: args
          )
        )
      end
    end
  end

  class MockInitiator < Initiator
    def initiate
      instance = args[:instance]
      instance.initiated = true
    end
  end

  RSpec.describe Initiator do
    it 'performs initiation when a transition occurs' do
      Mock.attach_after_callback(
        :close,
        &MockInitiator.call
      )

      mock = Mock.new

      expect(mock.initiated).to be false

      mock.close!

      expect(mock.initiated).to be true
    end
  end
end
