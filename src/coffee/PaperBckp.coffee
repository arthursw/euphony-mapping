# model of a single 2D piano key
# usage:
#   key = new PianoKey(desing, note)
#   key.press()
#   key.release()
#   setInterval((-> key.update()), 1000 / 60)
class PianoKey2D
	constructor: (design, note, @context, draw, scale) ->
		{
			blackKeyWidth, blackKeyHeight, blackKeyLength, blackKeyColor,
			whiteKeyWidth, whiteKeyHeight, whiteKeyLength, whiteKeyColor,
			blackKeyPosY, blackKeyPosZ, keyDip, keyInfo, keyUpSpeed, KeyType
		} = design
		{Black} = KeyType

		{keyType, keyCenterPosX} = keyInfo[note]

		if keyType is Black
			@rectangle = {x:keyCenterPosX, y:0, width:blackKeyWidth, height:blackKeyLength }
			@color = 'black'
		else
			@rectangle = {x:keyCenterPosX, y:0, width:whiteKeyWidth, height:whiteKeyLength }
			@color = 'white'
		
		@rectangle.x *= scale
		@rectangle.y *= scale
		@rectangle.width *= scale
		@rectangle.height *= scale
		
		if(draw)
		    @release()
		
	press: ->
        @context.fillStyle = "red"
        @context.fillRect(@rectangle.x, @rectangle.y, @rectangle.width, @rectangle.height)
		@isPressed = true

	release: ->
        @context.fillStyle = @color
        @context.fillRect(@rectangle.x, @rectangle.y, @rectangle.width, @rectangle.height)
		@isPressed = false


# model of piano keyboard
# usage:
#   keyboard = new PianoKeyboard(new PianoKeyboardDesign)
#   scene.add(keyboard.model) # scene is an instance of THREE.Scene
#   setInterval(keyboard.update, 1000 / 60) 
#   keyboard.press(30)   # press the key of note 30(G1)
#   keyboard.release(60) # release the key of note 60(C4)
class PianoKeyboard2D
	constructor: (design, noteToColor) ->
	    @keys = []
	    
	    canvas = document.getElementById("keyboard-2D")
	    canvas.setAttribute("width", $("body").width())
	    context = canvas.getContext("2d")
	    
	    scale = 80
	    # create piano keys
	    for note in [0...design.keyInfo.length]
	        key = new PianoKey2D(design, note, context, 20 < note < 109, scale)
	        @keys.push(key)

	press: (note) ->
		@keys[note].press()

	release: (note) ->
		@keys[note].release()

@PianoKeyboard2D = PianoKeyboard2D