--[[
  Simple package manager.
  Package Manager ComputerCraft
  Usage is quite simple, you can add your own repositories to the .repos
  file.
  Each repo is any HTTP web that serves as monorepo.

  Installing
  ----------
  Installation is done by:
  wget https://raw.githubusercontent.com/sigmasoldi3r/pacc/main/pacc/pacc.lua pacc.lua
]]

-- First step, check if the ".repos" file exists and is valid.
if not fs.exists '.repos' then
  local file = io.open('.repos', 'w')
  -- This is generates the official repositories list.
  -- Later the user can expand that.
  file:write 'https://raw.githubusercontent.com/sigmasoldi3r/pacc/main\n'
  file:close()
end
local repos ; do
  repos = {}
  for line in io.lines '.repos' do
    repos[#repos + 1] = line
  end
end

-- Second, load the pacc database.
if not fs.exists '.pacc.db' then
  local file = io.open('.pacc.db', 'w')
  file:write('{"pacc": ["pacc.lua"]}')
  file:close()
end
local db ; do
  local fin = io.open('.pacc.db', 'r')
  local raw = fin:read('*all')
  fin:close()
  db = textutils.unserializeJSON(raw)
end

-- Utilities

local function updateDatabase()
  local fout = io.open('.pacc.db', 'w')
  fout:write(textutils.serializeJSON(db))
  fout:close()
end

local function writeFile(to, content)
  do
    local dirs = fs.getDir(to)
    if #dirs > 0 then
      fs.makeDir(dirs)
    end
  end
  local fout = io.open(to, 'w')
  fout:write(content)
  fout:close()
end

local resolvePackage

local installed = {}
local SKIP_RESOLUTION = false

-- Attempt to download from repo
local function tryDownloadFrom(repo, package)
  if installed[package] then
    print('  Found a cyclic dependency at ' .. package .. ', skipping.')
    return true
  end
  installed[package] = true
  -- Try download file raw.
  local res = http.get(repo .. '/' .. package .. '/info.json')
  if res ~= nil then
    local data = res.readAll()
    data = textutils.unserializeJSON(data)
    res.close()
    -- If could read, try downloading
    if data ~= nil then
      -- Install file by file as pointed in the manifest.
      for _, v in pairs(data.files) do
        local res = http.get(repo .. '/' .. package .. '/' .. v)
        local raw = res.readAll()
        res.close()
        print('    ' .. v .. '...')
        writeFile(v, raw)
      end
      db[package] = data.files
      if SKIP_RESOLUTION then return true end
      -- Resolve dependencies
      print 'Resolving dependencies...'
      if data.dependencies ~= nil then
        for _, v in pairs(data.dependencies) do
          print('   ' .. v .. '...')
          if not resolvePackage(v) then
            for _, v in pairs(files) do
              fs.remove(v)
            end
            error('Could not resolve dependency: ' .. v .. ', cleaning up...')
          end
        end
      end
      return true
    end
  end
  -- Could not download!
  return false
end

-- SUBCOMMAND PROCESSING
local function showHelp()
  term.clear()
  term.setCursorPos(1,1)
  print[[Basic usage:

  pacc <subcommand> [params]

Subcommands:
  pacc help                         
    - Shows this usage
  pacc install <package>
    - Installs a package
  pacc update      
    - Updates the packages, all are updated.
  pacc remove <package>             
    - Deletes all packages that match
      the glob pattern.
]]
end

resolvePackage = function(package)
  for _, repo in pairs(repos) do
    if tryDownloadFrom(repo, package) then
      return true
    end
  end
  return false
end

local function doInstall(package)
  if package == nil then error 'Missing package name!' end
  print('Installing ' .. package .. '...')
  if resolvePackage(package) then
    updateDatabase()
    return print 'Done!'
  end
  error('Could not install ' .. package .. ', not found.')
end

local function doUpdate()
  SKIP_RESOLUTION = true
  for package, files in pairs(db) do
    print(' Updating ' .. package .. '...')
    if not resolvePackage(package) then
      print('    WARNING: Could not update ' .. package .. '!')
    end
  end
end

local function doRemove(package)
  if package == nil then error 'Missing package name!' end
  print('Removing ' .. package .. '...')
  for name, files in pairs(db) do
    if name == package then
      db[name] = nil
      for k, v in pairs(files) do
        fs.delete(v)
      end
      updateDatabase()
      print('  Deleted ' .. #files .. ' files')
      return
    end
  end
  error('Package ' .. package .. ' not removed: Not found.')
end


-- Basic argument parsing
local args = {...}
if #args <= 0 then
  error [[Missing subcommand!
example:
  pacc help
]]
end
local subcom = args[1]

-- Run the main subcommands.
if subcom == 'help' then showHelp()
elseif subcom == 'install' then doInstall(args[2])
elseif subcom == 'update' then doUpdate()
elseif subcom == 'remove' then doRemove(args[2])
else
  error([[Unknown command "]] .. subcom .. [["!
See help by:
  pacc help
]])
end
