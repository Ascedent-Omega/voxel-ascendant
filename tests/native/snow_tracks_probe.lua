return function(V,game)
 local D=V.require('DeepSnow');local S=V.require('SnowTracks');local world=game.overworld or game.world
 local cells,origin=D.cells,D.cellOrigin;assert(cells and origin)
 local chosen,best
 local m=V.require('Voxel3D').vp
 for iz=-D.RADIUS+3,D.RADIUS-3 do for ix=-D.RADIUS+3,D.RADIUS-7 do
  local good=true;for dx=0,4 do if not(cells[iz]and cells[iz][ix+dx])then good=false;break end end
  if good then
   local c=cells[iz][ix];local x,z=c.x+16,c.z+4;local y=c.base+2
   local w=m[13]*x+m[14]*y+m[15]*z+m[16]
   if w>0 then
    local px=(m[1]*x+m[2]*y+m[3]*z+m[4])/w;local py=(m[5]*x+m[6]*y+m[7]*z+m[8])/w
    local score=(px+.4)^2+(py-.4)^2
    if not best or score<best then best=score;chosen={ix,iz}end
   end
  end
 end end
 assert(chosen,'no snow trail strip')
 local x,z=(origin[1]+chosen[1])*8+1,(origin[2]+chosen[2])*8+4
 local p={px=x-8,py=z-8};local fake={save={options={sfxVol=0}},overworld={map=world.map,player=p}}
 S.update(.1,fake,'snow')
 for i=1,6 do p.px=p.px+5;S.update(.1,fake,'snow')end
 assert(#S.marks>=5,'native map does not accept walking footprints')
 print('SNOW_TRACKS_NATIVE_STAMPS',#S.marks)
 local h=cells[chosen[2]][chosen[1]].base
 return {eye={x+16,h+18,z+42},focus={x+16,h+1,z}}
end
