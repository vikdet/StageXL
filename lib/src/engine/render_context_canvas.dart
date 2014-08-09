part of stagexl;

class RenderContextCanvas extends RenderContext {

  final CanvasElement _canvasElement;

  CanvasRenderingContext2D _renderingContext;
  BlendMode _activeBlendMode = BlendMode.NORMAL;
  double _activeAlpha = 1.0;

  RenderContextCanvas(CanvasElement canvasElement) : _canvasElement = canvasElement {

    var renderingContext = _canvasElement.context2D;

    if (renderingContext is! CanvasRenderingContext2D) {
      throw new StateError("Failed to get Canvas context.");
    }

    _renderingContext = renderingContext;
  }

  //-----------------------------------------------------------------------------------------------

  CanvasRenderingContext2D get rawContext => _renderingContext;

  String get renderEngine => RenderEngine.Canvas2D;
  Matrix get viewPortMatrix => new Matrix.fromIdentity();

  //-----------------------------------------------------------------------------------------------

  void reset() {
    _activeBlendMode = BlendMode.NORMAL;
    _activeAlpha = 1.0;
    _renderingContext.globalCompositeOperation = "source-over";
    _renderingContext.globalAlpha = 1.0;
  }

  void clear(int color) {
    _renderingContext.setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    _renderingContext.globalAlpha = 1.0;
    if (color & 0xFF000000 == 0) {
      _renderingContext.clearRect(0, 0, _canvasElement.width, _canvasElement.height);
    } else {
      _renderingContext.fillStyle = _color2rgb(color);
      _renderingContext.fillRect(0, 0, _canvasElement.width, _canvasElement.height);
    }
  }

  void flush() {

  }

  //-----------------------------------------------------------------------------------------------

  void renderQuad(RenderState renderState, RenderTextureQuad renderTextureQuad) {

    var context = _renderingContext;
    var source = renderTextureQuad.renderTexture.canvas;
    var rotation = renderTextureQuad.rotation;
    var xyList = renderTextureQuad.xyList;
    var matrix = renderState.globalMatrix;
    var alpha = renderState.globalAlpha;
    var blendMode = renderState.globalBlendMode;

    if (_activeAlpha != alpha) {
      _activeAlpha = alpha;
      context.globalAlpha = alpha;
    }

    if (_activeBlendMode != blendMode) {
      _activeBlendMode = blendMode;
      context.globalCompositeOperation = blendMode.compositeOperation;
    }

    if (rotation == 0) {

      var sourceX = xyList[0];
      var sourceY = xyList[1];
      var sourceWidth = xyList[4] - sourceX;
      var sourceHeight = xyList[5] - sourceY;
      var destinationX = renderTextureQuad.offsetX;
      var destinationY = renderTextureQuad.offsetY;
      var destinationWidth= renderTextureQuad.textureWidth;
      var destinationHeight = renderTextureQuad.textureHeight;

      context.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
      context.drawImageScaledFromSource(source,
          sourceX, sourceY, sourceWidth, sourceHeight,
          destinationX, destinationY, destinationWidth, destinationHeight);

    } else if (rotation == 1) {

      var sourceX = xyList[6];
      var sourceY = xyList[7];
      var sourceWidth = xyList[2] - sourceX;
      var sourceHeight = xyList[3] - sourceY;
      var destinationX = 0.0 - renderTextureQuad.offsetY - renderTextureQuad.textureHeight;
      var destinationY = renderTextureQuad.offsetX;
      var destinationWidth = renderTextureQuad.textureHeight;
      var destinationHeight = renderTextureQuad.textureWidth;

      context.setTransform(-matrix.c, -matrix.d, matrix.a, matrix.b, matrix.tx, matrix.ty);
      context.drawImageScaledFromSource(source,
          sourceX, sourceY, sourceWidth, sourceHeight,
          destinationX, destinationY, destinationWidth, destinationHeight);

    } else if (rotation == 2) {

      throw new StateError("Not implemented."); // TODO: Implement rotation

    } else if (rotation == 3) {

      throw new StateError("Not implemented."); // TODO: Implement rotation

    }
  }

  void renderTriangle(RenderState renderState, num x1, num y1, num x2, num y2, num x3, num y3, int color) {

    var context = _renderingContext;
    var matrix = renderState.globalMatrix;
    var alpha = renderState.globalAlpha;
    var blendMode = renderState.globalBlendMode;

    if (_activeAlpha != alpha) {
      _activeAlpha = alpha;
      context.globalAlpha = alpha;
    }

    if (_activeBlendMode != blendMode) {
      _activeBlendMode = blendMode;
      context.globalCompositeOperation = blendMode.compositeOperation;
    }

    context.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);

    context.beginPath();
    context.moveTo(x1, y1);
    context.lineTo(x2, y2);
    context.lineTo(x3, y3);
    context.closePath();
    context.fillStyle = _color2rgba(color);
    context.fill();
  }

  //-----------------------------------------------------------------------------------------------

  void beginRenderMask(RenderState renderState, Mask mask) {
    var matrix = renderState.globalMatrix;
    _renderingContext.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
    _renderingContext.beginPath();
    mask.renderMask(renderState);
    _renderingContext.save();
    _renderingContext.clip();
  }

  void endRenderMask(RenderState renderState, Mask mask) {
    _renderingContext.restore();
    if (mask.border) {
      _renderingContext.strokeStyle = _color2rgba(mask.borderColor);
      _renderingContext.lineWidth = mask.borderWidth;
      _renderingContext.lineCap = "round";
      _renderingContext.lineJoin = "round";
      _renderingContext.stroke();
    }
  }

}