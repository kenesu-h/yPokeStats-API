--[[
-- An Option<X> is a {
--   is_some: boolean,
--   val: X
-- }
--
-- An Option<X> can be either a None or a Some<X>, like Rust's implementation.
--
-- When is_some is true, val's type must be X.
--]]
Option = {
  is_some = false,
  val = nil
}

--[[
-- Constructs a new Option<X>. This is not meant to be used directly.
--
-- Arguments:
-- is_some: boolean, whether the Option is a Some.
-- val: X, the value of the Option
--
-- Returns:
-- The newly constructed Option.
--]]
function Option:new(is_some, val)
  local option = {}
  option.is_some = is_some
  option.val = val
  return option
end

--[[
-- Constructs a None. Represents the absence of a value (not to be confused with
-- nil in Lua). Cannot be unwrapped.
--
-- Returns:
-- The newly constructed None.
--]]
function None()
  return Option:new(false, nil);
end

--[[
-- Constructs a Some<X>. Represents the presence of a value of type X.
--
-- Argument:
-- val: X, the value of the Some.
--
-- Returns:
-- The newly constructed Some.
--]]
function Some(val)
  return Option:new(true, val);
end

--[[
-- Unwraps the value of type X contained within an Option<X>.
--
-- Returns:
-- The wrapped value.
--
-- Errors:
-- If unwrap is used on a None.
--]]
function Option:unwrap()
  if self.is_some then
    return self.val
  else
    error("Cannot unwrap a value from a None.")
  end
end
