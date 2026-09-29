return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0);io.stdout:setvbuf('no')
 local root=assert(os.getenv('QA_VASC_ROOT'));arg={root}
 assert(loadfile(root..'/tests/indoor_mist_composite_test.lua'))()
 print('PASS_RC40_MIST_GPU');love.event.quit(0)
end
