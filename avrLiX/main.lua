local translations = {en="avrLiX", de="avrLiX"}

local function name(widget)
    local locale = system.getLocale()
    return translations[locale] or translations["en"]
 
end

local function create()
    return {source=1, min=-1024, max=1024, value=0}
    --can be accessed with e.g. widget.souce
end
local function round(num, dp)
    --[[
    round a number to so-many decimal of places, which can be negative, 
    e.g. -1 places rounds to 10's,  a]]--
    local mult = 10^(dp or 0)
    return math.floor(num * mult + 0.5)/mult
end
local function paint(widget)

    local w, h = lcd.getWindowSize()

    if widget.voltageSource == nil then
        return
    end

    -- Define positions
    if h < 50 then
        lcd.font(FONT_S)
    elseif h < 80 then
        lcd.font(FONT_L)
    elseif h > 170 then
        lcd.font(FONT_XL)
    else
        lcd.font(FONT_STD)
    end

    local text_w, text_h = lcd.getTextSize("")
    local box_top, box_height = text_h, h - text_h - 4
    local box_left, box_width = 4, w - 8

    -- Source name and value
    lcd.drawText(box_left, 0, widget.voltageSource:name())
    lcd.drawText(box_left + box_width, 0, widget.voltageSource:stringValue(), RIGHT)
   
    --Calculate remaining percentage

    local remainingPercentage =  (widget.avgCellVoltage-widget.minCellVoltage)/(widget.maxCellVoltage-widget.minCellVoltage)

    -- background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)
    
    --Voltage bar with color-changing according voltage
    if (widget.avgCellVoltage >=widget.lowAlarmVoltage) then
        lcd.color(GREEN)
    else
        if (widget.avgCellVoltage<widget.lowAlarmVoltage and widget.avgCellVoltage>=widget.criticalAlarmVoltage) then
            lcd.color(YELLOW)
        else
            lcd.color(RED)
        end
    end
    local gauge_width = (((box_width - 2)) * remainingPercentage) + 2
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    --average Voltage Text
    lcd.color(BLACK)
    lcd.font(FONT_L)
    
    local voltageUnit =""

    if (system.getLocale() == "de") then
        voltageUnit = " V/Zelle"
    else
        voltageUnit = " V/Cell"
    end
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2, round(widget.avgCellVoltage,2)..voltageUnit, CENTERED)
end

local function wakeup(widget)
    local switch = widget.calloutSwitch
    local numCell = widget.numberCells

    --First init of values (to prevent nil-Errors)
    if (widget.sourceValue) == nil then
        widget.sourceValue = 0
    end

    if widget.timeReadout == nil then
        widget.timeReadout = os.time()
    end
    if widget.timeLowAlarmReadout == nil then
        widget.timeLowAlarmReadout = os.time()
    end
    if widget.timeCriticalAlarmReadout == nil then
        widget.timeCriticalAlarmReadout = os.time()
    end

    if widget.repeatReading == nil then
        widget.repeatReading = false
    end
    if widget.lowAlarmCallout == nil then
        widget.lowAlarmCallout = false
    end
    if widget.criticalAlarmCallout ==nil then
        widget.criticalAlarmCallout = false
    end

    --trigger Refresh screen and value if coltageSource changes
    if widget.voltageSource then
        local newValue = widget.voltageSource:value()
        if widget.sourceValue ~= newValue then
            widget.sourceValue = newValue
            lcd.invalidate()
        end
    end
    --Calcualte avg Voltage
    widget.avgCellVoltage = widget.sourceValue / numCell

    --Play Voltage when switch is triggered and repeat
 if switch:state()  then
    if widget.repeatReading == true then
        system.playNumber(widget.avgCellVoltage,UNIT_VOLT,2)
        widget.repeatReading=false
    end
    --Repeate only every x seconds
    if (os.time()-widget.timeReadout)>widget.repeatSeconds then
        widget.timeReadout=os.time()
        widget.repeatReading=true    
    end
else
    widget.repeatReading = true
    widget.timeReadout=os.time()
end

--AlarmVoltage Readout
if (widget.avgCellVoltage <= widget.lowAlarmVoltage 
    and widget.avgCellVoltage > widget.criticalAlarmVoltage
    and widget.lowAlarmCallout == false
    ) then
        --Play alarm only when avg Voltage only x seconds under thresshold
        if (os.time() - widget.timeLowAlarmReadout) >= widget.waitSecondsLowAlarm then
            system.playFile("vollow.wav")
            widget.lowAlarmCallout = true
        end
elseif widget.avgCellVoltage > widget.lowAlarmVoltage then
    widget.lowAlarmCallout = false
    widget.timeLowAlarmReadout = os.time()
end

