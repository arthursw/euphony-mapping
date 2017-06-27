// Generated by CoffeeScript 1.10.0
(function() {
  var Quad,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Quad = (function() {
    function Quad(width, height, canvasKeyboard, scene) {
      var C, circleImage, context, face, i, j, k, len, margin, normal, pos, position, radius, ref, s, shaderMaterial, size, spriteMaterial, spriteTexture, strokeWidth, uv0, uv1, uv2, uv3;
      this.scene = scene;
      this.computeTextureProjection = bind(this.computeTextureProjection, this);
      this.resize = bind(this.resize, this);
      this.keyDown = bind(this.keyDown, this);
      this.mouseUp = bind(this.mouseUp, this);
      this.mouseMove = bind(this.mouseMove, this);
      this.mouseDown = bind(this.mouseDown, this);
      console.log('quad: ' + width + 'x' + height);
      console.log('scene: ' + this.scene.width + 'x' + this.scene.height);
      this.projector = new THREE.Projector();
      this.camera = this.scene.sceneOrtho;
      margin = 100;
      this.geometry = new THREE.Geometry();
      normal = new THREE.Vector3(0, 0, 1);
      this.positions = [];
      this.positions.push({
        x: -width / 2 + margin,
        y: height / 2 - margin
      });
      this.positions.push({
        x: width / 2 - margin,
        y: height / 2 - margin
      });
      this.positions.push({
        x: -width / 2 + margin,
        y: -height / 2 + margin
      });
      this.positions.push({
        x: width / 2 - margin,
        y: -height / 2 + margin
      });
      ref = this.positions;
      for (j = 0, len = ref.length; j < len; j++) {
        position = ref[j];
        this.geometry.vertices.push(new THREE.Vector3(position.x, position.y, 0));
      }
      uv0 = new THREE.Vector4(0, 1, 0, 1);
      uv1 = new THREE.Vector4(1, 1, 0, 1);
      uv2 = new THREE.Vector4(0, 0, 0, 1);
      uv3 = new THREE.Vector4(1, 0, 0, 1);
      face = new THREE.Face3(0, 2, 1);
      face.normal.copy(normal);
      face.vertexNormals.push(normal.clone(), normal.clone(), normal.clone());
      this.geometry.faces.push(face);
      this.geometry.faceVertexUvs[0].push([uv0.clone(), uv2.clone(), uv1.clone()]);
      face = new THREE.Face3(1, 2, 3);
      face.normal.copy(normal);
      face.vertexNormals.push(normal.clone(), normal.clone(), normal.clone());
      this.geometry.faces.push(face);
      this.geometry.faceVertexUvs[0].push([uv1.clone(), uv2.clone(), uv3.clone()]);
      this.geometry.computeCentroids();
      this.texture = new THREE.Texture(canvasKeyboard[0]);
      this.texture.needsUpdate = true;
      C = new THREE.Matrix4();
      this.uniforms = {
        "texture": {
          type: "t",
          value: this.texture
        },
        "resolution": {
          type: "v2",
          value: new THREE.Vector2(this.scene.width, this.scene.height)
        },
        "matC": {
          type: "m4",
          value: C
        }
      };
      shaderMaterial = new THREE.ShaderMaterial({
        uniforms: this.uniforms,
        vertexShader: $('#vertexshader').text(),
        fragmentShader: $('#fragmentshader').text()
      });
      this.mesh = new THREE.Mesh(this.geometry, shaderMaterial);
      this.mesh.position.set(0, 0, 1);
      this.scene.add(this.mesh);
      this.sprites = [];
      circleImage = document.createElement('canvas');
      context = circleImage.getContext('2d');
      size = 30;
      strokeWidth = 5;
      circleImage.width = size;
      circleImage.height = size;
      pos = size / 2;
      radius = size / 2 - strokeWidth;
      context.beginPath();
      context.arc(pos, pos, radius, 0, 2 * Math.PI, false);
      context.fillStyle = 'black';
      context.fill();
      context.lineWidth = strokeWidth;
      context.strokeStyle = 'white';
      context.stroke();
      spriteTexture = new THREE.Texture(circleImage);
      spriteTexture.needsUpdate = true;
      for (i = k = 0; k <= 3; i = ++k) {
        position = this.positions[i];
        spriteMaterial = new THREE.SpriteMaterial({
          map: spriteTexture,
          side: THREE.DoubleSide
        });
        s = new THREE.Sprite(spriteMaterial);
        s.scale.set(size, size, 1.0);
        s.position.set(position.x, position.y, 1);
        this.scene.add(s);
        this.sprites.push(s);
      }
      this.dragging = false;
      this.draggingOffset = new THREE.Vector3();
      this.scene.$container.mousedown(this.mouseDown);
      this.scene.$container.mousemove(this.mouseMove);
      this.scene.$container.mouseup(this.mouseUp);
      $(window).keydown(this.keyDown);
      this.loadQuad();
      return;
    }

    Quad.prototype.screenToWorld = function(mouseX, mouseY) {
      return new THREE.Vector3(mouseX - this.scene.width / 2, -mouseY + this.scene.height / 2, 1);
    };

    Quad.prototype.worldToScreen = function(pos) {
      return new THREE.Vector2((pos.x / this.scene.width) + 0.5, (pos.y / this.scene.height) + 0.5);
    };

    Quad.prototype.saveQuad = function() {
      var i, j, len, quad, ref, sprite;
      quad = [];
      ref = this.sprites;
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        sprite = ref[i];
        quad.push(sprite.position);
      }
      this.save('quad', quad);
    };

    Quad.prototype.loadQuad = function() {
      var corner, i, j, len, position, quad;
      quad = this.load('quad');
      if (quad != null) {
        for (i = j = 0, len = quad.length; j < len; i = ++j) {
          corner = quad[i];
          position = new THREE.Vector3(corner.x, corner.y, corner.z);
          this.sprites[i].position = position;
          this.mesh.geometry.vertices[i] = position;
        }
        this.mesh.geometry.verticesNeedUpdate = true;
      }
    };

    Quad.prototype.mouseDown = function(event) {
      var i, j, len, mousePos, ref, ref1, sprite;
      mousePos = this.screenToWorld(event.pageX, event.pageY);
      if ((ref = this.selectedSprite) != null) {
        ref.material.color = new THREE.Color(0xFFFFFF);
      }
      this.selectedSprite = null;
      this.selectedIndex = -1;
      this.dragging = false;
      console.log('scene size: ' + this.scene.width + ', ' + this.scene.height);
      console.log('event: ' + event.pageX + ', ' + event.pageY);
      console.log('mousePos: ' + mousePos.x + ', ' + mousePos.y);
      ref1 = this.sprites;
      for (i = j = 0, len = ref1.length; j < len; i = ++j) {
        sprite = ref1[i];
        console.log('sprite.position: ' + sprite.position.x + ', ' + sprite.position.y);
        if (sprite.position.distanceTo(mousePos) < 32) {
          this.selectedSprite = sprite;
          this.selectedIndex = i;
          this.dragging = true;
          this.draggingOffset = new THREE.Vector3(mousePos.x - sprite.position.x, mousePos.y - sprite.position.y, 0);
          this.selectedSprite.material.color = new THREE.Color(0x9ACD32);
        }
      }
    };

    Quad.prototype.mouseMove = function(event) {
      var mousePos;
      if ((this.selectedSprite != null) && this.dragging) {
        mousePos = this.screenToWorld(event.pageX, event.pageY).sub(this.draggingOffset);
        this.selectedSprite.position.copy(mousePos);
        this.mesh.geometry.vertices[this.selectedIndex] = mousePos;
        this.mesh.geometry.verticesNeedUpdate = true;
      }
    };

    Quad.prototype.mouseUp = function(event) {
      var mousePos;
      if ((this.selectedSprite != null) && this.dragging) {
        mousePos = this.screenToWorld(event.pageX, event.pageY).sub(this.draggingOffset);
        this.selectedSprite.position.copy(mousePos);
        this.mesh.geometry.vertices[this.selectedIndex] = mousePos;
        this.mesh.geometry.verticesNeedUpdate = true;
        this.saveQuad();
      }
      this.dragging = false;
    };

    Quad.prototype.keyDown = function(event) {
      var delta, ref;
      if (event.which === 9) {
        if ((ref = this.selectedSprite) != null) {
          ref.material.color = new THREE.Color(0xFFFFFF);
        }
        console.log(this.selectedIndex);
        this.selectedIndex++;
        if (this.selectedIndex > 3) {
          this.selectedIndex = 0;
        }
        this.selectedSprite = this.sprites[this.selectedIndex];
        this.selectedSprite.material.color = new THREE.Color(0x9ACD32);
        event.preventDefault();
        return;
      }
      if (this.selectedSprite != null) {
        delta = 1;
        if (event.shiftKey) {
          delta = 5;
        }
        if (event.metaKey || event.ctrlKey) {
          delta = 10;
        }
        switch (event.which) {
          case 37:
            this.selectedSprite.position.x -= delta;
            break;
          case 38:
            this.selectedSprite.position.y += delta;
            break;
          case 39:
            this.selectedSprite.position.x += delta;
            break;
          case 40:
            this.selectedSprite.position.y -= delta;
        }
        this.mesh.geometry.vertices[this.selectedIndex] = this.selectedSprite.position;
        this.mesh.geometry.verticesNeedUpdate = true;
        this.saveQuad();
      }
    };

    Quad.prototype.inverseMatrix = function(a) {
      var a11, a12, a13, a21, a22, a23, a31, a32, a33, ae, detA, detAinv, t, te;
      ae = a.elements;
      t = new THREE.Matrix3();
      te = t.elements;
      a11 = ae[0];
      a12 = ae[3];
      a13 = ae[6];
      a21 = ae[1];
      a22 = ae[4];
      a23 = ae[7];
      a31 = ae[2];
      a32 = ae[5];
      a33 = ae[8];
      detA = a11 * a22 * a33 + a21 * a32 * a13 + a31 * a12 * a23 - a11 * a32 * a23 - a31 * a22 * a13 - a21 * a12 * a33;
      detAinv = 1 / detA;
      te[0] = detAinv * (a22 * a33 - a23 * a32);
      te[3] = detAinv * (a13 * a32 - a12 * a33);
      te[6] = detAinv * (a12 * a23 - a13 * a22);
      te[1] = detAinv * (a23 * a31 - a21 * a33);
      te[4] = detAinv * (a11 * a33 - a13 * a31);
      te[7] = detAinv * (a13 * a21 - a11 * a23);
      te[2] = detAinv * (a21 * a32 - a22 * a31);
      te[5] = detAinv * (a12 * a31 - a11 * a32);
      te[8] = detAinv * (a11 * a22 - a12 * a21);
      return t;
    };

    Quad.prototype.multiplyMatrices = function(a, b) {
      var a11, a12, a13, a21, a22, a23, a31, a32, a33, ae, b11, b12, b13, b21, b22, b23, b31, b32, b33, be, t, te;
      ae = a.elements;
      be = b.elements;
      t = new THREE.Matrix3();
      te = t.elements;
      a11 = ae[0];
      a12 = ae[3];
      a13 = ae[6];
      a21 = ae[1];
      a22 = ae[4];
      a23 = ae[7];
      a31 = ae[2];
      a32 = ae[5];
      a33 = ae[8];
      b11 = be[0];
      b12 = be[3];
      b13 = be[6];
      b21 = be[1];
      b22 = be[4];
      b23 = be[7];
      b31 = be[2];
      b32 = be[5];
      b33 = be[8];
      te[0] = a11 * b11 + a12 * b21 + a13 * b31;
      te[3] = a11 * b12 + a12 * b22 + a13 * b32;
      te[6] = a11 * b13 + a12 * b23 + a13 * b33;
      te[1] = a21 * b11 + a22 * b21 + a23 * b31;
      te[4] = a21 * b12 + a22 * b22 + a23 * b32;
      te[7] = a21 * b13 + a22 * b23 + a23 * b33;
      te[2] = a31 * b11 + a32 * b21 + a33 * b31;
      te[5] = a31 * b12 + a32 * b22 + a33 * b32;
      te[8] = a31 * b13 + a32 * b23 + a33 * b33;
      return t;
    };

    Quad.prototype.multiplyMatrixVector = function(a, v) {
      var a11, a12, a13, a21, a22, a23, a31, a32, a33, ae, r;
      ae = a.elements;
      r = new THREE.Vector3();
      a11 = ae[0];
      a12 = ae[3];
      a13 = ae[6];
      a21 = ae[1];
      a22 = ae[4];
      a23 = ae[7];
      a31 = ae[2];
      a32 = ae[5];
      a33 = ae[8];
      r.x = a11 * v.x + a12 * v.y + a13 * v.z;
      r.y = a21 * v.x + a22 * v.y + a23 * v.z;
      r.z = a31 * v.x + a32 * v.y + a33 * v.z;
      return r;
    };

    Quad.prototype.printVector = function(v, str) {
      if (str != null) {
        console.log(str);
      }
      return console.log(v.x + " " + v.y + " " + v.z);
    };

    Quad.prototype.printMatrix = function(m, str) {
      var a11, a12, a13, a21, a22, a23, a31, a32, a33, ae;
      if (str != null) {
        console.log(str);
      }
      ae = m.elements;
      a11 = ae[0];
      a12 = ae[3];
      a13 = ae[6];
      a21 = ae[1];
      a22 = ae[4];
      a23 = ae[7];
      a31 = ae[2];
      a32 = ae[5];
      a33 = ae[8];
      console.log(a11 + " " + a12 + " " + a13);
      console.log(a21 + " " + a22 + " " + a23);
      return console.log(a31 + " " + a32 + " " + a33);
    };

    Quad.prototype.resize = function() {
      return this.uniforms.resolution.value = new THREE.Vector2(this.scene.width * window.devicePixelRatio, this.scene.height * window.devicePixelRatio);
    };

    Quad.prototype.computeTextureProjection = function() {
      var A, Ainv, B, C, ce, dstMat, dstMatInv, dstVars, pos1, pos2, pos3, pos4, srcMat, srcMatInv, srcVars;
      pos1 = this.worldToScreen(this.sprites[0].position);
      pos2 = this.worldToScreen(this.sprites[1].position);
      pos3 = this.worldToScreen(this.sprites[2].position);
      pos4 = this.worldToScreen(this.sprites[3].position);
      srcMat = new THREE.Matrix3(pos1.x, pos2.x, pos3.x, pos1.y, pos2.y, pos3.y, 1, 1, 1);
      srcMatInv = this.inverseMatrix(srcMat);
      srcVars = this.multiplyMatrixVector(srcMatInv, new THREE.Vector3(pos4.x, pos4.y, 1));
      A = new THREE.Matrix3(pos1.x * srcVars.x, pos2.x * srcVars.y, pos3.x * srcVars.z, pos1.y * srcVars.x, pos2.y * srcVars.y, pos3.y * srcVars.z, srcVars.x, srcVars.y, srcVars.z);
      dstMat = new THREE.Matrix3(0, 1, 0, 1, 1, 0, 1, 1, 1);
      dstMatInv = this.inverseMatrix(dstMat);
      dstVars = this.multiplyMatrixVector(dstMatInv, new THREE.Vector3(1, 0, 1));
      B = new THREE.Matrix3(0, dstVars.y, 0, dstVars.x, dstVars.y, 0, dstVars.x, dstVars.y, dstVars.z);
      Ainv = this.inverseMatrix(A);
      C = this.multiplyMatrices(B, Ainv);
      ce = C.elements;
      this.uniforms.matC.value = new THREE.Matrix4(ce[0], ce[3], ce[6], 0, ce[1], ce[4], ce[7], 0, ce[2], ce[5], ce[8], 0, 0, 0, 0, 0);
    };

    Quad.prototype.save = function(key, value) {
      localStorage.setItem(key, JSON.stringify(value));
    };

    Quad.prototype.load = function(key) {
      var value;
      value = localStorage.getItem(key);
      return value && JSON.parse(value);
    };

    return Quad;

  })();

  this.Quad = Quad;

}).call(this);
