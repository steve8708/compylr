angular.module('app.account', ['ui.router']).config( ($stateProvider) ->
  $stateProvider.state 'account',
    url: '/account'
    views:
      main:
        controller: 'AccountCtrl'
        templateUrl: 'modules/account/account.tpl.html'

    data:
      pageTitle: 'Account'

).controller 'AccountCtrl', ($scope) ->

