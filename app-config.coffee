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
      console.log 'toggleSelectedProduct', product
      sessionData = currentReq.session.pageData or= _.cloneDeep pageData
      id = product and product.id or product
      foundProduct = _.find sessionData.selectedProducts, (item) ->
        item and "#{item.id}" is "#{id}"
      if product
        sessionData.selectedProducts.unshift product
      else
        sessionData.selectedProducts.splice sessionData.selectedProducts.indexOf(product), 1