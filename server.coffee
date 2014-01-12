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

fs.writeFileSync "./#{templatesDir}/index.tpl.html", convert file: "#{preCompiledTemplatesDir}/index.tpl.html"

expressionCache = {}

# In Java can use ScriptEngineManager to eval js
# (http://stackoverflow.com/questions/2605032/using-eval-in-java)
evalExpression = (expression, context) ->
  expressionBody = expressionCache[expression] or parse(expression).body[0].expression
  expressionCache[expression] = expressionBody unless expressionCache[expression]
  try
    value = evaluate expressionBody, context
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

# TODO: looping through options
#   (key, value) in bar
handlebars.registerHelper "forEach", (name, _in, context) ->
  options = _.last arguments
  fn = options.fn
  ctx = @
  inverse = options.inverse
  i = 0
  ret = ""
  data = undefined
  # context = context.call(@) if typeof context is 'function'
  if context and _.isObject context
    if _.isArray context
      j = context.length

      while i < j
        iterContext = _.cloneDeep ctx
        iterContext[name] = context[i]
        if data
          data.index = i
          data.first = (i is 0)
          data.last = i is (iterContext.length - 1)
        ret = ret + fn(iterContext,
          data: data
        )
        i++
    else
      for key of context
        if context.hasOwnProperty key
          iterCtx = _.cloneDeep ctx
          iterCtx[name] = context[key]
          if data
            data.key = key
            data.index = i
            data.first = (i is 0)
          ret = ret + fn(iterCtx,
            data: data
          )
          i++
  # ret = inverse(@) if i is 0
  ret

# TODO: this is bad, remove
cache =
  results: {}

resultsSuccess = (req, res, results, localData) ->
  localData.results = localData.$data.results = results
  localData.selectedProducts = results.slice 0, 6
  product = req.params.product
  if product
    focus = localData.activeProduct.product = _.find results, (item) ->
      "#{item.id}" is "#{product}"

  res.render "#{templatesDir}/index.tpl.html", localData

app.get '/:page?/:tab?/:product?', (req, res) ->
  page = req.params.page or 'search'
  tab = req.params.tab
  product = req.params.product
  query = req.query.fts
  if page and not tab and tabDefaults[page]
    return res.redirect "/#{page}/#{tabDefaults[page]}"
  localData = _.cloneDeep pageData
  localData.openTab.name = page
  localData.activeTab.name = localData.accountTab = localData.mode.name = tab
  _.extend localData, $data: _.cloneDeep localData
  # localData.activeTab.name = 'earnings'
  localData.query.value = query

  pid = 'uid5204-23781302-79'
  urlBase = "http://api.shopstyle.com/api/v2"
  url = "#{urlBase}/products/?pid=#{pid}&limit=30&sort=Popular&fts=#{query or ''}"

  if page is 'search'
    cached = cache.results[query]
    if cached
      resultsSuccess req, res, cached, localData
    request.get url, (err, response, body) ->
      console.log 'NOT CACHED'
      results = JSON.parse(body).products
      cache.results[query] = results
      resultsSuccess req, res, results, localData
      null


  else
    res.render "#{templatesDir}/index.tpl.html", localData


console.info 'Listening in port 3000...'
app.listen 3000


tabDefaults =
  insights: 'earnings'
  account: 'settings'
  search: 'search'


pageData =
  activeProduct: {}
  query: value: ''
  mode: name: 'search'
  openTab: name: 'insights'
  activeTab: {}
  selectedProducts: []