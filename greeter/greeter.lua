-- Example of standalone library

-- A simple function exposed as a library.
return function(who)
  return function()
    return 'Hello, ' .. tostring(who) .. '!'
  end
end
