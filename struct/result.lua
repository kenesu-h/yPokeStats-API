Result = {
  ok = false,
  err = false,
  val = nil
}

--[[
-- A Result<X, Y> is a {
--   is_ok: boolean,
--   err: boolean,
--   val: X or Y
-- }
--
-- A Result<X, Y> can either be an Ok<X> or an Err<Y>, like Rust's
-- implementation.
--
-- When is_ok is true, val's type must be X.
-- When is_ok is false, val's type must be Y.
--]]

--[[
-- Constructs a new Result<X, Y>. This is not meant to be used directly.
--
-- Arguments:
-- is_ok: boolean, whether the Result is an Ok.
-- val: X or Y, the value of the Result.
--
-- Returns:
-- The newly constructed Result.
--]]
function Result:new(is_ok, val)
  local result = {}
  result.is_ok = is_ok
  result.val = val
  return result
end

--[[
-- Constructs an Ok<X>. Represents an success containing a value of type X.
--
-- Argument:
-- val: X, the value of the Ok.
--
-- Returns:
-- The newly constructed Ok.
--]]
function Ok(val)
  return Result:new(true, val)
end

--[[
-- Constructs an Err<X>. Represents an error containing a value of type X.
--
-- Argument:
-- val: X, the value of the Err.
--
-- Returns:
-- The newly constructed Err.
--]]
function Err(val)
  return Result:new(false, val)
end
