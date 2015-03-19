# Feature ideas:
#   Show-specific lists
#   Soundscapes


# My Code

TAGS = ['Action', 'Aggressive', 'Bouncy', 'Bright', 'Calming', 'Dark', 'Driving', 'Eerie', 'Epic', 'Grooving', 'Humorous', 'Intense', 'Mysterious', 'Mystical', 'Relaxed', 'Somber', 'Suspenseful', 'Unnerving', 'Uplifting']
GENRES = ['African', 'Blues', 'Classical', 'Contemporary', 'Disco', 'Electronica', 'Funk', 'Holiday', 'Horror', 'Jazz', 'Latin', 'Modern', 'Musical', 'Polka', 'Pop', 'Reggae', 'Rock', 'Silent Film Score', 'Location', 'Soundtrack', 'Stings', 'Unclassifiable', 'World']
INSTRUMENTS = []
LIMIT = 20
# fadeTime = 5000

window.songs = {}
initializedSongs = []
musics = {}

matchedSongs = []
pinnedSongs = []
playingSongs = []

searchTags = []
searchInstruments = []
searchName = ''
searchTime = ''
searchGenre = ''

$.getJSON 'json/scraped_song_data.json', (data) ->
  initialize(data)
$.getJSON 'json/my_song_data.json', (data) ->
  initialize(data)

addedFileloadListener = false
initialize = (data) ->
  if not addedFileloadListener
    createjs.Sound.addEventListener 'fileload', handleLoadComplete
    addedFileloadListener = true
  for song in data
    # Create dictionary
    songs[song.title] = song

    # Create instrument list
    if song.instruments
      for instrument in song.instruments
        if INSTRUMENTS.indexOf(instrument) == -1
          INSTRUMENTS.push(instrument)

handleLoadComplete = (event) ->
  playMusic(songs[event.id])

getPath = (song) ->
  linkParts = song.link.split('/')
  return (song.link)

getTags = (query) ->
  matchedTags = []
  for q in query.split(' ')
    for tag in TAGS
      if not (q.length == 0 or q.length > tag.length) and tag.substring(0, q.length).toUpperCase() == q.toUpperCase() and tag not in matchedTags
        matchedTags.push(tag)
  return matchedTags

getInstruments = (query) ->
  matchedInstruments = []
  for q in query.split(' ')
    for instrument in INSTRUMENTS
      if not (q.length == 0 or q.length > instrument.length) and instrument.substring(0, q.length).toUpperCase() == q.toUpperCase() and instrument not in matchedInstruments
        matchedInstruments.push(instrument)
  return matchedInstruments

getGenre = (query) ->
  for genre in GENRES
    if not (query.length == 0 or query.length > genre.length) and genre.substring(0, query.length).toUpperCase() == query.toUpperCase()
      return genre
  return null

initSong = (song) ->
  createjs.Sound.registerSound
    src: getPath(song)
    id: song.title  

isPlaying = (song) ->
  return playingSongs.indexOf(song) != -1

playMusic = (song) ->
  if song.title not in initializedSongs
    initializedSongs.push(song.title)
    initSong song
    return
  if not isPlaying(song)
    playingSongs.push(song)
    displayPlayingAndPinned()
    SM.playMusic(song.title, 0, fadeTime())

stopMusic = (song) ->
  if isPlaying(song)
    playingSongs.splice(playingSongs.indexOf(song), 1)
    displayPlayingAndPinned()
    SM.stopMusic(song.title, fadeTime())

toggleMusic = (song) ->
  if not isPlaying(song)
    playMusic(song)
  else
    stopMusic(song)

stopAllMusic = ->
  playingSongs = []
  displayPlayingAndPinned()
  SM.stopAllMusics(fadeTime())

playOnly = (song) ->
  if isPlaying(song)
    stopAllMusic()
  else
    stopAllMusic()
    playMusic(song)

updateTagSearch = (tags) ->
  if searchTags.length + tags.length == 0
    return
  if searchTags.length == tags.length
    match = true
    for tag, i in tags
      if tag != tags[i]
        match = false
        break
    if match
      return
  searchTags = tags
  updateSearch()

updateInstrumentSearch = (instruments) ->
  if searchInstruments.length + instruments.length == 0
    return
  if searchInstruments.length == instruments.length
    match = true
    for instrument, i in instruments
      if instrument != instruments[i]
        match = false
        break
    if match
      return
  searchInstruments = instruments
  updateSearch()

updateInstrumentText = (instruments) ->
  instrumentEls = [$("<div class=\"tag\">" + instrument + "</div>") for instrument in instruments]
  $('#instrument-text').children().remove()
  for el in instrumentEls
    $('#instrument-text').append(el)

