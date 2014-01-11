blankImg = document.createElement 'img'
blankImg.src = 'http://upload.wikimedia.org/wikipedia' +
  '/commons/c/c4/600_px_Transparent_flag.png'

angular.module('app.tools', ['ui.router']).config( ($stateProvider) ->
  $stateProvider.state 'tools',
    url: '/tools'
    views:
      main:
        # controller: 'ToolsCtrl'
        # templateUrl: 'modules/tools/tools.tpl.html'
        templateUrl: 'modules/account/account.tpl.html'

    data:
      pageTitle: 'Tools'

).controller 'ToolsCtrl', ($scope, $http, shared, $sce, $injector) ->
  pid = 'uid5204-23781302-79'
  urlBase = "http://api.shopstyle.com/api/v2"
  urlRoot = "#{urlBase}/products/?pid=#{pid}&limit=50"

  sorts = ['Popular', 'PriceHiLo', 'Recent', 'PriceLoHi' ]

  $scope.boutique = currentPage: 0

  # $scope.$watch 'selectedProducts', (newVal) ->
  #   # $scope.shopMyPost.results = newVal
  #   # $scope.lookbook.results = newVal
  #   $scope.boutique.results = newVal
  # , true

  nameChange = true

  $scope.$watch 'preset.name', (newVal) ->
    options = $scope.boutique.options
    nameChange = true
    $scope.boutique.currentPage = 0

    # Preset values
    switch newVal
      when 'lookbook'
        options.size.model = 500
        options.rows.model = 1
        options.columns.model = 1
      when 'row'
        options.size.model = 150
        options.rows.model = 1
        options.columns.model = 4
      when 'grid'
        options.size.model = 150
        options.rows.model = 4
        options.columns.model = 4

  firstLoad = true
  $scope.$watch '[boutique.options, selectedProducts]', ->

    if nameChange
      nameChange = false
    else
      $scope.preset.name = null

    padding = 15
    options = $scope.boutique.options

    $scope.boutique.containerSize =
      width: (parseInt(options.size.model) + padding) * options.columns.model
      height: (parseInt(options.size.model) + padding) * options.rows.model

    $scope.boutique.pages = []
    resultsPerPage = options.columns.model * options.rows.model

    localPage = []
    pageIndex = 0

    _.each $scope.selectedProducts, (result, index) ->
      localIndex = index - (pageIndex * resultsPerPage)
      # once we reach the end of the page, push it to pages list
      # and clear out the local page array of results
      if localIndex >= resultsPerPage
        $scope.boutique.pages.push localPage
        localPage = []
        pageIndex++

      localPage.push(result)

    $scope.boutique.pages.push localPage

  , true

  unless $scope.selectedProducts
    for item in ['boutique']
      do (item) ->
        $scope.$watch "#{item}.options.size.model", (value) ->
          switch value
            when 'My Favorites'   then sort = sorts[0]
            when 'Bags'           then sort = sorts[1]
            when 'Winter Picks'   then sort = sorts[2]
            when 'Shoes'          then sort = sorts[3]

          $scope.state.loading++
          $http.get("#{urlRoot}&sort=#{sort}").success (data) ->
            $scope.state.loading--
            $scope[item].results = data.products


  collections = [
    'Selected', 'Following', 'My Favorites', 'Bags', 'Shoes', 'Winter Picks'
  ]

  for type in ['boutique']
    do (type) ->
      $scope.$watch "#{type}.options.rows.model", (newVal) ->
        $scope[type].options.showInfo.model = newVal is 'Small'

  angular.element(window).on 'resize', _.debounce ->
    $scope.tagContainerStyle = $scope.getTagContainerStyle()
  , 16

  savedSearches = $scope.savedSearches.map (item) -> 'Search: ' + item.name
  # FIXME: this won't update itself automatically
  collections.push savedSearches...
  # collections.push 'New Collection +'

  # shared.syncProperties $scope, [
  #   'shopMyPost.options[0].model'
  #   'lookbook.options.size.model'
  #   # 'boutique.options.size.model'
  # ]

  $scope.pageImages = ( img.src for img in document.querySelectorAll('img') \
    when img.height > 100 and img.width > 100 )

  updateTagPosition = (event, tag) ->
    event = event.originalEvent or event
    return unless event.clientX and event.clientY
    rect = $scope.droppedImage.getBoundingClientRect()

    tag.x = ( event.clientX - rect.left ) / rect.width
    tag.y = ( event.clientY - rect.top ) / rect.height

  _.merge $scope,
    activeTab: name: 'Boutique'

    setDroppedImage: (url) ->
      angular.element(@droppedImage).on 'load', ->
        $scope.$apply ->
          $scope.tagContainerStyle = $scope.getTagContainerStyle()
      @droppedImage.src = url

    # dragTag: _.throttle (event, tag) ->
    #   # $scope.$apply => updateTagPosition event, tag
    # , 20

    dragendTag: (event, tag) ->
      updateTagPosition event, tag
      tag.dragging = false
      tag.show = true

    dragoverContainer: (event) ->
      event = event.originalEvent or event
      # Allow drop if what is being dragged is a file
      event.preventDefault() if event.dataTransfer.files[0]

    dragstartTag: (event, tag) ->
      event = event.originalEvent or event
      tag.dragging = true
      # event.dataTransfer.setDragImage blankImg, 0, 0
      event.dataTransfer.setData 'text', ''
      # tag.dragging = true
      tag.show = false

    dropImage: (event) ->
      @dragover = false
      dataTransfer = (event.originalEvent or event).dataTransfer
      file = dataTransfer.files[0]
      if file
        url = URL.createObjectURL file
        @setDroppedImage url
      else
        dragging = _.find @tags, (tag) -> tag.dragging
        if dragging
          @dragendTag event, dragging

    clickEmbedCode: (event) ->
      event.target.select()

    keypressEmbedCode: (event) ->
      if not event.metaKey and not event.ctrlKey
        event.preventDefault()

    navigateGallery: (direction) ->
      cp = @boutique.currentPage
      if direction is 'left' and cp != 0
        @boutique.currentPage--
      if direction is 'right' and cp != @boutique.pages.length - 1
        @boutique.currentPage++

    toolShare: (provider) ->
      pageUri = 'http://shopstyle.com/example-page'
      postText = 'check out this widget'
      imgUri = ''
      mailAddress = ''
      shared.triggerShareWindow provider, pageUri, postText,
        imgUri, mailAddress

    code: '<iframe src=""></iframe>'

    tags: []

    tagContainerStyle: {}

    getTagContainerStyle: ->
      rect = @droppedImage and @droppedImage.getBoundingClientRect()
      return unless rect
      top: @droppedImage.offsetTop + 'px'
      left: @droppedImage.offsetLeft + 'px'
      width: rect.width + 'px'
      height: rect.height + 'px'

    showBr: (index) ->
      widget = @shopMyPost
      bottom = Math.ceil widget.results.length / widg-et.options[5].model
      top = index + 1
      # console.log top, bottom
      !( top % bottom )

    addTag: (event) ->
      return unless event.target is event.currentTarget
      return unless @droppedImage.src
      rect = event.currentTarget.getBoundingClientRect()
      @tags.push
        x: event.offsetX / rect.height
        y: event.offsetY / rect.width

      # TODO: choose product

    preset:
      name: 'lookbook'

    # TODO: maybe dot size, opacity, color, tag size, etc
    taggedPhoto:
      options:
        brand:
          name: 'Show Brand Name'
          type: 'checkbox'
          model: true
        price:
          name: 'Show Price'
          type: 'checkbox'
          model: true
        dotShadow:
          name: 'Dot Shadow'
          type: 'checkbox'
          model: true
        tagShadow:
          name: 'Tag Shadow'
          type: 'checkbox'
          model: true
        dotSize:
          name: 'Dot Size'
          type: 'range'
          model: 30
          min: 10
          max: 40
        dotOpacity:
          name: 'Dot Opacity'
          type: 'range'
          min: 0
          max: 1
          step: 0.01
          model: 1
        tagOpacity:
          name: 'Tag Opacity'
          type: 'range'
          min: 0
          max: 1
          step: 0.01
          model: 1
        dotColor:
          name: 'Dot Color'
          type: 'color'
          model: '#ffffff'
        tagColor:
          name: 'Tag Color'
          type: 'color'
          model: '#ffffff'

    boutique:
      options:
        size:
          name: 'Image Size'
          type: 'range'
          model: 500
          min: 100
          max: 800
          step: 10
        rows:
          name: 'Rows'
          type: 'range'
          model: 1
          min: 1
          max: 8
          step: 1
        columns:
          name: 'Columns'
          type: 'range'
          model: 1
          min: 1
          max: 8
          step: 1
        showBrand:
          name: 'Show Brand Name'
          type: 'checkbox'
          model: true
        showPrice:
          name: 'Show Price'
          type: 'checkbox'
          model: true
        showInfo:
          name: 'Show Info on Hover'
          type: 'checkbox'
          model: false

  $scope.taggedPhoto.sortedOptions =
    _.sortBy $scope.taggedPhoto.options, (key, val) ->
      [
        'brand', 'price', 'dotShadow', 'tagShadow', 'dotSize', 'dotOpacity'
        'tagOpacity', 'dotColor', 'tagColor'
      ].indexOf key

  $scope.boutique.sortedOptions =
    _.sortBy $scope.boutique.options, (key, val) ->
      [
        'size', 'rows', 'columns', 'showBrand', 'showPrice', 'showInfo'
      ].indexOf key
