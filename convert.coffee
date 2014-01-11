#!/usr/bin/env coffee

# TODO:
#   partials (crawl and map directory this script gets pointed to)
#   flask server render whole app backend a page at a time
#   angular hook into page post-render

argv = require('optimist').argv
fs = require 'fs'

if argv.file
  file = fs.readFileSync argv.file, 'utf8'
else
  console.warn 'you must specify a file with "--file="'
  return

selfClosingTags = 'area, base, br, col, command, embed, hr, img, input,
keygen, link, meta, param, source, track, wbr'.split /,\s*/

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
      after = string.substr index
      # Check if self closing tag
      for selfClosingTag in selfClosingTags
        if after.indexOf(selfClosingTag) is 0
          selfClosing = true
          # Self closing tag, ignore
          break
      if selfClosing
        continue
      else
        depth++

interpolated = file
  .replace(/<[^>]*?ng\-repeat="(.*?)">([\S\s]+)/gi, (match, text, post) ->
    varName = text
    # varName = text.split(' in ')[1]
    close = getCloseTag match
    if close
      "{{#each #{varName}}}\n#{close.before}\n{{/each}}\n#{close.after}"
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
        throw new Error 'Parse error! Could not find close tag for ng-if'
    else
      close = getCloseTag match
      if close
        "{{#if #{varName}}}\n#{close.before}\n{{/if}}\n#{close.after}"
      else
        throw new Error 'Parse error! Could not find close tag for ng-if'
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

console.log '\n\n\n\n\n\n\NINTERPOLATED:\n\n', interpolated
