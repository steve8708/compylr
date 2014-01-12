config = require './config'

module.exports =
  warnVerbose: (args...) ->
    console.warn args... if config.verbose

  logVerbose: (args...) ->
    console.info args... if config.verbose

  safeEvalWithContext: (expression, context, clone, returnNewContext, thisArg = @) ->
    context = _.cloneDeep context if clone
    fn = new Function 'context', "with (context) { return #{expression} }"
    try
      output = fn.call context
    catch error
      helpers.warnVerbose 'Action error', error

    if returnNewContext
      context: context
      output: output
    else
      output

  # In Java can use ScriptEngineManager to eval js
  # (http://stackoverflow.com/questions/2605032/using-eval-in-java)
  safeEvalStaticExpression: (expression, context, thisArg = @) ->
    context = _.cloneDeep context
    context['this'] = thisArg
    try
      expressionBody = expressionCache[expression] or esprima.parse(expression).body[0].expression
      expressionCache[expression] = expressionBody unless expressionCache[expression]
    catch error
      console.warn 'Expression error', expression, error

    try
      value = evaluate expressionBody, context
    catch error
      helpers.warnVerbose 'Eval expression error'
    value