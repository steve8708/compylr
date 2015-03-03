# require the main app
compylr = require '../lib/compile'
fs = require 'fs'

compiledTemplate = compylr file: '/example/sample-angular-template.tpl.html'
fs.writeFile 'example/compiled-handlerbars-template.html', compiledTemplate, 'utf8'

sampleString = """
  <a ng-repeat="product in products" href="products/{{product.id}}">
    <img src="{{user.image}}" ng-show="foo && bar">

    {{foo}}

    <div ng-include="'path/to/partial'">
    </div>
  </a>

  <img class="small" ng-class="{ active: imgVisible }" ng-if="foo.length">
  <img ng-style="{ color: mainColor }" ng-if="foo && bar">

  {{ foo && bar }}"""

compiledString = compylr sampleString
fs.writeFile 'example/compiled-handlerbars-string.html', compiledString, 'utf8'
