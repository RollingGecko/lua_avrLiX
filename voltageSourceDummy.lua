-- Lua Source Example

local translations = {en="Voltage Dummy", fr="Voltage Dummy"}

local function name(widget)
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local function sourceInit(source)
  source:value(25.2)
  source:decimals(2)
  source:unit(UNIT_VOLT)
end

local function sourceWakeup(source)
  source:value(source:value() - 0.1)
  if source:value() <= 18.0 then
    source:value(25.2)
  end
end

local function init()
  system.registerSource({key="VolDum", name=name, init=sourceInit, wakeup=sourceWakeup})
end

return {init=init}