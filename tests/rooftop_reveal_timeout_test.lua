for _,osName in ipairs{'Android','iOS'}do
 local now,ready,roof,progress=0,false,true,0
 love={system={getOS=function()return osName end},timer={getTime=function()return now end}}
 local game={overworld={map={id='CELADON_MART_ROOF'}}}
 local fields
 local scene={readyForReveal=function()return ready end,revealTimeout=function()if roof then return 60,3600,progress end end}
 local V={mod={id='VOXEL_ASCENDANT',_vascMobileDiagnostic={checkpoint=function(_,f)fields=f end}},require=function(n)
  if n=='VoxelScene'then return scene end
  if n=='LoadingCompanion'then return{probe=function()end}end
  error(n)
 end}
 local R=assert(loadfile('lib/TransitionReveal.lua'))(V)
 local P={worldPipeline=function()return'voxel'end,worldRevealReady=function()end}
 local callback=R.configure{Pipelines=P,Game=game,Schemas={REGISTRIES={render_pipelines={fields={revealReady={}}}}}}
 assert(not callback());now=3;assert(not callback(),'roof released by 2.5-second fallback')
 now=40;assert(not callback(),'unfinished skyline released')
 progress=1;assert(not callback());now=80;assert(not callback(),'progressing skyline timed out after 60 total seconds')
 ready=true;assert(callback(),'completed skyline held')
 ready=false;assert(callback(),'approved arrival reclosed')
 game.overworld.map={id='CELADON_MART_ROOF'};assert(not callback())
 now=140;assert(callback(),'terminal timeout strands player')
 assert(fields.timeoutSeconds==60,'wrong timeout diagnostic')
 roof=false;game.overworld.map={id='ORDINARY'};now=141;assert(not callback())
 now=144;assert(callback(),'ordinary phone safety timeout changed')
 print('PASS '..osName..' rooftop timeout: 3/40 seconds held, actual readiness releases, terminal recovery, ordinary timeout unchanged')
end
