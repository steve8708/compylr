first = true
i = 0
randoDigits = ->
  i++
  num = (if first then 10 else 20) + Math.floor(Math.random()* 99) + 1
  first = false
  debouncedNewFirst()
  num + (i * 10)

debouncedNewFirst = _.debounce ->
  first = true
  i = 0
, 100

# moment = window.moment or window.require and window.require 'moment'

angular.module('app.insights', ['ui.router', 'nvd3ChartDirectives'])
.config( ($stateProvider) ->
  $stateProvider.state 'insights',
    url: '/insights'
    views:
      main:
        controller: 'InsightsCtrl'
        templateUrl: 'modules/insights/insights.tpl.html'

    data:
      pageTitle: 'Insights'

).controller 'InsightsCtrl', ($scope, $window, $http, $injector) ->
  utils = $injector.get 'utils'

  # weird hack to find a reference to the first chart in the child
  # scope need to wait 100 ms run or it won't find the reference
  earningsChart = null

  findCartRef = ($$childHead) ->
    return $$childHead.chart if $$childHead.chart
    return null if not $$childHead.$$nextSibling
    findCartRef $$childHead.$$nextSibling

  ############### PULL IN STATS FROM THE API ###############
  getDataFromApi = ->
    $scope.data.earningsGraph = earningsFromApi
    $scope.data.bestPerformers = bestPerformersFromApi
    $scope.parseEarningsData($scope.data.earningsGraph)
    $scope.parseBestPerformersData($scope.data.bestPerformers)
    $scope.updateChart()

  $scope.$watch 'controls', ->
    if $scope.controls.type is 'social'
      switch $scope.controls.date
        when '3'
          $scope.parseBestPerformersData(bestPerformersFromApi3d)
          $scope.data.earningsGraph = socialEarningsFromApi3d
        when '7'
          $scope.parseBestPerformersData(bestPerformersFromApi)
          $scope.data.earningsGraph = socialEarningsFromApi
        when '30'
          $scope.parseBestPerformersData(bestPerformersFromApi30d)
          $scope.data.earningsGraph = socialEarningsFromApi30d
    else
      switch $scope.controls.date
        when '3'
          $scope.parseBestPerformersData(bestPerformersFromApi3d)
          $scope.data.earningsGraph = earningsFromApi3d
        when '7'
          $scope.parseBestPerformersData(bestPerformersFromApi)
          $scope.data.earningsGraph = earningsFromApi
        when '30'
          $scope.parseBestPerformersData(bestPerformersFromApi30d)
          $scope.data.earningsGraph = earningsFromApi30d

    $scope.parseEarningsData()

  , true


  _.extend $scope,
    activeTab:
      name: 'earnings'

    controls:
      type: 'all'
      date: '7'

    colorOptions: [
      '#E06'
      '#EEB900'
      '#00AEEE'
      '#8D00EF'
      '#EE5A00'
    ]

    data:
      earningsData : []
      best : {}

    parseEarningsData: (data) ->
      data = data or @data.earningsGraph
      series = @controls.type is 'social' and
        ['facebook', 'personal', 'pinterest', 'twitter'] or
        ['prevPeriod', 'current']
      seriesColors = ['#EE0066', '#00AEED', '#EE5A00', '#EFB901']

      @data.earningsData = []
      @data.earningsTicks = data.axes.xaxis.ticks

      _.each series, (type, index) =>
        values = []
        _.each data.data[type], (row) ->
          values.push [ moment(row[0]).format('X'), row[1] ]

        @data.earningsData.push
          'key': type,
          'values': values
          'color': seriesColors[index]
          'disabled': false

      if @data.earningsTicks.length > 10
        @data.earningsTicks = _.filter @data.earningsTicks, (tick, index) ->
          index % 3 == 0


    parseBestPerformersData: (data) ->
      data = data or @data.bestPerformers
      _.each ['categories', 'weekDays', 'socialNetworks', 'brands',
        'retailers'], (type) =>
        values = []
        _.each data[type], (item, index) ->

          if type in [ 'brands', 'retailers' ]
            values.push
              key: item.name
              y: item.earnings
              url: item.url
          else
            values.push
              key: item[0]
              y: parseFloat item[1]
              color: $scope.colorOptions[index]

        @data.best[type] = values

    xTickValues: ->
      _.map $scope.data.earningsTicks, (tick) ->
        moment(tick).format('X')

    colorFunction: ->
      (d, i) ->
        $scope.colorOptions[i]

    xAxisTickFormatFunction: ->
      (d) ->
        format = d3.time.format('%Y-%m-%d')
        d3.time.format('%b %e')(new Date(d * 1000))

    yAxisTickFormatFunction: -> (n) -> '$' + n

    xFunction: -> (d) -> d.key
    yFunction: -> (d) -> d.y

    toolTipContentFunction: ->
      (key, x, y, e, graph) ->
        '<h3>' + y + '</h3>' +
        '<p>' + x + '</p>'

    toolTipBestContentFunction: ->
      (key, x, y, e, graph) ->
        '<p>' + '$' + x + '</p>'

    toggleSeries: (series) ->
      series.disabled = !series.disabled
      @updateChart()

    updateChart: ->
      earningsChart = earningsChart or
        findCartRef $scope.$$childHead if $scope.$$childHead
      if earningsChart
        earningsChart.update()
      else if not $scope.$$childHead then return
      else if $scope.$$childHead.chart
        $scope.$$childHead.chart.update()
      else if $scope.$$childHead.$$childHead.chart
        $scope.$$childHead.$$childHead.chart.update()

  getDataFromApi()

  _.delay ->
    $scope.updateChart()
  , 100

  firstLoad = true
  $scope.$watch 'openTab.name', (name) ->
    if name is 'insights' and firstLoad
      firstLoad = false
      _.delay ->
        $scope.$$childHead.$$childHead.chart.update()
        $scope.$$childHead.$$childHead.$$nextSibling.chart.update()
        $scope.$$childHead.$$childHead.$$nextSibling
          .$$nextSibling.chart.update()
        $scope.$$childHead.$$childHead.$$nextSibling
          .$$nextSibling.$$nextSibling.chart.update()
      , 100






















