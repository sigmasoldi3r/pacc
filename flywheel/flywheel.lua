--[[
  Flywheel simple DBMS

  Inspired by SQLite, with MongoDB storage style (Documents and object queires).
]]
local pandora = require 'pandora'
local class, static = pandora.class, pandora.static

local DBMS_VERSION = 1

local Database

function string:as(what)
  return {
    from = self,
    as = what
  }
end

----
-- Database manager.
----
Database = class 'Database' {
  Database = function(this, target)
    this._target = target
  end,

  read = function(this)
    local file = io.open(this._target, 'r')
    local data = file:read '*all'
    file:close()
    return Database.decode(data)
  end,

  write = function(this, data)
    local file = io.open(this._target, 'w')
    file:write(Database.encode(data))
    file:close()
  end,

  -- Creates a table, if not exists.
  create = function(this, tbl)
    local data = this:read()
    if data.tables[tbl] == nil then
      data.tables[tbl] = {}
      data.last_id[tbl] = 0
    end
    this:write(data)
  end,

  -- Remove table, if exists.
  drop = function(this, tbl)
    local data = this:read()
    data.tables[tbl] = nil
    data.last_id[tbl] = nil
    this:write(data)
  end,

  -- Deletes matching records by ID or uses the query functor.
  delete = function(this, where)
    return {
      from = function(_, tbl)
        this:create(tbl)
        if where == nil then
          this:truncate(tbl)
        elseif type(where) == 'function' then
          local data = this:read()
          local rows = data.tables[tbl]
          local out = {}
          for _, v in pairs(rows) do
            if not where(v) then
              out[#out + 1] = v
            end
          end
          data.tables[tbl] = out
          this:write(data)
        elseif type(where) == 'table' then
          local targets = {}
          for _, v in pairs(where) do
            targets[v.id] = true
          end
          local data = this:read()
          local rows = data.tables[tbl]
          local out = {}
          for _, v in pairs(rows) do
            if not targets[v.id] then
              out[#out + 1] = v
            end
          end
          data.tables[tbl] = out
          this:write(data)
        end
      end
    }
  end,

  -- Delete, without where.
  truncate = function(this, tbl)
    local data = this:read()
    data.tables[tbl] = {}
    this:write(data)
  end,

  -- Updates entities by matching IDs.
  update = function(this, input)
    return {
      from = function(_, tbl)
        local data = this:read()
        local rows = data.tables[tbl]
        local targets = {}
        for _, v in pairs(input) do
          targets[v.id] = v
        end
        for k, v in pairs(rows) do
          if targets[v.id] ~= nil then
            rows[k] = targets[v.id]
          end
        end
        this:write(data)
      end
    }
  end,

  -- Inserts into the table.
  insert = function(this, ...)
    local ents = {...}
    return {
      into = function(_, tbl)
        this:create(tbl)
        local data = this:read()
        local _tbl = data.tables[tbl]
        for _, v in pairs(ents) do
          v.id = data.last_id[tbl] + 1
          data.last_id[tbl] = data.last_id[tbl] + 1
          _tbl[#_tbl + 1] = v
        end
        this:write(data)
      end
    }
  end,

  -- Selects from tables.
  select = function(this, ...)
    local what = {...}
    return {
      -- Chooses the table to select from.
      from = function(_, tbl)
        local data = this:read()
        local _tbl = data.tables[tbl]
        return {
          -- Selects all, limits if neccessary.
          all = function(_, limit)
            return this:select(table.unpack(what)):from(tbl):where(function()return true end, limit)
          end,
          -- Selects the only first, if any.
          one = function(_)
            return this:select(table.unpack(what)):from(tbl):all(1)[1]
          end,
          -- Selects all that apply, limited if provided.
          where = function(_, query, limit)
            local out = {}
            local i = 0
            -- For each entry in the database,
            for _, v in pairs(_tbl) do
              -- If the query succeeds (Filter function type)
              if query(v) then
                -- If no mapping (select) provided, copy as is.
                local obj = #what == 0 and v or {}
                -- Else, for each field provided:
                for _, map in pairs(what) do
                  -- If string, map as is field-to-field
                  if type(map) == 'string' then
                    obj[map] = v[map]
                  -- If function, the functor must return a key-value result.
                  elseif type(map) == 'function' then
                    local k, r = map(v)
                    obj[k] = r
                  -- If table, assume the { from = 'field-name', as = 'target-name' }.
                  -- This is returned when doing 'field' :as 'name'
                  elseif type(map) == 'table' then
                    obj[map.as] = v[map.from]
                  end
                end
                out[#out + 1] = obj
                i = i + 1
                if limit ~= nil and i >= limit then
                  return out
                end
              end
            end
            return out
          end
        }
      end
    }
  end,
}

Database.null = textutils.json_null

function Database.encode(object)
  return textutils.serializeJSON(object)
end

function Database.decode(text)
  return textutils.unserializeJSON(text, { parse_empty_array = false, parse_null = true })
end
  
----
-- Opens a new DB, creates it empty if does not exist.
----
function Database.open(target)
  if not fs.exists(target) then
    local file, err = io.open(target, 'w')
    if err ~= nil then return nil, err end
    file:write(Database.encode {
      version = DBMS_VERSION,
      tables = {},
      last_id = {}
    })
    file:close()
  end
  local file ; do
    local _file, err = io.open(target, 'r')
    if err ~= nil then return nil, err end
    file = _file
  end
  local header ; do
    local _header, err = Database.decode(file:read '*all')
    if err ~= nil then return nil, err end
    header = _header
  end
  if header.version > DBMS_VERSION then
    return nil, 'Database version is higher than installed, update the engine.'
  end
  return Database(target)
end

return Database
