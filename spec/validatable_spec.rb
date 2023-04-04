# frozen_string_literal: true

require 'workflow'
require 'callbacker'

module Callbacker
  class MockValidatable
    include Validatable
    include Workflow

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

        execute_validators(triggering_event: triggering_event, **event_args)
      end
    end

    def to_event_args(from:, to:, triggering_event:, args:)
      {
        order: self,
        order_state: self,
        from: from,
        to: to,
        triggering_event: triggering_event,
        args: args
      }
    end
  end

  RSpec.describe Validatable do
    let(:validator) do
      ->(**_) { false }
    end

    let(:reason_for_error) { 'Something did not pass' }

    it 'performs validation on the state transition' do
      MockValidatable.attach_validator(:close, reason_for_error, &validator)

      mock = MockValidatable.new

      expect { mock.close! }.to raise_error(Workflow::TransitionHalted, reason_for_error)
    end
  end
end
