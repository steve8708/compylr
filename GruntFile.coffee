os = require 'os'

module.exports = (grunt) ->

  # Load tasks - - - - - - - - - - - - - - - - - - - - - - -

  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-compress'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-conventional-changelog'
  grunt.loadNpmTasks 'grunt-bump'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-npm'


  # Helpers - - - - - - - - - - - - - - - - - - - - - - - -

  filterForJS = (files) ->
    files.filter (file) ->
      file.match /\.js$/

  filterForCSS = (files) ->
    files.filter (file) ->
      file.match /\.css$/

  getLocalIp = ->
    interfaces = os.networkInterfaces()
    for name, value of interfaces
      for details in value
        if details.family is 'IPv4' and name is 'en1'
          return details.address


  # Config - - - - - - - - - - - - - - - - - - - - - - - - -

  taskConfig =
    appFiles:
      coffee: 'lib/**/*'

    buildDir: 'dist'
    compileDir: 'dist'

    connect:
      dev:
        options:
          port: 5100
          # hostname: getLocalIp()
          base: 'build'

    pkg: grunt.file.readJSON 'package.json'

    'npm-publish': {}

    meta:
      banner:
        '/**\n' +
        ' * <%= pkg.name %> - v<%= pkg.version %> - ' +
          '<%= grunt.template.today(\'yyyy-mm-dd\') %>\n' +
        ' * <%= pkg.homepage %>\n' +
        ' *\n' +
        ' * Copyright (c) <%= grunt.template.today(\'yyyy\')' +
          ' %> <%= pkg.author %>\n' +
        ' */\n'

    changelog:
      options:
        dest: 'CHANGELOG.md'
        template: 'changelog.tpl'

    bump:
      options:
        files: ['package.json']
        commit: true
        commitMessage: 'chore(release): v%VERSION%'
        commitFiles: ['package.json']
        createTag: true
        tagName: 'v%VERSION%'
        tagMessage: 'Version %VERSION%'
        push: true
        pushTo: 'origin'

    clean: [
      '<%= buildDir %>'
      '<%= compileDir %>'
    ]

    coffee:
      source:
        options:
          bare: true

        expand: true
        cwd: './lib'
        src: ['**/*']
        dest: '<%= buildDir %>'
        ext: '.js'

      karmaConfig:
        options:
          bare: true

        src: '<%= buildDir %>/karma-unit.coffee'
        dest: '<%= buildDir %>/karma-unit.js'

    coffeelint:
      src:
        files:
          src: [
            '<%= appFiles.coffee %>'
            '<%= appFiles.coffeeunit %>'
            'GruntFile.coffee'
          ]

      test:
        files:
          src: ['<%= appFiles.coffeeunit %>']

    karma:
      options:
        configFile: '<%= buildDir %>/karma-unit.js'

      unit:
        runnerPort: 9101
        background: true

      continuous:
        singleRun: true

      compile:
        dir: '<%= compileDir %>'
        src: []

    karmaconfig:
      unit:
        dir: '<%= buildDir %>'
        src: []

    delta:
      options:
        livereload: true

      gruntfile:
        files: 'Gruntfile.coffee'
        tasks: ['coffeelint']
        options:
          livereload: false

      coffeesrc:
        files: ['<%= appFiles.coffee %>']
        # tasks: ['coffeelint:src', 'coffee:source', 'copy:buildAppjs']
        tasks: ['build']

      coffeeunit:
        files: ['<%= appFiles.coffeeunit %>']
        tasks: ['coffeelint:test', 'karma:unit:run']
        options:
          livereload: false

  grunt.initConfig taskConfig
  grunt.renameTask 'watch', 'delta'
  grunt.registerTask 'build', 'coffee:source'


  ###
  In order to avoid having to specify manually the files needed for karma to
  run, we use grunt to manage the list for us. The `karma/*` files are
  compiled as grunt templates for use by Karma. Yay!
  ###
  grunt.registerMultiTask 'karmaconfig', 'Process karma config templates', ->
    jsFiles = filterForJS @filesSrc
    buildDir = grunt.config 'buildDir'
    templatePath = 'karma/karma-unit.tpl.coffee'

    grunt.file.copy templatePath, "#{buildDir}/karma-unit.coffee",
      process: (contents, path) ->
        grunt.template.process contents,
          data:
            scripts: jsFiles

    grunt.task.run 'coffee:karmaConfig'
