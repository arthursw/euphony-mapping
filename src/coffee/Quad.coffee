# Quad: build and draw the webGl quad controlled with 4 2D sprites
# A projective transformation matrix is computed (to go from the corner positions to the texture UVs)
# and sent to a fragment shader which compute the adequate texture coordinates
# Based on http://math.stackexchange.com/a/339033/117531
# http://stackoverflow.com/questions/20718663/computing-a-projective-transformation-to-texture-an-arbitrary-quad
class Quad
	constructor: (width, height, canvasKeyboard, @scene) ->


		# @sceneX = @scene.$container.position().left
		# @sceneY = @scene.$container.position().top

		# @scene.width = width
		# @scene.height = height

		console.log('quad: ' + width + 'x' + height)
		console.log('scene: ' + @scene.width + 'x' + @scene.height)

		@projector = new THREE.Projector()
		@camera = @scene.sceneOrtho

		margin = 100

		# --- QuadGeometry --- #

		@geometry = new THREE.Geometry()

		normal = new THREE.Vector3( 0, 0, 1 )

		@positions = []
		@positions.push( x: -width/2 + margin, y: height/2 - margin )
		@positions.push( x: width/2 - margin, y: height/2 - margin )
		@positions.push( x: -width/2 + margin, y: -height/2 + margin )
		@positions.push( x: width/2 - margin, y: -height/2 + margin )

		for position in @positions
			@geometry.vertices.push( new THREE.Vector3( position.x, position.y, 0 ) )

		uv0 = new THREE.Vector4(0,1,0,1)
		uv1 = new THREE.Vector4(1,1,0,1)
		uv2 = new THREE.Vector4(0,0,0,1)
		uv3 = new THREE.Vector4(1,0,0,1)

		face = new THREE.Face3( 0, 2, 1)
		face.normal.copy( normal )
		face.vertexNormals.push( normal.clone(), normal.clone(), normal.clone() )

		@geometry.faces.push( face )
		@geometry.faceVertexUvs[ 0 ].push( [ uv0.clone(), uv2.clone(), uv1.clone() ] )

		face = new THREE.Face3( 1, 2, 3)
		face.normal.copy( normal )
		face.vertexNormals.push( normal.clone(), normal.clone(), normal.clone() )

		@geometry.faces.push( face )
		@geometry.faceVertexUvs[ 0 ].push( [ uv1.clone(), uv2.clone(), uv3.clone() ] )

		@geometry.computeCentroids()

		# --- Mesh --- #

		@texture = new THREE.Texture(canvasKeyboard[0])
		@texture.needsUpdate = true

		C = new THREE.Matrix4()
		# it seems three.js handles Matrix4, but not Matrix3...
		@uniforms = { "texture": { type: "t", value: @texture }, "resolution": { type: "v2", value: new THREE.Vector2(@scene.width, @scene.height) }, "matC": { type: "m4", value: C } }

		shaderMaterial = new THREE.ShaderMaterial(
			uniforms:     	@uniforms,
			vertexShader:   $('#vertexshader').text(),
			fragmentShader: $('#fragmentshader').text()
		)

		@mesh = new THREE.Mesh( @geometry, shaderMaterial )

		@mesh.position.set(0,0,1)

		@scene.add(@mesh)

		# --- Sprites --- #

		@sprites = []

		circleImage = document.createElement('canvas')
		context = circleImage.getContext('2d')
		size = 30
		strokeWidth = 5
		circleImage.width = size
		circleImage.height = size
		pos = size/2
		radius = size/2 - strokeWidth
		context.beginPath()
		context.arc(pos, pos, radius, 0, 2*Math.PI, false)
		context.fillStyle = 'black'
		context.fill()
		context.lineWidth = strokeWidth
		context.strokeStyle = 'white'
		context.stroke()

		spriteTexture = new THREE.Texture( circleImage )
		spriteTexture.needsUpdate = true

		for i in [0..3]
			position = @positions[i]
			spriteMaterial = new THREE.SpriteMaterial( {map: spriteTexture, side: THREE.DoubleSide } )
			s = new THREE.Sprite( spriteMaterial )
			s.scale.set( size, size, 1.0 )
			s.position.set(position.x,position.y,1)
			@scene.add(s)
			@sprites.push(s)

		# --- Mouse handlers --- #
		@dragging = false
		@draggingOffset = new THREE.Vector3()
		@scene.$container.mousedown(@mouseDown)
		@scene.$container.mousemove(@mouseMove)
		@scene.$container.mouseup(@mouseUp)
		$(window).keydown(@keyDown)
		@loadQuad()
		return

	screenToWorld: (mouseX, mouseY) ->
		return new THREE.Vector3(mouseX-@scene.width/2, -mouseY+@scene.height/2, 1)

	worldToScreen: (pos) ->
		return new THREE.Vector2((pos.x / @scene.width)+0.5, (pos.y / @scene.height)+0.5)
		# return new THREE.Vector2(@sceneWidth*(pos.x+1)/2, @sceneHeight*(-(pos.y-1)/2))

	# worldToScreen: (pos) ->
	# 	screenPos = @projector.projectVector(pos.clone(), @camera)
	# 	screenPos.x = (screenPos.x+1)/2 * @sceneWidth
	# 	screenPos.y = -(screenPos.y-1)/2 * @sceneHeight
	# 	screenPos.x += @sceneX
	# 	@scenePos.y += @sceneY
	# 	return screenPos

	saveQuad: ()->
		quad = []
		for sprite, i in @sprites
			quad.push(sprite.position)
		@save('quad', quad)
		return

	loadQuad: ()->
		quad = @load('quad')
		if quad?
			for corner, i in quad
				position = new THREE.Vector3(corner.x, corner.y, corner.z)
				@sprites[i].position = position
				@mesh.geometry.vertices[i] = position
			@mesh.geometry.verticesNeedUpdate = true
		return

	mouseDown: (event) =>
		mousePos = @screenToWorld(event.pageX, event.pageY)
		@selectedSprite?.material.color = new THREE.Color(0xFFFFFF)
		@selectedSprite = null
		@selectedIndex = -1
		@dragging = false
		console.log('scene size: ' + @scene.width + ', ' + @scene.height)
		console.log('event: ' + event.pageX + ', ' + event.pageY)
		console.log('mousePos: ' + mousePos.x + ', ' + mousePos.y)
		for sprite,i in @sprites
			console.log('sprite.position: ' + sprite.position.x + ', ' + sprite.position.y)
			if sprite.position.distanceTo(mousePos) < 32
				@selectedSprite = sprite
				@selectedIndex = i
				@dragging = true
				@draggingOffset = new THREE.Vector3(mousePos.x-sprite.position.x, mousePos.y-sprite.position.y, 0)
				@selectedSprite.material.color = new THREE.Color(0x9ACD32)
		return

	mouseMove: (event) =>
		if @selectedSprite? and @dragging
			mousePos = @screenToWorld(event.pageX, event.pageY).sub(@draggingOffset)
			@selectedSprite.position.copy(mousePos)
			@mesh.geometry.vertices[@selectedIndex] = mousePos
			@mesh.geometry.verticesNeedUpdate = true
		return

	mouseUp: (event) =>
		if @selectedSprite? and @dragging
			mousePos = @screenToWorld(event.pageX, event.pageY).sub(@draggingOffset)
			@selectedSprite.position.copy(mousePos)
			@mesh.geometry.vertices[@selectedIndex] = mousePos
			@mesh.geometry.verticesNeedUpdate = true
			@saveQuad()
			# @selectedSprite = null
			# @selectedIndex = -1
		@dragging = false
		return

	keyDown: (event)=>
		if event.which == 9 		# tab key
			@selectedSprite?.material.color = new THREE.Color(0xFFFFFF)
			console.log @selectedIndex
			@selectedIndex++
			if @selectedIndex>3 then @selectedIndex = 0
			@selectedSprite = @sprites[@selectedIndex]
			@selectedSprite.material.color = new THREE.Color(0x9ACD32)
			event.preventDefault()
			return
		if @selectedSprite?
			delta = 1
			if event.shiftKey then delta = 5
			if event.metaKey or event.ctrlKey then delta = 10
			switch event.which
				when 37 		# left
					@selectedSprite.position.x -= delta
				when 38 		# up
					@selectedSprite.position.y += delta
				when 39 		# right
					@selectedSprite.position.x += delta
				when 40 		# down
					@selectedSprite.position.y -= delta
			@mesh.geometry.vertices[@selectedIndex] = @selectedSprite.position
			@mesh.geometry.verticesNeedUpdate = true
			@saveQuad()
		return

	inverseMatrix:  ( a ) ->
		ae = a.elements

		t = new THREE.Matrix3()
		te = t.elements

		a11 = ae[0]
		a12 = ae[3]
		a13 = ae[6]
		a21 = ae[1]
		a22 = ae[4]
		a23 = ae[7]
		a31 = ae[2]
		a32 = ae[5]
		a33 = ae[8]

		detA = a11 * a22 * a33 + a21 * a32 * a13 + a31 * a12 * a23 - a11 * a32 * a23 - a31 * a22 * a13 - a21 * a12 * a33
		detAinv = 1/detA

		te[0] = detAinv * (a22 * a33 - a23 * a32)
		te[3] = detAinv * (a13 * a32 - a12 * a33)
		te[6] = detAinv * (a12 * a23 - a13 * a22)

		te[1] = detAinv * (a23 * a31 - a21 * a33)
		te[4] = detAinv * (a11 * a33 - a13 * a31)
		te[7] = detAinv * (a13 * a21 - a11 * a23)

		te[2] = detAinv * (a21 * a32 - a22 * a31)
		te[5] = detAinv * (a12 * a31 - a11 * a32)
		te[8] = detAinv * (a11 * a22 - a12 * a21)

		return t

	multiplyMatrices:  ( a, b ) ->
		ae = a.elements
		be = b.elements
		t = new THREE.Matrix3()
		te = t.elements

		a11 = ae[0]
		a12 = ae[3]
		a13 = ae[6]
		a21 = ae[1]
		a22 = ae[4]
		a23 = ae[7]
		a31 = ae[2]
		a32 = ae[5]
		a33 = ae[8]

		b11 = be[0]
		b12 = be[3]
		b13 = be[6]
		b21 = be[1]
		b22 = be[4]
		b23 = be[7]
		b31 = be[2]
		b32 = be[5]
		b33 = be[8]

		te[0] = a11 * b11 + a12 * b21 + a13 * b31
		te[3] = a11 * b12 + a12 * b22 + a13 * b32
		te[6] = a11 * b13 + a12 * b23 + a13 * b33

		te[1] = a21 * b11 + a22 * b21 + a23 * b31
		te[4] = a21 * b12 + a22 * b22 + a23 * b32
		te[7] = a21 * b13 + a22 * b23 + a23 * b33

		te[2] = a31 * b11 + a32 * b21 + a33 * b31
		te[5] = a31 * b12 + a32 * b22 + a33 * b32
		te[8] = a31 * b13 + a32 * b23 + a33 * b33

		return t

	multiplyMatrixVector:  ( a, v ) ->
		ae = a.elements
		r = new THREE.Vector3()

		a11 = ae[0]
		a12 = ae[3]
		a13 = ae[6]
		a21 = ae[1]
		a22 = ae[4]
		a23 = ae[7]
		a31 = ae[2]
		a32 = ae[5]
		a33 = ae[8]

		r.x = a11 * v.x + a12 * v.y + a13 * v.z
		r.y = a21 * v.x + a22 * v.y + a23 * v.z
		r.z = a31 * v.x + a32 * v.y + a33 * v.z

		return r

	printVector:  ( v, str ) ->
		if str?
			console.log str

		console.log(v.x + " " + v.y + " " + v.z)

	printMatrix:  ( m, str ) ->
		if str?
			console.log str

		ae = m.elements

		a11 = ae[0]
		a12 = ae[3]
		a13 = ae[6]
		a21 = ae[1]
		a22 = ae[4]
		a23 = ae[7]
		a31 = ae[2]
		a32 = ae[5]
		a33 = ae[8]

		console.log(a11 + " " + a12 + " " + a13)
		console.log(a21 + " " + a22 + " " + a23)
		console.log(a31 + " " + a32 + " " + a33)

	resize: ()=>
		@uniforms.resolution.value = new THREE.Vector2(@scene.width*window.devicePixelRatio, @scene.height*window.devicePixelRatio)

	computeTextureProjection: ()=>
		pos1 = @worldToScreen(@sprites[0].position)
		pos2 = @worldToScreen(@sprites[1].position)
		pos3 = @worldToScreen(@sprites[2].position)
		pos4 = @worldToScreen(@sprites[3].position)

		srcMat = new THREE.Matrix3(pos1.x, pos2.x, pos3.x, pos1.y, pos2.y, pos3.y, 1, 1, 1)
		srcMatInv = @inverseMatrix(srcMat)
		srcVars = @multiplyMatrixVector(srcMatInv, new THREE.Vector3(pos4.x, pos4.y, 1))
		A = new THREE.Matrix3(pos1.x*srcVars.x, pos2.x*srcVars.y, pos3.x*srcVars.z, pos1.y*srcVars.x, pos2.y*srcVars.y, pos3.y*srcVars.z, srcVars.x, srcVars.y, srcVars.z)

		dstMat = new THREE.Matrix3(0, 1, 0, 1, 1, 0, 1, 1, 1)
		dstMatInv = @inverseMatrix(dstMat)
		dstVars = @multiplyMatrixVector(dstMatInv, new THREE.Vector3(1, 0, 1))
		B = new THREE.Matrix3(0, dstVars.y, 0, dstVars.x, dstVars.y, 0, dstVars.x, dstVars.y, dstVars.z)

		Ainv =  @inverseMatrix(A)

		C = @multiplyMatrices(B,Ainv)

		ce = C.elements
		@uniforms.matC.value = new THREE.Matrix4(ce[0], ce[3], ce[6], 0, ce[1], ce[4], ce[7], 0, ce[2], ce[5], ce[8], 0, 0, 0, 0, 0)
		return

	save: (key, value)->
		localStorage.setItem(key, JSON.stringify(value))
		return

	load: (key)->
		value = localStorage.getItem(key)
		return value && JSON.parse(value)

@Quad = Quad