if widget.avgCellVoltage <= widget.criticalAlarmVoltage and widget.criticalAlarmCallout == false then
    --Play alarm only when avg Voltage only x seconds under thresshold
    if (os.time() - widget.timeCriticalAlarmReadout) >= widget.waitSecondsCriticalAlarm then
        system.playFile("volCrit.wav")
        widget.criticalAlarmCallout = true
    end
elseif widget.avgCellVoltage > widget.criticalAlarmVoltage then
    widget.criticalAlarmCallout = false
    widget.timeCriticalAlarmReadout = os.time()
end

end --function

local function configure(widget)
    line = form.addLine("Source")
    form.addSourceField(line, nil, function() return widget.voltageSource end, function(value) widget.voltageSource = value end)
    line = form.addLine("Callout Switch / Repeat")
    local r  = form.getFieldSlots(line,{0,0})
    form.addSwitchField(line, r[1], function() return widget.calloutSwitch end, function(value) widget.calloutSwitch = value end)
    local field = form.addNumberField(line, r[2],0, 60, function() return widget.repeatSeconds end, function(value) widget.repeatSeconds = value end)
    field:suffix(" s")
    field:default(30)
    line = form.addLine("Number Cell's")
    local field = form.addNumberField(line, nil,1, 20, function() return widget.numberCells end, function(value) widget.numberCells = value end)
    field:suffix(" Cells")
    field:default(1)
    line = form.addLine("min/max Voltage")
    local r  = form.getFieldSlots(line,{0,0})
    local field = form.addNumberField(line, r[1],1, 50, function() return widget.minCellVoltage*10 end, function(value) widget.minCellVoltage = value/10 end)
    field:suffix(" V")
    field:decimals(1)
    field:default(30)
    local field = form.addNumberField(line, r[2],1, 50, function() return widget.maxCellVoltage*10 end, function(value) widget.maxCellVoltage = value/10 end)
    field:suffix(" V")
    field:decimals(1)
    field:default(30)
    line = form.addLine("low Alarm V/delay")
    local r  = form.getFieldSlots(line,{0,0})
    local field = form.addNumberField(line, r[1],1, 50, function() return widget.lowAlarmVoltage*10 end, function(value) widget.lowAlarmVoltage = value/10 end)
    field:suffix(" V")
    field:decimals(1)
    field:default(30)
    local field = form.addNumberField(line, r[2],0, 20, function() return widget.waitSecondsLowAlarm end, function(value) widget.waitSecondsLowAlarm = value end)
    field:suffix(" s")
    field:default(1)
    line = form.addLine("critical Alarm V/delay")
    local r  = form.getFieldSlots(line,{0,0})
    local field = form.addNumberField(line, r[1],1, 50, function() return widget.criticalAlarmVoltage*10 end, function(value) widget.criticalAlarmVoltage = value/10 end)
    field:suffix(" V")
    field:decimals(1)
    field:default(30)
    local field = form.addNumberField(line, r[2],0, 20, function() return widget.waitSecondsCriticalAlarm end, function(value) widget.waitSecondsCriticalAlarm = value end)
    field:suffix(" s")
    field:default(1)


end --function

local function read(widget)
    widget.calloutSwitch = storage.read("calloutswitch")
    widget.numberCells = storage.read("numbercells")
    widget.minCellVoltage = storage.read("mincellvoltage")
    widget.maxCellVoltage = storage.read("maxcellvoltage")
    widget.voltageSource = storage.read("voltagesource")
    widget.repeatSeconds = storage.read("repatseconds")
    widget.lowAlarmVoltage = storage.read("lowalarmvoltage")
    widget.criticalAlarmVoltage = storage.read("criticalalarmvoltage")
    widget.waitSecondsLowAlarm = storage.read("waitsecondslowalarm")
    widget.waitSecondsCriticalAlarm = storage.read("waitsecondscriticalalarm")
end

local function write(widget)
    storage.write("calloutswitch",widget.calloutSwitch)
    storage.write("numberCells",widget.numberCells)
    storage.write("mincellvoltage",widget.minCellVoltage)
    storage.write("maxcellvoltage",widget.maxCellVoltage)
    storage.write("voltagesource",widget.voltageSource)
    storage.write("repatseconds",widget.repeatSeconds)
    storage.write("lowalarmvoltage",widget.lowAlarmVoltage)
    storage.write("criticalalarmvoltage",widget.criticalAlarmVoltage)
    storage.write("waitSecondsLowAlarm",widget.waitSecondsLowAlarm)
    storage.write("waitsecondscriticalalarm",widget.waitSecondsCriticalAlarm)
end

local function init()
    system.registerWidget({key="avrvolt", name=name, create=create, paint=paint, wakeup=wakeup, configure=configure, read=read, write=write})
end

return {init=init}