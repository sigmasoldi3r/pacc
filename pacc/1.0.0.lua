--[[{
  "name": "pacc",
  "version": "1.0.0",
  "author": "sigmasoldier",
  "dependencies": {}
}]]
--[[
  Simple package manager.
  PAckage ComputerCraft
  Usage is quite simple, you can add your own repositories to the .repos
  file.
  Each repo is any HTTP web that serves as monorepo.

  Repositories
  ------------
  Structure of the repositories: A simple file that lists other files as
  dependencies, in the first comment (JSON table!).
  Versioning is achieved by folder structure, dependencies can have version
  locking by semver.
  Each folder can have sub-files, if desired, but it should contain at least one
  entry file for the package named init.lua.
  If your package is intended to be an executable, a file should be ALWAYS
  provided, or else your users should run by inserting slashes in the command,
  which can be annoying and ugly.

  IMPORTANT: User should have a list of versions at .meta.json file, at the root
  of the package's folder, and the files that will be downloaded mapped there.

  Installing
  ----------
  Installation is done by:
  wget https://raw.githubusercontent.com/sigmasoldi3r/pacc/main/pacc/1.0.0.lua pacc.lua

  Then perform a package update by:
  pacc update *
]]

-- Completion options
shell.setCompletionFunction("pacc", function(shell, parNumber, curText, lastText)
	return {
    'help',
    'install',
    'update',
    'remove',
  }
end)


-- First step, check if the ".repos" file exists and is valid.
if not fs.exists '.repos' then
  local file = io.open('.repos', 'w')
  -- This is generates the official repositories list.
  -- Later the user can expand that.
  file:write 'https://raw.githubusercontent.com/sigmasoldi3r/pacc/main/\n'
  file:close()
end
local repos ; do
  repos = {}
  for line in io.lines '.repos' do
    repos[#repos + 1] = line
  end
end

local args = {...}
if #args <= 0 then
  error [[Missing subcommand!
example:
  pacc help
]]
end
local subcom = args[1]

-- Utilities

-- Converts a version (any) string to a pattern ready for matching.
local function versionAsPattern(version)
  if version:match'^%d+$' then
    version = version .. '.*.*'
  end
  if version:match'^%d+%.%d+$' then
    version = version .. '.*'
  end
  return version:gsub('%.', '%%.'):gsub('%*', '.-'):gsub('%.%-$', '.+')
end

-- Tells if the string is semver-like
local function isSemVer(version)
  return (version:match'.-%..-%..+') ~= nil
end

-- Takes a semver string, splits it into a k-v table.
local function explodeSemver(semver)
  local major, minor, patch = semver:match'(%d+)%.(%d+)%.(%d+)'
  return {
    major = major,
    minor = minor,
    patch = patch
  }
end

-- Returns a if higher than b, b elsewhere.
local function compareSemver(a, b)
  a = explodeSemver(a)
  b = explodeSemver(b)
  if a.major > b.major then
    return a
  end
  if a.major == b.major and a.minor > b.minor then
    return a
  end
  if a.major == b.major and a.minor == b.minor and a.patch > b.patch then
    return a
  end
  return b
end

-- Sorts and takes the highest (newest) of the version array
local function highestSemver(versions)
  local highest = nil
  for _, version in pairs(matching) do
    if highest == nil then
      highest = version
    else
      highest = compareSemver(version, highest)
    end
  end
  return highest
end

local function tryDownloadFrom(repo, package, version)
  if fs.exists(package) then
    error('Package ' .. package ..  ' is already installed.')
  end
  -- Try download file raw.
  local res = http.get(repo .. '/' .. package .. '/.meta.json')
  if res ~= nil then
    local data = request.readAll()
    data = textutils.unserializeJSON(data)
    res.close()
    -- If could read, try looking up the version.
    if data ~= nil then
      -- Lookup the highest semver version, if any.
      -- That counts as "published", if not tagged.
      local pat = versionAsPattern(version or '*.*.*')
      local matching = {}
      -- Filter coincident versions
      for version in pairs(data) do
        if version:match(pat) then
          matching[#matching + 1] = version
        end
      end
      -- Choose the highest
      local highest = highestSemver(matching)
      -- Install the found one, file by file as pointed in the manifest.
      local files = data[highest]
      for k, v in pairs(files) do
        print('   ' .. v .. '...')
        local res = http.get(repo .. '/' .. package .. '/' .. k)
        local raw = res.readAll()
        res.close()
        local fout = io.open(v, 'w')
        fout:write(raw)
        fout:close()
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
  pacc install <package> [version]
    - Installs a package
  pacc update [package]            
    - Updates the packages that match
      the glob, if provided. If not
      provided, all are updated.
  pacc remove <package>             
    - Deletes all packages that match
      the glob pattern.
]]
end

local function doInstall()
  if #args <= 1 then error 'Missing package name!' end
  local package = args[2]
  local version = args[3]
  print('Installing ' .. package .. '...')
  for repo in pairs(repos) do
    if tryDownloadFrom(repo, package, version) then
      return print('Done!')
    end
  end
  error('Could not install ' .. package .. (version and (' ' .. version) or '') .. ', not found.')
end

local function doUpdate()

end

local function doRemove()

end

-- Run the main subcommands.
if subcom == 'help' then showHelp()
elseif subcom == 'install' then doInstall()
elseif subcom == 'update' then doUpdate()
elseif subcom == 'remove' then doRemove()
else
  error([[Unknown command "]] .. subcom .. [["!
See help by:
  pacc help
]])
end
