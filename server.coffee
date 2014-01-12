handlebars = require 'handlebars'
express = require 'express'
exphbs  = require 'express3-handlebars'
_  = require 'lodash'
fs = require 'fs'
mkdirp = require 'mkdirp'
convert = require './convert'
evaluate = require("static-eval")
parse = require("esprima").parse

app = express()

partialsDir = 'compiled-templates'

app.engine 'html', exphbs
  defaultLayout: 'main'
  layoutsDir: './'
  partialsDir: "./#{partialsDir}"
  extname: '.tpl.html'

app.set 'view engine', 'handlebars'
app.set 'views', __dirname

pageData =
  openTab: name: 'search'
  foo: 'BAR'
  selectedProducts: [
    name: 'product name'
    image: sizes: Small: url: 'https://www.google.com/images/srpr/logo11w.png'
  ]

app.get '/', (req, res) ->
  res.render 'template-output/output.html', _.extend _.cloneDeep(pageData), $data: _.cloneDeep pageData

# TODO: make this recursively support infinite depth
for type in ['templates', 'modules/account', 'modules/home', 'modules/insights', 'modules/ribbon', 'modules/search', 'modules/tools']
  path = "./templates/#{type}/"
  for fileName in fs.readdirSync path
    continue unless _.contains fileName, '.tpl.html'
    fileStr = fs.readFileSync "#{path}#{fileName}", 'utf8'
    # fileStr = fileStr.replace '.tpl.html', ''
    partialName = "#{type}/" + fileName.replace(/\.handlebars^|.html^/, '')
    mkdirp.sync "./#{partialsDir}/#{type}"
    fs.writeFileSync "./#{partialsDir}/#{partialName}", convert fileStr

handlebars.registerHelper "ifExpression", (expression, options) ->
  fn = new Function expression
  value = null

  # TODO: there are better ways to do this, borrow angular eval function
  ast = parse(expression).body[0].expression
  value = evaluate ast, pageData

  if not options.hash.includeZero and not value
    options.inverse this
  else
    options.fn this

handlebars.registerHelper "expression", (expression, options) ->
  fn = new Function expression
  value = null

  # TODO: there are better ways to do this, borrow angular eval function
  ast = parse(expression).body[0].expression
  value = evaluate ast, pageData

  value

handlebars.registerHelper "json", (data) ->
  JSON.stringify data, null, 2

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
  # ret = inverse(this) if i is 0
  ret

console.info 'Listening in port 3000...'
app.listen 3000