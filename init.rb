# Stub to invoke real init.rb when GlobalSession is installed as a vendored
# Rails plugin.
basedir = File.dirname(__FILE__)
require File.join(basedir, 'rails', 'init')