updateSearch = ->
  # Copy dict to array
  matchedSongs = []
  for key of songs
    song = songs[key]
    matchedSongs.push(song)

  # Filter by genre
  if searchGenre
    soundtrackSongs = []
    for song in matchedSongs
      if song['genre'].toUpperCase() == searchGenre.toUpperCase()
        soundtrackSongs.push(song)

    matchedSongs = soundtrackSongs

  # Filter by tag
  if searchTags
    tagSongs = []
    for song in matchedSongs
      tagMatch = true
      for tag in searchTags
        if tag not in song.tags
          tagMatch = false
          break
      if tagMatch
        tagSongs.push(song)

    matchedSongs = tagSongs

  # Filter by instrument
  if searchInstruments
    instrumentSongs = []
    for song in matchedSongs
      instrumentMatch = true
      for instrument in searchInstruments
        if not song.instruments or instrument not in song.instruments
          instrumentMatch = false
          break
      if instrumentMatch
        instrumentSongs.push(song)

    matchedSongs = instrumentSongs

  # Filter by name
  if searchName
    nameSongs = []
    for song in matchedSongs
      if smartMatch(song.title)
        nameSongs.push(song)

    matchedSongs = nameSongs

  # Filter by time
  if searchTime.length > 0
    timeSongs = []
    for song in matchedSongs
      if song.time.toUpperCase().indexOf(searchTime.toUpperCase()) != -1
        timeSongs.push(song)

    matchedSongs = timeSongs

  matchedSongs.sort (a,b) ->
    return a.title.localeCompare(b.title)
  displayMatchedSongs(limit=LIMIT)

createSongEl = (song) ->
  $template = $('#song-template').clone().attr('id', '').removeClass('hidden')
  $song = $template.clone()
  $song.find('.title').html(song.title)
  $song.find('.tags').html(song.tags.join(' '))
  $song.find('input.volume').val(SM.getVolume(song.title))
  if song.instruments and song.instruments[0] != ' Listen!'
    $song.find('.instruments').html(song.instruments.join(' '))
  else
    $song.find(':contains(Instruments:)').remove()
  if song.genre
    $song.find('.genre').html(song.genre)
  if song.time
    $song.find('.time').html(song.time)
  return $song

displayMatchedSongs = (limit=null) ->
  $matchedSongs = $('#matched-songs')
  $matchedSongs.empty()
  if matchedSongs.length == 0
    $matchedSongs.html('<i>No songs match your search.</i>')
    return
  for song, i in matchedSongs
    if limit and i == limit
      songBindings('#matched-songs')
      return
    $matchedSongs.append(createSongEl(song))
  songBindings('#matched-songs')

displayPlayingAndPinned = ->
  $('.pinned').removeClass('pinned')
  $('.playing').removeClass('playing')

  $pinnedSongs = $('#pinned-songs')
  $pinnedSongs.empty()
  if pinnedSongs.length == 0 and playingSongs == 0
    $pinnedSongs.html('<i>No songs pinned or playing.</i>')
    return
  for song, i in pinnedSongs
    $pinnedSongs.append(createSongEl(song))
    $('.title:contains(' + song.title + ')').closest('.song').addClass('pinned')
  for song, i in playingSongs
    if pinnedSongs.indexOf(song) == -1
      $pinnedSongs.append(createSongEl(song))
    $('.title:contains(' + song.title + ')').closest('.song').addClass('playing')

  songBindings('#pinned-songs')

songBindings = (selector) =>
  $el = $(selector)
  $el.find('.play').click ->
    title = $(this).closest('.song').find('.title').text()
    playOnly(songs[title])

  $el.find('.just-play').click ->
    title = $(this).closest('.song').find('.title').text()
    toggleMusic(songs[title])

  $el.find('.pin').click ->
    title = $(this).closest('.song').find('.title').text()
    song = songs[title]
    pinSong(song)
    displayPlayingAndPinned()

  $el.find('input.volume').on 'input', ->
    title = $(this).closest('.song').find('.title').text()
    SM.setVolume(title, $(@).val())

pinSong = (song) ->
  if pinnedSongs.indexOf(song) != -1
    pinnedSongs.splice(pinnedSongs.indexOf(song), 1)
  else
    pinnedSongs.push(song)

updateTagHighlighting = (tags) ->
  for tag in $('.feel-tag')
    $tag = $(tag)
    if $tag.attr('id') in tags
      $tag.addClass 'selected'
    else
      $tag.removeClass 'selected'

