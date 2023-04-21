-- Lua Source Example

local translations = {en="reg_VoltDum", fr="reg_VoltDum"}

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
  local throttleValue = system.getSource({name="K3"}):value()
  local percent = throttleValue/1000
  local value = 25.2 * percent
  source:value(value)

end

local function init()
  system.registerSource({key="VDumReg", name=name, init=sourceInit, wakeup=sourceWakeup})
end

return {init=init}