###### DUMMY DATA #######

earningsFromApi =
  data:
    prevPeriod: [
      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    current:[
      ["2013-12-30",randoDigits(),"12/30"]
      ["2013-12-31",randoDigits(),"12/31"]
      ["2014-01-01",randoDigits(),"1/1"]
      ["2014-01-02",randoDigits(),"1/2"]
      ["2014-01-03",randoDigits(),"1/3"]
      ["2014-01-04",randoDigits(),"1/4"]
      ["2014-01-05",randoDigits(),"1/5"]
    ]
  series: [ {
    label: "Previous Period"
    color: "#00AEED"
  }, {
    label:"Current"
    color:"#e06"
    yaxis:"yaxis"
    markerOptions:
      show:true
  }]
  axes:
    xaxis:
      ticks: [
        "2013-12-30",
        "2013-12-31",
        "2014-01-01",
        "2014-01-02",
        "2014-01-03",
        "2014-01-04",
        "2014-01-05"]
      tickOptions:
        formatString: "%m/%d"
    yaxis:
      numberTicks:5
      min:0
      max:5
      tickOptions:
        formatString:"$%.2f"




earningsFromApi3d =
  data:
    prevPeriod: [
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    current:[
      ["2014-01-03",randoDigits(),"1/3"]
      ["2014-01-04",randoDigits(),"1/4"]
      ["2014-01-05",randoDigits(),"1/5"]
    ]
  series: [ {
    label: "Previous Period"
    color: "#00AEED"
  }, {
    label:"Current"
    color:"#e06"
    yaxis:"yaxis"
    markerOptions:
      show:true
  }]
  axes:
    xaxis:
      ticks: [
        "2014-01-03",
        "2014-01-04",
        "2014-01-05"]
      tickOptions:
        formatString: "%m/%d"
    yaxis:
      numberTicks:5
      min:0
      max:5
      tickOptions:
        formatString:"$%.2f"


earningsFromApi30d =
  data:
    prevPeriod: [
      ["2013-12-07",randoDigits(),"12/23"]
      ["2013-12-08",randoDigits(),"12/23"]

      ["2013-12-09",randoDigits(),"12/23"]
      ["2013-12-10",randoDigits(),"12/24"]
      ["2013-12-11",randoDigits(),"12/25"]
      ["2013-12-12",randoDigits(),"12/26"]
      ["2013-12-13",randoDigits(),"12/27"]
      ["2013-12-14",randoDigits(),"12/28"]
      ["2013-12-15",randoDigits(),"12/29"]

      ["2013-12-16",randoDigits(),"12/23"]
      ["2013-12-17",randoDigits(),"12/24"]
      ["2013-12-18",randoDigits(),"12/25"]
      ["2013-12-19",randoDigits(),"12/26"]
      ["2013-12-20",randoDigits(),"12/27"]
      ["2013-12-21",randoDigits(),"12/28"]
      ["2013-12-22",randoDigits(),"12/29"]

      ["2013-12-23",randoDigits(),"12/23"]
      ["2013-12-24",randoDigits(),"12/24"]
      ["2013-12-25",randoDigits(),"12/25"]
      ["2013-12-26",randoDigits(),"12/26"]
      ["2013-12-27",randoDigits(),"12/27"]
      ["2013-12-28",randoDigits(),"12/28"]
      ["2013-12-29",randoDigits(),"12/29"]

      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]

    ]
    current:[
      ["2013-12-07",randoDigits(),"12/23"]
      ["2013-12-08",randoDigits(),"12/23"]

      ["2013-12-09",randoDigits(),"12/23"]
      ["2013-12-10",randoDigits(),"12/24"]
      ["2013-12-11",randoDigits(),"12/25"]
      ["2013-12-12",randoDigits(),"12/26"]
      ["2013-12-13",randoDigits(),"12/27"]
      ["2013-12-14",randoDigits(),"12/28"]
      ["2013-12-15",randoDigits(),"12/29"]

      ["2013-12-16",randoDigits(),"12/23"]
      ["2013-12-17",randoDigits(),"12/24"]
      ["2013-12-18",randoDigits(),"12/25"]
      ["2013-12-19",randoDigits(),"12/26"]
      ["2013-12-20",randoDigits(),"12/27"]
      ["2013-12-21",randoDigits(),"12/28"]
      ["2013-12-22",randoDigits(),"12/29"]

      ["2013-12-23",randoDigits(),"12/23"]
      ["2013-12-24",randoDigits(),"12/24"]
      ["2013-12-25",randoDigits(),"12/25"]
      ["2013-12-26",randoDigits(),"12/26"]
      ["2013-12-27",randoDigits(),"12/27"]
      ["2013-12-28",randoDigits(),"12/28"]
      ["2013-12-29",randoDigits(),"12/29"]

      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
  series: [ {
    label: "Previous Period"
    color: "#00AEED"
  }, {
    label:"Current"
    color:"#e06"
    yaxis:"yaxis"
    markerOptions:
      show:true
  }]
  axes:
    xaxis:
      ticks: [
        "2013-12-07"
        "2013-12-08"

        "2013-12-09"
        "2013-12-10"
        "2013-12-11"
        "2013-12-12"
        "2013-12-13"
        "2013-12-14"
        "2013-12-15"

        "2013-12-16"
        "2013-12-17"
        "2013-12-18"
        "2013-12-19"
        "2013-12-20"
        "2013-12-21"
        "2013-12-22"

        "2013-12-23"
        "2013-12-24"
        "2013-12-25"
        "2013-12-26"
        "2013-12-27"
        "2013-12-28"
        "2013-12-29"

        "2013-12-30"
        "2013-12-31"
        "2014-01-01"
        "2014-01-02"
        "2014-01-03"
        "2014-01-04"
        "2014-01-05"
      ]
      tickOptions:
        formatString: "%m/%d"
    yaxis:
      numberTicks:5
      min:0
      max:5
      tickOptions:
        formatString:"$%.2f"








socialEarningsFromApi =
  data:
    facebook: [
      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    personal: [
      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    pinterest: [
      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    twitter: [
      ["2013-12-30",randoDigits(),"12/30"]
      ["2013-12-31",randoDigits(),"12/31"]
      ["2014-01-01",randoDigits(),"1/1"]
      ["2014-01-02",randoDigits(),"1/2"]
      ["2014-01-03",randoDigits(),"1/3"]
      ["2014-01-04",randoDigits(),"1/4"]
      ["2014-01-05",randoDigits(),"1/5"]
    ]
  series: [
    {label: 'Twitter', color:'#EFB901'}
    {label: 'Pinterest', color:'#ee5a00'}
    {label: 'Facebook', color:'#00AEED'}
    {label: 'Personal', color:'#e06'}
  ]
  axes:
    xaxis:
      ticks: [
        "2013-12-30",
        "2013-12-31",
        "2014-01-01",
        "2014-01-02",
        "2014-01-03",
        "2014-01-04",
        "2014-01-05"]
      tickOptions:
        formatString: "%m/%d"
    yaxis:
      numberTicks:5
      min:0
      max:5
      tickOptions:
        formatString:"$%.2f"






socialEarningsFromApi3d =
  data:
    facebook: [
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    personal: [
      ["2014-01-03",randoDigits(),"1/3"]
      ["2014-01-04",randoDigits(),"1/4"]
      ["2014-01-05",randoDigits(),"1/5"]
    ]
    pinterest: [
      ["2014-01-03",randoDigits(),"1/3"]
      ["2014-01-04",randoDigits(),"1/4"]
      ["2014-01-05",randoDigits(),"1/5"]
    ]
    twitter: [
      ["2014-01-03",randoDigits(),"1/3"]
      ["2014-01-04",randoDigits(),"1/4"]
      ["2014-01-05",randoDigits(),"1/5"]
    ]
  series: [
    {label: 'Twitter', color:'#EFB901'}
    {label: 'Pinterest', color:'#ee5a00'}
    {label: 'Facebook', color:'#00AEED'}
    {label: 'Personal', color:'#e06'}
  ]
  axes:
    xaxis:
      ticks: [
        "2014-01-03",
        "2014-01-04",
        "2014-01-05"]
      tickOptions:
        formatString: "%m/%d"
    yaxis:
      numberTicks:5
      min:0
      max:5
      tickOptions:
        formatString:"$%.2f"


socialEarningsFromApi30d =
  data:
    facebook: [
      ["2013-12-07",randoDigits(),"12/23"]
      ["2013-12-08",randoDigits(),"12/23"]

      ["2013-12-09",randoDigits(),"12/23"]
      ["2013-12-10",randoDigits(),"12/24"]
      ["2013-12-11",randoDigits(),"12/25"]
      ["2013-12-12",randoDigits(),"12/26"]
      ["2013-12-13",randoDigits(),"12/27"]
      ["2013-12-14",randoDigits(),"12/28"]
      ["2013-12-15",randoDigits(),"12/29"]

      ["2013-12-16",randoDigits(),"12/23"]
      ["2013-12-17",randoDigits(),"12/24"]
      ["2013-12-18",randoDigits(),"12/25"]
      ["2013-12-19",randoDigits(),"12/26"]
      ["2013-12-20",randoDigits(),"12/27"]
      ["2013-12-21",randoDigits(),"12/28"]
      ["2013-12-22",randoDigits(),"12/29"]

      ["2013-12-23",randoDigits(),"12/23"]
      ["2013-12-24",randoDigits(),"12/24"]
      ["2013-12-25",randoDigits(),"12/25"]
      ["2013-12-26",randoDigits(),"12/26"]
      ["2013-12-27",randoDigits(),"12/27"]
      ["2013-12-28",randoDigits(),"12/28"]
      ["2013-12-29",randoDigits(),"12/29"]

      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]

    ]
    personal: [
      ["2013-12-07",randoDigits(),"12/23"]
      ["2013-12-08",randoDigits(),"12/23"]

      ["2013-12-09",randoDigits(),"12/23"]
      ["2013-12-10",randoDigits(),"12/24"]
      ["2013-12-11",randoDigits(),"12/25"]
      ["2013-12-12",randoDigits(),"12/26"]
      ["2013-12-13",randoDigits(),"12/27"]
      ["2013-12-14",randoDigits(),"12/28"]
      ["2013-12-15",randoDigits(),"12/29"]

      ["2013-12-16",randoDigits(),"12/23"]
      ["2013-12-17",randoDigits(),"12/24"]
      ["2013-12-18",randoDigits(),"12/25"]
      ["2013-12-19",randoDigits(),"12/26"]
      ["2013-12-20",randoDigits(),"12/27"]
      ["2013-12-21",randoDigits(),"12/28"]
      ["2013-12-22",randoDigits(),"12/29"]

      ["2013-12-23",randoDigits(),"12/23"]
      ["2013-12-24",randoDigits(),"12/24"]
      ["2013-12-25",randoDigits(),"12/25"]
      ["2013-12-26",randoDigits(),"12/26"]
      ["2013-12-27",randoDigits(),"12/27"]
      ["2013-12-28",randoDigits(),"12/28"]
      ["2013-12-29",randoDigits(),"12/29"]

      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    pinterest: [
      ["2013-12-07",randoDigits(),"12/23"]
      ["2013-12-08",randoDigits(),"12/23"]

      ["2013-12-09",randoDigits(),"12/23"]
      ["2013-12-10",randoDigits(),"12/24"]
      ["2013-12-11",randoDigits(),"12/25"]
      ["2013-12-12",randoDigits(),"12/26"]
      ["2013-12-13",randoDigits(),"12/27"]
      ["2013-12-14",randoDigits(),"12/28"]
      ["2013-12-15",randoDigits(),"12/29"]

      ["2013-12-16",randoDigits(),"12/23"]
      ["2013-12-17",randoDigits(),"12/24"]
      ["2013-12-18",randoDigits(),"12/25"]
      ["2013-12-19",randoDigits(),"12/26"]
      ["2013-12-20",randoDigits(),"12/27"]
      ["2013-12-21",randoDigits(),"12/28"]
      ["2013-12-22",randoDigits(),"12/29"]

      ["2013-12-23",randoDigits(),"12/23"]
      ["2013-12-24",randoDigits(),"12/24"]
      ["2013-12-25",randoDigits(),"12/25"]
      ["2013-12-26",randoDigits(),"12/26"]
      ["2013-12-27",randoDigits(),"12/27"]
      ["2013-12-28",randoDigits(),"12/28"]
      ["2013-12-29",randoDigits(),"12/29"]

      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
    twitter: [
      ["2013-12-07",randoDigits(),"12/23"]
      ["2013-12-08",randoDigits(),"12/23"]

      ["2013-12-09",randoDigits(),"12/23"]
      ["2013-12-10",randoDigits(),"12/24"]
      ["2013-12-11",randoDigits(),"12/25"]
      ["2013-12-12",randoDigits(),"12/26"]
      ["2013-12-13",randoDigits(),"12/27"]
      ["2013-12-14",randoDigits(),"12/28"]
      ["2013-12-15",randoDigits(),"12/29"]

      ["2013-12-16",randoDigits(),"12/23"]
      ["2013-12-17",randoDigits(),"12/24"]
      ["2013-12-18",randoDigits(),"12/25"]
      ["2013-12-19",randoDigits(),"12/26"]
      ["2013-12-20",randoDigits(),"12/27"]
      ["2013-12-21",randoDigits(),"12/28"]
      ["2013-12-22",randoDigits(),"12/29"]

      ["2013-12-23",randoDigits(),"12/23"]
      ["2013-12-24",randoDigits(),"12/24"]
      ["2013-12-25",randoDigits(),"12/25"]
      ["2013-12-26",randoDigits(),"12/26"]
      ["2013-12-27",randoDigits(),"12/27"]
      ["2013-12-28",randoDigits(),"12/28"]
      ["2013-12-29",randoDigits(),"12/29"]

      ["2013-12-30",randoDigits(),"12/23"]
      ["2013-12-31",randoDigits(),"12/24"]
      ["2014-01-01",randoDigits(),"12/25"]
      ["2014-01-02",randoDigits(),"12/26"]
      ["2014-01-03",randoDigits(),"12/27"]
      ["2014-01-04",randoDigits(),"12/28"]
      ["2014-01-05",randoDigits(),"12/29"]
    ]
  series: [
    {label: 'Twitter', color:'#EFB901'}
    {label: 'Pinterest', color:'#ee5a00'}
    {label: 'Facebook', color:'#00AEED'}
    {label: 'Personal', color:'#e06'}
  ]
  axes:
    xaxis:
      ticks: [
        "2013-12-07"
        "2013-12-08"

        "2013-12-09"
        "2013-12-10"
        "2013-12-11"
        "2013-12-12"
        "2013-12-13"
        "2013-12-14"
        "2013-12-15"

        "2013-12-16"
        "2013-12-17"
        "2013-12-18"
        "2013-12-19"
        "2013-12-20"
        "2013-12-21"
        "2013-12-22"

        "2013-12-23"
        "2013-12-24"
        "2013-12-25"
        "2013-12-26"
        "2013-12-27"
        "2013-12-28"
        "2013-12-29"

        "2013-12-30"
        "2013-12-31"
        "2014-01-01"
        "2014-01-02"
        "2014-01-03"
        "2014-01-04"
        "2014-01-05"
      ]
      tickOptions:
        formatString: "%m/%d"
    yaxis:
      numberTicks:5
      min:0
      max:5
      tickOptions:
        formatString:"$%.2f"
















######## BEST PERFORMERS DATA ####################

bestPerformersFromApi =
  categories:[
    ['Shoes & Boots', randoDigits()]
    ['Denim', randoDigits()]
    ['Tops', randoDigits()]
    ['Shoes',randoDigits()]
    ['Dresses', randoDigits()]
  ]
  brands: [
    {
      earnings: randoDigits()
      id: "226"
      isCommonWord: false
      name: "Free People"
      synonyms: ['Free People Knits']
      url: "http://www.shopstyle.com/browse/Free-People"
    }, {
      earnings: randoDigits()
      id: "1226"
      isCommonWord: false
      name: "Giuseppe Zanotti"
      synonyms: ['Guiseppe Zanotti', 'Giuseppe Zanotti Design']
      url: "http://www.shopstyle.com/browse/Giuseppe-Zanotti"
    }, {
      earnings: randoDigits()
      id: "292"
      isCommonWord: false
      name: "Jessica Simpson"
      synonyms: ['Jessica Simpson Kids', 'Jessica Simpson Fragrance']
      url: "http://www.shopstyle.com/browse/Jessica-Simpson"
    }, {
      earnings: randoDigits()
      id: "309"
      isCommonWord: false
      name: "Juicy Couture"
      synonyms: ['Juicy Couture Timepieces', 'Juicy Couture Beach']
      url: "http://www.shopstyle.com/browse/Juicy-Couture"
    }
  ]
  retailers: [
    {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "21"
      mobileOptimized: true
      name: "shopbop.com"
      url: "http://www.shopstyle.com/browse/shopbop.com-US"
    }, {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "1"
      mobileOptimized: true
      name: "Nordstrom"
      url: "http://www.shopstyle.com/browse/Nordstrom-US"
    }, {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "306"
      name: "SSENSE"
      url: "http://www.shopstyle.com/browse/SSENSE-US"
    }
  ]
  socialNetworks: [
    ['Personal', randoDigits()],
    ['Facebook', randoDigits()],
    ['Twitter', randoDigits()]
  ]
  weekDays: [
    ['Sun', randoDigits()]
    ['Mon', randoDigits()]
    ['Tue', randoDigits()]
    ['Thu', randoDigits()]
    ['Sat', randoDigits()]
  ]





bestPerformersFromApi3d =
  categories:[
    ['Shoes & Boots', randoDigits()]
    ['Denim', randoDigits()]
    ['Tops', randoDigits()]
    ['Shoes',randoDigits()]
    ['Dresses', randoDigits()]
  ]
  brands: [
    {
      earnings: randoDigits()
      id: "226"
      isCommonWord: false
      name: "Free People"
      synonyms: ['Free People Knits']
      url: "http://www.shopstyle.com/browse/Free-People"
    }, {
      earnings: randoDigits()
      id: "1226"
      isCommonWord: false
      name: "Giuseppe Zanotti"
      synonyms: ['Guiseppe Zanotti', 'Giuseppe Zanotti Design']
      url: "http://www.shopstyle.com/browse/Giuseppe-Zanotti"
    }, {
      earnings: randoDigits()
      id: "292"
      isCommonWord: false
      name: "Jessica Simpson"
      synonyms: ['Jessica Simpson Kids', 'Jessica Simpson Fragrance']
      url: "http://www.shopstyle.com/browse/Jessica-Simpson"
    }, {
      earnings: randoDigits()
      id: "309"
      isCommonWord: false
      name: "Juicy Couture"
      synonyms: ['Juicy Couture Timepieces', 'Juicy Couture Beach']
      url: "http://www.shopstyle.com/browse/Juicy-Couture"
    }
  ]
  retailers: [
    {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "21"
      mobileOptimized: true
      name: "shopbop.com"
      url: "http://www.shopstyle.com/browse/shopbop.com-US"
    }, {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "1"
      mobileOptimized: true
      name: "Nordstrom"
      url: "http://www.shopstyle.com/browse/Nordstrom-US"
    }, {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "306"
      name: "SSENSE"
      url: "http://www.shopstyle.com/browse/SSENSE-US"
    }
  ]
  socialNetworks: [
    ['Personal', randoDigits()],
    ['Facebook', randoDigits()],
    ['Twitter', randoDigits()]
  ]
  weekDays: [
    ['Sun', randoDigits()]
    ['Mon', randoDigits()]
    ['Tue', randoDigits()]
    ['Thu', randoDigits()]
    ['Sat', randoDigits()]
  ]






bestPerformersFromApi30d =
  categories:[
    ['Shoes & Boots', randoDigits()]
    ['Denim', randoDigits()]
    ['Tops', randoDigits()]
    ['Shoes',randoDigits()]
    ['Dresses', randoDigits()]
  ]
  brands: [
    {
      earnings: randoDigits()
      id: "226"
      isCommonWord: false
      name: "Free People"
      synonyms: ['Free People Knits']
      url: "http://www.shopstyle.com/browse/Free-People"
    }, {
      earnings: randoDigits()
      id: "1226"
      isCommonWord: false
      name: "Giuseppe Zanotti"
      synonyms: ['Guiseppe Zanotti', 'Giuseppe Zanotti Design']
      url: "http://www.shopstyle.com/browse/Giuseppe-Zanotti"
    }, {
      earnings: randoDigits()
      id: "292"
      isCommonWord: false
      name: "Jessica Simpson"
      synonyms: ['Jessica Simpson Kids', 'Jessica Simpson Fragrance']
      url: "http://www.shopstyle.com/browse/Jessica-Simpson"
    }, {
      earnings: randoDigits()
      id: "309"
      isCommonWord: false
      name: "Juicy Couture"
      synonyms: ['Juicy Couture Timepieces', 'Juicy Couture Beach']
      url: "http://www.shopstyle.com/browse/Juicy-Couture"
    }
  ]
  retailers: [
    {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "21"
      mobileOptimized: true
      name: "shopbop.com"
      url: "http://www.shopstyle.com/browse/shopbop.com-US"
    }, {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "1"
      mobileOptimized: true
      name: "Nordstrom"
      url: "http://www.shopstyle.com/browse/Nordstrom-US"
    }, {
      deeplinkSupport: true
      earnings: randoDigits()
      id: "306"
      name: "SSENSE"
      url: "http://www.shopstyle.com/browse/SSENSE-US"
    }
  ]
  socialNetworks: [
    ['Personal', randoDigits()],
    ['Facebook', randoDigits()],
    ['Twitter', randoDigits()]
  ]
  weekDays: [
    ['Sun', randoDigits()]
    ['Mon', randoDigits()]
    ['Tue', randoDigits()]
    ['Thu', randoDigits()]
    ['Sat', randoDigits()]
  ]
