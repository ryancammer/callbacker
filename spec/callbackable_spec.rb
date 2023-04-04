require 'workflow'
require 'callbacker'

module Callbacker
  class MockCallbackable
    include Callbackable
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

  RSpec.describe Callbacker do
    it 'performs the callback attached to the after_callback method' do
      set = false
      MockCallbackable.attach_after_callback(:close) { set = true }

      expect(set).to be false

      mock = MockCallbackable.new

      mock.close!

      expect(set).to be true
    end
  end
end
