var app, appConfig, cache, compile, config, currentReq, directories, esprima, exphbs, express, fileName, fs, handlebars, handlebarsHelpers, helpers, mkdirp, partialName, path, port, preCompiledTemplatesDir, request, resultsSuccess, templatesDir, type, _, _i, _j, _len, _len1, _ref;

handlebars = require('handlebars');

express = require('express');

exphbs = require('express3-handlebars');

_ = require('lodash');

_.str = require('underscore.string');

fs = require('fs');

mkdirp = require('mkdirp');

request = require('request');

compile = require('./compile');

helpers = require('./helpers');

handlebarsHelpers = require('./handlebars-helpers');

config = require('./config');

esprima = require('esprima');

appConfig = require('../compilr-config');

console.info('Running...');

console.info('Process id = ' + process.pid);

app = express();

templatesDir = 'compiled-templates';

preCompiledTemplatesDir = 'templates';

app.use(express.cookieParser());

app.use(express.session({
  secret: 'foobar',
  store: new express.session.MemoryStore
}));

app.use(express["static"]('static'));

app.engine('html', exphbs({
  layoutsDir: './',
  partialsDir: "./" + templatesDir,
  extname: '.tpl.html'
}));

app.set('view engine', 'handlebars');

app.set('views', __dirname + '/..');

console.info('Compiling templates..');

mkdirp.sync("./" + templatesDir);

fs.writeFileSync("./" + templatesDir + "/index.tpl.html", compile({
  file: "" + preCompiledTemplatesDir + "/index.tpl.html"
}));

directories = ['templates', 'modules/account', 'modules/home', 'modules/insights', 'modules/ribbon', 'modules/search', 'modules/tools'];

for (_i = 0, _len = directories.length; _i < _len; _i++) {
  type = directories[_i];
  path = "./" + preCompiledTemplatesDir + "/" + type + "/";
  _ref = fs.readdirSync(path);
  for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
    fileName = _ref[_j];
    if (!_.contains(fileName, '.tpl.html')) {
      continue;
    }
    partialName = "" + type + "/" + fileName;
    mkdirp.sync("./" + templatesDir + "/" + type);
    fs.writeFileSync("./" + templatesDir + "/" + partialName, compile({
      file: "" + path + fileName
    }));
  }
}

console.info('Done compiling templates.');

cache = {
  results: {}
};

currentReq = null;

resultsSuccess = function(req, res, results) {
  var product, sessionData, _base;
  sessionData = (_base = req.session).pageData || (_base.pageData = _.cloneDeep(appConfig.data));
  sessionData.results = results;
  product = req.params.product;
  if (product) {
    sessionData.activeProduct.product = _.find(results, function(item) {
      return ("" + item.id) === ("" + product);
    });
  } else {
    sessionData.activeProduct.product = null;
  }
  if (!res.headerSent) {
    console.log('render start');
    res.render("" + templatesDir + "/index.tpl.html", sessionData);
    return console.log('render end');
  }
};

app.get('/:page?/:tab?/:product?', function(req, res) {
  var action, cached, page, pid, product, query, sessionData, tab, url, urlBase, _base;
  currentReq = req;
  page = req.params.page || 'search';
  tab = req.params.tab;
  product = req.params.product;
  query = req.query.fts || '';
  if (page === 'favicon.ico') {
    return res.send(200);
  }
  sessionData = (_base = req.session).pageData || (_base.pageData = _.cloneDeep(appConfig.data));
  action = req.query.action;
  if (action) {
    helpers.safeEvalWithContext(action, sessionData);
    return res.redirect(req._parsedUrl.pathname);
  }
  if (page && !tab && appConfig.data.tabDefaults[page]) {
    return res.redirect("/" + page + "/" + appConfig.data.tabDefaults[page]);
  }
  sessionData.noJS = req.query.nojs;
  sessionData.openTab.name = page;
  sessionData.urlPath = req._parsedUrl.pathname.replace(/\/$/, '');
  sessionData.urlPathList = sessionData.urlPath.split('/');
  sessionData.activeTab.name = sessionData.accountTab = sessionData.mode.name = tab;
  sessionData.query.value = query;
  pid = 'uid5204-23781302-79';
  urlBase = "http://api.shopstyle.com/api/v2";
  url = "" + urlBase + "/products/?pid=" + pid + "&limit=30&sort=Popular&fts=" + (query || '');
  cached = cache.results[query];
  if (cached) {
    resultsSuccess(req, res, cached);
    return;
  }
  console.log('api request start');
  return request.get(url, function(err, response, body) {
    var results;
    console.log('api request end');
    results = JSON.parse(body).products;
    cache.results[query] = results;
    return resultsSuccess(req, res, results);
  });
});

port = process.env.PORT || 5000;

console.info("Listening on part " + port + "..");

app.listen(port);
