#!/usr/bin/ruby -KU
# encoding: utf-8

require 'yaml'
require 'rdoba/re'
require 'rdoba/debug'
require 'rdoba/deploy'
require 'rdoba/yaml'

module YAML
  class Template

#  def puts(*args)
#    File.open('yaml_t.log','a') do |f| f.puts(*args) end
#  end

    @@errors = {
      :dict_unallow   => 'Словарь не допустим на уровне %i',
      :var_undef      => 'Переменная %s не определена',
      :no_tmpl_str    => 'Значение строки шаблона отсутствует',
      :added          => 'Переменная \'%s\' добавлена',
    }

  private

    def deploy_verility(content)
      @verility_template = YAML.load( StringIO.new content.to_s ).deploy
      deploy_value(@verility_template)
    end

    def deploy_value(value)
      @levelno ? @levelno += 1 : @levelno = 0
      res = case value.class.to_s
      when 'Hash'
        unless value.class == Hash
          @levelno -= 1
          raise @@errors[:dict_unallow] % @levelno
        end

        value.each_pair do |tkey, tvalue|
          if tkey =~ /^(.*)=$/ and not @vars.keys.include? $1
            dbp12 "[deploy_value]> #{@@errors[:added] % $1}"
            @vars[$1] = tvalue
            value.delete(tkey)
          end
        end

        err = []
        unless (value.each_pair do |tkey, tvalue|
              begin
                if tkey =~ /^%(.*)$/
                  raise @@errors[:var_undef] % $1 unless @vars.keys.include? $1
                  value.delete(tkey)
                  @vars[$1].each_pair do |k,v| value[k] = v; end
                else
                  break false unless deploy_value(tkey)
                end
                break false unless deploy_value(tvalue)
              rescue
                $stderr.puts "Exception: #{$!}\n\t#{$@.join("\n\t")}"
                err << $!.to_s
                break false
              end
            end)
          @levelno -= 1
          raise err.join(',')
        end

      when 'Array'
        err = []
        unless (value.each do |tvalue|
              begin
                break false unless deploy_value(tvalue)
              rescue
                $stderr.puts "Exception: #{$!}\n\t#{$@.join("\n\t")}"
                err << $!.to_s
                break false
              end
            end)
          @levelno -= 1
          raise err.join(',')
        end

      when 'String'
        if value == ''
          @levelno -= 1
          raise @@errors[:no_tmpl_str]
        end

      else
      end

      @levelno -= 1
      true
    end

    def initialize(verility_template)
      @levels = []
      @vars = {}
      deploy_verility(verility_template)
    end

    public

    def deploy
      @verility_template.clone
    end

    def deploy_to(inval, options = {})
      # options:
      # required: array - field list in hash that is required to be shewn
      # use_template: true | +false
      # expand_level: integer - force expand upto the specified level( or -1 to full) the hash and array
      dbp11 "[deploy_to] <<< #{inval.inspect}, #{options.inspect}"
      options = { :required => [], :use_template => false, :expand_level => 0 } | options
      options[:expand_level] = -1 if options[:expand_level].class != Fixnum

      hash = @verility_template.clone

      def deploy_array_to(form, tform, options = {})
        dbp11 "[deploy_array_to] <<< form = #{form.inspect}, tform = #{tform.inspect}, options = #{options.inspect}"
        tidx = -tform.size
        expand = options[:expand_level]
        form.reverse.each do |value|
          expand = true
          dbp14 "[deploy_array_to]> #{value.inspect} <<< #{tform[0].inspect}"
          case value.class.to_s
          when 'Hash'
            deploy_hash_to(value, tform[0], options)
          when 'Array'
            deploy_array_to(value, tform[0], options)
          when 'String'
            if tform[0] =~ /@.*@(.*)$/
              # - matched array value /@expr@/ =~ '@.*@'
              value.replace(tform[0] + value)
            end
          end
        end

        if options[:expand_level] < 0
          tform.reverse.each do |tvalue|
          dbp12 "[deploy_array_to]> Append: #{tvalue.inspect}"
          form.push(tvalue)
          end
        end
        dbp11 "[deploy_array_to] >>> #{form.inspect}"
      end

      def crop_to(level, value)
        dbp14 "[crop_to] <<< level = #{level.inspect}, value = #{value.inspect}"
        level -= 1 if level > 0
        res = case value.class.to_sym
        when :Hash
          res = {}
          value.each do |k,v| res[k] = level != 0 && crop_to(level, v) || nil end if level != 0
          res
        when :Array
          res = []
          value.each do |v|
            res << crop_to(level, v)
          end if level != 0
          res
        else
          value
        end
        dbp14 "[crop_to] >>> #{res.inspect}"
        res
      end

      def deploy_hash_to(form, tform, options = {})
        dbp11 "[deploy_hash_to] <<< form = #{form.inspect}, tform = #{tform.inspect}, options = #{options.inspect}"
        rplc = {}
        expand = options[:expand_level] || (not (options[:required].empty? ||
          options[:required].each do |x| break false if tform.key?(x) end ))
        form.each_pair do |key, value|
          expand = true
          tform.each_pair do |tkey, tvalue|
            dbp12 "[deploy_hash_to]> Check #{tkey} => #{key}"
            if tkey =~ /^\/([^\/]+)/ and key =~ /#{$1}/ and key !~ /^\//
              # matched hash key /(sr|...)/ =~ 'sr'
	      p tkey, key, options
              if options[:use_template]
                nkey = tkey.gsub(key,"+#{key}")
                dbp12 "[deploy_hash_to]> Replace key #{key} => #{nkey}"
                rplc[key] = nkey
              end
              key = tkey
            end

            if tkey == key
              dbp14 "[deploy_hash_to]> Try deploy #{key}: #{value.inspect} <= #{tvalue.inspect}"
              break case value.class.to_s
              when 'Hash'
                deploy_hash_to(value, tvalue, options)
              when 'Array'
                deploy_array_to(value, tvalue, options)
	      when 'String'
		value.insert(0, '+') if tvalue == value
              end
            end
          end
        end

        rplc.each do |key,nkey| form[nkey] = form.delete(key); end

        if expand
          tform.each_pair do |tkey, tvalue|
            dbp14 "[deploy_hash_to]> Template pair: #{tkey.inspect} => #{tvalue.inspect}"
            if form.key?(tkey)
              dbp14 "[deploy_hash_to]> Form has template key: #{tkey.inspect}"
              basevalue = form[tkey]
              if tvalue.class == String
                dbp14 "[deploy_hash_to]> Try match string: #{basevalue.inspect} to string as re: #{tvalue.inspect}"
                if tvalue =~ /^\/(.*)/u and (re_s = $1) =~ /[\(\)]/ and basevalue.match(/#{re_s}/u)
                  # matched value /(sr|...)/ =~ 'sr'
                  form[tkey] = tvalue.sub(basevalue, '+' + basevalue)
                elsif tvalue =~ /@.*@(.*)$/
                  # matched value /@expr@/ =~ '@.*@'
                  form[tkey] = tvalue + basevalue + $1.to_s
                end
              end
            else
              dbp14 "[deploy_hash_to]> Form has NO template key: #{tkey.inspect}"
              basekey = tkey =~ /(.*)\[.*\]/
              form[tkey] = if basekey and form.key?($1)
                basevalue = form.delete($1)
                tvalue.sub(/#{basevalue}/, '+' + basevalue)
              else
                if options[:expand_level]
                  dbp14 "[deploy_hash_to]> Expand level >>> #{options[:expand_level].inspect}"
                  crop_to(options[:expand_level].to_i, tvalue)
                elsif tvalue.class == String
                  tvalue
                else
                  tvalue.dup.clear
                end if options[:expand_level].to_i != 0
              end
            end
          end
        end
      end

      inhash = if inval.class == String
        YAML.load(StringIO.new(inval)) || {}
      elsif inval.class == Hash
        inval
      else
        raise "The class '#{inval.class}' of the input parameter is undeploable"
      end

      begin
        deploy_hash_to(inhash, hash, options)
      rescue
        $stderr.puts "Error #{$!}\t#{$@.join("\n\t")}"
        return {}
      end

      dbp18 "[deploy_to]>>> output dump: vvv\n #{inhash.inspect}"

      dbp11 "[deploy_to] >>> #{inhash.to_yml}"

      inval.class == String ? inval.replace(inhash.to_yml) : inval.replace(inhash)
      inhash
    end

    def match(inval, options = {}) #TODO add path to a base value to match... ":key1:key2", to match to => key3:value
      # options:
      # required: array - field list in hash that is required to be shewn
      # use_template: true | +false
      # expand_level: integer - force expand upto the specified level( or -1 to full) the hash and array
      dbp11 "[match] <<< #{inval.inspect}, #{options.inspect}"
      options = { :required => [], :use_template => false, :expand_level => 0 } | options
      options[:expand_level] = -1 if options[:expand_level].class != Fixnum

      hash = @verility_template.clone

      err = []

      def crop_to(level, value)
        dbp14 "[crop_to] <<< level = #{level.inspect}, value = #{value.inspect}"
        level -= 1 if level > 0
        res = case value.class.to_sym
        when :Hash
          res = {}
          value.each do |k,v| res[k] = level != 0 && crop_to(level, v) || nil end if level != 0
          res
        when :Array
          res = []
          value.each do |v|
            res << crop_to(level, v)
          end if level != 0
          res
        else
          value
        end
        dbp14 "[crop_to] >>> #{res.inspect}"
        res
      end

      def match_string(path, value, tvalue, err, options = {})
        return if tvalue =~ /@.*@(.*)$/

	if value != tvalue
	  err << "#{path.join(':')} => #{value} =~ #{tvalue}"
	end
      end

      def match_array(path, form, tform, err, options = {})
        dbp11 "[match_array] <<< form = #{form.inspect}, tform = #{tform.inspect}, options = #{options.inspect}"
        tidx = -tform.size
        expand = options[:expand_level]
	size = from.size
        rform = form.reverse.each_index do |idx|
	  value = form[-idx - 1]
          expand = true
          dbp14 "[match_array]> #{value.inspect} <<< #{tform[0].inspect}"
	  npath = path.dup << size - idx - 1
          case value.class.to_s
          when 'Hash'
            match_hash(npath, value, tform[0], err, options)
          when 'Array'
            match_array(npath, value, tform[0], err, options)
          when 'String'
            match_array(npath, value, tform[0], err, options)
          end
        end

        dbp11 "[match_array] >>> #{form.inspect}"
      end

      def match_hash(path, form, tform, err, options = {})
        dbp11 "[match_hash] <<< form = #{form.inspect}, tform = #{tform.inspect}, options = #{options.inspect}"
        rplc = {}
        expand = options[:expand_level] || (not (options[:required].empty? ||
          options[:required].each do |x| break false if tform.key?(x) end ))
        form.each_pair do |key, value|
          expand = true
          tform.each_pair do |tkey, tvalue|
            dbp12 "[match_hash]> Check #{tkey} => #{key}"
            if tkey =~ /^\/([^\/]+)/ and key =~ /#{$1}/
              # matched hash key /(sr|...)/ =~ 'sr'
              if options[:use_template]
                nkey = tkey.gsub(key,"+#{key}")
                dbp12 "[match_hash]> Replace key #{key} => #{nkey}"
                rplc[key] = nkey
              end
              key = tkey
            end

            if tkey == key
              dbp14 "[match_hash]> Try match #{key} => #{value.inspect}"
	      npath = path.dup << key
              break case value.class.to_sym
              when :Hash
                match_hash(npath, value, tvalue, err, options)
              when :Array
                match_array(npath, value, tvalue, err, options)
              when :String
		match_string(npath, value, tvalue, err, options)
              end
            end
          end
        end

      end

      inhash = if inval.class == String
        YAML.load(StringIO.new(inval)) || {}
      elsif inval.class == Hash
        inval
      else
        raise "The class '#{inval.class}' of the input parameter is unmatchable"
      end

      begin
        match_hash([''], inhash, hash, err, options)
      rescue
        $stderr.puts "Error #{$!}\t#{$@.join("\n\t")}"
        return {}
      end

      dbp18 "[match]>>> output dump: vvv\n #{inhash.inspect}"

      dbp11 "[match] >>> #{inhash.to_yml}"

      inval.class == String ? inval.replace(inhash.to_yml) : inval.replace(inhash)
      err
    end
  end
end

