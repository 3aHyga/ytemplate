#!/usr/bin/ruby

require File.expand_path('../spec_helper', __FILE__)

describe 'Eventer' do
  it "Expand of a template" do
    tmpl = YAML::Template.new SampleTemplate

    o = tmpl.deploy

    raise "Resulted YAML-document is wrong" if o != YAML.load( SampleResultTemplate )
  end

  it "Expand of a document" do
    tmpl = YAML::Template.new SampleTemplate

    o = tmpl.deploy_to( YAML.load( SampleFile ), :use_template => true)

    raise "Resulted YAML-document is wrong" if o != YAML.load( SampleResultDocument )
  end

  it "Document match to the template" do
    tmpl = YAML::Template.new SampleTemplate

    o = tmpl.match(YAML.load( SampleFile) )

    raise "Resulted YAML-document is wrong" unless o.empty?
  end

  it "Erroneous document match to the template" do
    tmpl = YAML::Template.new SampleTemplate

    file = YAML.load( SampleFile )
    file['key1'] = 'novalue'

    o = tmpl.match( file )

    raise "Resulted YAML-document is wrong" if o.empty?
  end
end


