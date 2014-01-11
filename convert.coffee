#!/usr/bin/env node
argv = require('optimist').argv
fs = require 'fs'

file = fs.readFileSync argv.file, 'utf8'

selfClosingTags = 'area, base, br, col, command, embed, hr, img, input,
keygen, link, meta, param, source, track, wbr'.split /,\s*/

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
    varName = text.split(' in ')[1]
    close = getCloseTag match
    if close
      "{{##{varName}}}\n#{close.before}\n{{/#{varName}}}\n#{close.after}"
    else
      throw new Error 'Parse error! Coudlnt find close tag for ng-repeat'
  )
  .replace(/<[^>]*?ng\-if="(.*)".*?>([\S\s]+)/, (match, varName, post) ->
    # Unless
    if varName.indexOf('!') is 0
      varName = varName.substr 1
      close = getCloseTag match
      if close
        "{{##{varName}}}\n#{close.before}\n{{/#{varName}}}\n#{close.after}"
      else
        throw new Error 'Parse error! Coudlnt find close tag for ng-repeat'
    else
      close = getCloseTag match
      if close
        "{{##{varName}}}\n#{close.before}\n{{/#{varName}}}\n#{close.after}"
      else
        throw new Error 'Parse error! Coudlnt find close tag for ng-repeat'
  )
  .replace(/<[^>]*?ng\-show="(.*)".*?>([\S\s]+)/g, (match, varName, post) ->
    close = getCloseTag match
    if close
      "{{##{varName}}}\n#{close.before}\n{{/#{varName}}}\n#{close.after}"
    else
      throw new Error 'Parse error! Coudlnt find close tag for ng-repeat'
  )
  .replace(/<[^>]*?ng\-hide="(.*)".*?>([\S\s]+)/g, (match, varName, post) ->
    close = getCloseTag match
    if close
      "{{##{varName}}}\n#{close.before}\n{{/#{varName}}}\n#{close.after}"
    else
      throw new Error 'Parse error! Coudlnt find close tag for ng-repeat'
  )

console.log '\n\n\n\n\n\n\NINTERPOLATED:\n\n', interpolated
