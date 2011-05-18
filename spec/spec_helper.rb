
require File.expand_path('../../lib/ytemplate', __FILE__)

RSpec.configure do |c|
  c.mock_with :rspec
end

SampleTemplate = <<C
---
@instance=:
  ikey: ivalue
local=:
  lkey: lvalue
key1: value
key2: %local
key3:
  %local:
  key4: value
C

SampleFile = <<C
---
key1: value
key2:
  lkey: lvalue
key3:
  lkey: lvalue
  key4: value
C

SampleResultTemplate = <<C
---
key1: value
key2:
  lkey: lvalue
key3:
  lkey: lvalue
  key4: value
C

SampleResultDocument = <<C
---
key1: +value
key2:
  lkey: +lvalue
key3:
  lkey: +lvalue
  key4: +value
C

