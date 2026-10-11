return function(game)
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-sevii%-.*%-qa$'))
 assert(not game.mods.exports.kanto_ascendant,'corrupt animation was silently accepted')
 print('SEVII_CORRUPT_ANIMATION_ASSET_REJECTED')
 love.event.quit()
end
