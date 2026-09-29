return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'))
 local Rig=assert(loadfile(root..'/integrated/ascendant_pokemon_overworld/src/human_rig.lua'))()
 local profiles=assert(loadfile(root..'/integrated/ascendant_pokemon_overworld/src/human_rig_profiles.lua'))()
 local g=love.graphics
 local format={{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexShade','float',1}}
 local voxel={newMesh=function(v,i)local m=g.newMesh(format,v,'triangles','dynamic');m:setVertexMap(i);return m end,
  pushQuad=function(indices,b)local n=b*4;for _,i in ipairs{1,2,3,1,3,4}do indices[#indices+1]=n+i end end}
 local data=love.image.newImageData(192,256)
 for y=0,255 do for x=0,191 do data:setPixel(x,y,(x%17)/16,(y%19)/18,((x+y)%23)/22,1)end end
 local texture=g.newImage(data);data:release()
 local source={texture=texture,bounds={}}
 for row=0,3 do source.bounds[row]={};for col=0,2 do source.bounds[row][col]={left=col*64+4,right=col*64+60,top=row*64+2,bottom=row*64+62}end end
 local warm,cold=Rig.new(voxel,profiles),Rig.new(voxel,profiles)
 local atlas='red_cards_4x3.png';local role='red'
 assert(not warm:prewarm(source,'unknown',atlas))
 for i=1,12 do local previous=warm.metrics.composites;assert(warm:prewarm(source,role,atlas));assert(not warm.error,warm.error);assert(warm.metrics.composites==previous+1,'more than one composite per preparation step')end
 assert(not warm:prewarm(source,role,atlas),'finished source restarted')
 local record={role=role,def={ascendantAtlasImage=atlas},humanMotion={distance=12,idleShift=.2}}
 local original=voxel.newMesh({{0,0,0,0,0,1},{16,0,0,1/3,0,1},{16,16,0,1/3,1/4,1},{0,16,0,0,1/4,1}},{1,2,3,1,3,4})
 for row=0,3 do for col=0,2 do
  local wm,wt=warm:prepare(record,original,source,row,col);assert(wm and wt,warm.error)
  local cm,ct=cold:prepare(record,original,source,row,col);assert(cm and ct,cold.error)
  local a,b=wt:newImageData(),ct:newImageData();assert(a:getString()==b:getString(),'preparation changed pixels');a:release();b:release()
 end end
 assert(warm.metrics.composites==12,'draw rebuilt prepared composites')
 assert(record.humanMotion.distance==12 and record.humanMotion.idleShift==.2,'preparation advanced animation')
 warm:clear();cold:clear();assert(warm.metrics.residentComposites==0 and warm.metrics.residentMeshes==0,'clear retained GPU resources')
 local failed=Rig.new(voxel,profiles);local allocate=g.newCanvas
 g.newCanvas=function()error('QA optional composite allocation rejected')end
 assert(failed:prewarm(source,role,atlas));assert(failed.error and not failed:prewarm(source,role,atlas),'optional failure loops loading')
 g.newCanvas=allocate;failed:clear();texture:release();original:release()
 print('PASS_HUMAN_PREWARM: 12 exact composites, one per step, draw reuse, stable pose, cleanup, terminal optional failure');love.event.quit(0)
end
