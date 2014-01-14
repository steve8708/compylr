handlebars        = require 'handlebars'
express           = require 'express'
exphbs            = require 'express3-handlebars'
_                 = require 'lodash'
_.str             = require 'underscore.string'
fs                = require 'fs'
mkdirp            = require 'mkdirp'
request           = require 'request'
compile           = require './compile'
helpers           = require './helpers'
handlebarsHelpers = require './handlebars-helpers'
config            = require './config'
esprima           = require 'esprima'
appConfig         = require '../compilr-config'

console.info 'Running...'
console.info 'Process id = ' + process.pid

# Setup  - - - - - - - - - - - - - - - - - - - - - - -

# If not on heroku let us debug with a webkit agent
# unless process.env.PORT
#   try
#     agent = require 'webkit-devtools-agent'
#   catch error
#     console.warn 'Could\'t create node devtools agent', error

app = express()

templatesDir = 'compiled-templates'
preCompiledTemplatesDir = 'templates'

app.use express.cookieParser()
app.use express.session secret: 'foobar', store: new express.session.MemoryStore
app.use express.static 'static'

app.engine 'html', exphbs
  layoutsDir: './'
  partialsDir: "./#{templatesDir}"
  extname: '.tpl.html'

app.set 'view engine', 'handlebars'
app.set 'views', __dirname + '/..'


# Compile templates - - - - - - - - - - - - - - - - - - - - - - -

# TODO: file paths
# compile  src: preCompiledTemplatesDir, dest: templatesDir, recursive: true

console.info 'Compiling templates..'

mkdirp.sync "./#{templatesDir}"
fs.writeFileSync "./#{templatesDir}/index.tpl.html", compile file: "#{preCompiledTemplatesDir}/index.tpl.html"

# TODO: make this recursively support infinite depth
# TODO: move this to compile.coffee and allow recursive src and dest options
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
    fs.writeFileSync "./#{templatesDir}/#{partialName}", compile file: "#{path}#{fileName}"

console.info 'Done compiling templates.'


# Server  - - - - - - - - - - - - - - - - - - - - - - -

# TODO: this is bad, remove
cache =
  results: {}

currentReq = null

resultsSuccess = (req, res, results) ->
  sessionData = req.session.pageData or= _.cloneDeep appConfig.data
  sessionData.results = results
  # unless sessionData.selectedProducts.length
  #   sessionData.selectedProducts.unshift results.slice(0, 6)..
  product = req.params.product
  if product
    sessionData.activeProduct.product = _.find results, (item) ->
      "#{item.id}" is "#{product}"
  else
    sessionData.activeProduct.product = null

  unless res.headerSent
    console.log 'render start'
    res.render "#{templatesDir}/index.tpl.html", sessionData
    console.log 'render end'

# TODO: route logic based on route definitions in app-config.coffee
app.get '/:page?/:tab?/:product?', (req, res) ->
  currentReq = req
  page = req.params.page or 'search'
  tab = req.params.tab
  product = req.params.product
  query = req.query.fts or ''

  if page is 'favicon.ico'
    return res.send 200

  sessionData = req.session.pageData or= _.cloneDeep appConfig.data

  action = req.query.action
  if action
    helpers.safeEvalWithContext action, sessionData
    return res.redirect req._parsedUrl.pathname

  if page and not tab and appConfig.data.tabDefaults[page]
    return res.redirect "/#{page}/#{appConfig.data.tabDefaults[page]}"

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
    return

  console.log 'api request start'
  request.get url, (err, response, body) ->
    console.log 'api request end'
    results = JSON.parse(body).products
    cache.results[query] = results
    resultsSuccess req, res, results


# Run - - - - - - - - - - - - - - - - - - - - - - - - - -

port = process.env.PORT || 5000
console.info "Listening on part #{port}.."
app.listen port
