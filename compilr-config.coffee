# TODO: compile to angular and express routes
module.exports =
  routes:
    '/:page/:tab/:product':
      data:
        showModal: true
      compute:
        'activeTab.name': '@tab'
        activeProduct: 'results[@product]'
        foo: (params, stateData) -> foobar
      # Separate function on client and server
      exec: ['getProducts']

  data:
    tabDefaults:
      insights: 'earnings'
      account: 'settings'
      search: 'search'
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

    # TODO: session data
    toggleSelectedProduct: (product) ->
      console.log 'toggleSelectedProduct', @selectedProducts
      id = product and product.id or product
      foundProduct = _.find @selectedProducts, (item) ->
        item and "#{item.id}" is "#{id}"
      if foundProduct
        @selectedProducts.splice @selectedProducts.indexOf(product), 1
      else
        @selectedProducts.unshift product
