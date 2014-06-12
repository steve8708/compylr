argv         = require('optimist').argv
fs           = require 'fs'
_            = require 'lodash'
_str         = require 'underscore.string'
beautifyHtml = require('js-beautify').html
helpers      = require './helpers'
config       = require './config'
glob         = require 'glob'

# TODO: API for compile replacements
#
# compylr.add /foo/g, (match, group, etc) -> # doSomething()

config = _.defaults {}, argv,
  ugly: false





# Helpers
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# E.g. <div ng-repeat="foo in bar"></div>
getRefNames = (str, options) ->
  tags = str.match(/<.*?>/g)
  map = {}
  return map unless tags
  tags.reverse()
  depth = 0
  for tag in tags
    if tag.indexOf('</')
      depth--
      return map if depth < 0
    else
      depth++
      repeat = tag.match /\s(bo|ng)-repeat="(.*?)"/g
      continue unless repeat
      repeatText = RegExp.$1
      split = repeatText.split ' in '
      map[slit[0]] = split[1]
  map

stripComments = (str = '') ->
  str.replace /<!--[^\[]*?-->/g, ''

selfClosingTags = 'area, base, br, col, command, embed, hr, img, input,
  keygen, link, meta, param, source, track, wbr'.split /,\s*/

htmlEscapeCurlyBraces = (str) ->
  str
    .replace(/\{/g, '&#123;')
    .replace(/\}/g, '&#125;')

beautify = (str) ->
  str = str.replace /\{\{(#|\/)([\s\S]+?)\}\}/g, (match, type, body) ->
    modifier = if type is '#' then '' else '/'
    "<#{modifier}##{body}>"

  str = str
    .replace /<(\/?#)(.*)>/g, (match, modifier, body) ->
      modifier = '/' if modifier is '/#'
      "{{#{modifier}#{body}}}"

  pretty = beautifyHtml str,
    indent_size: 2
    indent_inner_html: true
    preserve_newlines: false

  pretty


# TODO: pretty format
#   replace '\n' with '\n  ' where '  ' is 2 spaces * depth
#   Maybe prettify at very end instead
getCloseTag = (string) ->
  string = string.trim()
  index = 0
  depth = 0
  open = string.match(/<[\s\S]*?>/)[0]
  tagName = string.match(/<\w+/)[0].substring 1
  string = string.replace open, ''

  if tagName in selfClosingTags
    out =
      before: open
      after: string
    return out

  for char, index in string
    # Close tag
    if char is '<' and string[index + 1] is '/'
      if not depth
        after = string.substr index
        close = after.match(/<\/.*?>/)[0]
        afterWithTag = after + close
        afterWithoutTag = after.substring close.length

        return (
          after: afterWithoutTag
          before: open + '\n' + string.substr(0, index) + close
        )
      else
        depth--
    # Open tag
    else if char is '<'
      selfClosing = false
      tag = string.substr(index).match(/\w+/)[0]
      # Check if self closing tag
      if tag and tag in selfClosingTags
        continue
      depth++

# FIXME: this will break for pipes inside strings
processFilters = (str) ->
  filterSplit = str.split /\s\|\s/
  filters: filterSplit.slice(1).join ' | '
  replaced: filterSplit[0]

# FIXME: will breal if this is in words
escapeReplacement = (str) ->
  convertNgToDataNg str

convertNgToDataNg = (str) ->
  str.replace /\s(ng|bo)-/g, ' data-$1-'

convertDataNgToNg = (str) ->
  str.replace /\sdata-(ng|bo)-/g, ' $1-'

unescapeReplacements = (str) ->
  str
  # str.replace /__NG__/g, 'ng-'

escapeBasicAttribute = (str) ->
  '__ATTR__' + str + '__ATTR__'

unescapeBasicAttributes = (str) ->
  str.replace /__ATTR__/g, ''

escapeDoubleBraces = (str) ->
  str
    .replace(/\{\{/g, '__{{__')
    .replace(/\}\}/g, '__}}__')

unescapeDoubleBraces = (str) ->
  str
    .replace(/__\{\{__/g, '{{')
    .replace(/__\}\}__/g, '}}')

escapeTripleBraces = (str) ->
  str
    .replace(/\{\{\{/g, '__[[[__')
    .replace(/\}\}\}/g, '__]]]__')

unescapeTripleBraces = (str) ->
  str
    .replace(/__\[\[\[__/g, '{{{')
    .replace(/__\]\]\]__/g, '}}}')


# Compile
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

compile = (options) ->
  filePath = argv.file or options.file
  if filePath
    helpers.logVerbose 'filePath', filePath
    file = fs.readFileSync filePath, 'utf8'
  else
    file = options.string or options

  updated = true
  interpolated = escapeTripleBraces stripComments file
  i = 0
  maxIters = 10000

  while updated
    updated = false

    throw new Error 'infinite update loop' if i++ > maxIters

    interpolated = interpolated

      # ng-repeat
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace(/<[^>]*?\s(bo|ng)-repeat="(.*?)"[\s\S]*?>([\S\s]+)/gi, (match, type, text, post) ->
        helpers.logVerbose 'match 1'
        updated = true
        repeatExp = text

        # Convert '(key, val) in bar' to 'key,val in bar' as our #forEach
        # helper wants to ultimately see {{#forEach 'key,val' in 'bar'}} for
        # objects
        repeatExp = repeatExp.trim()
          .replace /\(\s*(\w+?)\s*,\s*(\w+?)\s*\)/g, '$1,$2'

        # Strip out any filters (e.g. ng-repeat="foo in bar | limitTo: 10")
        # and split by whitespace and compact the result (remove any empty
        # strings in the list) as well as the 'track by' option in angular
        repeatExpSplit = _.compact repeatExp
          .split('|')[0]
          .split('track by')[0]
          .split /\s+/

        propName = repeatExpSplit[0]

        # Wrap the property name in strings for 'foo' in
        # {{#forEach 'foo' in 'bar'}}
        repeatExpSplit[0] = "'#{repeatExpSplit[0]}'"

        # Wrap the expression value in strings for 'bar' in
        # {{#forEach 'foo' in 'bar'}}
        repeatExpSplit[repeatExpSplit.length - 1] = "'#{_.last(repeatExpSplit).replace /'/g, '"'}'"

        repeatExp = repeatExpSplit.join ' '
        close = getCloseTag match

        # The real keypath of what we are looping through with quotes removed
        # I.e. for {{#forEach 'foo' in 'bar'}} this would be: bar
        expressionKeypath = _.last(repeatExpSplit)[1...-1]


        if close
          """
            {{#forEach #{repeatExp}}}
              #{close.before.replace /\s(bo|ng)-repeat/, ' data-$1-repeat'}
            {{/forEach}}
            #{close.after}
          """
        else
          throw new Error 'Parse error! Could not find close tag for ng-repeat'
      )


      # ng-if, bo-if
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace(/<[^>]*?\s(?:ng|bo)-if="(.*?)"[\s\S]*?>([\S\s]+)/g, (match, varName, post) ->
        helpers.logVerbose 'match 2'
        updated = true
        if _.contains match.replace(post, ''), 'compylr-keep'
          return match.replace 'ng-if', 'ng-cloak data-ng-if'

        varName = varName.trim()

        tagName = if varName.match /^[\w\.]+$/ then 'if' else 'ifExpression'
        if varName.indexOf('!') is 0 and tagName is 'if'
          tagName = 'unless'
          varName = varName.substr 1
        else if tagName is 'ifExpression'
          varName = "\"#{varName}\""

        close = getCloseTag match

        if close
          "{{##{tagName} #{varName}}}\n#{close.before.replace /\s(ng|bo)-if=/, " data-$1-if="}\n{{/#{tagName}}}\n#{close.after}"
        else
          throw new Error 'Parse error! Could not find close tag for ng-if\n\n' + match + '\n\n' + file
      )

      # ng-include
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace(/<[^>]*?\sng-include="'(.*)'"[^>]*?>/, (match, includePath, post) ->
        helpers.logVerbose 'match 3'
        updated = true
        includePath = includePath.replace '.tpl.html', ''
        match = match.replace /\sng-include=/, ' data-ng-include='
        """
          #{match}
          <span data-ng-non-bindable>
            {{> #{includePath}}}
          </span>
        """
      )

      # ng-include expressions
      .replace(/<[^>]*?\sng-include="([^']+?)".*?>/, (match, includePath, post) ->
        helpers.logVerbose 'match 10'
        updated = true
        match = match.replace /\sng-include=/, ' data-ng-include='
        escapeDoubleBraces """
          #{match}
          <span data-ng-non-bindable>
            {{dynamicTemplate #{includePath}}}
          </span>
        """
      )

      # ng-src, ng-href, ng-value, bo-src, bo-href, bo-value
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      # FIXME: this should replace ng-src with src, etc
      .replace(/\s((?:ng|bo)-src|(?:ng|bo)-href|(?:ng|bo)-value)="([\s\S]*?)"/g, (match, attrName, attrVal) ->
        helpers.logVerbose 'match 4'
        updated = true

        # bo-src and bo-href don't use interpolations and use expressions directly so we
        # we need to wrap them
        if _.contains attrName, 'bo-'
          match = match.replace attrVal, """{{expression "#{attrVal.split('|')[0].trim().replace /'/g, "\\'" }"}}"""

        match.replace attrName, attrName.replace /(ng|bo)-/, ''
      )


      # component="foobar"
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      #
      # TODO: remove these hardcoded items for us and have a compylr.add regex, replace
      #
      .replace(/\scomponent="([\s\S]*?)"/g, (match, componentName) ->
        helpers.logVerbose 'match 12'
        updated = true
        ctrlName = _.str.classify componentName
        templateName = "modules/components/#{componentName}/#{componentName}.tpl.html"

        match = match.replace /\scomponent=/, ' data-component='

        """#{match} ng-include="'#{templateName}'" ng-controller="#{ctrlName}Ctrl" """
      )


      # ng-class, ng-style, bo-class, bo-style
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      .replace(/<(\w+)[^>]*\s((?:ng|bo)-class|(?:ng|bo)-style)\s*=\s*"([^>"]+)"[\s\S]*?>/, (match, tagName, attrName, attrVal) ->
        # TODO: modify class attributes based on object here

        helpers.logVerbose 'match 8'
        type = attrName.substr 3 # 'class' or 'style'

        # TODO: need to support class without duplicating class attribute all the time
        #       style is permitted because inline styles shouldn't ever be used so
        #       attribute duplication shouldn't happen
        return match if type is 'class'

        updated = true
        typeMatch = match.match new RegExp "\\s#{type}=\"([\\s\\S]*?)\""
        typeStr = typeMatch and typeMatch[0].substr(1) or "#{type}=\"\""
        typeStrOpen = typeStr.substr 0, typeStr.length - 1
        typeExpressionStr = """{{#{type}Expression "#{attrVal}"}}"""
        if typeMatch
          match = match.replace typeMatch, ''
        match = match.replace new RegExp("\\s(ng|bo)-#{type}"), "data-$1-#{type}"

        match.replace "<#{tagName}", """<#{tagName} #{typeStrOpen} #{typeExpressionStr}" """
      )


      # attr="{{interpolation}}"
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace(/<[^>]*?([\w\-]+)\s*=\s*"([^">_]*?\{\{[^">]+\}\}[^">_]*?)"[\s\S]*?>/g, (match, attrName, attrVal) ->
        helpers.logVerbose 'match 5', attrName: attrName, attrVal: attrVal
        # Match without the final '>'
        trimmedMatch = match.substr 0, match.length - 1

        # If the tag was a self closing tag, e.g. <img /> remove the trailing '/'
        if _str.endsWith trimmedMatch, '/'
          trimmedMatch = trimmedMatch.substr 0, match.length - 1

        trimmedMatch = trimmedMatch.replace "#{attrName}=", escapeBasicAttribute "#{attrName}="
        if attrName.indexOf('data-(ng|bo)-attr-') is 0 or _.contains attrVal, '__{{__'
          return match
        else
          updated = true
          newAttrVal = attrVal.replace /\{\{([\s\S]+?)\}\}/g, (match, expression) ->
            match = match.trim()
            if expression.length isnt expression.match(/[\w\.]+/)[0].length
              "{{expression '#{expression.split('|')[0].trim().replace /'/g, "\\'"}'}}"
            else
              match.replace /\[|\]/g, '.'

          trimmedMatch = trimmedMatch.replace attrVal, escapeDoubleBraces newAttrVal
          """#{trimmedMatch}>"""
      )


      # translate
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace /(<[^>]*\stranslate[^>]*>)([\s\S]*?)(<.*?>)/g, (match, openTag, contents, closeTag) ->
        helpers.logVerbose 'match 9'

        # Ignore {{ foo | translate }} in attributes
        if /\|\s*translate/.test match
          return match

        # Pre escaped
        if _.contains(match, '__{{__translate')
          return match

        cleanup = (str = '') ->
          str.replace(/'/g, "\\'").replace(/\n/g, ' ')

        valuesRe = /[\s\S]*?translate-values\s*=\s*"([^"]+)"[\s\S]*/
        if valuesRe.test openTag
          values = openTag.replace valuesRe, '$1'
        cleanedValues = cleanup values or '{}'

        updated = true

        # Escape single quotes and remove newline which aren't allowed in js
        # strings
        cleanedContents = cleanup contents
        openTag = openTag.replace /translate([^a-z\-0-9])/i, """translate="#{contents.trim()}"$1"""

        escapeDoubleBraces """#{openTag}{{translate '#{ cleanedContents.trim() }' '#{cleanedValues}'}}#{closeTag}"""


      # ng-show, ng-hide, bo-show, bo-hide
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace(/\s((?:ng|bo)-show|(?:ng|bo)-hide)\s*=\s*"([^"]+)"/g, (match, showOrHide, expression) ->
        helpers.logVerbose 'match 6'

        updated = true
        hbsTagType = if _(showOrHide).contains '-show' then 'hbsShow' else 'hbsHide'
        match = match.replace ' ' + showOrHide, " data-#{showOrHide}"
        "#{match} {{#{hbsTagType} \"#{expression}\"}}"
      )

      # ng-bind, ng-bind-html, bo-bind, bo-html
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace /<[^>]*\s((?:ng|bo)-bind|ng-bind-html|bo-html)\s*=\s*"([^"]+?)"[^>]*>[^<]*(<.*?>)/g, (match, type, expression, closeTag) ->
        helpers.logVerbose 'match 7'
        updated = true
        str = match.replace type, "data-#{type}"
        if expression.length isnt expression.match(/[\w\.]+/)[0].length
          expression = "expression '#{expression.replace /'/g, "\\'"}'"

        expressionTag = if _(type).contains '-html' then escapeTripleBraces "{{{#{expression}}}}" else escapeDoubleBraces "{{#{expression}}}"
        str = str.replace closeTag, expressionTag + closeTag


  # Higher priority
  updated = true
  i = 0
  while updated
    updated = false
    throw new Error 'infinite update loop' if i++ > maxIters

    interpolated = interpolated

      # locals
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      .replace(/<[^>]*?\slocals="([^"]*?)"[\s\S]*?>([\S\s]+)/g, (match, expression, post) ->
        helpers.logVerbose 'match 11'
        updated = true

        expression = expression.trim()
        close = getCloseTag match

        if close
          """{{#locals "#{expression}"}}\n  #{close.before.replace /\slocals=/, ' data-locals='}\n{{/locals}}\n#{close.after}"""
        else
          throw new Error 'Parse error! Could not find close tag for locals directive\n\n' + match + '\n\n' + file
      )


  i = 0
  updated = true
  while updated
    updated = false

    throw new Error 'infinite update loop' if i++ > maxIters

    interpolated = interpolated

      # {{interpolation}}, {{exression == true}} -

      .replace(/\{\{([^#\/>_][\s\S]*?[^_])\}\}/g, (match, body) ->
        helpers.logVerbose 'match 7'
        updated = true
        body = body.trim()
        words = body.match /[\w\.]+/
        isHelper = words[0] in ['json', 'expression', 'hbsShow', 'hbsHide', 'classExpression', 'styleExpression']
        if not isHelper
          prefix = ''
          suffix = ''
          if words and words[0].length isnt body.length
            helpers.logVerbose 'body', body
            prefix = 'expression "'
            suffix = '"'
          escapeDoubleBraces """{{#{prefix}#{body}#{suffix}}}"""
        else
          escapeDoubleBraces match
      )

  # Unescape and output
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  interpolated = unescapeTripleBraces interpolated
  interpolated = unescapeReplacements interpolated
  interpolated = unescapeBasicAttributes interpolated
  # interpolated = convertNgToDataNg interpolated
  interpolated = convertDataNgToNg interpolated
  interpolated = unescapeDoubleBraces unescapeDoubleBraces interpolated
  beautified = beautify interpolated

  if argv.file and not argv['no-write']
    fs.writeFileSync 'template-output/output.html', beautified

  beautified


compile.setHelpers = (handlebars) ->
  require('./handlebars-helpers') handlebars

module.exports = compile
