var _, config, esprima, evalFnCache, evaluate, expressionCache, he, i,
  slice = [].slice;

esprima = require('esprima');

config = require('./config');

_ = require('lodash');

evaluate = require('static-eval');

he = require('he');

expressionCache = {};

evalFnCache = {};

i = 0;

module.exports = {
  warnVerbose: function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    if (config.verbose) {
      return console.warn.apply(console, args);
    }
  },
  logVerbose: function() {
    var args;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    if (config.verbose) {
      return console.info.apply(console, args);
    }
  },
  safeEvalWithContext: function(expression, context, clone, thisArg, returnNewContext) {
    var error, error1, error2, fn, output;
    if (expression == null) {
      expression = '';
    }
    if (thisArg == null) {
      thisArg = context;
    }
    expression = he.decode(expression);
    try {
      fn = evalFnCache[expression] || (evalFnCache[expression] = new Function('context', "with (context) { return " + expression + " }"));
    } catch (error1) {
      error = error1;
      this.warnVerbose('Failed to compile expression', error.message, expression);
    }
    try {
      output = fn.call(thisArg, context);
    } catch (error2) {
      error = error2;
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
    var error, error1, error2, expressionBody, ref, value;
    if (expression == null) {
      expression = '';
    }
    if (thisArg == null) {
      thisArg = this;
    }
    expression = he.decode(expression);
    context['this'] = thisArg;
    try {
      expressionBody = expressionCache[expression] || ((ref = esprima.parse(expression).body[0]) != null ? ref.expression : void 0);
      if (!expressionCache[expression]) {
        expressionCache[expression] = expressionBody;
      }
    } catch (error1) {
      error = error1;
      console.warn('Expression error', expression, error);
    }
    try {
      value = evaluate(expressionBody, context);
    } catch (error2) {
      error = error2;
      this.warnVerbose('Eval expression error');
    }
    return value;
  }
};
