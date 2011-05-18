#!/usr/bin/ruby -KU
# encoding: utf-8

require 'yaml'
require 'strscan'
require 'rdoba'

module YAML
  class TemplateMisc

#  def puts(*args)
#    File.open('yaml_t.log','a') do |f| f.puts(*args) end
#  end

    @@errors = {
    :unkn_class	    => 'Непонятный класс %s для присваиваемого ключа %s',
    :dict_unallow   => 'Словарь не допустим на уровне %i',
    :var_undef	    => 'Переменная %s не определена',
    :no_tmpl_str    => 'Значение строки шаблона отсутствует',
    :tmpl_undef	    => 'Не определён шаблон %s на уровне %i',
    :git_unfound    => 'Гит схов не найден в папке %s',
    :fold_unfound   => 'Папка %s для словаря не существует',
    :dict_unfound   => 'Словарь %s не найден во Гит схове',
    :cant_save	    => 'Невозможно сохранить изменения лексемы %s по причине %s',
    :create_ok	    => 'Лексема создана успешно',
    :update_ok	    => 'Лексема обновлена успешно',
    :added	    => 'Переменная \'%s\' добавлена',
    }

    def self.simply(hash, vars)
	hash.keys.each do |key|
	    vars[$1] = hash.delete(key) if key =~ /(.*)=$/
	end

	hash.keys.each do |key|
	    value = hash[key]
	    if key =~ /^%(.*)/
		var = vars[$1].clone
		if var.class == Hash
		    self.simply(var, vars)
		    hash.replace( hash.merge(var) )
		elsif var.class == String
		    hash[var] = nil
		else
		    raise "Unsupported variable #{$1} value class #{var.class}"
		end
		hash.delete(key)
		next
	    end

	    case value.class.to_s.to_sym
	    when :String
		hash[key] = vars[$1].clone if value =~ /^%(.*)/
	    when :Hash
		self.simply(value, vars)
	    end
	end
    end

    def rule
###	dbp21 "$$$ Строка '#{invalue}' == '#{tinvalue}'"
	# parse conditiones
	tvalue = ''
	ss = StringScanner.new(tinvalue)

	while ss.scan_until(/\[(.*)\]/)
	    if ss[1] =~ /(.*)=(.*)/
		ckey = $1
		cvalue = $2
		tvalue += ss.pre_match if begin
			@levels[-2].class == Hash and @levels[-2].key?(ckey) and match(@levels[-2][ckey], cvalue)
		    rescue
			false
		    end

###		dbp22 "$$$ Добавок в правило: #{tvalue}"
	    end
	end

	tvalue += ss.rest
###	dbp12 "$$$ Новое правило #{tvalue}"

    end

    def expand__(invalue, tinvalue)
    @levels << invalue
    res = case invalue.class.to_s
    when 'Hash'
	unless tinvalue.class == Hash
	    @levels.pop
	    raise "#{@levels.size}"
###	    raise "Словарь не допустим на уровне #{@levels.size}"
	end

	tinvalue.each_pair do |tkey, tvalue|
	    if tkey =~ /^(.*)=$/ and not @vars.keys.include? $1
###		dbp22 "### Переменная '#{$1}' добавлена"
		@vars[$1] = tvalue
		tinvalue.delete(tkey)
	    end
	end

	tinvalue.each_pair do |tkey, tvalue|
	    if tkey =~ /^%(.*)$/
		raise "#{$1}" unless @vars.keys.include? $1
###		raise "Переменная #{$1} не определена" unless @vars.keys.include? $1
		tinvalue.delete(tkey)
		@vars[$1].each_pair do |k,v| tinvalue[k] = v; end
	    end
	end

    when 'Array'
    when 'String'
	if tinvalue == ''
	    @levels.pop
###	    raise "Значение строки шаблона отсутствует"
	end

    else
	@levels.pop
###	raise "Неизвестный класс #{value.class}"
    end

    @levels.pop
    true
    end

    def match(invalue, tinvalue)
    @levels << invalue
    res = case invalue.class.to_s
    when 'Hash'
	unless tinvalue.class == Hash
	    @levels.pop
	    raise "1 #{@levels.size}"
###	    raise "Словарь не допустим на уровне #{@levels.size}"
	end

	tinvalue.each_pair do |tkey, tvalue|
	    if tkey =~ /^(.*)=$/ and not @vars.keys.include? $1
###		dbp22 "### Переменная '#{$1}' добавлена"
		@vars[$1] = tvalue
		tinvalue.delete(tkey)
	    end
	end

	tinvalue.each_pair do |tkey, tvalue|
	    if tkey =~ /^%(.*)$/
		raise "#{$1}" unless @vars.keys.include? $1
###		raise "Переменная #{$1} не определена" unless @vars.keys.include? $1
		tinvalue.delete(tkey)
		@vars[$1].each_pair do |k,v| tinvalue[k] = v; end
	    end
	end

	invalue.each_pair do |key, value|
	    err = []
	    errup = tinvalue.each_pair do |tkey, tvalue|
		begin
		    break false if match(key, tkey) and match(value, tvalue)
		rescue
		    err << $!
		    break true
		end
	    end
	    if errup
		@levels.pop
		key += ": #{value}" if value.class == String
###		raise "Пара с ключём '#{key}' не удовлетворяет шаблонной на уровне #{@levels.size}\n <= #{err.join(',')}\t"
	    end
	end
	true
    when 'Array'
	invalue.each do |value|
	    err = []
	    errup = tinvalue.each do |tvalue|
		begin
		    break false if match(value, tvalue)
		rescue
		    err << $!
		    break true
		end
	    end
	    if errup
		@levels.pop
###		val = " со значением #{value}" if value.class == String
###		raise "Массив#{val} не удовлетворяет шаблонному на уровне #{@levels.size}\n <= #{err.join(',')}"
	    end
	end
	true
    when 'String'
	if tinvalue == ''
	    @levels.pop
	    raise "2"
###	    raise "Значение строки шаблона отсутствует"
	end
	if invalue == ''
	    @levels.pop
	    raise "3"
###	    raise "Входное значение сроки отсутствует"
	end

###	dbp22 "$$$ Строка '#{invalue}' == '#{tinvalue}'"
	# parse conditiones
	tvalue = ''
	ss = StringScanner.new(tinvalue)

	while ss.scan_until(/\[(.*)\]/)
	    if ss[1] =~ /(.*)=(.*)/
		ckey = $1
		cvalue = $2
		tvalue += ss.pre_match if begin
			@levels[-2].class == Hash and @levels[-2].key?(ckey) and match(@levels[-2][ckey], cvalue)
		    rescue
			false
		    end

###		dbp22 "$$$ Добавок в правило: #{tvalue}"
	    end
	end

	tvalue += ss.rest
###	dbp22 "$$$ Новое правило #{tvalue}"

	if tvalue != ''

	    # match
	    (tvalue = /#{$1}/) if tvalue =~ /^\/([^\/]+)/

###	    dbp22 "$$$ Правило '#{invalue}' =~ '#{tvalue}'"

	    res = (invalue =~ tvalue)
###	    dbp22 "$$$ Попало? #{not not res}"

	    res
	else
	    false
	end
    else
	@levels.pop
	raise "333 #{value.class}"
###	raise "Неизвестный класс #{value.class}"
    end

    @levels.pop
    res
    end
  end
end

