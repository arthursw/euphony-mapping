# The Euphony class provides interfaces to play MIDI files and do 3D visualization.
# The controller and playlist on the left of the screen is not part of it.
class Euphony

	constructor: ->

		@measureDuration = 1000
		@timeDivision = 0.25
		@noteDuration = 0.25

		@design = new PianoKeyboardDesign()
		# @keyboard = new PianoKeyboard(@design)

		# path = new paper.Path.Rectangle(250, 0.5*0.75*$("body").width(), 100, 100)
		# path.fillColor = 'red'

		@keyboard2D = new PianoKeyboard2D(@design)

		@rain = new NoteRain2D(@design, @keyboard2D, @)
		# @particles = new NoteParticles(@design)
		@context = paper.view.element.getContext('2d')

		@player = MIDI.Player
		@player.BPM = 50
		@player.addListener (data) =>
			NOTE_OFF = 128
			NOTE_ON  = 144
			{note, message} = data
			if message is NOTE_ON
				@keyboard2D.press(note)
				# @particles.createParticles(note)
			else if message is NOTE_OFF
				@keyboard2D.release(note)
		# @player.setAnimation
		# 	delay: 20
		# 	callback: (data) =>
		# 		{now, end} = data
		# 		@onprogress?(
		# 			current: now
		# 			total: end
		# 		)
		# 		@update(now)
		@player.setAnimation (data) =>
			{now, end} = data
			@onprogress?(
				current: now
				total: end
			)
			@update(now)

		@charToNoteNumber =
			'Q': 60
			'S': 62
			'D': 64
			'F': 65
			'G': 67
			'H': 69
			'J': 71

		$(window).keydown(@keyDown)

	update: (now, forceUpdate = false)=>
		# console.log 'update: ' + now
		canvas = paper.view.element
		@context.clearRect(0,0,canvas.width,canvas.height)
		if @player.playing or forceUpdate
			@rain.update(now * 1000)
		@keyboard2D.update(now * 1000)
		paper.view.update(true)
		# @keyboard2D.quad.computeTextureProjection()
		@keyboard2D.quad.texture.needsUpdate = true
		return

	keyDown: (event)=>
		# console.log 'before: ' + @player.currentTime
		switch event.which
			when 32
				if @player.playing then @player.pause() else @player.resume()
			when 37, 38, 39, 40
				if @keyboard2D.quad.selectedSprite? then return
				
				wasPlaying = @player.playing
				if wasPlaying then @player.pause()
				switch event.which
					when 37 		# left
						@player.currentTime -= @timeDivision*@measureDuration
					when 38 		# up
						@player.currentTime += @measureDuration
					when 39 		# right
						@player.currentTime += @timeDivision*@measureDuration
					when 40 		# down
						@player.currentTime -= @measureDuration

				step = @measureDuration*@timeDivision
				@player.currentTime = Math.floor(@player.currentTime/step)*step
				if wasPlaying then @player.resume()
				@update(@player.currentTime/1000, true)

		console.log 'current time: ' + @player.currentTime

		if event.which >= 65 and event.which <= 90
			console.log 'which, char, note number'
			console.log event.which
			console.log String.fromCharCode(event.which)
			console.log @charToNoteNumber[String.fromCharCode(event.which)]
			@toggle(@charToNoteNumber[String.fromCharCode(event.which)])
		return

	toggle: (noteNumber)=>
		if not noteNumber then return
		step = @measureDuration*@timeDivision
		startTime = Math.floor(@player.currentTime/step)*step
		noteInfo =
			noteNumber: noteNumber
			startTime: startTime
			duration: @noteDuration * @measureDuration
			velocity: 64
		@rain.toggleNote(noteInfo)
		@player.toggleNote(noteInfo, @measureDuration)
		return

	initScene: ->
		@scene = new SimpleScene('#canvas')

		canvas3D = $('#canvas').find('canvas')

		# @scene.add(@keyboard.model)
		# @scene.add(@rain.model)
		# @scene.add(@particles.model)
		@keyboard2D.initialize(@scene)

		@scene.animate =>
			@keyboard2D.quad.computeTextureProjection()

			# @keyboard.update()
			# @particles.update()

	initMidi: (callback) ->
		onPluginLoaded = ->
			# mute channel 10, which is reserved for percussion instruments only.
			# the channel index is off by one
			MIDI.channels[9].mute = true
			callback?()
			return
		# MIDI.loadPlugin onPluginLoaded, 'soundfont', './soundfont/'
		# MIDI.loadPlugin onPluginLoaded, 'banjo', './midi-js-soundfonts/FluidR3_GM/'
		MIDI.loadPlugin
			onsuccess: onPluginLoaded,
			instruments: ['./midi-js-soundfonts/FluidR3_GM/acoustic_grand_piano']

	loadBuiltinPlaylist: (callback) ->
		return callback(@playlist) if @playlist
		$.getJSON 'tracks/index.json', (@playlist) =>
			callback(@playlist)

	loadBuiltinMidi: (id, callback) ->
		return unless 0 <= id < @playlist.length

		# try to load the MIDI file from localStorage
		if localStorage?[id]
			return @loadMidiFile(localStorage[id], callback)

		# if the file is not available in the localStorage
		# then issue an AJAX request to get it from remote server
		# and try to save the file into localStorage
		$.ajax
			url: "tracks/#{@playlist[id]}"
			dataType: 'text'
			success: (data) =>
				@loadMidiFile(data, callback)
				try
					localStorage?[id] = data
				catch e
					console?.error('localStorage quota limit reached')

	# load a base64 encoded or binary XML MIDI file
	loadMidiFile: (midiFile, callback) ->
		@player.loadFile midiFile, =>
			@rain.setMidiData(@player.data, callback)
			@keyboard2D.noteInfos = @rain.noteInfos

	start: =>
		@keyboard2D.reset()
		@player.start()
		@playing = true

	resume: =>
		@player.currentTime += 1e-6 # bugfix for MIDI.js
		@player.resume()
		@playing = true

	stop: =>
		@player.stop()
		@playing = false

	pause: =>
		@player.pause()
		@playing = false

	getEndTime: =>
		@player.endTime

	setCurrentTime: (currentTime) =>
		@player.pause()
		@player.currentTime = currentTime
		@player.resume() if @playing

	setProgress: (progress) =>
		currentTime = @player.endTime * progress
		@setCurrentTime(currentTime)

	on: (eventName, callback) ->
		@["on#{eventName}"] = callback

	saveMidi: ()=>

		file = new JSMidgen.File()
		track = new JSMidgen.Track()

		currentTime = 0

		midiData = []

		# add the all events not sorted, not by interval but with absolute times :
		for noteInfo in @rain.noteInfos
			noteOn =
				noteNumber: noteInfo.noteNumber
				startTime: noteInfo.startTime
				velocity: noteInfo.velocity
				type: 'noteOn'
			midiData.push(noteOn)
			noteOff =
				noteNumber: noteInfo.noteNumber
				startTime: noteInfo.startTime + noteInfo.duration
				velocity: noteInfo.velocity
				type: 'noteOff'
			midiData.push(noteOff)

		# sort the events
		midiData.sort (a, b)->
			return a.startTime - b.startTime

		# convert absolute times to intervals
		previousTime = 0
		for event in midiData
			event.interval = event.startTime - previousTime
			previousTime = event.startTime

		for event in midiData
			# not working:
			# addNote(channel, pitch, duration[, time[, velocity]])
			# track.addNote(0, MIDI.noteToKey[noteInfo.noteNumber], noteInfo.duration, noteInfo.startTime-currentTime, noteInfo.velocity)

			# addNoteOn(channel, pitch[, time[, velocity]])
			if event.type == 'noteOn'
				track.addNoteOn(0, MIDI.noteToKey[event.noteNumber], event.interval, event.velocity)
			else if event.type == 'noteOff'
				track.addNoteOff(0, MIDI.noteToKey[event.noteNumber], event.interval, event.velocity)

		file.addTrack(track)

		bytes = file.toBytes()
		byteArray = new Uint8Array(bytes.length)
		for i in [0 .. bytes.length-1]
			byteArray[i] = bytes.charCodeAt(i)
		blob = new Blob([byteArray], {type: 'application/octet-stream'}) 	# "text/plain;charset=utf-8"})
		saveAs(blob, "track.midi")

		return

# exports to global
@Euphony = Euphony
