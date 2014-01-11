angular.module('app.home', ['ui.router']).config( ($stateProvider) ->
  $stateProvider.state 'home',
    url: '/home'
    views:
      main:
        controller: 'HomeCtrl'
        templateUrl: 'modules/home/home.tpl.html'

    data:
      pageTitle: 'Home'

).controller 'HomeCtrl', ($scope) ->
  $scope.foo = 'bar'
