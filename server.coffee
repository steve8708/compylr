handlebars = require 'handlebars'
express = require 'express'
exphbs  = require 'express3-handlebars'
_  = require 'lodash'
app = express()

app.engine 'html', exphbs defaultLayout: '../../main'
app.set 'view engine', 'handlebars'
app.set 'views', __dirname

app.get '/', (req, res) ->
  res.render 'template-output/output.html',
    foo: 'BAR'
    selectedProducts: [
      name: 'product name'
      image: sizes: Small: url: 'https://www.google.com/images/srpr/logo11w.png'
    ]

console.info 'Listening in port 3000...'
app.listen 3000


handlebars.registerHelper "forEach", (name, _in, context, options) ->
  fn = options.fn
  inverse = options.inverse
  i = 0
  ret = ""
  data = undefined
  context = context.call(this) if typeof context is 'function'
  if context and _.isObject context
    if _.isArray context
      j = context.length

      while i < j
        context = _.cloneDeep context
        context[name] = context[i]
        if data
          data.index = i
          data.first = (i is 0)
          data.last = i is (context.length - 1)
        ret = ret + fn(context,
          data: data
        )
        i++
    else
      for key of context
        if context.hasOwnProperty key
          context = _.cloneDeep context
          context[name] = context[key]
          if data
            data.key = key
            data.index = i
            data.first = (i is 0)
          ret = ret + fn(context,
            data: data
          )
          i++
  ret = inverse(this) if i is 0
  ret
