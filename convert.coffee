#!/usr/bin/env coffee

# TODO:
#   - crawl full directory of templates and partials and output new tree of files
#   - partials (crawl and map directory this script gets pointed to)
#   - flask server render whole app backend a page at a time
#   - angular hook into page post-render
#   - prettify output
#
#   - options
#     - no prettify
#     - no strip comments

argv = require('optimist').argv
fs = require 'fs'
beautifyHtml = require('js-beautify').html

stripComments = (str) ->
  str.replace(/<!--[\s\S]*?-->/g, '')

convert = (options) ->
  filePath = argv.file or options.filePath
  if filePath
    console.log 'filePath', filePath
    file = fs.readFileSync filePath, 'utf8'
  else
    file = options.string or options

  selfClosingTags = 'area, base, br, col, command, embed, hr, img, input,
  keygen, link, meta, param, source, track, wbr'.split /,\s*/

  escapeCurlyBraces = (str) ->
    str
      .replace(/\{/g, '&#123;')
      .replace(/\}/g, '&#125;')

  beautify = (str) ->
    str = str.replace /\{\{(#|\/)([\s\S]+?)\}\}/g, (match, type, body) ->
      modifier = if type is '#' then '' else '/'
      "<#{modifier}##{body}>"

    pretty = beautifyHtml str

    pretty = pretty
      .replace /<(\/?#)(.*)>/g, (match, modifier, body) ->
        modifier = '/' if modifier is '/#'
        "{{#{modifier}#{body}}}"

    pretty


  # TODO: pretty format
  #   replace '\n' with '\n  ' where '  ' is 2 spaces * depth
  #   Maybe prettify at very end instead
  getCloseTag = (string) ->
    index = 0
    depth = 0
    open = string.match(/<.*?>/)[0]
    string = string.replace open, ''

    for char, index in string
      # Close tag
      if char is '<' and string[index + 1] is '/'
        if not depth
          after = string.substr index
          close = after.match(/<\/.*?>/)[0]
          afterWithTag = after + close
          afterWithoutTag = after.substring close.length

          return (
            index: index
            closeTag: close
            after: afterWithoutTag
            startIndex: index
            endIndex: index + afterWithTag.length
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

  interpolated = stripComments(file)
    .replace(/<[^>]*?ng\-repeat="(.*?)">([\S\s]+)/gi, (match, text, post) ->
      varName = text
      varNameSplit = varName.split ' '
      varNameSplit[0] = "'#{varNameSplit[0]}'"
      varName = varNameSplit.join ' '
      # varName = text.split(' in ')[1]
      close = getCloseTag match
      if close
        "{{#forEach #{varName}}}\n#{close.before}\n{{/forEach}}\n#{close.after}"
      else
        throw new Error 'Parse error! Could not find close tag for ng-repeat'
    )
    .replace(/<[^>]*?ng\-if="(.*)".*?>([\S\s]+)/, (match, varName, post) ->
      # Unless
      if varName.indexOf('!') is 0
        varName = varName.substr 1
        close = getCloseTag match
        if close
          "{{#unless #{varName}}}\n#{close.before}\n{{/unless}}\n#{close.after}"
        else
          throw new Error 'Parse error! Could not find close tag for ng-if\n\n' + match + '\n\n' + file
      else
        close = getCloseTag match
        if close
          "{{#if #{varName}}}\n#{close.before}\n{{/if}}\n#{close.after}"
        else
          throw new Error 'Parse error! Could not find close tag for ng-if\n\n' + match + '\n\n' + file
    )
    .replace(/<[^>]*?ng\-include="'(.*)'".*?>/, (match, includePath, post) ->
      "#{match}\n{{> #{includePath}}}"
    )
    .replace(/(ng-src|ng-href|ng-value)="(.*)"/, (match, src) ->
      escapedMatch = escapeCurlyBraces match
      """#{escapedMatch} src="#{src}" """
    )
    # FIXME: this doesn't support multiple interpolations in one tag
    .replace(/<[^>]*?(\w+)\s*?=\s*?"([^">]*?\{\{[^">]+\}\}[^">*]?)".*?>/, (match, attrName, attrVal) ->
      # Match without the final '#'
      trimmedMatch = match.substr 0, match.length - 1
      if attrName.indexOf('ng-attr-') is 0
        match
      else
        """#{trimmedMatch} ng-attr-#{attrName}="#{escapeCurlyBraces attrVal}">"""
    )

    # .replace(/<[^>]*?ng\-show="(.*)".*?>([\S\s]+)/g, (match, varName, post) ->
    #   close = getCloseTag match
    #   if close
    #     "{{#if #{varName}}}\n#{close.before}\n{{/if}}\n#{close.after}"
    #   else
    #     throw new Error 'Parse error! Could not find close tag for ng-show'
    # )
    # .replace(/<[^>]*?ng\-hide="(.*)".*?>([\S\s]+)/g, (match, varName, post) ->
    #   close = getCloseTag match
    #   if close
    #     "{{#unless #{varName}}}\n#{close.before}\n{{/unless}}\n#{close.after}"
    #   else
    #     throw new Error 'Parse error! Could not find close tag for ng-hide'
    # )


  beautified = beautify interpolated

  if argv.file and not argv['no-write']
    fs.writeFileSync 'template-output/output.html', beautified

  beautified

module.exports = convert
