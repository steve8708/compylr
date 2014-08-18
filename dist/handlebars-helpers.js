var helpers, _,
  __slice = [].slice;

_ = require('lodash');

helpers = require('./helpers');

module.exports = function(handlebars) {
  handlebars || (handlebars = require('handlebars'));
  handlebars.registerHelper('dynamicTemplate', function() {
    var map, options, template, _i;
    template = arguments[0], map = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), options = arguments[_i++];
    template = helpers.safeEvalWithContext(template, this) || '';
    template = template.replace('.tpl.html', '');
    return new handlebars.SafeString(handlebars.partials[template](this));
  });
  handlebars.registerHelper("eachExpression", function(name, _in, expression, options) {
    var value;
    value = helpers.safeEvalWithContext(expression, this);
    return instance.helpers.forEach(name, _in, value, options);
  });
  handlebars.registerHelper("styleExpression", function(expression, options) {
    var key, out, val, value;
    value = helpers.safeEvalWithContext(expression, this, true);
    out = ';';
    for (key in value) {
      val = value[key];
      out += "" + (_.str.dasherize(key)) + ": " + val + ";";
    }
    return " " + out + " ";
  });
  handlebars.registerHelper("classExpression", function(expression, options) {
    var key, out, val, value;
    value = helpers.safeEvalWithContext(expression, this, true);
    out = [];
    for (key in value) {
      val = value[key];
      if (val) {
        out.push(key);
      }
    }
    return ' ' + out.join(' ') + ' ';
  });
  handlebars.registerHelper("locals", function(expression, options) {
    var ctx, key, locals, value;
    locals = helpers.safeEvalWithContext(expression, this);
    ctx = _.clone(this);
    for (key in locals) {
      value = locals[key];
      ctx[key] = helpers.safeEvalWithContext(value, this);
    }
    return options.fn(ctx, options);
  });
  handlebars.registerHelper("ifExpression", function(expression, options) {
    var value;
    value = helpers.safeEvalWithContext(expression, this);
    if (!options.hash.includeZero && !value) {
      return options.inverse(this);
    } else {
      return options.fn(this);
    }
  });
  handlebars.registerHelper("expression", function(expression, options) {
    var value;
    value = helpers.safeEvalWithContext(expression, this);
    return value;
  });
  handlebars.registerHelper("hbsShow", function(expression, options) {
    var value;
    value = helpers.safeEvalWithContext(expression, this);
    if (value) {
      return ' data-hbs-show ';
    } else {
      return ' data-hbs-hide ';
    }
  });
  handlebars.registerHelper("hbsHide", function(expression, options) {
    var value;
    value = helpers.safeEvalWithContext(expression, this);
    if (value) {
      return ' data-hbs-hide ';
    } else {
      return ' data-hbs-show ';
    }
  });
  handlebars.registerHelper("json", function() {
    var args, obj, options, _i;
    args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), options = arguments[_i++];
    obj = args[0] || this;
    return new handlebars.SafeString(JSON.stringify(obj, null, 2));
  });
  handlebars.registerHelper("interpolatedScript", function(options) {
    var key, scriptStr, value, _ref;
    scriptStr = "<script";
    _ref = options.hash;
    for (key in _ref) {
      value = _ref[key];
      scriptStr += " " + key + "=\"" + value + "\"";
    }
    scriptStr += '>';
    return "" + scriptStr + " " + (options.fn(this)) + " </script>";
  });
  return handlebars.registerHelper("forEach", function(name, _in, contextExpression) {
    var context, ctx, data, fn, i, inverse, iterContext, iterCtx, j, key, nameSplit, objSize, options, ret, value;
    context = helpers.safeEvalWithContext(contextExpression, this);
    options = _.last(arguments);
    fn = options.fn;
    ctx = this;
    inverse = options.inverse;
    i = 0;
    ret = "";
    data = void 0;
    nameSplit = name.split(',');
    if (context) {
      if (_.isArray(context) || _.isString(context)) {
        j = context.length;
        while (i < j) {
          iterContext = _.clone(ctx);
          iterContext[name] = context[i];
          iterContext.$index = i;
          iterContext.$first = i === 0;
          iterContext.$last = i === (iterContext.length - 1);
          iterContext.$odd = i % 2;
          iterContext.$even = !(i % 2);
          iterContext.$middle = !iterContext.$first && !iterContext.$last;
          ret = ret + fn(iterContext);
          i++;
        }
      } else {
        objSize = _.size(context);
        for (key in context) {
          value = context[key];
          iterCtx = _.clone(ctx);
          iterCtx[nameSplit[0]] = key;
          iterCtx[nameSplit[1]] = value;
          iterCtx.$index = i;
          iterCtx.$first = i === 0;
          iterCtx.$odd = i % 2;
          iterCtx.$even = !(i % 2);
          iterCtx.$last = i === objSize - 1;
          iterCtx.$middle = !iterCtx.$first && !iterCtx.$last;
          ret = ret + fn(iterCtx);
          i++;
        }
      }
    }
    return ret;
  });
};
