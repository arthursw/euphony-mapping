class NoteRain2D

	lengthScale: 0.001

	constructor: (@pianoDesign, @keyboard2D, app) ->
		@keyUnitToPixelsRatio = @keyboard2D.keyUnitToPixelsRatio
		@offsetX = @keyboard2D.offsetX
		@group = new paper.Group()
		@background = new paper.Group()
		background = paper.Path.Rectangle(0, 0, @keyboard2D.canvasWidth, @keyboard2D.canvasHeight)
		background.fillColor = '#303030'
		@background.addChild(background)

		# draw vertical background lines
		for keyInfo, i in @pianoDesign.keyInfo
			if i>=@keyboard2D.begin and i<=@keyboard2D.end and ( keyInfo.keyType == @pianoDesign.KeyType.WhiteC or keyInfo.keyType == @pianoDesign.KeyType.WhiteF or keyInfo.keyType == @pianoDesign.KeyType.Black )
				line = new paper.Path()
				line.strokeWidth = 1
				line.strokeColor = '#bfbebb'
				x = (keyInfo.keyCenterPosX+@offsetX-@pianoDesign.whiteKeyWidth*0.5)*@keyUnitToPixelsRatio
				if keyInfo.keyType == @pianoDesign.KeyType.Black
					line.strokeColor = '#393939'
					line.strokeWidth = @pianoDesign.blackKeyWidth*@keyboard2D.keyUnitToPixelsRatio
					# line.dashArray = [10, 4]
					x = (keyInfo.keyCenterPosX+@offsetX)*@keyUnitToPixelsRatio
				line.add(new paper.Point(x, 0))
				line.add(new paper.Point(x, @keyboard2D.canvasHeight))
				@background.addChild(line)

		# draw horizontal background lines
		@horizontalLinesGroup = new paper.Group()
		@onTimeDivisionChange(app.timeDivision, app.measureDuration)

		@horizontalLinesGroup.moveAbove(@background)
		@group.moveAbove(@horizontalLinesGroup)
		@keyboard2D.group.moveAbove(@group)
		return

	# midiData is acquired from MIDI.Player.data
	setMidiData: (midiData, callback) ->
		@clear()
		@noteInfos = @_getNoteInfos(midiData)
		@_buildNoteMeshes(@noteInfos, callback)

	# clear all existing note rains
	clear: ->
		@group.removeChildren()
		return

	createNote: (noteInfo, offsetY = false)->
		{whiteKeyWidth, blackKeyWidth, blackKeyHeight, keyInfo, KeyType, noteToColor} = @pianoDesign
		{Black} = KeyType
		{noteNumber, startTime, duration} = noteInfo
		{keyType, keyCenterPosX} = keyInfo[noteNumber]
		# scale the length of the note
		length = duration * @lengthScale

		# calculate the note's position
		x = keyCenterPosX
		y = - startTime * @lengthScale - length
		# console.log(y*@keyUnitToPixelsRatio)

		color = noteToColor(noteNumber)
		color = '#7aa5d7'

		width = whiteKeyWidth

		if keyType is Black
			color = '#9ae05f'
			x += @offsetX - blackKeyWidth*0.5
			width = blackKeyWidth
		else
			x += @offsetX - whiteKeyWidth*0.5
			width = whiteKeyWidth

		yInPixels = @keyUnitToPixelsRatio*y
		if offsetY
			deltaY = yInPixels-@bounds.centerY
			yInPixels = @group.position.y + deltaY
		rectangle = new paper.Path.Rectangle(@keyUnitToPixelsRatio*x, yInPixels, @keyUnitToPixelsRatio*width, @keyUnitToPixelsRatio*length)
		rectangle.fillColor = color
		noteInfo.rectangle = rectangle
		# if @group.children.length < 20
		@group.addChild(rectangle)
		return

	toggleNote: (note)->
		console.log("toggle note: "+ note)
		noteFound = false
		noteIndex = 0
		noteTime = note.startTime
		for noteInfo, i in @noteInfos
			if noteInfo.startTime < noteTime
				noteIndex++
			else if noteInfo.startTime >= noteTime && noteInfo.startTime <= noteTime + app.measureDuration * app.noteDuration && noteInfo.noteNumber == note.noteNumber
				noteInfo.rectangle.remove()
				@noteInfos.splice(i, 1)
				noteFound = true
				break
		if not noteFound
			@createNote(note, true)
			@noteInfos.splice(noteIndex, 0, note)
		return

	# the raw midiData uses delta time between events to represent the flow
	# and it's quite unintuitive
	# here we calculates the start and end time of each notebox
	_getNoteInfos: (midiData) ->
		currentTime = 0
		noteInfos = []
		noteTimes = []

		for [{event}, interval] in midiData
			currentTime += interval
			{subtype, noteNumber, channel, velocity} = event

			# In General MIDI, channel 10 is reserved for percussion instruments only.
			# It doesn't make any sense to convert it into piano notes. So just skip it.
			continue if channel is 9 # off by 1

			if subtype is 'noteOn'
				# if note is on, record its start time
				noteTimes[noteNumber] = currentTime

			else if subtype is 'noteOff'
				# if note if off, calculate its duration and build the model
				startTime = noteTimes[noteNumber]
				duration = currentTime - startTime
				noteInfos.push {
					noteNumber: noteNumber
					startTime: startTime
					duration: duration
					velocity: velocity
				}
		noteInfos


	# convert note infos (internal format) to midi
	# NOT TESTED
	_noteInfosToMidiData: (noteInfos) ->

		midiData = []

		# add the all events not sorted, not by interval but with absolute times :

		for noteInfo in noteInfos
			event =
				subtype: 'noteOn'
				noteNumber: noteInfo.noteNumber
				channel: 1
				velocity: noteInfo.velocity
			midiData.push([event: event, noteInfo.startTime])
			event =
				subtype: 'noteOff'
				noteNumber: noteInfo.noteNumber
				channel: 1
				velocity: noteInfo.velocity
			midiData.push([event: event, noteInfo.startTime + noteInfo.duration])

		# sort the events

		midiData.sort (a, b)->
			return a[1] - b[1]

		# convert absolute times to intervals

		previousTime = 0

		for event in midiData
			t = previousTime
			previousTime = event[1]
			event[1] -= t

		currentTime = 0
		noteInfos = []
		noteTimes = []

		return midiData

	# given a list of note info, build their meshes
	# the callback is called on finishing this task
	_buildNoteMeshes: (noteInfos, callback) ->

		for noteInfo, i in noteInfos
			@createNote(noteInfo)

		callback?()

		@bounds = @group.getBounds()
		@group.addChild(@horizontalLinesGroup)
		@horizontalLinesGroup.position.y = @bounds.bottom - @horizontalLinesGroup.bounds.height * 0.5
		return

	update: (playerCurrentTime) =>
		@group.position.y = - @bounds.height*0.5 + @keyboard2D.canvasHeight - @keyboard2D.keyboardHeightInPixel + playerCurrentTime * @lengthScale * @keyUnitToPixelsRatio
		# @horizontalLinesGroup.position.y = @group.position.y
		if @horizontalLinesGroup.bounds.bottom > @keyboard2D.canvasHeight + @horizontalLinesStep
			@horizontalLinesGroup.position.y -= @horizontalLinesStep
		return

	onTimeDivisionChange: (timeDivision=app.timeDivision, measureDuration=app.measureDuration)->
		@horizontalLinesGroup.removeChildren()

		y = @horizontalLinesGroup.bounds.top
		t = 0
		@horizontalLinesStep = measureDuration * @lengthScale * @keyUnitToPixelsRatio

		while y<@keyboard2D.canvasHeight
			line = new paper.Path()
			line.stokeWidth = 1
			line.strokeColor = '#bfbebb'
			switch t%measureDuration
				when 0
					line.strokeColor.alpha = 1
				when measureDuration * 0.5
					line.strokeColor.alpha = 0.5
				when measureDuration * 0.25, measureDuration * 0.75
					line.strokeColor.alpha = 0.25
				else
					line.strokeColor.alpha = 0.1

			line.add(new paper.Point(0, y))
			line.add(new paper.Point(@keyboard2D.canvasWidth, y))
			@horizontalLinesGroup.addChild(line)
			t += timeDivision * measureDuration
			y = t * @lengthScale * @keyUnitToPixelsRatio

		return

# export to global
@NoteRain2D = NoteRain2D
