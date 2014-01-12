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

app.use express.cookieParser()
app.use express.session secret: 'foobar', store: new express.session.MemoryStore
app.use express.static 'static'

app.engine 'html', exphbs
  defaultLayout: 'main'
  layoutsDir: './'
  partialsDir: "./#{templatesDir}"
  extname: '.tpl.html'

app.set 'view engine', 'handlebars'
app.set 'views', __dirname

expressionCache = {}

# In Java can use ScriptEngineManager to eval js
# (http://stackoverflow.com/questions/2605032/using-eval-in-java)
evalExpression = (expression, context) ->
  expressionBody = expressionCache[expression] or parse(expression).body[0].expression
  expressionCache[expression] = expressionBody unless expressionCache[expression]
  try
    value = evaluate expressionBody, context
  catch error
    console.warn 'Expression error', error
  value

console.info 'Compiling templates...'

mkdirp.sync "./#{templatesDir}"
fs.writeFileSync "./#{templatesDir}/index.tpl.html", convert file: "#{preCompiledTemplatesDir}/index.tpl.html"

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
console.info 'Compiling done.'

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

resultsSuccess = (req, res, results) ->
  sessionData = req.session.pageData or= _.cloneDeep pageData
  sessionData.results = results
  # unless sessionData.selectedProducts.length
  #   sessionData.selectedProducts.unshift results.slice(0, 6)...
  product = req.params.product
  if product
    sessionData.activeProduct.product = _.find results, (item) ->
      "#{item.id}" is "#{product}"
  else
    sessionData.activeProduct.product = null

  res.render "#{templatesDir}/index.tpl.html", sessionData

currentReq = null

toggleSelectedProduct = (product) ->
  sessionData = currentReq.session.pageData or= _.cloneDeep pageData
  id = product and product.id or product
  foundProduct = _.find sessionData.selectedProducts, (item) ->
    item and "#{item.id}" is "#{id}"
  if product
    sessionData.selectedProducts.unshift product
  else
    sessionData.selectedProducts.splice sessionData.selectedProducts.indexOf(product), 1



app.get '/:page?/:tab?/:product?', (req, res) ->
  currentReq = req
  page = req.params.page or 'search'
  tab = req.params.tab
  product = req.params.product
  query = req.query.fts or ''
  sessionData = req.session.pageData or= _.cloneDeep pageData

  if page and not tab and tabDefaults[page]
    return res.redirect "/#{page}/#{tabDefaults[page]}"

  action = req.query.action
  if action
    # evalExpression action, pageData
    # FIXME: get eval out of here
    `with (sessionData) {
      eval(action);
    }`

    res.redirect req._parsedUrl.pathname

  sessionData.noJS = req.query.nojs
  sessionData.openTab.name = page
  sessionData.urlPath = req._parsedUrl.pathname.replace /\/$/, ''
  sessionData.urlPathList = sessionData.urlPath.split '/'
  sessionData.activeTab.name = sessionData.accountTab = sessionData.mode.name = tab
  # _.extend sessionData, $data: sessionData
  # sessionData.activeTab.name = 'earnings'
  sessionData.query.value = query

  pid = 'uid5204-23781302-79'
  urlBase = "http://api.shopstyle.com/api/v2"
  url = "#{urlBase}/products/?pid=#{pid}&limit=30&sort=Popular&fts=#{query or ''}"

  cached = cache.results[query]
  if cached
    resultsSuccess req, res, cached
  request.get url, (err, response, body) ->
    results = JSON.parse(body).products
    cache.results[query] = results
    resultsSuccess req, res, results
    null

port = process.env.PORT || 5000
console.info "Listening on port #{port}..."
app.listen port

tabDefaults =
  insights: 'earnings'
  account: 'settings'
  search: 'search'

# Sync these with session: expression sessino
pageData =
  js: off
  show:
    showPrice: on
    showBrand: on
    showName: on
  activeProduct: {}
  query: value: ''
  mode: name: 'search'
  openTab: name: 'insights'
  activeTab: {}
  selectedProducts: []
