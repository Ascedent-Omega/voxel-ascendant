-- Real local calendar, deliberately independent of Weather's compressed year.
local V=...
local M={events={spring={month=4,first=1,last=30},summer={month=7,first=1,last=31},halloween={month=10,first=1,last=31},winter={month=12,first=1,last=31}},elapsed=1}
M.setting=V.require('ModSetting').new('calendarEvents','MONTHLY EVENTS',
 {'auto','off','spring','summer','halloween','winter'},{'AUTO','OFF','SPRING PREVIEW','SUMMER PREVIEW','HALLOWEEN PREVIEW','WINTER PREVIEW'},'auto')
function M.at(date)
 if type(date)~='table' or type(date.month)~='number' or type(date.day)~='number'
  or date.month%1~=0 or date.day%1~=0 then return nil end
 for id,event in pairs(M.events)do
  if date.month==event.month and date.day>=event.first and date.day<=event.last then return id end
 end
end
function M.update(dt)
 M.elapsed=M.elapsed+math.max(0,math.min(1,tonumber(dt)or 0))
 if M.elapsed<1 then return end
 M.elapsed=0
 local ok,date=pcall(function()return os.date('*t')end)
 M.current=ok and M.at(date)or nil
end
function M.active(id)
 local selected=M.setting:get()
 return selected=='auto' and M.current==id or selected==id
end
function M.hash(text)
 local h=29
 for i=1,#text do h=(h*131+text:byte(i))%65521 end
 return h
end
return M
