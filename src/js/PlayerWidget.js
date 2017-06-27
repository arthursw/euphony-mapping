// Generated by CoffeeScript 1.10.0
(function() {
  var PlayerWidget,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  PlayerWidget = (function() {
    function PlayerWidget(container) {
      this.displayProgress = bind(this.displayProgress, this);
      this.getRandomTrack = bind(this.getRandomTrack, this);
      this.setTrackFromHash = bind(this.setTrackFromHash, this);
      this.setTrack = bind(this.setTrack, this);
      this.ontrackchange = bind(this.ontrackchange, this);
      this.onnext = bind(this.onnext, this);
      this.onprev = bind(this.onprev, this);
      this.onstop = bind(this.onstop, this);
      this.onresume = bind(this.onresume, this);
      this.onpause = bind(this.onpause, this);
      this.onplay = bind(this.onplay, this);
      this.hide = bind(this.hide, this);
      this.show = bind(this.show, this);
      this.updateSize = bind(this.updateSize, this);
      this.toggle = bind(this.toggle, this);
      this.autoHide = bind(this.autoHide, this);
      this.$container = $(container);
      this.$controlsContainer = $('.player-controls', this.$container);
      this.$playlistContainer = $('.player-playlist-container', this.$container);
      this.$progressContainer = $('.player-progress-container', this.$container);
      this.$controlsToggleBtn = $('.player-toggle', this.$container);
      this.$progressBar = $('.player-progress-bar', this.$container);
      this.$progressText = $('.player-progress-text', this.$container);
      this.$playlist = $('.player-playlist', this.$container);
      this.$prevBtn = $('.player-prev', this.$container);
      this.$nextBtn = $('.player-next', this.$container);
      this.$playBtn = $('.player-play', this.$container);
      this.$stopBtn = $('.player-stop', this.$container);
      this.$pauseBtn = $('.player-pause', this.$container);
      this.canvasKeyboard = $('#keyboard-2D');
      this.$controlsToggleBtn.hover((function(_this) {
        return function() {
          return _this.toggle();
        };
      })(this));
      this.$prevBtn.click((function(_this) {
        return function() {
          return _this.onprev();
        };
      })(this));
      this.$nextBtn.click((function(_this) {
        return function() {
          return _this.onnext();
        };
      })(this));
      this.$stopBtn.click((function(_this) {
        return function() {
          return _this.stop();
        };
      })(this));
      this.$pauseBtn.click((function(_this) {
        return function() {
          return _this.pause();
        };
      })(this));
      this.$playBtn.click((function(_this) {
        return function() {
          if (_this.current === 'paused') {
            return _this.resume();
          } else {
            return _this.play();
          }
        };
      })(this));
      this.$progressContainer.click((function(_this) {
        return function(event) {
          var progress;
          progress = (event.clientX - _this.$progressContainer.offset().left) / _this.$progressContainer.width();
          return typeof _this.progressCallback === "function" ? _this.progressCallback(progress) : void 0;
        };
      })(this));
      this.$playlist.click((function(_this) {
        return function(event) {
          var $list, $target;
          $target = $(event.target);
          if ($target.is('li')) {
            $list = $('li', _this.$playlist);
            return _this.setTrack($list.index($target));
          }
        };
      })(this));
      this.$container.on('mousewheel', function(event) {
        return event.stopPropagation();
      });
      this.updateSize();
      $(window).resize(this.updateSize);
      $(window).on('hashchange', this.setTrackFromHash);
    }

    PlayerWidget.prototype.autoHide = function() {
      var onmousemove;
      onmousemove = (function(_this) {
        return function(event) {
          if (event.pageX < 10) {
            return _this.show();
          }
        };
      })(this);
      return $(document).on('mousemove', onmousemove).on('mousedown', (function(_this) {
        return function() {
          $(_this).off('mousemove', onmousemove);
          if (event.pageX > 300 && !window.app.lock2DGUI) {
            return _this.hide();
          }
        };
      })(this)).on('mouseup', function() {
        return $(this).on('mousemove', onmousemove);
      });
    };

    PlayerWidget.prototype.toggle = function() {
      if (this.visible) {
        return this.hide();
      } else {
        return this.show();
      }
    };

    PlayerWidget.prototype.updateSize = function() {
      this.$playlistContainer.height(this.$container.innerHeight() - this.$controlsContainer.outerHeight(true) - this.$progressContainer.outerHeight(true) - 15).nanoScroller();
      if (this.visible) {
        return this.canvasKeyboard.css({
          bottom: 0
        });
      } else {
        return this.canvasKeyboard.css({
          bottom: -this.canvasKeyboard.height()
        });
      }
    };

    PlayerWidget.prototype.show = function(callback) {
      if (this.visible || this.animating) {
        return;
      }
      this.visible = true;
      this.animating = true;
      this.$container.animate({
        left: '0px'
      }, {
        duration: 500,
        easing: 'easeInOutCubic',
        complete: (function(_this) {
          return function() {
            _this.animating = false;
            return typeof callback === "function" ? callback() : void 0;
          };
        })(this)
      });
      this.$controlsToggleBtn.find("i").removeClass("fa-angle-double-right").addClass("fa-angle-double-left");
      return this.canvasKeyboard.animate({
        bottom: '0px'
      }, {
        duration: 500,
        easing: 'easeInOutCubic'
      });
    };

    PlayerWidget.prototype.hide = function(callback) {
      if (!this.visible || this.animating) {
        return;
      }
      this.visible = false;
      this.animating = true;
      this.$container.animate({
        left: (-this.$container.width()) + "px"
      }, {
        duration: 500,
        easing: 'easeInOutCubic',
        complete: (function(_this) {
          return function() {
            _this.animating = false;
            return typeof callback === "function" ? callback() : void 0;
          };
        })(this)
      });
      this.$controlsToggleBtn.find("i").removeClass("fa-angle-double-left").addClass("fa-angle-double-right");
      return this.canvasKeyboard.animate({
        bottom: -this.canvasKeyboard.height()
      }, {
        duration: 500,
        easing: 'easeInOutCubic'
      });
    };

    PlayerWidget.prototype.setPlaylist = function(playlist) {
      var i, len, ref, trackName;
      this.playlist = playlist;
      this.$playlist.html('');
      ref = this.playlist;
      for (i = 0, len = ref.length; i < len; i++) {
        trackName = ref[i];
        this.$playlist.append($('<li>').text(trackName));
      }
      return this.$playlistContainer.nanoScroller();
    };

    PlayerWidget.prototype.on = function(eventName, callback) {
      return this[eventName + "Callback"] = callback;
    };

    PlayerWidget.prototype.onplay = function() {
      this.$playBtn.hide();
      this.$pauseBtn.show();
      return typeof this.playCallback === "function" ? this.playCallback() : void 0;
    };

    PlayerWidget.prototype.onpause = function() {
      this.$pauseBtn.hide();
      this.$playBtn.show();
      return typeof this.pauseCallback === "function" ? this.pauseCallback() : void 0;
    };

    PlayerWidget.prototype.onresume = function() {
      this.$playBtn.hide();
      this.$pauseBtn.show();
      return typeof this.resumeCallback === "function" ? this.resumeCallback() : void 0;
    };

    PlayerWidget.prototype.onstop = function() {
      this.$pauseBtn.hide();
      this.$playBtn.show();
      return typeof this.stopCallback === "function" ? this.stopCallback() : void 0;
    };

    PlayerWidget.prototype.onprev = function() {
      if (!(this.currentTrackId > 0)) {
        return;
      }
      this.currentTrackId -= 1;
      return this.setTrack(this.currentTrackId);
    };

    PlayerWidget.prototype.onnext = function() {
      if (!(this.currentTrackId < this.playlist.length - 1)) {
        return;
      }
      this.currentTrackId += 1;
      return this.setTrack(this.currentTrackId);
    };

    PlayerWidget.prototype.ontrackchange = function(trackId) {
      var ref;
      if (!((0 <= trackId && trackId < this.playlist.length))) {
        return;
      }
      this.stop();
      if ((ref = this.$currentTrack) != null) {
        ref.removeClass('player-current-track');
      }
      this.$currentTrack = this.$playlist.find("li").eq(trackId).addClass('player-current-track');
      if (typeof this.trackchangeCallback === "function") {
        this.trackchangeCallback(trackId);
      }
      return this.currentTrackId = trackId;
    };

    PlayerWidget.prototype.setTrack = function(trackId) {
      return window.location.hash = trackId + 1;
    };

    PlayerWidget.prototype.setTrackFromHash = function() {
      var hash;
      hash = window.location.hash.slice(1);
      if (hash) {
        return this.ontrackchange(parseInt(hash, 10) - 1);
      }
    };

    PlayerWidget.prototype.getRandomTrack = function() {
      return this.playlist[Math.floor(Math.random() * this.playlist.length)];
    };

    PlayerWidget.prototype.displayProgress = function(event) {
      var curTime, current, progress, totTime, total;
      current = event.current, total = event.total;
      current = Math.min(current, total);
      progress = current / total;
      this.$progressBar.width(this.$progressContainer.width() * progress);
      curTime = this._formatTime(current);
      totTime = this._formatTime(total);
      return this.$progressText.text(curTime + " / " + totTime);
    };

    PlayerWidget.prototype._formatTime = function(time) {
      var minutes, seconds;
      minutes = time / 60 >> 0;
      seconds = String(time - (minutes * 60) >> 0);
      if (seconds.length === 1) {
        seconds = "0" + seconds;
      }
      return minutes + ":" + seconds;
    };

    return PlayerWidget;

  })();

  StateMachine.create({
    target: PlayerWidget.prototype,
    events: [
      {
        name: 'init',
        from: 'none',
        to: 'ready'
      }, {
        name: 'play',
        from: 'ready',
        to: 'playing'
      }, {
        name: 'pause',
        from: 'playing',
        to: 'paused'
      }, {
        name: 'resume',
        from: 'paused',
        to: 'playing'
      }, {
        name: 'stop',
        from: '*',
        to: 'ready'
      }
    ]
  });

  this.PlayerWidget = PlayerWidget;

}).call(this);
