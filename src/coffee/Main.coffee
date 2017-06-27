$(document)
	.on 'selectstart', ->
		false
	.on 'mousewheel', ->
		false
	.on 'dragover', ->
		false
	.on 'dragenter', ->
		false
	.on 'ready', ->

		# paper.install(window)
		$('#keyboard-2D')[0].width = $('#canvas').width()
		$('#keyboard-2D')[0].height = $('#canvas').height()
		paper.setup($('#keyboard-2D')[0])
		console.log(paper.view.width)
		# paper.keepalive = true

		window.gui = new dat.GUI()

		#
		# textFile = null
		#
		# makeTextFile = (data) ->
		#		 data = new Blob([ data ], type: 'application/octet-stream')
		#		 # If we are replacing a previously generated file we need to
		#		 # manually revoke the object URL to avoid memory leaks.
		#		 if textFile != null
		#				 window.URL.revokeObjectURL textFile
		#		 textFile = window.URL.createObjectURL(data)
		#		 return textFile
		#
		# link = document.getElementById('downloadlink')
		# link.href = makeTextFile(file.toBytes())


		# global loader to show progress
		window.loader = new LoaderWidget()
		loader.message('Downloading')

		#start app
		window.app = new Euphony()
		window.app.lock2DGUI = true

		button = window.gui.add(window.app, 'saveMidi')
		#
		# inputJ = $('<input type="file" id="files" name="files[]" multiple />')
		# $(button.domElement).append(inputJ)
		# inputJ[0].addEventListener('change', window.app.saveFile, false)

		window.gui.add(window.app, 'lock2DGUI').onChange (value)->
			if not value
				player.hide()
				player.autoHide()
			else
				player.show()
			return

		window.gui.add({speed: 1}, 'speed', 0.1, 10).onChange (value)->
			# value = ( Math.log10(1.0 / value) + 1.0 ) / 2
			# console.log 1.0 / value
			app.player.timeWarp = 1.0 / value
			return

		window.gui.add(app, 'timeDivision', { '1/1': 1, '1/2': 0.5, '1/4': 0.25, '1/8': 0.125, '1/16': 0.0625, '1/32': 0.03125 }).onChange(app.rain.onTimeDivisionChange)
		window.gui.add(app, 'noteDuration', { '1/1': 1, '1/2': 0.5, '1/4': 0.25, '1/8': 0.125, '1/16': 0.0625, '1/32': 0.03125 })

		app.initMidi ->
			app.initScene()
			app.loadBuiltinPlaylist (playlist) ->
				window.player = new PlayerWidget('#player')
				player.setPlaylist(playlist)
				player.on('pause', app.pause)
				player.on('resume', app.resume)
				player.on('stop', app.stop)
				player.on('play', app.start)
				player.on('progress', app.setProgress)
				player.on 'trackchange', (trackId) ->
					loader.message 'Loading MIDI', ->
						app.loadBuiltinMidi trackId, ->
							loader.stop ->
								player.play()
				player.on 'filedrop', (midiFile) ->
					player.stop()
					loader.message 'Loading MIDI', ->
						app.loadMidiFile midiFile, ->
							loader.stop ->
								player.play()
				app.on('progress', player.displayProgress)

				player.show ->
					if window.location.hash
						player.setTrackFromHash()
					else
						candidates = [3, 5, 6, 7, 10, 11, 12, 13, 14, 16, 19, 30]
						id = Math.floor(Math.random() * candidates.length)
						player.setTrack(candidates[id])

				setTimeout (->
					if not window.app.lock2DGUI
						player.hide()
						player.autoHide()
				), 5000

				# drag and drop MIDI files to play
				$(document).on 'drop', (event) ->
					event or= window.event
					event.preventDefault()
					event.stopPropagation()

					# jquery wraps the original event
					event = event.originalEvent or event

					files = event.files or event.dataTransfer.files
					file = files[0]

					reader = new FileReader()
					reader.onload = (e) ->
						midiFile = e.target.result
						player.stop()
						loader.message 'Loading MIDI', ->
							app.loadMidiFile midiFile, ->
								loader.stop ->
									player.play()
					reader.readAsDataURL(file)
