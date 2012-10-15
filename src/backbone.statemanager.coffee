###
Backbone.Statemanager, v0.0.1-alpha
Copyright (c)2012 Patrick Camacho and Mark Roseboom, Crashlytics
Distributed under MIT license
http://github.com/crashlytics/backbone.statemanager
###

Backbone.StateManager = ((Backbone, _) ->

  # Set our constructor - just a hash of states and a target
  StateManager = (states, @options = {}) ->
    @states = {}

    # Add each state into the stateManager
    if _.isObject states then _.each states, (value, key) => @addState key, value

  # Give access to Backbone's extend method if they want it
  StateManager.extend = Backbone.View.extend

  # Extend the prototype to make functionality available for instantiations
  _.extend StateManager.prototype, Backbone.Events,
    addState : (state, callbacks) ->
      @states[state] = callbacks
      @trigger 'add:state', state

    removeState : (state) ->
      delete @states[state]
      @trigger 'remove:state', state

    getCurrentState : -> @currentState

    initialize : (options = {}) ->
      # We trigger the initial state if it is set
      if initial = _.chain(@states).keys().find((state) => @states[state].initial).value()
        @triggerState initial, options

    triggerState : (state, options = {}) ->
      return false unless newState = @_matchState state

      unless newState is @states[@currentState] and not options.reEnter
        @exitState options if @currentState
        @enterState state, options
      else
        false

    enterState : (state, options = {}) ->
      return false unless (matchedState = @_matchState @currentState) and _.isFunction matchedState.enter
      @trigger 'before:enter:state', state, matchedState, options
      matchedState.enter options
      @trigger 'enter:state', @currentState, matchedState, options
      @currentState = state
      @

    exitState : (options = {}) ->
      return false unless (matchedState = @_matchState @currentState) and _.isFunction matchedState.exit
      @trigger 'before:exit:state', @currentState, matchedState, options
      matchedState.exit options
      @trigger 'exit:state', @currentState, matchedState, options
      delete @currentState
      @

    _matchState : (state) ->
      return false unless _.isString state

      # We want to allow states to be defined the same way as routes with splats and :params
      state = state.replace(/[-[\]{}()+?.,\\^$|#\s]/g, '\\$&')
                   .replace(/:\w+/g, '([^\/]+)')
                   .replace(/\*\w+/g, '(.*?)')

      stateRegex = new RegExp "^#{ state }$"
      _.chain(@states).keys().find((state) -> stateRegex.test state).value()

  # Function we can use to provide StateManager capabilities to views on construct
  StateManager.addStateManager = (target, options = {}) ->
    new Error 'Target must be defined' unless target
    _.deepBindAll target.states, target
    stateManager = new Backbone.StateManager target.states, options
    target.triggerState = -> stateManager.triggerState.apply stateManager, arguments
    target.getCurrentState = -> stateManager.getCurrentState()

    # Initialize the state manager, unless explictly told not to
    stateManager.initialize options if options.initialize or _.isUndefined options.initialize

    # Cleanup
    delete target.states

  # Recursively finds methods in an object and binds them to target
  _.deepBindAll = (obj) ->
    target = _.last arguments
    _.each obj, (value, key) ->
      if _.isFunction value
        obj[key] = _.bind value, target
      else if _.isObject value
        obj[key] = _.deepBindAll(value, target)
    obj

  StateManager
)(Backbone, _)