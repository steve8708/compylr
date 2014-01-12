# TODO: get data from shopstylie API over HTTP

handlebars = require 'handlebars'
express = require 'express'
exphbs  = require 'express3-handlebars'
_  = require 'lodash'
fs = require 'fs'
mkdirp = require 'mkdirp'
request = require 'request'
convert = require './convert'
evaluate = require("static-eval")
parse = require("esprima").parse

app = express()

templatesDir = 'compiled-templates'
preCompiledTemplatesDir = 'templates'

app.engine 'html', exphbs
  defaultLayout: 'main'
  layoutsDir: './'
  partialsDir: "./#{templatesDir}"
  extname: '.tpl.html'

app.set 'view engine', 'handlebars'
app.set 'views', __dirname

pageData =
  mode: name: 'search'
  openTab: name: 'insights'
  foo: 'BAR'
  selectedProducts: [
    name: 'product name'
    image: sizes: Small: url: 'https://www.google.com/images/srpr/logo11w.png'
  ]

fs.writeFileSync "./#{templatesDir}/index.tpl.html", convert file: "#{preCompiledTemplatesDir}/index.tpl.html"

# In Java can use ScriptEngineManager to eval js
# (http://stackoverflow.com/questions/2605032/using-eval-in-java)
evalExpression = (expression, context) ->
  value = evaluate parse(expression).body[0].expression, context
  value

# TODO: make this recursively support infinite depth
# TODO: move this to convert.coffee and allow recursive src and dest options
# TODO: make into grunt task
for type in ['templates', 'modules/account', 'modules/home', 'modules/insights', 'modules/ribbon', 'modules/search', 'modules/tools']
  path = "./#{preCompiledTemplatesDir}/#{type}/"
  for fileName in fs.readdirSync path
    continue unless _.contains fileName, '.tpl.html'
    partialName = "#{type}/#{fileName}"
    mkdirp.sync "./#{templatesDir}/#{type}"
    fs.writeFileSync "./#{templatesDir}/#{partialName}", convert file: "#{path}#{fileName}"

handlebars.registerHelper "ifExpression", (expression, options) ->
  fn = new Function expression
  value = null

  value = evalExpression expression, @

  if not options.hash.includeZero and not value
    options.inverse @
  else
    options.fn @

handlebars.registerHelper "expression", (expression, options) ->
  fn = new Function expression
  value = null

  # TODO: there are better ways to do @, borrow angular eval function
  value = evalExpression expression, @

  value

handlebars.registerHelper "hbsShow", (expression, options) ->
  value = evalExpression expression, @
  if value then 'data-hbs-show' else 'data-hbs-hide'

handlebars.registerHelper "hbsHide", (expression, options) ->
  value = evalExpression expression, @
  if value then 'data-hbs-hide' else 'data-hbs-show'

handlebars.registerHelper "json", (obj) ->
  new handlebars.SafeString JSON.stringify obj, null, 2

handlebars.registerHelper "interpolatedScript", (options) ->
  scriptStr = "<script"
  for key, value of options.hash
    scriptStr += " #{key}=\"#{value}\""
  scriptStr += '>'

  "#{scriptStr} #{options.fn @} </script>"

handlebars.registerHelper "forEach", (name, _in, context) ->
  options = _.last arguments
  fn = options.fn
  inverse = options.inverse
  i = 0
  ret = ""
  data = undefined
  # context = context.call(@) if typeof context is 'function'
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
  # ret = inverse(@) if i is 0
  ret


app.get '*', (req, res) ->
  page = req.query.p
  localData = _.cloneDeep pageData
  localData.openTab.name = page or 'search'
  _.extend localData, $data: _.cloneDeep localData

  pid = 'uid5204-23781302-79'
  urlBase = "http://api.shopstyle.com/api/v2"
  url = "#{urlBase}/products/?pid=#{pid}&limit=10"

  if page is 'search'
    request.get url, (err, response, body) ->
      localData.results = JSON.parse(body).products
      res.render "#{templatesDir}/index.tpl.html", localData
  else
    res.render "#{templatesDir}/index.tpl.html", localData


console.info 'Listening in port 3000...'
app.listen 3000
