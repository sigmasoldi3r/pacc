--[[
  Flywheel test package.
]]
local Db = require 'flywheel'

fs.delete 'test.db'

local test = Db.open 'test.db'

test:insert(
  { name = 'Ganja', rank = 'Squad', members = 1 },
  { name = 'The Foo', rank = 'Figher', members = 5 }
):into 'groups'

local groups = test:select():from('groups'):all()

groups[1].name = 'Ganja 2'

test:update({
  groups[1]
}):from 'groups'

assert(#groups == 2, 'All did not return the whole scheme.')

groups =
  test:select(
    'id',
    ('name') :as 'nick',
    ('rank') :as 'mode',
    'members')
  :from('groups')
  :all()
local ganja, foo = groups[1], groups[2]

assert(ganja.nick == 'Ganja 2', 'Invalid mapping: name did not map to nick')
assert(ganja.mode == 'Squad', 'Invalid mapping: rank did not map to mode')
assert(ganja.members == 1, 'Invalid mapping: members did not select')

print 'All OK - 4 tests passed'

fs.delete 'test.db'
