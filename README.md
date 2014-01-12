# Compilr
Compiles angular apps to be run on any backend. SEO is not longer a problem
for single page apps. Maximum performance, minimal load times, optimal development efficiency.

## How it works
* Compiles Angular Templates to Handlebars Templates
* Standardizes route configuration using JSON for angular and any backend (via an adapter)
* Standardizes state management with angular and any backend (via an adapter)
* Keeps your life simple and happy. Build your angular app, don't even think about
  your server. Compilr will do everything for you

## Key Components
* 100% SEO friendly
* Ultra high performance
  * You don't need to run your whole app on the server to render a template. So don't.
    Instead cross compile templates and sync state.
* Client and server rendering (render on server, once app loaded renders on client)
* Pushtate support (always keep urls in sync)
* Simple state and route configuration
* Shared session state on client and server with simple configuration
* Shared route logic on client and server with simple configuration
* Backend agnostic. Supports any backend with a simple adapter
* Full expression support - e.g. `ng-show="foo && bar[foo] || bar.foo"`
* Event support - e.g. `ng-click="foo = !foo"`
* Form support
* Offline support
* Template resolution
  * All angular template attributes are 100% safe. They are converted
    to handlebars expressions and to ng-attributes so the template
    can be immediately displayed in the browser but angular can still
    find all necessary hooks to take control of the application once loaded
  * e.g. '{{foo}}' -> '<span ng-bind="foo">{{foo}}<span>'

## Supports
* ### ng-repeat
  * `<a ng-repeat="foo in bar"></a>` -> `{{#forEach 'foo' in bar}}<a ng-repeat="foo in bar"></a>{{/forEach}}`
* ### ng-include
  * `<div ng-include="'path/to/partial'"></div>` -> `{{> path/to/partial}}`
* ### ng-show
  * `<img ng-show="foo && bar">` -> `<img ng-show="foo" {{hbsShow "foo && bar"}}>`
* ### ng-hide
  * `<input ng-show="foo || bar">` -> `<input ng-show="foo" {{hbsHide "foo || bar"}}>`
* ### ng-if
  * `<img ng-if="foo.length">` -> `{{#if foo.length}}<img ng-if="foo.length">{{/if}}`
  * `<img ng-if="foo && bar">` -> `{{#ifExpression "foo && bar"}}<img ng-if="foo.length">{{/ifExpression}}`
* ### ng-click
  * `<a ng-click="foo = !bar">` -> `<a href="?action=foo!%3Dbar"></a>`
* ### ng-class
  * `<img class="small" ng-class="{ active: imgVisible }">` -> `<img class="small {{#if imgVisible}}active{{/if}}`
* ### ng-style
  * `<img ng-style="{ color: mainColor }">` -> `<img style="{{styleExpression '{ color: mainColor }'}}`
* ### ng-attr-*
  * `<img ng-attr-src="{{logo}}">` -> `<img src="{{logo}}">`
* ### ng-href`, `ng-value`, `ng-src
  * `<a ng-href="{{home}}"></a>` -> `<a href="{{home}}"></a>`
* ### ng-bind
  * `<span ng-bind="user.name"></span>` -> `<span>{{user.name}}</span>`
* ### Interpolations
  * `{{foo}}` -> '<span ng-bind="foo"></span>'
  * `<img name="{{foo}}">` -> `<img ng-attr-name="{{foo}}">`
* ### Expressions
  * `{{ foo && bar }}` -> `{{expression "foo && bar"}}`
  * `<img src="{{ foo[bar] || attributes }}>"` -> `<img src="{{expression 'foo[bar] || attributes'}}>`

## Route configuration
Configure your state and routes in one place and Compilr
will compile them into application logic for both your client and server
```
{
  routes: {
    '/:page/:tab/:product': {
      data: {
        showModal: true
      },
      compute: {
        'activeTab.name': '@tab',
        activeProduct: 'results[@product]',
        foo: function(params, stateData) {
          return foobar;
        }
      },
      exec: ['getProducts']
    }
  },
  data: {
    activeProduct: {},
    query: {
      value: ''
    },
    mode: {
      name: 'search'
    },
    openTab: {
      name: 'insights'
    },

    toggleSelectedProduct: function(id) {
      var product = _.find(this.selectedProducts, function(item) {
        return item && ("" + item.id) === ("" + id);
      });
      if (product) {
        return this.selectedProducts.unshift(product);
      } else {
        return this.remove(this.selectedProducts, product);
      }
    }
  }
}

```

## Usage
`compilr src/path/* dest/path/*`

## Contribution
We need more adapters! Node + express is built. We need python, ruby, and more!

## Demo
Coming soon...
