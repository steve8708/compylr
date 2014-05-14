esprima = require 'esprima'
config = require './config'
_ = require 'lodash'
evaluate = require 'static-eval'
ent = require 'ent'

expressionCache = {}
evalFnCache = {}

i = 0

module.exports =
  warnVerbose: (args...) ->
    console.warn args... if config.verbose

  logVerbose: (args...) ->
    console.info args... if config.verbose

  safeEvalWithContext: (expression = '', context, clone, thisArg = context, returnNewContext) ->
    expression = ent.decode expression

    fn = evalFnCache[expression] or= new Function 'context', "with (context) { return #{expression} }"
    try
      output = fn.call thisArg, context
    catch error
      @warnVerbose 'Action error', error

    if returnNewContext
      context: context
      output: output
    else
      output

  # In Java can use ScriptEngineManager to eval js
  # (http://stackoverflow.com/questions/2605032/using-eval-in-java)
  safeEvalStaticExpression: (expression = '', context, thisArg = @) ->
    expression = ent.decode expression

    context['this'] = thisArg
    try
      expressionBody = expressionCache[expression] or esprima.parse(expression).body[0]?.expression
      expressionCache[expression] = expressionBody unless expressionCache[expression]
    catch error
      console.warn 'Expression error', expression, error

    try
      value = evaluate expressionBody, context
    catch error
      @warnVerbose 'Eval expression error'
    value
