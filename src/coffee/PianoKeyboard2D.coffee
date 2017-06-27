# model of a single 2D piano key
class PianoKey2D
	constructor: (design, @note, @whiteGroup, @blackGroup) ->
		{
			blackKeyWidth, blackKeyHeight, blackKeyLength, blackKeyColor,
			whiteKeyWidth, whiteKeyHeight, whiteKeyLength, whiteKeyColor,
			blackKeyPosY, blackKeyPosZ, keyDip, keyInfo, keyUpSpeed, KeyType
		} = design
		{Black} = KeyType

		{keyType, keyCenterPosX} = keyInfo[@note]

		if keyType is Black
			@rectangle = new paper.Rectangle(keyCenterPosX-blackKeyWidth/2, 0, blackKeyWidth, blackKeyLength)
			@color = 'black'
		else
			@rectangle = new paper.Rectangle(keyCenterPosX-whiteKeyWidth/2, 0, whiteKeyWidth, whiteKeyLength)
			@color = 'white'
	#
	# highlight: (step)=>
	# 	if step==2
	# 		@path.fillColor = 'DarkOrange'
	# 	else if step==1
	# 		@path.fillColor = 'Orange'
	# 	else if step==0
	# 		@path.fillColor = 'OrangeRed'

	highlight: (velocity)=>
		if velocity <= 1
			@path.fillColor = 'darkblue'
		else if velocity > 1
			@path.fillColor = 'yellowgreen'
		@isPressed = true
		return

	press: ->
		@path.fillColor = 'red'
		@isPressed = true

	release: ->
		@path.fillColor = @color
		@isPressed = false

	update:(offsetX, scale)=>
		@path?.remove()
		@path = new paper.Path.Rectangle((@rectangle.x+offsetX)*scale, @rectangle.y*scale, @rectangle.width*scale, @rectangle.height*scale)
		@path.fillColor = @color
		@path.strokeColor = 'black'

		if @color == 'black'
			@blackGroup.addChild(@path)
		else
			@whiteGroup.addChild(@path)


# model of piano keyboard
# usage:
#   keyboard = new PianoKeyboard(new PianoKeyboardDesign)
#   keyboard.press(30)   # press the key of note 30(G1)
#   keyboard.release(60) # release the key of note 60(C4)
class PianoKeyboard2D
	constructor: (design) ->
		@begin = 21
		@end = 109
		@nWhiteKeys = 0
		@nWhiteKeysBefore = 0

		@keys = []
		@design = design

		@canvasKeyboard = $('#keyboard-2D')
		@timeOffset = 1000

		paper.setup(@canvasKeyboard[0])

		@group = new paper.Group()
		@whiteGroup = new paper.Group()
		@blackGroup = new paper.Group()

		@group.addChild(@whiteGroup)
		@group.addChild(@blackGroup)

		# create piano keys
		for note in [0...design.keyInfo.length]
			if @begin <= note < @end
				key = new PianoKey2D(design, note, @whiteGroup, @blackGroup)
				if key.color == 'white'
					@nWhiteKeys++
				@keys.push(key)
			if note < @begin
				if design.keyInfo[note].keyType != design.KeyType.Black
					@nWhiteKeysBefore++

		firstNotePosX = design.keyInfo[@begin].keyCenterPosX
		lastNotePosX = design.keyInfo[@end-1].keyCenterPosX
		@keyboardWidth = @design.whiteKeyWidth + lastNotePosX-firstNotePosX

		# @canvasHeightRatio = 0.75

		# @border = new paper.Path.Rectangle(0, 0, width, height)
		# @border.strokeColor = 'red'
		# @border.strokeWidth = 1

		# window.gui.add(@, 'canvasHeightRatio', 0.1, 1.5).onChange (value)->
		# 	window.app.keyboard2D.setCanvasHeightRatio(value)
		# 	return

		@onresize()

		# paper.view.onFrame = (event) =>
		# 	console.log "render"
		# 	@quad.texture.needsUpdate = true

		$(window).resize(@onresize)

	initialize: (scene)->
		@canvasWidth = $("body").width()
		@canvasHeight = $("body").height()

		@quad = new Quad(@canvasWidth, @canvasHeight, @canvasKeyboard, scene)
		@quad.resize()
		# @context = paper.view.element.getContext('2d')
		# paper.view.onFrame = (event)=>
		# @timerID = setInterval( () =>
		# 	canvas = paper.view.element
		# 	@context.clearRect(0,0,canvas.width,canvas.height)
		# 	paper.view.draw()
		# 	@quad.texture.needsUpdate = true
		# 	return
		# , 1000/60 )
		return

	onresize: () =>
		@canvasWidth = $("body").width()
		@canvasHeight = $("body").height()

		# keyboardWidth = @nWhiteKeys*@design.whiteKeyWidth
		keyboardHeight = @design.whiteKeyHeight
		@keyUnitToPixelsRatio = @canvasWidth/@keyboardWidth
		@keyboardHeightInPixel = @design.whiteKeyLength*@keyUnitToPixelsRatio
		@offsetX = -@nWhiteKeysBefore*@design.whiteKeyWidth

		@canvasKeyboard.attr("width", @canvasWidth)
		@canvasKeyboard.attr("height", @canvasHeight)

		# @group.scale(scale)
		# @group.translate(new paper.Point((-offsetX+keyboardWidth/2)*scale,(keyboardHeight/2)*scale))

		for key in @keys
			key.update(@offsetX, @keyUnitToPixelsRatio)

		@blackGroup.moveAbove(@whiteGroup)

		@group.position.y = @canvasHeight - @keyboardHeightInPixel*0.5
		# paper.view.setCenter(paper.view.center.x, paper.view.center.y - canvasHeight + keyboardHeightInPixel)
		@quad?.resize()

	# setCanvasHeightRatio: (heightRatio)->
	# 	@canvasHeight = @canvasHeightRatio * @canvasWidth
	# 	@canvasKeyboard.attr("height", heightRatio*$("body").width())
	# 	return

	update: (playerCurrentTime) ->
		for key in @keys
			key.release()
		if not @noteInfos? then return
		for noteInfo,j in @noteInfos
			{noteNumber, startTime, duration, velocity} = noteInfo
			# if playerCurrentTime > startTime - @timeOffset && playerCurrentTime < startTime
			# 	step = @timeOffset/3
			# 	n = noteNumber-@begin
			# 	if 0 < n < @keys.length
			# 		@keys[n].highlight(Math.floor((startTime-playerCurrentTime)/step))
			if playerCurrentTime > startTime && playerCurrentTime < startTime + duration
				n = noteNumber-@begin
				if 0 < n < @keys.length
					@keys[n].highlight(velocity)

	press: (note) ->
		# n = note-@begin
		# if 0 < n < @keys.length
		# 	@keys[n].press()
		return

	release: (note) ->
		# n = note-@begin
		# if 0 < n < @keys.length
		# 	@keys[n].release()
		return

	reset: () =>
		for key in @keys
			key.release()

@PianoKeyboard2D = PianoKeyboard2D
