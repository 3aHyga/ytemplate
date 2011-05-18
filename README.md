# YAML-шаблонъ

YAML-шаблонъ есть расширитель YAML модели шаблонами. Онъ позволяетъ расшрирять любой YAML-документъ, предоставляя пользователю развёртывать и проверять его по опредѣлённому шаблону.

## Использованіе

### Простая развёртка

    require 'ytemplate'

    SampleTemplate = <<C
    ---
    local=:
      lkey: lvalue
    key1: value
    key2: %local
    key3:
      %local:
      key4: value
    C

    tmpl = YAML::Template.new SampleTemplate

    o = tmpl.deploy # => {"key1"=>"value", "key2"=>{"lkey"=>"lvalue"}, "key3"=>{"lkey"=>"lvalue", "key4"=>"value"}}
    puts o.to_yaml
    # ---
    # key1: value
    # key2:
    #   lkey: lvalue
    # key3:
    #   lkey: lvalue
    #   key4: value


### Развёртка въ иной YAML-документъ

    SampleFile = <<C
    ---
    key1: value
    key2:
      lkey: lvalue
    key3:
      lkey: lvalue
      key4: value
    C

    o = tmpl.deploy_to( YAML.load( SampleFile) ) # => {"key1"=>"+value", "key2"=>{"lkey"=>"+lvalue"}, "key3"=>{"lkey"=>"+lvalue", "key4"=>"+value"}}
    puts o.to_yaml
    # ---
    # key1: +value
    # key2:
    #   lkey: +lvalue
    # key3:
    #   lkey: +lvalue
    #   key4: +value

### Провѣрка подобности

Можно провѣрить, подобенъ ли YAML-документъ нѣкоему шаблону. Выходомъ метода 'match' будетъ Наборъ ошибокъ, представленныхъ въ видѣ текста.

    file = YAML.load( SampleFile )
    o = tmpl.match( file ) # => []

    file['key1'] = 'novalue'
    o = tmpl.match( file ) # => [":key1 => novalue =~ value"]

# Права

Авторскія и исключительныя права (а) 2011 Малъ Скрылевъ
Зри LICENSE за подробностями.

