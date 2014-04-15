_ = require 'lodash'
# handlebars = require 'handlebars'
helpers = require './helpers'

module.exports = (handlebars) ->
  handlebars or= require 'handlebars'

  # Compylr Handlebars Helpers
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  handlebars.registerHelper "eachExpression", (name, _in, expression, options) ->
    value = helpers.safeEvalStaticExpression expression, @
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
    value = helpers.safeEvalStaticExpression expression, @

    if not options.hash.includeZero and not value
      options.inverse @
    else
      options.fn @

  handlebars.registerHelper "expression", (expression, options) ->
    # TODO: there are better ways to do @, borrow angular helpers.eval function
    value = helpers.safeEvalStaticExpression expression, @
    value

  handlebars.registerHelper "hbsShow", (expression, options) ->
    value = helpers.safeEvalStaticExpression expression, @
    if value then ' data-hbs-show ' else ' data-hbs-hide '

  handlebars.registerHelper "hbsHide", (expression, options) ->
    value = helpers.safeEvalStaticExpression expression, @
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

  # TODO: looping through options
  #   (key, value) in bar
  # TODO: eachIndex
  handlebars.registerHelper "forEach", (name, _in, contextExpression) ->
    context = value = helpers.safeEvalStaticExpression contextExpression, @
    options = _.last arguments
    fn = options.fn
    ctx = @
    inverse = options.inverse
    i = 0
    ret = ""
    data = undefined

    nameSplit = name.split ','

    if context and _.isObject context
      if _.isArray context
        j = context.length

        while i < j
          iterContext = _.clone ctx
          iterContext[name] = context[i]

          if data
            data[name + 'Index'] = i
            data.$index = i
            data.$first = (i is 0)
            data.$last = i is (iterContext.length - 1)
            data.$odd = i % 2
            data.$even = not (i % 2)
            data.$middle = not data.$first and not data.$last
          ret = ret + fn iterContext, data: data
          i++
      else
        objSize = _.size context
        for key, value of context
          if context.hasOwnProperty key
            iterCtx = _.clone ctx
            iterCtx[name] = context[key]
            if data
              data[nameSplit[0]] = key
              data[nameSplit[1]] = value
              data.$index = i
              data.$first = i is 0
              data.$odd = i % 2
              data.$even = not (i % 2)
              data.$last = i is objSize - 1
              data.$middle = not data.$first and not data.$last
            ret = ret + fn iterCtx, data: data
            i++

    ret
