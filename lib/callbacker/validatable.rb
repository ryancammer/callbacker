# frozen_string_literal: true

module Callbacker
  # The Validatable module provides a mechanism to attach
  # validators to a class implementing Workflow or
  # WorkflowActiveRecord functionality. This enables these
  # validators to allow or prevent a state transition before
  # it happens by returning true or false respectively.
  module Validatable
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  # The InstanceMethods module provides the execute_validators method
  # which is used to run any validators that have been attached to the
  # class.
  module InstanceMethods
    # The execute_validators method is used to run any validators that
    # have been attached to the class, which essentially enables
    # the validator to return false and halt a state transition, or
    # return true to allow it to continue.
    # transition.
    # @param [*Hash] args the args to pass to the callback.
    # @return [Boolean] true if the validators succeed.
    # @raise [Workflow::TransitionHalted] if a validation fails.
    def execute_validators(triggering_event:, **args)
      self.class.validators[triggering_event].each do |validator|
        conditional = validator[:conditional]
        halt!(validator[:reason]) unless conditional.call(**args)
      end

      true
    end
  end

  # The ClassMethods module provides the attach_validator method
  # which is how validators can be called when an event attempts to
  # transition states.
  module ClassMethods
    # The attach_validator method is how validators can be called when
    # an event attempts to transition states.
    # @example Attach a validator that blocks a state transition when the
    # close_for_admin_changes event is triggered:
    # validator = ->(id, from, to, triggering_event, args) { false }
    # Orders::OrderState.attach_validator(:close_for_admin_changes, &validator)
    #
    # @param event [Symbol] the event defined in the workflow to watch.
    # @param reason [String] the reason for the error.
    # @yieldparam validator the validator to execute before an event occurs.
    # @raise [States::AddValidationError] if the event is not part of the workflow.
    def attach_validator(event, reason, &validator)
      raise add_validation_error(event) unless validatable_events.include?(event)

      validators[event] << { reason: reason, conditional: validator }
    end

    # The attach_validators method enables attaching multiple validators.
    # See (Validatable#attach_validators).
    def attach_validators(validators)
      return unless validators.present?

      validators.each do |event, validator_objects|
        validator_objects.each do |validator|
          attach_validator(event, validator[:reason], &validator[:conditional])
        end
      end
    end

    # This will remove all of the validators attached to OrderState.
    def clear_all_validators
      @validators = Hash.new { |hash, key| hash[key] = [] }
    end

    # validators are attached to an event, so that when the event attempts to
    # transition states, if the validator returns false, they don't happen.
    def validators
      @validators ||= Hash.new { |hash, key| hash[key] = [] }
    end

    protected

    def add_validation_error(event)
      States::AddValidationError.new(
        event: event,
        msg: "#{event} does not exist in the workflow."
      )
    end

    def validatable_events
      @validatable_events ||=
        workflow_spec
        .state_names
        .collect { |state_name| workflow_spec.states[state_name].events }
        .reject(&:nil?)
        .collect(&:keys)
        .flatten
    end
  end
end
