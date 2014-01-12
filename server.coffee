handlebars = require 'handlebars'
express = require 'express'
exphbs  = require 'express3-handlebars'
_  = require 'lodash'
_.str = require 'underscore.string'
fs = require 'fs'
mkdirp = require 'mkdirp'
request = require 'request'
convert = require './convert'
evaluate = require("static-eval")
parse = require("esprima").parse

# Setup  - - - - - - - - - - - - - - - - - - - - - - -

app = express()

config =
  verbose: false

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


# Helpers  - - - - - - - - - - - - - - - - - - - - - - -

safeEvalWithContext = (expression, context, clone, returnNewContext) ->
  context = _.cloneDeep context if clone
  fn = new Function 'context', "with (context) { return #{expression} }"
  try
    output = fn context
  if returnNewContext
    context: context
    output: output
  else
    output

warnVerbose = (args...) ->
  console.warn args... if config.verbose

# In Java can use ScriptEngineManager to eval js
# (http://stackoverflow.com/questions/2605032/using-eval-in-java)
safeEvalStaticExpression = (expression, context) ->
  try
    expressionBody = expressionCache[expression] or parse(expression).body[0].expression
    expressionCache[expression] = expressionBody unless expressionCache[expression]
  catch error
    console.warn 'Expression error', expression, error

  try
    value = evaluate expressionBody, context
  catch error
    warnVerbose 'Eval expression error'
  value


# Compile templates - - - - - - - - - - - - - - - - - - - - - - -

console.info 'Compiling templates...'

mkdirp.sync "./#{templatesDir}"
fs.writeFileSync "./#{templatesDir}/index.tpl.html", convert file: "#{preCompiledTemplatesDir}/index.tpl.html"

# TODO: make this recursively support infinite depth
# TODO: move this to convert.coffee and allow recursive src and dest options
# TODO: make into grunt task
directories = [
  'templates', 'modules/account', 'modules/home', 'modules/insights'
  'modules/ribbon', 'modules/search', 'modules/tools'
]

for type in directories
  path = "./#{preCompiledTemplatesDir}/#{type}/"
  for fileName in fs.readdirSync path
    continue unless _.contains fileName, '.tpl.html'
    partialName = "#{type}/#{fileName}"
    mkdirp.sync "./#{templatesDir}/#{type}"
    fs.writeFileSync "./#{templatesDir}/#{partialName}", convert file: "#{path}#{fileName}"

console.info 'Done compiling templates.'


# Compile Handlebars Helpers - - - - - - - - - - - - - - - - - - -

handlebars.registerHelper "eachExpression", (name, _in, expression, options) ->
  value = safeEvalStaticExpression expression, @
  instance.helpers.forEach name, _in, value, options

handlebars.registerHelper "styleExpression", (expression, options) ->
  value = safeEvalWithContext expression, @, true
  console.log 'styleExpression', expression, value if value
  out = ';'
  for key, val of value
    out += "#{_.str.dasherize key}: #{val};"
  " #{out} "

handlebars.registerHelper "classExpression", (expression, options) ->
  value = safeEvalWithContext expression, @, true
  out = []
  for key, val of value
    out.push key if val
  ' ' + out.join(' ') + ' '

handlebars.registerHelper "ifExpression", (expression, options) ->
  value = safeEvalStaticExpression expression, @

  if not options.hash.includeZero and not value
    options.inverse @
  else
    options.fn @

handlebars.registerHelper "expression", (expression, options) ->
  # TODO: there are better ways to do @, borrow angular eval function
  value = safeEvalStaticExpression expression, @
  value

handlebars.registerHelper "hbsShow", (expression, options) ->
  value = safeEvalStaticExpression expression, @
  if value then 'data-hbs-show' else 'data-hbs-hide'

handlebars.registerHelper "hbsHide", (expression, options) ->
  value = safeEvalStaticExpression expression, @
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
          data[name + 'Index'] = i
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


# Server  - - - - - - - - - - - - - - - - - - - - - - -

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

  unless res.headerSent
    res.render "#{templatesDir}/index.tpl.html", sessionData

currentReq = null

app.get '/:page?/:tab?/:product?', (req, res) ->
  currentReq = req
  page = req.params.page or 'search'
  tab = req.params.tab
  product = req.params.product
  query = req.query.fts or ''
  sessionData = req.session.pageData or= _.cloneDeep pageData

  action = req.query.action
  if action
    safeEvalWithContext action, sessionData
    console.log 'action', action
    return res.redirect req._parsedUrl.pathname

  if page and not tab and tabDefaults[page]
    return res.redirect "/#{page}/#{tabDefaults[page]}"

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


# Run - - - - - - - - - - - - - - - - - - - - - - - - - -

port = process.env.PORT || 5000
console.info "Listening on part #{port}..."
app.listen port


# State Data - - - - - - - - - - - - - - - - - - - - - - -

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

  toggleSelectedProduct: (product) ->
    sessionData = currentReq.session.pageData or= _.cloneDeep pageData
    id = product and product.id or product
    foundProduct = _.find sessionData.selectedProducts, (item) ->
      item and "#{item.id}" is "#{id}"
    if product
      sessionData.selectedProducts.unshift product
    else
      sessionData.selectedProducts.splice sessionData.selectedProducts.indexOf(product), 1