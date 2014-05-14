_ = require 'lodash'
helpers = require './helpers'

module.exports = (handlebars) ->
  handlebars or= require 'handlebars'

  # Compylr Handlebars Helpers
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  handlebars.registerHelper "eachExpression", (name, _in, expression, options) ->
    value = helpers.safeEvalWithContext expression, @
    instance.helpers.forEach name, _in, value, options

  handlebars.registerHelper "styleExpression", (expression, options) ->
    value = helpers.safeEvalWithContext expression, @, true
    out = ';'
    for key, val of value
      out += "#{_.str.dasherize key}: #{val};"
    " #{out} "

  handlebars.registerHelper "classExpression", (expression, options) ->
    value = helpers.safeEvalWithContext expression, @, true
    out = []
    for key, val of value
      out.push key if val
    ' ' + out.join(' ') + ' '

  handlebars.registerHelper "ifExpression", (expression, options) ->
    value = helpers.safeEvalWithContext expression, @

    if not options.hash.includeZero and not value
      options.inverse @
    else
      options.fn @

  handlebars.registerHelper "expression", (expression, options) ->
    value = helpers.safeEvalWithContext expression, @
    value

  handlebars.registerHelper "hbsShow", (expression, options) ->
    value = helpers.safeEvalWithContext expression, @
    if value then ' data-hbs-show ' else ' data-hbs-hide '

  handlebars.registerHelper "hbsHide", (expression, options) ->
    value = helpers.safeEvalWithContext expression, @
    if value then ' data-hbs-hide ' else ' data-hbs-show '

  handlebars.registerHelper "json", (args..., options) ->
    obj = args[0] or @
    new handlebars.SafeString JSON.stringify obj, null, 2

  handlebars.registerHelper "interpolatedScript", (options) ->
    scriptStr = "<script"
    for key, value of options.hash
      scriptStr += " #{key}=\"#{value}\""
    scriptStr += '>'

    "#{scriptStr} #{options.fn @} </script>"

  handlebars.registerHelper "forEach", (name, _in, contextExpression) ->
    context = helpers.safeEvalWithContext contextExpression, @
    options = _.last arguments
    fn = options.fn
    ctx = @
    inverse = options.inverse
    i = 0
    ret = ""
    data = undefined

    nameSplit = name.split ','

    if context
      if _.isArray(context) or _.isString context
        j = context.length

        while i < j
          iterContext = _.clone ctx
          iterContext[name] = context[i]

          iterContext.$index = i
          iterContext.$first = (i is 0)
          iterContext.$last = i is (iterContext.length - 1)
          iterContext.$odd = i % 2
          iterContext.$even = not (i % 2)
          iterContext.$middle = not iterContext.$first and not iterContext.$last
          ret = ret + fn iterContext
          i++
      else
        objSize = _.size context
        for key, value of context
          iterCtx = _.clone ctx
          iterCtx[nameSplit[0]] = key
          iterCtx[nameSplit[1]] = value
          iterCtx.$index = i
          iterCtx.$first = i is 0
          iterCtx.$odd = i % 2
          iterCtx.$even = not (i % 2)
          iterCtx.$last = i is objSize - 1
          iterCtx.$middle = not iterCtx.$first and not iterCtx.$last
          ret = ret + fn iterCtx
          i++

    ret
