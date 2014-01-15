var config, esprima, evalFnCache, evaluate, expressionCache, i, _,
  __slice = [].slice;

esprima = require('esprima');

config = require('./config');

_ = require('lodash');

evaluate = require('static-eval');

expressionCache = {};

evalFnCache = {};

i = 0;

module.exports = {
  warnVerbose: function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (config.verbose) {
      return console.warn.apply(console, args);
    }
  },
  logVerbose: function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (config.verbose) {
      return console.info.apply(console, args);
    }
  },
  safeEvalWithContext: function(expression, context, clone, thisArg, returnNewContext) {
    var error, fn, output;
    if (thisArg == null) {
      thisArg = context;
    }
    fn = evalFnCache[expression] || (evalFnCache[expression] = new Function('context', "with (context) { return " + expression + " }"));
    try {
      output = fn.call(thisArg, context);
    } catch (_error) {
      error = _error;
      this.warnVerbose('Action error', error);
    }
    if (returnNewContext) {
      return {
        context: context,
        output: output
      };
    } else {
      return output;
    }
  },
  safeEvalStaticExpression: function(expression, context, thisArg) {
    var error, expressionBody, value;
    if (thisArg == null) {
      thisArg = this;
    }
    context['this'] = thisArg;
    try {
      expressionBody = expressionCache[expression] || esprima.parse(expression).body[0].expression;
      if (!expressionCache[expression]) {
        expressionCache[expression] = expressionBody;
      }
    } catch (_error) {
      error = _error;
      console.warn('Expression error', expression, error);
    }
    try {
      value = evaluate(expressionBody, context);
    } catch (_error) {
      error = _error;
      this.warnVerbose('Eval expression error');
    }
    return value;
  }
};
