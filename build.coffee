fs          = require 'fs'
async       = require 'async'
less        = require 'less'
chalk       = require 'chalk'

Metalsmith  = require 'metalsmith'
markdown    = require 'metalsmith-markdown'
templates   = require 'metalsmith-templates'
collections = require 'metalsmith-collections'

theme = (cb) ->
  async.waterfall [
    (cb) ->
      fs.readFile './theme/style/main.less', 'utf-8', cb
    
    (data, cb) ->
      less.render data,
        'paths': [ './theme/style/' ]
        'compress': yes
      , cb

    ({ css }, cb) ->
      fs.writeFile './public/assets/style.css', css, cb

  ], cb

content = (cb) ->
  console.log chalk.bold 'Metalsmith building content'

  # Source and destination.
  m = Metalsmith(__dirname)
  .source('./content')
  .destination('./public')
  
  m.use ->
    console.log 'Markdown'
    (do markdown).apply null, arguments
  
  m.use ->
    console.log 'Collections'
    collections({
      'posts':
        'pattern': 'clanky/*'
        'sortBy': 'date'
        'reverse': yes
    }).apply null, arguments

  m.use (files, metalsmith, done) ->
    console.log 'URLs'
    ( obj.path = file for file, obj of files )
    do done

  m.use ->
    console.log 'Render templates'
    templates({
      'engine': 'swig'
      'directory': './theme/templates'
    }).apply null, arguments

  m.build (err) ->
    console.log if (err) then chalk.red err else chalk.green.bold 'Done'
    cb err

async.parallel [ theme, content ], (err) ->
  throw err if err