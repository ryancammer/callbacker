# frozen_string_literal: true

module Callbacker
  # The Callbackable module provides a mechanism to attach before and after
  # callbacks to a class implementing Workflow or WorkflowActiveRecord
  # functionality. This enables both before and after callbacks to be executed
  # around a state transition manifested by an event.
  module Callbackable
    # The ClassMethods module provides the methods that are extended onto the
    # class that includes the Callbackable module.
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  # The InstanceMethods module provides the methods that are included in the
  # class that includes the Callbackable module.
  module InstanceMethods
    # The to_event_args method is used to convert the arguments passed to the
    # execute_before_callbacks and execute_after_callbacks methods into a
    # hash that can be passed to the callback.
    # @param from: [Symbol] the previous state.
    # @param to: [Symbol] the current state.
    # @param triggering_event: [Symbol] the event that triggered the state
    # transition.
    # @param args: [Hash] the arguments passed to the event.
    # @return [Hash] the arguments to pass to the callback.
    def to_event_args(from:, to:, triggering_event:, args:)
      {
        instance: self,
        from: from,
        to: to,
        triggering_event: triggering_event,
        args: args
      }
    end

    # The execute_after_callbacks method is used to run any callbacks that
    # have been attached to the class, which essentially enables
    # observers to have access to the previous and current state, along
    # with the event that triggered the state transition. This is fired
    # after a successful state transition has occurred.
    # @param [Symbol] triggering_event the event that triggered the state
    # transition.
    # @param [*Hash] args the args to pass to the callback.
    def execute_after_callbacks(triggering_event:, **args)
      self.class.after_callbacks[triggering_event].each do |callback|
        callback.call(**args)
      end
    end

    # The execute_before_callbacks method is used to run any callbacks that
    # have been attached to the class, but these run *before* a state
    # transition triggered by an event.
    # @param [Symbol] triggering_event the event that is attempting to
    # trigger the state transition.
    # @param [*Hash] args the args to pass to the callback.
    def execute_before_callbacks(triggering_event:, **args)
      self.class.before_callbacks[triggering_event].each do |callback|
        callback.call(**args)
      end
    end
  end

  # The ClassMethods module provides the methods that are extended into the
  # class that includes the Callbackable module.
  module ClassMethods
    # The attach_after_callback method is how we can fire off callbacks after
    # an event has triggered a state change.
    # @example Attach an after_callback to the OrderState class:
    # callback = ->(id, from, to, triggering_event, args) { puts "callback!" }
    # Orders::OrderState.attach_after_callback(:close_for_admin_changes, &callback)
    #
    # @param event [Symbol] the event defined in the workflow to watch.
    # @yieldparam callback the callback to execute after an event occurs.
    # @raise [States::AddCallbackError] if the event is not part of the workflow.
    def attach_after_callback(event, &callback)
      raise add_callback_error(event) unless callbackable_events.include?(event)

      after_callbacks[event] << callback
    end

    # The attach_before_callback method is how we can fire off callbacks before
    # an event triggers a state change.
    # @example Attach a callback to the OrderState class:
    # callback = ->(id, from, to, triggering_event, args) { puts "callback!" }
    # Orders::OrderState.attach_before_callback(:close_for_admin_changes, &callback)
    #
    # @param event [Symbol] the event defined in the workflow to watch.
    # @yieldparam callback the callback to execute after an event occurs.
    # @raise [States::AddCallbackError] if the event is not part of the workflow.
    def attach_before_callback(event, &callback)
      raise add_callback_error(event) unless callbackable_events.include?(event)

      before_callbacks[event] << callback
    end

    # The attach_before_callbacks method enables attaching multiple after callbacks.
    # See (Callbackable#attach_after_callback). Basically, you want to use this to
    # reattach after callbacks you cleared.
    # @param [Object] callbacks the callbacks to attach. NOTE: the expected format is
    # essentially what you get when you call, say, #after_callbacks, which looks like:
    # {:close_for_admin_changes=>
    #   [#<Proc:0x00005576334144d0 (lambda)>,
    #    #<Proc:0x00005576334144a8 (lambda)>]}
    def attach_after_callbacks(callbacks)
      return unless callbacks.present?

      callbacks.each do |event, callback_objects|
        callback_objects.each do |callback|
          attach_after_callback(event, &callback)
        end
      end
    end

    # The attach_before_callbacks method enables attaching multiple after callbacks.
    # See (Callbackable#attach_before_callback). Basically, you want to use this to
    # reattach before callbacks you cleared.
    # @param [Object] callbacks the callbacks to attach. NOTE: the expected format is
    # essentially what you get when you call, say, #after_callbacks, which looks like:
    # {:close_for_admin_changes=>
    #   [#<Proc:0x00005576334144d0 (lambda)>,
    #    #<Proc:0x00005576334144a8 (lambda)>]}
    def attach_before_callbacks(callbacks)
      return unless callbacks.present?

      callbacks.each do |event, callback_objects|
        callback_objects.each do |callback|
          attach_after_callback(event, &callback)
        end
      end
    end

    # This will remove all of the attached after callbacks.
    def clear_all_after_callbacks
      @after_callbacks = Hash.new { |hash, key| hash[key] = [] }
    end

    # This will remove all of the before callbacks attached to OrderState.
    def clear_all_before_callbacks
      @before_callbacks = Hash.new { |hash, key| hash[key] = [] }
    end

    # before_callbacks are blocks that are executed before a state transition
    # triggered by an event.
    def before_callbacks
      @before_callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    # after_callbacks are blocks that are executed upon successful state transition
    # by an event.
    def after_callbacks
      @after_callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    protected

    def add_callback_error(event)
      States::AddCallbackError.new(
        event: event,
        msg: "#{event} does not exist in the workflow."
      )
    end

    def callbackable_events
      @callbackable_events ||=
        workflow_spec
          .state_names
          .collect { |state_name| workflow_spec.states[state_name].events }
          .reject(&:nil?)
          .collect(&:keys)
          .flatten
    end
  end
end
