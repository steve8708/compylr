angular.module('app.ribbon', []).config( ->


).controller 'RibbonCtrl', ($scope, shared, $injector, $http) ->
  _.extend $scope,
    openTab: {}

  $mainPage = $ document.getElementById 'mainPage'
  $body = $ document.body

  $scope.$watch 'openTab.name', (newVal) ->
    if newVal
      $mainPage.addClass 'blur-light'
      $body.addClass 'no-scroll'
    else
      $mainPage.removeClass 'blur-light'
      $body.removeClass 'no-scroll'

  if _.contains location.hostname, 'shopstyle'
    # Bind to DOM
    $overlay = $ """
      <div class="shopsense-product-overlay">
        <div class="hover-actions">
          <a data-action="get-link" class="hover-action">Get Link</a>
          <a data-action="add-to-widget" class="hover-action">
            Add to Quicklist
          </a>
        </div>
      </div>
    """

    # TODO: click events
    $overlay.on 'click', '[data-action=add-to-widget]', (event) ->
      id = $(event.target).closest('[data-pid]').attr 'data-pid'
      # TODO: use another API token (app-wide)
      pid = 'uid5204-23781302-79'
      productUrl = "http://api.shopstyle.com/api/v2/products/#{id}?pid=#{pid}"
      $http.get(productUrl).success (product) ->
        $scope.toggleSelectedProduct product

    $overlay.on 'click', '[data-action=get-link]', (event) ->
      $scope.clickGetLink()
      # $(event.currentTarget)
      #   .closest('.rawCell')
      #   .find('[data-action=product-details]')
      #   .click()
      # _.defer ->
      #   $('.share-medium-grey').click()

    $overlay.on 'click', (event) ->
      if event.target is event.currentTarget
        $(event.currentTarget)
          .closest('.rawCell')
          .find('[data-action=product-details]')
          .click()

    $(document)
      .on('mouseenter', '.detailsFetcher', (event) ->
        $el = $ event.currentTarget
        $el.append $overlay
      )

      .on('mouseleave', '.detailsFetcher', (event) ->
        if $overlay.parent()[0] == event.currentTarget
          $overlay.detach()
      )

  pid = 'uid5204-23781302-79'
  urlRoot = "http://api.shopstyle.com/api/v2/products?pid=#{pid}&"
  encodedTitle = encodeURIComponent document.querySelector('title').innerHTML
  url = "#{urlRoot}fts=#{encodedTitle}"

  $http.get(url).success (data) ->
    product = data.products[0]
    if product
      $scope.findLink.productOnPage = product
      console.log 'product', product
      brand = encodeURIComponent product.brand.id
      category = encodeURIComponent product.categories[0].id
      $http.get("#{urlRoot}fl=b#{brand}&cat=#{category}").success (data) ->
        $scope.findLink.relatedProducts = data.products
    else
      $scope.findLink.noProductOnPage = true

  $scope.onShopstyle = _.contains location.hostname, 'shopstyle'

  _.extend $scope,
    findLink: {}