return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'))
 local oldArg=arg;arg={root}
 assert(loadfile(root..'/tests/local_light_grid_test.lua'))()
 arg=oldArg;love.event.quit()
end
