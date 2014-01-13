![Compylr](http://i.imgur.com/A3XYEWM.png)

Angular.js apps 100% on the server, no JS required!

Compile angular apps for rendering on any backend, regardless of language or platform.
Server side rendering, full angular expression support, 100% SEO comparible,
client/server route and logic sharing, environment agnostic state persistence.


## Purpose
* Simplicity: write your angular app, let Compylr do the rest
* Best of both worlds: first render on the server, then let angular take over once the page is displayed
* Minimal pageload times pre-load
* Maximum performance post-load
* Backend agnostic
* Easily share state and route logic on client and server


## How it works
* Compiles angular templates to handlebars templates
* Standardizes route configuration using JSON for angular and any backend (via an adapter)
* Standardizes state management with angular and any backend (via an adapter)


## Example

#### Angular Template Input
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

#### Compiled Temlpate Output
Includes {{}} for handlebars and attributes + escaped {{}} (&amp;#123;) for angular interpolations
```html
{{#forEach 'foo' in bar}}
  <a ng-repeat="foo in bar" ng-click="activeProduct = product" href="?action=activeProduct%3Dproduct">
    <img src="{{user.image}}" ng-show="foo" {{hbsShow "foo && bar"}} ng-attr-src="&#123;&#123;user.image&#125;&#125;">

    <span ng-bind="foo">{{foo}}</span>

    <div ng-include="'path/to/partial'">
      {{> path/to/partial}}
    </div>
  </a>
{{/forEach}}

{{#if foo.length}}
  <img class="small {{#if imgVisible}}active{{/if}}" ng-class="{ active: imgVisible }" ng-if="foo.length">
{{/if}}

{{#ifExpression "foo && bar"}}
  <img ng-if="foo && bar" style="{{styleExpression '{ color: mainColor }'}}">
{{/ifExpression}}

<span ng-bind="foo && bar">
  {{expression "foo && bar"}}
</span>
```

#### State & Route Configuration
Configure your state and routes in one place and Compylr
will compile them into application logic for both your client and server.

`compylr.json`

```javascript
{
  "routes": {
    "/:page/:tab/:product": {
      "data": {
        "showModal": true
      },
      "compute": {
        "activeTab.name": "$params.tab",
        "activeProduct": "results[$params.product]"
      }
    }
  },
  "data": {
    "activeProduct": {},
    "query": {
      "value": ""
    },
    "mode": {
      "name": "search"
    },
    "openTab": {
      "name": "insights"
    }
  }
}
```


#### Server Events & Actions
Compilr runs your applications routes and states on both the client
and the server. This means that you can run things like

* `<a ng-click="selectedProduct = products[i]"></a>`
* `<a ng-click="showModal = true"></a>`
* `<a ng-click="user.loggedIn = false"></a>`

And this will update state logic in your templates, such as
* `<div class="modal" ng-show="showModal">...</div>`
* `<h1>{{selectedProduct.name}}</h1><p>{{selectedProduct.description}}</p>`
* `<div ng-if="user.loggedIn" id="main-container"></div>`

This means your applications not only render on the server, but can
function as fully standalone applications without any JS at all!
This is all taken care of automatigically by Compylr.

For example, this interactive webpage written in angular can function 100%
on the server and without JS when copiled by Compylr.


Pre-compile:

```html
<a ng-click="selectedProduct = product" ng-repeat="product in productResults">
  {{selectedProduct.name}}
</a>
<div ng-if="selectedProduct">
  <h1>{{selectedProduct.name}}</h1>
  <p>{{selectedProduct.description}}</p>
</div>
```

Post-compile:

```html
{{#forEach 'product' in productResults}}
  <a  href="?action=selectedProduct%3Dproduct" ng-click="selectedProduct = product" ng-repeat="product in productResults" ng-bind="selectedProduct.name">
    {{selectedProduct.name}}
  </a>
{{/forEach}}
{{#if selectedProduct}}
  <div ng-if="selectedProduct">
    <h1 ng-bind="selectedProduct.name">{{selectedProduct.name}}</h1>
    <p ng-bind="selectedProduct.description">{{selectedProduct.description}}</p>
  </div>
{{/if}}
```

Note in the above example the key to this is in the href "?action=". This is compiled
from your angular template and tells the server adapter the state and/or route
changes to make


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
  * e.g. `{{foo}}` ➜ `<span ng-bind="foo">{{foo}}<span>`


## Supported Attributes
* ng-repeat
* ng-include
* ng-show
* ng-hide
* ng-if
* ng-click
* ng-class
* ng-style
* ng-attr-*
* ng-href, ng-value, ng-src
* ng-bind
* interpolations
 * `{{foo}} <img src="{{bar}}.png">`
* expressions
 * `{{foo && bar}} <img ng-show="bar || foo">`


## Project Status
Functional demo complete. Working on production ready v1.0.0


## Usage
`Compylr src/path/* dest/path/*`


## Contributing
We need more adapters! Node + express is built. We need python, ruby, and more!


## Todo
* Support for angular filters
* Support for other templating languages (e.g. jinja on python)
* Supoprt for logic sharing
  * On node through code sharing
  * On other platforms (python, java, etc) through expression parsing


## Demo
Coming soon...
