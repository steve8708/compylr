angular.module('app.search', ['ui.router']).config( ($stateProvider) ->
  $stateProvider.state 'search',
    url: '/search'
    views:
      main:
        controller: 'SearchCtrl'
        templateUrl: 'modules/search/search.tpl.html'

    data:
      pageTitle: 'Search'

).controller 'SearchCtrl', ($scope, $http, $document, utils,
  shared, $injector) ->
  $timeout = $injector.get '$timeout'
  $window = $injector.get '$window'
  $location = $injector.get '$location'
  persist = $injector.get 'persist'

  pid = 'uid5204-23781302-79'
  queryLimit = 30
  urlBase = "http://api.shopstyle.com/api/v2"
  searchQuery = "limit=#{queryLimit}"
  urlRoot = "#{urlBase}/products/"

  allBrands = []
  allStores =[]

  locationSearch = ->
    if $scope.config.appMode is 'app'
      $location.search arguments...

  # TODO: on first load, grab $location.search('query') and create active
  # filters off of it
  # FIXME: $location.search getter not working
  query = locationSearch 'query'
  if query and _.isString query
    activeFilters = []
    for item in query.split '&'
      split = item.split '='
      key = split[0]
      value = split[1]
      # TODO: tough part here is we don't have list of brands and retailers yet
      #   we can run the first search with the raw query string, but after that
      #   we need to load them into $scope.activeFilters
      #   for now we can create an object and use it
      #   once brands, retailers, categories, and colors have loaded (via a $q)
      # TODO: ignore page start point when looping here, that should alwayas
      #   reset to 0

    $scope.activeFilters = activeFilters

  # need to check to see if list has been pulled from localstorage
  $scope.lists = [
    { name: 'Must Haves', values: [], sort: 0},
    { name: 'Workwear', values: [], sort:  0},
    { name: 'Winter Accessories', values: [], sort:  0}
    { name: '+ New List', values: [], sort: -1 }
  ]

  getSearchURL = (queryString) ->
    unless queryString
      query = encodeURIComponent $scope.query.value
      q = searchQuery
      queryString = "#{q}&fts=#{query}"
      for item in $scope.activeFilters
        if item.type is 'category'
          queryString += "&cat=#{item.id}"
        else
          prefix = if item.type is 'store' then 'r' else item.type[0]
          queryString += "&fl=#{prefix + item.id}"
      queryString += "&sort=#{$scope.query.sort}"

      # FIXME: setting price min and max kills API response times
      minInt = parseInt($scope.price.min) + 20
      maxInt = parseInt($scope.price.max) + 20
      unless minInt is 20 and maxInt is 49
        queryString += "&fl=p#{ minInt }:#{ maxInt }"

      _.defer ->
        locationSearch 'q', queryString

    urlPrefix = "#{urlRoot}?pid=#{pid}&offset=#{$scope.offset * queryLimit}"
    url = "#{urlPrefix}&#{queryString}"

  debouncedSearch = _.debounce ( -> $scope.search() ), 50
  $scope.$watch 'activeFilters', ->
    debouncedSearch() if $scope.mode.name isnt 'feed'
    $scope.calcVisibleCategories()
  , true
  $scope.$watch 'price.min', debouncedSearch
  $scope.$watch 'price.max', debouncedSearch
  $scope.$watch 'query.sort', debouncedSearch

  focusSearchKeypressHandler = (event) ->
    # If slash key is pressed and there are no active inputs
    activeElTagName = document.activeElement.tagName
    noInputSelected = activeElTagName not in ['INPUT', 'TEXTAREA']
    if noInputSelected and event.which is 47
      event.preventDefault()
      document.getElementById('search-products').focus()

  $document.on 'keypress', focusSearchKeypressHandler
  $scope.$on '$destroy', -> $document.off 'keypress', focusSearchKeypressHandler

  focusSearch = ->
    document.querySelector('.search-input').focus()

  angular.element(window).on 'resize', _.debounce ->
    $scope.$apply -> $scope.setPosition()
  , 50

  $scope.$watch 'openTab.name', (newVal) ->
    if newVal is 'search'
      _.defer -> $scope.$apply -> $scope.setPosition()
    else
      locationSearch ''
    locationSearch 'p', newVal

  $scope.$watch 'input.brand', (term) ->
    term = term.replace(/\W/g, '').trim().toLowerCase()
    tmpBrands = []
    for brand in allBrands
      brandName = brand.name.replace(/\W/g,'').trim().toLowerCase()
      tmpBrands.push(brand) if brandName.indexOf(term) isnt -1

    $scope.brands = tmpBrands

  $scope.$watch 'input.store', (term) ->
    term = term.replace(/\W/g, '').trim().toLowerCase()
    tmpStores = []
    for store in allStores
      storeName = store.name.replace(/\W/g,'').trim().toLowerCase()
      tmpStores.push(store) if storeName.indexOf(term) isnt -1

    $scope.stores = tmpStores

  $http.get("#{urlBase}/brands?pid=#{pid}").success (data) ->
    allBrands = $scope.brands = data.brands
    brand.type = 'brand' for brand in $scope.brands

  categories = null
  categoriesById = {}
  rootCategory = name: 'root', children: [], id: "clothes-shoes-and-jewelry"
  $http.get("#{urlBase}/categories?pid=#{pid}").success (data) ->
    categories = data.categories
    categories.push rootCategory
    for category in categories
      category.type = 'category'
      categoriesById[category.id] = category

    for category in categories
      continue if category.name is 'root'
      parent = getCategory category.parentId
      parent.children or= []
      parent.children.push category

    $scope.categoryHierarchy = rootCategory.children
    $scope.calcVisibleCategories()

  getCategory = (id) -> categoriesById[id]

  $http.get("#{urlBase}/retailers?pid=#{pid}").success (data) ->
    allStores = $scope.stores = data.retailers
    store.type = 'store' for store in $scope.stores

  $http.get("#{urlBase}/colors?pid=#{pid}").success (data) ->
    $scope.colors = data.colors
    color.type = 'color' for color in $scope.colors

  lastValue = ''
  lastPage = 0

  $scope.$watch 'mode.name', (value) ->
    searchFollowing()

  # FIXME: why was this necessary?
  _.defer ->
    $scope.$watch 'activeFollow.name', searchFollowing, true

  lastActiveFilter = null
  searched = false
  searchFollowing = ->
    return unless $scope.mode.name is 'feed'
    $scope.query.sort = 'Recency'

    # Don't repeat the same search
    return if lastActiveFilter is $scope.activeFollow.name and not searched
    lastActiveFilter = $scope.activeFollow.name
    searched = false

    if $scope.activeFollow.name is 'following'
      search $scope.following
    else if not $scope.activeFollow.name.filters
      search $scope.activeFollow.name


  search = ( (filters, start = @offset * queryLimit, limit = queryLimit) ->
    if filters
      @resetFilters if Array.isArray filters then filters else [filters]
    else
      searched = true

    # Don't search if no value changes
    lastValue = @query.value
    paginate = lastPage != @offset

    @paginating++ if paginate

    url = getSearchURL()
    @searchState.loading++
    lastPage = @offset

    # console.log 'search'
    # @results = [] unless paginate
    $http.get(url).success (data) =>
      @searchState.firstLoad = false
      @searchState.loading--
      if paginate
        @results.push data.products...
        @paginating--
      else
        @results = data.products
        $scope.resultsContainer.scrollTop = 0

      @setPosition()
      @mapFavorites()
      @mapLists()

  ).bind $scope

  queryDefaults =
    value: ''
    sort: 'Popular'
    deal: 0

  persist.localStore $scope, 'search', [
    'following'
    'widgets'
    'favorites'
    'lists'
  ], true

  utils.deepDefaults $scope,
    widgets:
      # open: null
      products: []

    following:  [
      id: "462"
      name: "Polo Ralph Lauren"
      synonyms: ["Polo Golf"]
      type: "brand"
    ,
      id: "284"
      name: "J.Crew"
      synonyms: ["J. Crew", "JCrew"]
      type: "brand"
    ,
      id: "4486"
      name: "Asos"
      synonyms: ["Asos Collection"]
      type: "brand"
    ,
      id: "226"
      name: "Free People"
      synonyms: ["Free People Knits"]
      type: "brand"
    ,
      id: "2290"
      name: "Urban Outfitters"
      synonyms: []
      type: "brand"
    ,
      id: "14524"
      name: "Alternative Apparel"
      synonyms: ["オルタナティブ", "Alternative"]
      type: "brand"
    ,
      id: "12130"
      name: "American Apparel"
      synonyms: []
      type: "brand"
    ,
      id: "25"
      name: "American Rag"
      synonyms: ["American Rag Cie"]
      type: "brand"
    ,
      id: "298"
      name: "Joie"
      synonyms: []
      type: "brand"
    ,
      id: "21236"
      name: "Madewell"
      synonyms: []
      type: "brand"
    ,
      id: "3487"
      name: "Sephora"
      synonyms: ["Sephora Girls", "Sephora Piiink"]
      type: "brand"
    ,
      id: "30114"
      name: "Warby Parker"
      synonyms: []
      type: "brand"
    ]

    collections:  [
      id: "21236"
      name: "Favorites"
      synonyms: []
      type: "brand"
    ,
      id: "462"
      name: "Polos"
      synonyms: ["Polo Golf"]
      type: "brand"
    ,
      id: "30114"
      name: "Glasses"
      synonyms: []
      type: "brand"
    ]

    # selectedProducts: []


  # FIXME: convert to deep defaults
  _.merge $scope,
    query: _.clone queryDefaults

    mode: name: 'search'

    sortOptions:
      'Popular': 'Popular'
      'Recency': 'Recency'
      'PriceLoHi': 'Highest Price'
      'PriceHiLo': 'Lowest Price'
      'Commission': 'Highest Commission'

    offset: lastPage

    searchState:
      loading: 0
      firstLoad: true

    paginating: 0

    activeProduct: product: null

    results: []
    activeFilters: []
    favorites: []

    activeFilterPanel: 'category'

    filters:
      brand: active: false
      store: active: false
      category: active: true
      size: active: false
      price: active: false
      color: active: false
      deal: active: false

    input:
      brand: ''
      store: ''

    price:
      min: 0
      max: 29

    activeFollow:
      name: 'following'

    priceMap: [
      0, 10, 25, 50, 75, 100, 125, 150, 200, 250, 300, 350, 400, 500, 600
      700, 800, 900, 1000, 1250, 1500, 1750, 2000, 2500, 2250, 3000,
      3500, 4000, 4500, '5000+'
    ]

    activateSearch: (search) ->
      @activeFollow.name = search
      @resetFilters _.cloneDeep search.filters
      _.extend @query, _.cloneDeep search.query

    saveSearch: ->
      name = prompt 'What do you want to call this search?'
      return unless name
      @savedSearches.push
        name: name
        filters: _.cloneDeep @activeFilters
        query: _.cloneDeep @query


    togglePanel: (name) ->
      if @activeFilterPanel is name
        @activeFilterPanel = null
      else
        @activeFilterPanel = name

    toggleFavorite: (product) ->
      product.favorite = !product.favorite
      @favorites.push product.id if product.favorite

    toggleList: (product) ->
      if product.list.sort is -1
        name = $window.prompt 'Enter a list name'
        if not name
          @toggleList(product)
          return
        product.list = {name: name, values: [], sort: 0}
        @lists.push product.list

      product.list.values.push product.id

    clickCategory: (category) ->
      @toggleFilter category

    calcVisibleCategories: ->
      return unless categories
      visibleCategoryLength = 0
      for category in categories
        category.visible = @categoryVisible category
        visibleCategoryLength++ if category.visible
      $scope.visibleCategoryLength = visibleCategoryLength

    categoryVisible: (item) ->
      return true if item.active

      parent = getCategory item.parentId
      return true if not parent or parent.name is 'root'

      recurseChildren = (itm) ->
        return true if itm.active
        return false unless itm.children
        for child in itm.children
          res = recurseChildren child
          return res if res

      response = recurseChildren item
      return true if response
      return true if parent.active

      siblings = parent.children
      for sibling in siblings
        return true if sibling.active

      return false

    closeModal: ->
      @hideModal = true
      # @blur.header = false
      $timeout =>
        @hideModal = false
        @activeProduct.product = null
      , 300

    showModal: (product) ->
      @activeProduct.product = product
      # @blur.header = true

    clickProductLinkInput: (event) ->
      event.target.select()

    keypressProductLinkInput: (event) ->
      if not event.metaKey and not event.ctrlKey
        event.preventDefault()

    removeFilter: (filter) ->
      return unless filter
      utils.remove @activeFilters, filter
      filter.active = false

    clearFilters: (andQuery) ->
      @removeFilter filter for filter in @activeFilters
      # FIXME: this shouldn't be needed, why is the above
      # not always clearingn every filter?
      utils.clear @activeFilters
      if andQuery
        @query = _.clone queryDefaults

    resetFilters: (filters) ->
      @clearFilters()
      @activeFilters.push filters...

    addFilter: (filter) ->
      if filter.type is 'category'
        category = _.find @activeFilters, (item) -> item.type is 'category'
        if category
          @removeFilter category
      else
        filterMatch = _.find @activeFilters, (item) ->
          item.name is filter.name and item.type is filter.type

      unless filterMatch
        @activeFilters.push filter
        filter.active = true

    toggleFilter: (filter) ->
      if filter.active
        @removeFilter filter
      else
        @addFilter filter

    resetResults: ->
      @offset = 0
      # @results = []

    searchKeypress: (event) ->
      return if lastValue.trim() is @query.value.trim()
      @resetResults()
      @search()

    mapFavorites: () ->
      _.each @results, (result) =>
        result.favorite = true if result.id in @favorites

    mapLists: () ->
      for result in @results
        for list in @lists
          result.list = list if result.id in list.values

    setPosition: ->
      @tops = []
      @lefts = []

      columnWidth = 180
      gutterWidth = 10

      topOffset = 10
      horizOffset = 20

      containerRect = @resultsContainer.getBoundingClientRect()
      containerWidth = containerRect.width
      containerHeight = containerRect.height

      numerator = containerWidth - horizOffset
      columnNumber = Math.floor numerator / ( columnWidth + gutterWidth )
      columns = []
      columns.push gutterWidth for item in _.range columnNumber

      for result, index in @results
        column = index % columnNumber

        prevTop = @tops[index - 1] or 0
        prevLeft = @lefts[index - 1] or 0
        @tops.push columns[column] + topOffset + 'px'
        @lefts.push (columnWidth + gutterWidth) * column + horizOffset + 'px'

        columns[column] += result.image.sizes.Large.height + 60

      # Load another page if current page doesn't fill screen
      maxHeight = Math.max columns...
      if maxHeight <= containerHeight and @results.length is queryLimit
        # if app.config.appMode isnt 'ribbon'
        @paginate()
      @containerHeight = maxHeight

    rawSearch: search
    search: _.debounce search, 150
    throttledSearch: _.throttle search, 1500

    paginate: () ->
      $scope.offset++
      $scope.throttledSearch()

    productShare: (provider, product) ->
      pageUri = product.pageUrl or ''
      postText = product.pageUrl or ''
      imgUri = product.image.sizes.Original.url or ''
      mailAddress = ''
      $scope.share provider, pageUri, postText,
        imgUri, mailAddress


