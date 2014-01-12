![Compilr](http://i.imgur.com/sgvfBB7.png)

Compiles angular apps for rendering on any backend, regardless of language or platform.
Server side rendering, full angular expression support, 100% SEO comparible, client/server route logic sharing, and environment agnostic state persistence.

Maximum performance, minimal load times, optimal development efficiency, 100% SEO support.

Build apps that load fast and feel amazing.

## Purpose
* Write your angular app, auto compile to your backend, never think about SEO again.
* Maximum performance (don't run a bunch of frontend-specific code just to render your templates for faster loadtimes and SEO)
* Backend agnostic

## How it works
* 100% automatic - configure your routes, compile your app, enjoy.
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
* Angular application logic
  * Use ng-click to trigger client __and__ server actions
  (e.g. changing states and routes) even without any browser javascript!
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
* Templates compile to 100% valid handlebars
  * Handlebars helpers comparible - extend with your own
* Template resolution
  * All angular template attributes are 100% safe. They are converted
    to handlebars expressions and to ng-attributes so the template
    can be immediately displayed in the browser but angular can still
    find all necessary hooks to take control of the application once loaded
  * e.g. '{{foo}}' ➜ '<span ng-bind="foo">{{foo}}<span>'

## Example

### Angular template input
```html
<a ng-repeat="product in products" ng-click="activeProduct = product">
  <img src="{{user.image}}" ng-show="foo && bar">

  {{foo}}

  <div ng-include="'path/to/partial'">
  </div>
</a>


<img class="small" ng-class="{ active: imgVisible }" ng-if="foo.length">
<img ng-style="{ color: mainColor }" ng-if="foo && bar">

{{ foo && bar }}
```

### Compiled temlpate output
Includes {{}} for handlebars and attributes + escaped {{}} (&amp;#123;) for angular interpolations
```html
{{#forEach 'foo' in bar}}
  <a ng-repeat="foo in bar" ng-click="activeProduct = product" href="?action=activeProduct%3Dproduct">
    <img src="{{user.image}}" ng-attr-src="&amp;#123;&amp;#123;user.image&amp;#123;&amp;#123;" ng-show="foo" {{hbsShow "foo && bar"}}>

    <span ng-bind="foo">{{foo}}</span>

    <div ng-include="'path/to/partial'">
      {{> path/to/partial}}
    </div>
  </a>
{{/forEach}}

{{#if foo.length}}
  <img class="small {{#if imgVisible}}active{{/if}} ng-class="{ active: imgVisible }" ng-if="foo.length">
{{/if}}

{{#ifExpression "foo && bar"}}
  <img ng-if="foo && bar" style="{{styleExpression '{ color: mainColor }'}}>
{{/ifExpression}}

<span ng-bind="foo && bar">
  {{expression "foo && bar"}}
</span>
```

### State & Route Configuration
Configure your state and routes in one place and Compilr
will compile them into application logic for both your client and server

```javascript
{
  routes: {
    '/:page/:tab/:product': {
      data: {
        showModal: true
      },
      compute: {
        'activeTab.name': '$params.tab',
        activeProduct: 'results[$params.product]'
      }
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
    }
  }
}

```

## Supported Attributes

* **ng-repeat**
* **ng-include**
* **ng-show**
* **ng-hide**
* **ng-if**
* **ng-click**
* **ng-class**
* **ng-style**
* **ng-attr-***
* **ng-href, ng-value, ng-src**
* **ng-bind**
* **Interpolations**
* **Expressions**

## State & Route Configuration
Configure your state and routes in one place and Compilr
will compile them into application logic for both your client and server

```javascript
{
  routes: {
    '/:page/:tab/:product': {
      data: {
        showModal: true
      },
      compute: {
        'activeTab.name': '$params.tab',
        activeProduct: 'results[$params.product]',
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

## Project Status
Functional demo complete. Working on production ready v1.0.0

## Usage
`compilr src/path/* dest/path/*`

## Contributing
We need more adapters! Node + express is built. We need python, ruby, and more!

## Todo
* Support for angular filters.
* Support for other templating languages (e.g. jinja on python)

## Demo
Coming soon...
