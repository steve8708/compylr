#!/usr/bin/env node
argv = require('optimist').argv
fs = require 'fs'

file = fs.readFileSync argv.file, 'utf8'

selfClosingTags = 'area, base, br, col, command, embed, hr, img, input,
keygen, link, meta, param, source, track, wbr'.split ', '

getCloseTag = (string) ->
  index = 0
  depth = 0
  for char, index in string
    # Close tag
    if char is '<' and string[index + 1] is '/'
      if not depth
        after = string.substr index
        close = after.match(/<\/.*?>/)[0]
        return
          index: index
          closeTag: close
          after: after
          startIndex: index
          endIndex: index + after.length
          before: string.substr 0, index
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

flat = file
  .replace(/<[^>]*?ng\-repeat="(.*)".*?>(.|\s)*?<\/.*?>/g, (match, text) ->
    varName = text.split(' in ')[1]
    "{{##{varName}}}\n#{match}\n{{/#{varName}}}"
  )
  .replace(/<[^>]*?ng\-if="(.*)".*?>(.|\s)*?<\/.*?>/, (match, varName) ->
    # Unless
    if varName.indexOf('!') is 0
      varName = varName.substr 1
      "{{^#{varName}}}\n#{match}\n{{/#{varName}}}"
    else
      "{{##{varName}}}\n#{match}\n{{/#{varName}}}"
  )
  .replace(/<[^>]*?ng\-show="(.*)".*?>(.|\s)*?<\/.*?>/g, (match, varName) ->

    "{{##{varName}}}\n#{match}\n{{/#{varName}}}"
  )
  .replace(/<[^>]*?ng\-hide="(.*)".*?>(.|\s)*?<\/.*?>/g, (match, varName) ->
    "{{^#{varName}}}\n#{match}\n{{/#{varName}}}"
  )

interpolated = file
  .replace(/<[^>]*?ng\-repeat="(.*)".*?>(.|\s)*/g, (match, text, post) ->
    varName = text.split(' in ')[1]
    "{{##{varName}}}\n#{match}\n{{/#{varName}}}"
  )
  .replace(/<[^>]*?ng\-if="(.*)".*?>(.|\s)*?<\/.*?>/, (match, varName) ->
    # Unless
    if varName.indexOf('!') is 0
      varName = varName.substr 1
      "{{^#{varName}}}\n#{match}\n{{/#{varName}}}"
    else
      "{{##{varName}}}\n#{match}\n{{/#{varName}}}"
  )
  .replace(/<[^>]*?ng\-show="(.*)".*?>(.|\s)*?<\/.*?>/g, (match, varName) ->
    "{{##{varName}}}\n#{match}\n{{/#{varName}}}"
  )
  .replace(/<[^>]*?ng\-hide="(.*)".*?>(.|\s)*?<\/.*?>/g, (match, varName) ->
    "{{^#{varName}}}\n#{match}\n{{/#{varName}}}"
  )

console.log 'interpolated:', interpolated
console.log 'flat:', flat
