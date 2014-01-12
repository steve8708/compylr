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

fs.writeFileSync "./#{templatesDir}/index.tpl.html", convert file: "#{preCompiledTemplatesDir}/index.tpl.html"

# In Java can use ScriptEngineManager to eval js
# (http://stackoverflow.com/questions/2605032/using-eval-in-java)
evalExpression = (expression, context) ->
  try
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

# TODO: this is bad, remove
cache =
  results: {}

resultsSuccess = (req, res, results, localData) ->
  localData.results = localData.$data.results = results
  product = req.params.product
  if product
    localData.activeProduct.product = _.find results, (item) -> item.id is product
  res.render "#{templatesDir}/index.tpl.html", localData

app.get '/:page?/:tab?/:product?', (req, res) ->
  page = req.params.page or 'search'
  tab = req.params.tab
  product = req.params.product
  query = req.params.q
  if page and not tab and tabDefaults[page]
    return res.redirect "/#{page}/#{tabDefaults[page]}"
  localData = _.cloneDeep pageData
  localData.openTab.name = page
  localData.activeTab.name = localData.accountTab = localData.mode.name = tab
  _.extend localData, $data: _.cloneDeep localData
  localData.activeTab.name = 'earnings'

  pid = 'uid5204-23781302-79'
  urlBase = "http://api.shopstyle.com/api/v2"
  url = "#{urlBase}/products/?pid=#{pid}&limit=30&sort=Popular&q=#{query or ''}"

  if page is 'search'
    cached = cache.results[query]
    if cached
      resultsSuccess req, res, cached, localData
    request.get url, (err, response, body) ->
      results = JSON.parse(body).products
      cache.results[query] = results
      resultsSuccess req, res, results, localData

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
  mode: name: 'search'
  openTab: name: 'insights'
  activeTab: {}
  selectedProducts: [
    id: 433111065
    name: "Lovers + Friends Feeling Fine Maxi Dress"
    type: "product"
    currency: "USD"
    price: 136
    priceLabel: "$136.00"
    salePrice: 82
    salePriceLabel: "$82.00"
    inStock: true
    retailer:
      id: "105"
      name: "Revolve Clothing"
      url: "http://www.shopstyle.com/browse/Revolve-Clothing-US?pid=uid5204-23781302-79"

    locale: "en_US"
    description: "PRODUCT DETAIL: This trendy line will have you impressing lovers and friends alike. <ul> <li>Rayon blend</li> <li>Shoulder seam to hem measures approx 60\" in length</li> <li>Unlined</li> <li>Criss cross back shoulder straps</li> <li>Back cut out</li> <li>Coordinates with gorjana Lena Shimmer Double Bar Ring in Gold.</li> </ul>"
    clickUrl: "http://api.shopstyle.com/action/apiVisitRetailer?id=433111065&pid=uid5204-23781302-79"
    pageUrl: "http://www.shopstyle.com/p/lovers-friends-feeling-fine-maxi-dress/433111065?pid=uid5204-23781302-79"
    image:
      id: "47f92e3bf8494ba349316f7ae9666d00"
      sizes:
        Small:
          sizeName: "Small"
          width: 32
          height: 40
          url: "http://resources.shopstyle.com/pim/47/f9/47f92e3bf8494ba349316f7ae9666d00_small.jpg"

        Medium:
          sizeName: "Medium"
          width: 112
          height: 140
          url: "http://resources.shopstyle.com/sim/47/f9/47f92e3bf8494ba349316f7ae9666d00_medium/lovers-friends-feeling-fine-maxi-dress.jpg"

        Large:
          sizeName: "Large"
          width: 164
          height: 205
          url: "http://resources.shopstyle.com/sim/47/f9/47f92e3bf8494ba349316f7ae9666d00/lovers-friends-feeling-fine-maxi-dress.jpg"

        XLarge:
          sizeName: "XLarge"
          width: 328
          height: 410
          url: "http://resources.shopstyle.com/xim/47/f9/47f92e3bf8494ba349316f7ae9666d00.jpg"

        Original:
          sizeName: "Original"
          url: "http://bim.shopstyle.com/pim/47/f9/47f92e3bf8494ba349316f7ae9666d00_best.jpg"

        IPhoneSmall:
          sizeName: "IPhoneSmall"
          width: 100
          height: 125
          url: "http://resources.shopstyle.com/mim/47/f9/47f92e3bf8494ba349316f7ae9666d00_small.jpg"

        IPhone:
          sizeName: "IPhone"
          width: 288
          height: 360
          url: "http://resources.shopstyle.com/mim/47/f9/47f92e3bf8494ba349316f7ae9666d00.jpg"

    colors: [
      name: "Black"
      image:
        id: "5ab07b90423f59164eee80a53c4d1f79"
        sizes:
          Small:
            sizeName: "Small"
            width: 32
            height: 40
            url: "http://resources.shopstyle.com/pim/5a/b0/5ab07b90423f59164eee80a53c4d1f79_small.jpg"

          Medium:
            sizeName: "Medium"
            width: 112
            height: 140
            url: "http://resources.shopstyle.com/sim/5a/b0/5ab07b90423f59164eee80a53c4d1f79_medium/lovers-friends-feeling-fine-maxi-dress.jpg"

          Large:
            sizeName: "Large"
            width: 164
            height: 205
            url: "http://resources.shopstyle.com/sim/5a/b0/5ab07b90423f59164eee80a53c4d1f79/lovers-friends-feeling-fine-maxi-dress.jpg"

          XLarge:
            sizeName: "XLarge"
            width: 328
            height: 410
            url: "http://resources.shopstyle.com/xim/5a/b0/5ab07b90423f59164eee80a53c4d1f79.jpg"

          Original:
            sizeName: "Original"
            url: "http://bim.shopstyle.com/pim/5a/b0/5ab07b90423f59164eee80a53c4d1f79_best.jpg"

          IPhoneSmall:
            sizeName: "IPhoneSmall"
            width: 100
            height: 125
            url: "http://resources.shopstyle.com/mim/5a/b0/5ab07b90423f59164eee80a53c4d1f79_small.jpg"

          IPhone:
            sizeName: "IPhone"
            width: 288
            height: 360
            url: "http://resources.shopstyle.com/mim/5a/b0/5ab07b90423f59164eee80a53c4d1f79.jpg"

      swatchUrl: "http://resources.shopstyle.com/pim/3a/c8/3ac89460e6b4d61dea2167df06b0b8b8.jpg"
      canonicalColors: [
        id: "16"
        name: "Black"
        url: "http://www.shopstyle.com/browse?fl=c16&pid=uid5204-23781302-79"
      ]
    ,
      name: "Scooter"
      image:
        id: "47f92e3bf8494ba349316f7ae9666d00"
        sizes:
          Small:
            sizeName: "Small"
            width: 32
            height: 40
            url: "http://resources.shopstyle.com/pim/47/f9/47f92e3bf8494ba349316f7ae9666d00_small.jpg"

          Medium:
            sizeName: "Medium"
            width: 112
            height: 140
            url: "http://resources.shopstyle.com/sim/47/f9/47f92e3bf8494ba349316f7ae9666d00_medium/lovers-friends-feeling-fine-maxi-dress.jpg"

          Large:
            sizeName: "Large"
            width: 164
            height: 205
            url: "http://resources.shopstyle.com/sim/47/f9/47f92e3bf8494ba349316f7ae9666d00/lovers-friends-feeling-fine-maxi-dress.jpg"

          XLarge:
            sizeName: "XLarge"
            width: 328
            height: 410
            url: "http://resources.shopstyle.com/xim/47/f9/47f92e3bf8494ba349316f7ae9666d00.jpg"

          Original:
            sizeName: "Original"
            url: "http://bim.shopstyle.com/pim/47/f9/47f92e3bf8494ba349316f7ae9666d00_best.jpg"

          IPhoneSmall:
            sizeName: "IPhoneSmall"
            width: 100
            height: 125
            url: "http://resources.shopstyle.com/mim/47/f9/47f92e3bf8494ba349316f7ae9666d00_small.jpg"

          IPhone:
            sizeName: "IPhone"
            width: 288
            height: 360
            url: "http://resources.shopstyle.com/mim/47/f9/47f92e3bf8494ba349316f7ae9666d00.jpg"

      swatchUrl: "http://resources.shopstyle.com/pim/8c/95/8c954fc8d60764fc81bff228766c0856.jpg"
      canonicalColors: [
        id: "7"
        name: "Red"
        url: "http://www.shopstyle.com/browse?fl=c7&pid=uid5204-23781302-79"
      ]
    ]
    sizes: [
      name: "XS"
      canonicalSize:
        id: "81"
        name: "XS (2)"
        url: "http://www.shopstyle.com/browse?fl=s81&pid=uid5204-23781302-79"
    ,
      name: "S"
      canonicalSize:
        id: "83"
        name: "S (4-6)"
        url: "http://www.shopstyle.com/browse?fl=s83&pid=uid5204-23781302-79"
    ,
      name: "M"
      canonicalSize:
        id: "85"
        name: "M (8-10)"
        url: "http://www.shopstyle.com/browse?fl=s85&pid=uid5204-23781302-79"
    ,
      name: "L"
      canonicalSize:
        id: "87"
        name: "L (12-14)"
        url: "http://www.shopstyle.com/browse?fl=s87&pid=uid5204-23781302-79"
    ]
    categories: [
      id: "evening-dresses"
      name: "Evening Dresses"
    ]
    seeMoreLabel: "Revolve Clothing Evening Dresses"
    seeMoreUrl: "http://www.shopstyle.com/browse/evening-dresses/Revolve-Clothing-US?pid=uid5204-23781302-79"
    extractDate: "2013-07-17"
    $$hashKey: "171"
    mouseover: false
  ,
    id: 407101862
    name: "Boulee Cruz Open Back Maxi Dress"
    type: "product"
    currency: "USD"
    price: 231
    priceLabel: "$231.00"
    salePrice: 139
    salePriceLabel: "$139.00"
    maxSalePrice: 162
    maxSalePriceLabel: "$162.00"
    inStock: true
    retailer:
      id: "105"
      name: "Revolve Clothing"
      url: "http://www.shopstyle.com/browse/Revolve-Clothing-US?pid=uid5204-23781302-79"

    locale: "en_US"
    description: "PRODUCT DETAIL: Launched in 2006 by Los Angeles-based designer Debbie Moradzadeh, Boulee offers a collection of eye candy - silky dresses, tanks, and tops. Designed for those confident enough to show some skin, this line has everything from fitted pencil skirts, draped trapeze dresses, and intricate cut-outs. <ul> <li>95% rayon 5% spandex</li> <li>Shoulder seam to hem measures approx 66\" in length</li> <li>Back cut-out</li> <li>Dry clean only</li> </ul>"
    brand:
      id: "22868"
      name: "Boulee"
      url: "http://www.shopstyle.com/browse/Boulee?pid=uid5204-23781302-79"

    clickUrl: "http://api.shopstyle.com/action/apiVisitRetailer?id=407101862&pid=uid5204-23781302-79"
    pageUrl: "http://www.shopstyle.com/p/boulee-cruz-open-back-maxi-dress/407101862?pid=uid5204-23781302-79"
    image:
      id: "ff2ed652411a8f50d7bc2868a2fc013a"
      sizes:
        Small:
          sizeName: "Small"
          width: 32
          height: 40
          url: "http://resources.shopstyle.com/pim/ff/2e/ff2ed652411a8f50d7bc2868a2fc013a_small.jpg"

        Medium:
          sizeName: "Medium"
          width: 112
          height: 140
          url: "http://resources.shopstyle.com/sim/ff/2e/ff2ed652411a8f50d7bc2868a2fc013a_medium/boulee-cruz-open-back-maxi-dress.jpg"

        Large:
          sizeName: "Large"
          width: 164
          height: 205
          url: "http://resources.shopstyle.com/sim/ff/2e/ff2ed652411a8f50d7bc2868a2fc013a/boulee-cruz-open-back-maxi-dress.jpg"

        XLarge:
          sizeName: "XLarge"
          width: 328
          height: 410
          url: "http://resources.shopstyle.com/xim/ff/2e/ff2ed652411a8f50d7bc2868a2fc013a.jpg"

        Original:
          sizeName: "Original"
          url: "http://bim.shopstyle.com/pim/ff/2e/ff2ed652411a8f50d7bc2868a2fc013a_best.jpg"

        IPhoneSmall:
          sizeName: "IPhoneSmall"
          width: 100
          height: 125
          url: "http://resources.shopstyle.com/mim/ff/2e/ff2ed652411a8f50d7bc2868a2fc013a_small.jpg"

        IPhone:
          sizeName: "IPhone"
          width: 288
          height: 360
          url: "http://resources.shopstyle.com/mim/ff/2e/ff2ed652411a8f50d7bc2868a2fc013a.jpg"

    colors: [
      name: "Black"
      image:
        id: "b84b0451f620db971e0e29d24305ee5d"
        sizes:
          Small:
            sizeName: "Small"
            width: 32
            height: 40
            url: "http://resources.shopstyle.com/pim/b8/4b/b84b0451f620db971e0e29d24305ee5d_small.jpg"

          Medium:
            sizeName: "Medium"
            width: 112
            height: 140
            url: "http://resources.shopstyle.com/sim/b8/4b/b84b0451f620db971e0e29d24305ee5d_medium/boulee-cruz-open-back-maxi-dress.jpg"

          Large:
            sizeName: "Large"
            width: 164
            height: 205
            url: "http://resources.shopstyle.com/sim/b8/4b/b84b0451f620db971e0e29d24305ee5d/boulee-cruz-open-back-maxi-dress.jpg"

          XLarge:
            sizeName: "XLarge"
            width: 328
            height: 410
            url: "http://resources.shopstyle.com/xim/b8/4b/b84b0451f620db971e0e29d24305ee5d.jpg"

          Original:
            sizeName: "Original"
            url: "http://bim.shopstyle.com/pim/b8/4b/b84b0451f620db971e0e29d24305ee5d_best.jpg"

          IPhoneSmall:
            sizeName: "IPhoneSmall"
            width: 100
            height: 125
            url: "http://resources.shopstyle.com/mim/b8/4b/b84b0451f620db971e0e29d24305ee5d_small.jpg"

          IPhone:
            sizeName: "IPhone"
            width: 288
            height: 360
            url: "http://resources.shopstyle.com/mim/b8/4b/b84b0451f620db971e0e29d24305ee5d.jpg"

      swatchUrl: "http://resources.shopstyle.com/pim/0c/a4/0ca4039f5b5bcdf085a11e115a9f0ecc.jpg"
      canonicalColors: [
        id: "16"
        name: "Black"
        url: "http://www.shopstyle.com/browse?fl=c16&pid=uid5204-23781302-79"
      ]
    ,
      name: "Wheaton"
      image:
        id: "7681932e09a848f6666ec747b228524f"
        sizes:
          Small:
            sizeName: "Small"
            width: 32
            height: 40
            url: "http://resources.shopstyle.com/pim/76/81/7681932e09a848f6666ec747b228524f_small.jpg"

          Medium:
            sizeName: "Medium"
            width: 112
            height: 140
            url: "http://resources.shopstyle.com/sim/76/81/7681932e09a848f6666ec747b228524f_medium/boulee-cruz-open-back-maxi-dress.jpg"

          Large:
            sizeName: "Large"
            width: 164
            height: 205
            url: "http://resources.shopstyle.com/sim/76/81/7681932e09a848f6666ec747b228524f/boulee-cruz-open-back-maxi-dress.jpg"

          XLarge:
            sizeName: "XLarge"
            width: 328
            height: 410
            url: "http://resources.shopstyle.com/xim/76/81/7681932e09a848f6666ec747b228524f.jpg"

          Original:
            sizeName: "Original"
            url: "http://bim.shopstyle.com/pim/76/81/7681932e09a848f6666ec747b228524f_best.jpg"

          IPhoneSmall:
            sizeName: "IPhoneSmall"
            width: 100
            height: 125
            url: "http://resources.shopstyle.com/mim/76/81/7681932e09a848f6666ec747b228524f_small.jpg"

          IPhone:
            sizeName: "IPhone"
            width: 288
            height: 360
            url: "http://resources.shopstyle.com/mim/76/81/7681932e09a848f6666ec747b228524f.jpg"

      swatchUrl: "http://resources.shopstyle.com/pim/5c/a5/5ca5475bc353b2f621c4f2e7b56fa55f.jpg"
      canonicalColors: [
        id: "20"
        name: "Beige"
        url: "http://www.shopstyle.com/browse?fl=c20&pid=uid5204-23781302-79"
      ]
    ]
    sizes: [
      name: "0"
      canonicalSize:
        id: "79"
        name: "XXS (0)"
        url: "http://www.shopstyle.com/browse?fl=s79&pid=uid5204-23781302-79"
    ,
      name: "2"
      canonicalSize:
        id: "81"
        name: "XS (2)"
        url: "http://www.shopstyle.com/browse?fl=s81&pid=uid5204-23781302-79"
    ,
      name: "4"
      canonicalSize:
        id: "83"
        name: "S (4-6)"
        url: "http://www.shopstyle.com/browse?fl=s83&pid=uid5204-23781302-79"
    ]
    categories: [
      id: "dresses"
      name: "Dresses"
    ]
    seeMoreLabel: "Boulee Dresses"
    seeMoreUrl: "http://www.shopstyle.com/browse/dresses/Boulee?pid=uid5204-23781302-79"
    extractDate: "2013-02-11"
    $$hashKey: "170"
    mouseover: false
  ]