updateGenreHighlighting = ->
  for genreTag in $('.genre-tag')
    $genre = $(genreTag)
    if $genre.attr('id') == searchGenre or ($genre.attr('id') == 'Silent' and searchGenre == "Silent Film Score")
      $genre.addClass 'selected'
    else
      $genre.removeClass 'selected'

smartMatch = (input) ->
  if searchName == ''
    return true
  matchIndex = 0
  j = 0
  while j < input.length
    if input[j].toUpperCase() == searchName[matchIndex].toUpperCase()
      matchIndex++
    if matchIndex == searchName.length
      return true
    j++
  false

fadeTime = ->
  return $('#crossfade-time').val() * 1000

quickShuffleOn = false
counter = 0
quickShuffle = ->
  quickShuffleHelper(45000)

quickShuffleHelper = (time) ->
  setTimeout ->
    if not quickShuffleOn
      return
    if Math.random() < .5
      counter++
      console.log counter
      stopAllMusic()
      playRandom()
      setTimeout ->
        stopAllMusic()
      , 5000
    quickShuffleHelper(time)
  , time

playRandom = ->
  playOnly(matchedSongs[Math.floor(Math.random() * matchedSongs.length)])

window.onload = ->
  updateSearch()
  displayPlayingAndPinned()

  $('.independent-scroll').on 'scroll', ->
    if $(@).scrollTop() + $(@).innerHeight() >= @scrollHeight and $('#matched-songs').children().length == LIMIT
      displayMatchedSongs()

  $('#tags').on 'input', ->
    tags = getTags $(@).val()
    updateTagHighlighting tags
    updateTagSearch tags

  $('#instruments').on 'input', ->
    instruments = getInstruments $(@).val()
    updateInstrumentText instruments
    updateInstrumentSearch instruments

  $('#genre').on 'input', ->
    genre = getGenre $(@).val()
    searchGenre = genre
    updateGenreHighlighting()
    updateSearch()

  $('#name').on 'input', ->
    name = $(@).val()
    searchName = name
    updateSearch()

  $('#time').on 'input', ->
    searchTime = $(@).val()
    updateSearch()

  $('#crossfade-time').on 'input', ->
    $('#crossfade-time-label').html($(@).val())

  $('#clear-pins').click ->
    pinnedSongs = []
    displayPlayingAndPinned()

  $('#random').click (e) ->
    if quickShuffleOn
      $(e.target).removeClass('active')
      quickShuffleOn = false
      stopAllMusic()
    else
      $(e.target).addClass('active')
      quickShuffleOn = true
      playRandom()
      quickShuffle()

  $keyElements = $.merge($(document), $('input'))

  # return: play only top match
  $keyElements.bind 'keydown', 'return', (event) ->
    playOnly(matchedSongs[0])
    event.preventDefault()

  # shift-return: play top match
  $keyElements.bind 'keydown', 'shift+return', (event) ->
    toggleMusic(matchedSongs[0])
    event.preventDefault()

  # alt-f: fade out
  $keyElements.bind 'keydown', 'alt+f', (event) ->
    stopAllMusic()
    event.preventDefault()

  # alt-s: hard stop
  # $keyElements.bind 'keydown', 'alt+s', (event) ->
  #   SM.stopAllMusics()
  #   event.preventDefault()

  # alt-c: clear pinned songs
  $keyElements.bind 'keydown', 'alt+c', (event) ->
    pinnedSongs = []
    displayPlayingAndPinned()
    event.preventDefault()

  # alt-shift-c: clear all filters
  $keyElements.bind 'keydown', 'alt+shift+c', (event) ->
    $('input:not([type=range])').val('')
    searchTags = []
    searchInstruments = []
    searchName = ''
    searchTime = ''
    searchGenre = ''
    updateSearch()
    updateTagHighlighting([])
    updateGenreHighlighting('')
    updateInstrumentText([])
    event.preventDefault()

  # alt-p: pin top matched song
  $keyElements.bind 'keydown', 'alt+p', (event) ->
    pinSong(matchedSongs[0])
    displayPlayingAndPinned()
    event.preventDefault()

  # alt-shift-{num}: set crossfade time to {num}
  for i in [0..9]
    $keyElements.bind 'keydown', 'alt+shift+' + i, (event) ->
      $('#crossfade-time').val(event.keyCode - 48)
      $('#crossfade-time-label').html(event.keyCode - 48)
      event.preventDefault()

  # alt-{num}: play pinned song at index {num}
  for i in [0..9]
    $keyElements.bind 'keydown', 'alt+' + i, (event) ->
      num = event.keyCode - 48
      if num == 0
        num = 9
      else
        num--
      if num < pinnedSongs.length
        playOnly(pinnedSongs[num])
      event.preventDefault()






