class SimpleScene
	constructor: (container) ->
		# set dom container
		$container = $(container)
		width = $container.width()
		height = $container.height()

		@width = width
		@height = height

		@cameraOrtho = new THREE.OrthographicCamera( - width / 2, width / 2, height / 2, - height / 2, 1, 10 )
		@cameraOrtho.position.z = 10

		@sceneOrtho = new THREE.Scene()

		# create scene
		# scene = new THREE.Scene()

		# create camera
		# camera = new THREE.PerspectiveCamera(60, width / height, 0.001, 100000)
		# camera.lookAt(new THREE.Vector3())
		# scene.add(camera)

		# create renderer
		renderer = new THREE.WebGLRenderer(antialias: true)
		renderer.setSize(width, height)
		renderer.setClearColor(0x000000, 1)
		renderer.autoClear = false
		$container.append(renderer.domElement)

		# create lights
		# ambientLight = new THREE.AmbientLight(0x222222)
		# scene.add(ambientLight)

		# mainLight = new THREE.DirectionalLight(0xffffff, 0.8)
		# mainLight.position.set(1, 2, 4).normalize()
		# scene.add(mainLight)

		# auxLight = new THREE.DirectionalLight(0xffffff, 0.3)
		# auxLight.position.set(-4, -1, -2).normalize()
		# scene.add(auxLight)

		# controls = new THREE.OrbitControls(camera)
		# controls.center.set(8.73, 0, 0)
		# controls.autoRotateSpeed = 1.0
		# controls.autoRotate = false
		# camera.position.copy(controls.center).add(new THREE.Vector3(2, 6, 9))

		$(window).resize(@onresize)

		# set instance variables
		@$container = $container
		# @camera = camera
		# @scene = scene
		@renderer = renderer
		# @controls = controls

	onresize: =>
		[width, height] = [@$container.width(), @$container.height()]
		console.log("SimpleScene on resize: " + width + ", " + height)
		@width = width
		@height = height
		@cameraOrtho.left = - width / 2
		@cameraOrtho.right = width / 2
		@cameraOrtho.top = height / 2
		@cameraOrtho.bottom = - height / 2
		@cameraOrtho.updateProjectionMatrix()

		# @camera.aspect = width / height
		# @camera.updateProjectionMatrix()
		@renderer.setSize(width, height)

	add: (object) ->
		@sceneOrtho.add(object)

	remove: (object) ->
		@sceneOrtho.remove(object)

	animate: (callback) =>
		requestAnimationFrame => @animate(callback)
		callback?()
		# @controls.update()
		@renderer.clear()
		@renderer.clearDepth()
		@renderer.render(@sceneOrtho, @cameraOrtho)

# export Scene to global
@SimpleScene = SimpleScene
