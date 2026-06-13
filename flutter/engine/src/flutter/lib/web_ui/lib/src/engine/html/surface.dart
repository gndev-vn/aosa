// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../frame_reference.dart';
import '../onscreen_logging.dart';
import '../semantics.dart';
import '../util.dart';
import '../vector_math.dart';
import 'picture.dart';
import 'scene.dart';
import 'surface_stats.dart';

/// When `true` prints statistics about what happened to the surface tree when
/// it was composited.
///
/// Also paints an on-screen overlay with the numbers visualized as a timeline.
const bool debugExplainSurfaceStats = false;

/// When `true` shows an overlay that contains stats about canvas reuse.
///
/// The overlay also includes a button to reset the stats.
const bool debugShowCanvasReuseStats = false;

/// When `true` renders the outlines of clip layers on the screen instead of
/// clipping the contents.
///
/// This is useful when visually debugging clipping behavior.
bool debugShowClipLayers = false;

/// The threshold for the canvas pixel count to screen pixel count ratio, beyond
/// which in debug mode a warning is issued to the console.
///
/// As we improve canvas utilization we should decrease this number. It is
/// unlikely that we will hit 1.0, but something around 3.0 should be
/// reasonable.
const double kScreenPixelRatioWarningThreshold = 6.0;

/// Performs any outstanding painting work enqueued by [PersistedPicture]s.
void commitScene(PersistedScene scene) {
  if (paintQueue.isNotEmpty) {
    try {
      if (paintQueue.length > 1) {
        // Sort paint requests in decreasing canvas size order. Paint requests
        // attempt to reuse canvases. For efficiency we want the biggest pictures
        // to find canvases before the smaller ones claim them.
        paintQueue.sort((PaintRequest a, PaintRequest b) {
          final double aSize = a.canvasSize.height * a.canvasSize.width;
          final double bSize = b.canvasSize.height * b.canvasSize.width;
          return bSize.compareTo(aSize);
        });
      }

      for (final PaintRequest request in paintQueue) {
        request.paintCallback();
      }
    } finally {
      paintQueue = <PaintRequest>[];
    }
  }

  // After the update the retained surfaces are back to active.
  if (retainedSurfaces.isNotEmpty) {
    for (int i = 0; i < retainedSurfaces.length; i++) {
      final PersistedSurface retainedSurface = retainedSurfaces[i];
      assert(debugAssertSurfaceState(retainedSurface, PersistedSurfaceState.pendingRetention));
      retainedSurface.state = PersistedSurfaceState.active;
    }
    retainedSurfaces = <PersistedSurface>[];
  }
  if (debugExplainSurfaceStats) {
    debugPrintSurfaceStats(scene, debugFrameNumber);
    debugRepaintSurfaceStatsOverlay(scene);
  }

  assert(() {
    final List<String> validationErrors = <String>[];
    scene.debugValidate(validationErrors);
    if (validationErrors.isNotEmpty) {
      print(
        'ENGINE LAYER TREE INCONSISTENT:\n'
        '${validationErrors.map((String e) => '  - $e\n').join()}',
      );
    }
    return true;
  }());

  for (int i = 0; i < frameReferences.length; i++) {
    frameReferences[i].value = null;
  }
  frameReferences = <FrameReference<dynamic>>[];

  if (debugExplainSurfaceStats) {
    surfaceStats = <PersistedSurface, DebugSurfaceStats>{};
  }
  assert(() {
    debugFrameNumber++;
    return true;
  }());
}

/// Signature of a function that receives a [PersistedSurface].
///
/// This is used to traverse surfaces using [PersistedSurface.visitChildren].
typedef PersistedSurfaceVisitor = void Function(PersistedSurface);

/// Controls the algorithm used to reuse a previously rendered surface.
enum PersistedSurfaceState {
  /// A new or revived surface that does not have a
  /// [PersistedSurface.rootElement].
  ///
  /// Surfaces in this state acquire an element either by creating a new element
  /// or by adopting an element from an [active] surface.
  created,

  /// The surface has DOM resources that are attached to the live DOM tree.
  ///
  /// During update surfaces in this state come from the previous frame. This is
  /// also the state that all surfaces that are attached to the new frame's
  /// scene acquire at the end of the frame.
  ///
  /// In this state the surface has a non-null [PersistedSurface.rootElement].
  /// The element may be adopted by a new surface by matching to it during
  /// update (see [PersistedSurface.matchForUpdate]).
  active,

  /// The surface object will be reused along with all its descendants.
  ///
  /// This strategy relies on Flutter's retained-mode layer system (see
  /// [EngineLayer]).
  pendingRetention,

  /// The surface's DOM elements will be reused and updated.
  ///
  /// The surface in this state must have been rendered in a previous frame, it
  /// must have non-null [PersistedSurface.rootElement], and there must be a new
  /// surface that points to this surface via
  /// [PersistedContainerSurface.oldLayer]. The new surface will adopt this
  /// surface's DOM elements and update them.
  pendingUpdate,

  /// This state indicates that all DOM resources of this surface have been
  /// released and cannot be reused anymore.
  ///
  /// There are two ways a surface may be released:
  ///
  /// - When the surface is updated its DOM elements are adopted by a new
  ///   surface. This can happen either via [PersistedContainerSurface.oldLayer]
  ///   or by matching.
  /// - When the surface is removed from the tree because it is no longer in the
  ///   scene, nor its elements are reused by another surface.
  ///
  /// A surface may be revived from this state back into [created] state via
  /// [PersistedSurface.revive].
  released,
}

class PersistedSurfaceException implements Exception {
  PersistedSurfaceException(this.surface, this.message);

  final PersistedSurface surface;
  final String message;

  @override
  String toString() {
    String result = super.toString();
    assert(() {
      result = '${surface.runtimeType}: $message';
      return true;
    }());
    return result;
  }
}

/// Verifies that the [surface] is in one of the valid states.
///
/// This function should be used inside an assertion expression.
bool debugAssertSurfaceState(
  PersistedSurface surface,
  PersistedSurfaceState state1, [
  PersistedSurfaceState? state2,
  PersistedSurfaceState? state3,
]) {
  final List<PersistedSurfaceState?> validStates = <PersistedSurfaceState?>[state1, state2, state3];

  if (validStates.contains(surface.state)) {
    return true;
  }

  throw PersistedSurfaceException(
    surface,
    'is in an unexpected state.\n'
    'Expected one of: ${validStates.whereType<PersistedSurfaceState>().join(', ')}\n'
    'But was: ${surface.state}',
  );
}

/// A node in the tree built by [SceneBuilder] that contains information used to
/// compute the fewest amount of mutations necessary to update the browser DOM.
abstract class PersistedSurface implements ui.EngineLayer {
  /// Creates a persisted surface.
  PersistedSurface(PersistedSurface? oldLayer)
    : _oldLayer = FrameReference<PersistedSurface>(
        oldLayer != null && oldLayer.isActive ? oldLayer : null,
      );

  /// The surface that is being updated using this surface.
  ///
  /// If not null this surface will reuse the old surface's HTML [element].
  ///
  /// This value is set to null at the end of the frame.
  PersistedSurface? get oldLayer => _oldLayer.value;
  final FrameReference<PersistedSurface> _oldLayer;

  /// The index of this surface in its parent's [PersistedContainerSurface._children]
  /// list.
  ///
  /// This index is used to detect whether any child nodes moved within a
  /// container layer. The index is cached by the child to avoid a linear
  /// look-up in the parent's child list.
  ///
  /// This index is updated by [PersistedContainerSurface.update].
  int _index = -1;

  /// Controls the algorithm that reuses the DOM resources owned by this
  /// surface.
  PersistedSurfaceState get state => _state;
  set state(PersistedSurfaceState newState) {
    assert(
      newState != _state,
      'Attempted to set state that the surface is already in. This likely indicates a bug in the compositor.',
    );
    assert(_debugValidateStateTransition(newState));
    _state = newState;
  }

  PersistedSurfaceState _state = PersistedSurfaceState.created;

  bool _debugValidateStateTransition(PersistedSurfaceState newState) {
    if (newState == PersistedSurfaceState.created) {
      assert(isReleased, 'Only released surfaces may be revived.');
    } else {
      assert(
        !isReleased,
        'Released surfaces may only be revived, but caught attempt to set $newState.',
      );
    }
    if (newState == PersistedSurfaceState.active) {
      assert(
        isCreated || isPendingRetention || isPendingUpdate,
        'Surface is $state. Only created, pending retention, and pending update surfaces may be activated.',
      );
    }
    if (newState == PersistedSurfaceState.pendingRetention) {
      assert(isActive, 'Surface is not active. Only active surfaces may be retained.');
    }
    if (newState == PersistedSurfaceState.pendingUpdate) {
      assert(isActive, 'Surface is not active. Only active surfaces may be updated.');
    }
    if (newState == PersistedSurfaceState.released) {
      assert(
        isActive || isPendingUpdate,
        'A surface may only be released if it is currently active or pending update, but it is in $state.',
      );
    }
    return true;
  }

  /// Attempts to retain this surface along with its descendants.
  ///
  /// If the surface is currently active this surface is retained. If the
  /// surface is released, it means that the surface's DOM resources have been
  /// reused before the request to retain it came in. In this case, the surface
  /// is [revive]d and rebuilt from scratch.
  void tryRetain() {
    assert(
      debugAssertSurfaceState(this, PersistedSurfaceState.active, PersistedSurfaceState.released),
    );
    // Request that the layer is retained, but only if it's still active. It
    // could have been released.
    if (isActive) {
      state = PersistedSurfaceState.pendingRetention;
    } else {
      // The surface is released. This means that by the time addRetained was
      // called this surface's DOM elements have been reused for something else.
      // In this case, we reset the surface back to "created" state.
      revive();
    }
  }

  /// Turns a previously released surface and all its descendants into a
  /// [PersistedSurfaceState.created] one.
  ///
  /// This is used to rebuild surfaces that were released before a request to
  /// retain came in.
  @mustCallSuper
  @visibleForTesting
  void revive() {
    assert(debugAssertSurfaceState(this, PersistedSurfaceState.released));
    state = PersistedSurfaceState.created;
  }

  /// The surface is in the [PersistedSurfaceState.created] state;
  bool get isCreated => _state == PersistedSurfaceState.created;

  /// The surface is in the [PersistedSurfaceState.active] state;
  bool get isActive => _state == PersistedSurfaceState.active;

  /// The surface is in the [PersistedSurfaceState.pendingRetention] state;
  bool get isPendingRetention => _state == PersistedSurfaceState.pendingRetention;

  /// The surface is in the [PersistedSurfaceState.pendingUpdate] state;
  bool get isPendingUpdate => _state == PersistedSurfaceState.pendingUpdate;

  /// The surface is in the [PersistedSurfaceState.released] state;
  bool get isReleased => _state == PersistedSurfaceState.released;

  /// The root element that renders this surface to the DOM.
  ///
  /// This element can be reused across frames. See also, [childContainer],
  /// which is the element used to manage child nodes.
  DomElement? rootElement;

  /// Whether this surface can update an existing [oldSurface].
  @mustCallSuper
  bool canUpdateAsMatch(PersistedSurface oldSurface) {
    return oldSurface.isActive && runtimeType == oldSurface.runtimeType;
  }

  /// The element that contains child surface elements.
  ///
  /// By default this is the same as the [rootElement]. However, specialized
  /// surface implementations may choose to override this and provide a
  /// different element for nesting children.
  DomElement? get childContainer => rootElement;

  /// This surface's immediate parent.
  PersistedContainerSurface? parent;

  /// Visits immediate children.
  ///
  /// Does not recurse.
  void visitChildren(PersistedSurfaceVisitor visitor);

  /// Computes how expensive it would be to update an [existingSurface]'s DOM
  /// resources using this surface's data.
  ///
  /// The returned value is a score between 0.0 and 1.0, inclusive. 0.0 is the
  /// perfect score, meaning that the update is free. 1.0 is the worst score,
  /// indicating that the DOM resources cannot be reused, and if an update is
  /// performed, will result in reallocation.
  ///
  /// Values that fall strictly between 0.0 and 1.0 are used to communicate
  /// the efficiency of updates, with lower scores having better efficiency
  /// compared to higher scores. For example, when matching a picture with a
  /// bitmap canvas the score is higher for a canvas that's bigger in size than
  /// a smaller canvas that also fits the picture.
  double matchForUpdate(covariant PersistedSurface? existingSurface);

  /// Creates a new element and sets the necessary HTML and CSS attributes.
  ///
  /// This is called when we failed to locate an existing DOM element to reuse,
  /// such as on the very first frame.
  @mustCallSuper
  void build() {
    assert(() {
      final DomElement? existingElement = rootElement;
      if (existingElement != null) {
        throw PersistedSurfaceException(
          this,
          'Attempted to build a $runtimeType, but it already has an HTML '
          'element ${existingElement.tagName}.',
        );
      }
      return true;
    }());
    assert(debugAssertSurfaceState(this, PersistedSurfaceState.created));
    rootElement = createElement();
    assert(rootElement != null);
    applyWebkitClipFix(rootElement);
    if (debugExplainSurfaceStats) {
      surfaceStatsFor(this).allocatedDomNodeCount++;
    }
    apply();
    state = PersistedSurfaceState.active;
  }

  /// Instructs this surface to adopt HTML DOM elements of another surface.
  ///
  /// This is done for efficiency. Instead of creating new DOM elements on every
  /// frame, we reuse old ones as much as possible. This method should only be
  /// called when [isTotalMatchFor] returns true for the [oldSurface]. Otherwise
  /// adopting the [oldSurface]'s elements could lead to correctness issues.
  @mustCallSuper
  void adoptElements(covariant PersistedSurface oldSurface) {
    assert(oldSurface.rootElement != null);
    assert(
      debugAssertSurfaceState(
        oldSurface,
        PersistedSurfaceState.active,
        PersistedSurfaceState.pendingUpdate,
      ),
    );
    assert(() {
      if (oldSurface.isPendingUpdate) {
        final PersistedContainerSurface self = this as PersistedContainerSurface;
        assert(identical(self.oldLayer, oldSurface));
      }
      return true;
    }());
    rootElement = oldSurface.rootElement;
    if (debugExplainSurfaceStats) {
      surfaceStatsFor(this).reuseElementCount++;
    }

    // We took ownership of the old element.
    oldSurface.rootElement = null;
    // Make sure the old surface object is no longer usable.
    oldSurface.state = PersistedSurfaceState.released;
  }

  /// Updates the attributes of this surface's element.
  ///
  /// Attempts to reuse [oldSurface]'s DOM element, if possible. Otherwise,
  /// creates a new element by calling [build].
  @mustCallSuper
  void update(covariant PersistedSurface oldSurface) {
    assert(!identical(oldSurface, this));
    assert(debugAssertSurfaceState(this, PersistedSurfaceState.created));
    assert(
      debugAssertSurfaceState(
        oldSurface,
        PersistedSurfaceState.active,
        PersistedSurfaceState.pendingUpdate,
      ),
    );

    adoptElements(oldSurface);

    assert(() {
      rootElement!.setAttribute('flt-layer-state', 'updated');
      return true;
    }());
    state = PersistedSurfaceState.active;
    assert(rootElement != null);
  }

  /// Reuses a [PersistedSurface] rendered in the previous frame.
  ///
  /// This is different from [update], which reuses another surface's elements,
  /// i.e. it was not requested to be retained by the framework.
  ///
  /// This is also different from [build], which constructs a brand new surface
  /// sub-tree.
  @mustCallSuper
  void retain() {
    assert(rootElement != null);
    if (isPendingRetention) {
      // Adding to the list of retained surfaces so that at the end of the frame
      // it is set to active state. We do not set the state to active
      // immediately. Otherwise, another surface could match on it and steal
      // this surface's DOM elements.
      retainedSurfaces.add(this);
    }
    assert(() {
      rootElement!.setAttribute('flt-layer-state', 'retained');
      return true;
    }());
    if (debugExplainSurfaceStats) {
      surfaceStatsFor(this).retainSurfaceCount++;
    }
  }

  /// Removes the [element] of this surface from the tree and makes this
  /// surface released.
  ///
  /// This method may be overridden by concrete implementations, for example, to
  /// recycle the resources owned by this surface.
  @mustCallSuper
  void discard() {
    assert(debugAssertSurfaceState(this, PersistedSurfaceState.active));
    assert(rootElement != null);
    // TODO(yjbanov): it may be wasteful to recursively disassemble the DOM tree
    //                node by node. It should be sufficient to detach the root
    //                of the tree and let the browser handle the rest. Note,
    //                element.isConnected might be a poor choice to drive this
    //                decision because it is sensitive to the timing of when a
    //                scene's element is attached to the document. We might want
    //                to use a custom tracking mechanism, such as pass a boolean
    //                to `discard`, which would be `true` for the root, and
    //                `false` for children. Or, which might be cleaner, we could
    //                split this method into two methods. One method will detach
    //                the DOM, and the second method will disassociate the
    //                surface from the DOM and release it irrespective of
    //                whether the DOM itself gets detached or not.
    rootElement!.remove();
    rootElement = null;
    state = PersistedSurfaceState.released;
  }

  @override
  @mustCallSuper
  void dispose() {}

  @mustCallSuper
  void debugValidate(List<String> validationErrors) {
    if (rootElement == null) {
      validationErrors.add('${debugIdentify(this)} has null rootElement.');
    }
    if (!isActive) {
      validationErrors.add(
        '${debugIdentify(this)} is in the wrong state.\n'
        'It is in the live DOM tree expectec to be in ${PersistedSurfaceState.active}.\n'
        'However, it is currently in $state.',
      );
    }
  }

  /// Creates a DOM element for this surface.
  DomElement createElement();

  /// Creates a DOM element for this surface preconfigured with common
  /// attributes, such as absolute positioning and debug information.
  DomElement defaultCreateElement(String tagName) {
    final DomElement element = createDomElement(tagName);
    element.style.position = 'absolute';
    assert(() {
      element.setAttribute('flt-layer-state', 'new');
      return true;
    }());
    return element;
  }

  /// Sets the HTML and CSS properties appropriate for this surface's
  /// implementation.
  ///
  /// For example, [PersistedTransform] sets the "transform" CSS attribute.
  void apply();

  /// The effective transform at this surface level.
  ///
  /// This value is computed by concatenating transforms of all ancestor
  /// transforms as well as this layer's transform (if any).
  ///
  /// The value is update by [recomputeTransformAndClip].
  Matrix4? transform;

  /// The intersection at this surface level.
  ///
  /// This value is the intersection of clips in the ancestor chain, including
  /// the clip added by this layer (if any).
  ///
  /// The value is update by [recomputeTransformAndClip].
  ui.Rect? projectedClip;

  /// Bounds of clipping performed by this layer.
  ui.Rect? localClipBounds;

  /// The inverse of the local transform that this surface applies to its children.
  ///
  /// The default implementation is identity transform. Concrete
  /// implementations may override this getter to supply a different transform.
  Matrix4? get localTransformInverse => null;

  /// Recomputes [transform] and [globalClip] fields.
  ///
  /// The default implementation inherits the values from the parent. Concrete
  /// surface implementations may override this with their custom transform and
  /// clip behaviors.
  ///
  /// This method is called by the [preroll] method.
  void recomputeTransformAndClip() {
    transform = parent!.transform;
    localClipBounds = null;
    projectedClip = null;
  }

  /// Performs computations before [build], [update], or [retain] are called.
  ///
  /// The computations prepare data needed for efficient scene diffing. For
  /// example, as part of a preroll we compute transforms and cull rects, which
  /// are used to find the best matching canvases.
  ///
  /// This method recursively walks the surface tree calling `preroll` on all
  /// descendants.
  void preroll(PrerollSurfaceContext prerollContext) {
    recomputeTransformAndClip();
  }

  /// Prints this surface into a [buffer] in a human-readable format.
  void debugPrint(StringBuffer buffer, int indent) {
    if (rootElement != null) {
      buffer.write('${'  ' * indent}<${rootElement!.tagName.toLowerCase()} ');
    } else {
      buffer.write('${'  ' * indent}<$runtimeType recycled ');
    }
    debugPrintAttributes(buffer);
    buffer.writeln('>');
    debugPrintChildren(buffer, indent);
    if (rootElement != null) {
      buffer.writeln('${'  ' * indent}</${rootElement!.tagName.toLowerCase()}>');
    } else {
      buffer.writeln('${'  ' * indent}</$runtimeType>');
    }
  }

  @mustCallSuper
  void debugPrintAttributes(StringBuffer buffer) {
    if (rootElement != null) {
      buffer.write('@${rootElement!.hashCode} ');
    }
  }

  @mustCallSuper
  void debugPrintChildren(StringBuffer buffer, int indent) {}

  @override
  String toString() {
    String result = super.toString();
    assert(() {
      final StringBuffer log = StringBuffer();
      debugPrint(log, 0);
      result = log.toString();
      return true;
    }());
    return result;
  }
}

/// A surface that doesn't have child surfaces.
abstract class PersistedLeafSurface extends PersistedSurface {
  PersistedLeafSurface() : super(null);

  @override
  void visitChildren(PersistedSurfaceVisitor visitor) {
    // Does not have children.
  }
}

/// A surface that has a flat list of child surfaces.
abstract class PersistedContainerSurface extends PersistedSurface {
  /// Creates a container surface.
  ///
  /// `oldLayer` points to the surface rendered in the previous frame that's
  /// being updated by this layer.
  PersistedContainerSurface(PersistedSurface? oldLayer) : super(oldLayer) {
    assert(oldLayer == null || runtimeType == oldLayer.runtimeType);
  }

  final List<PersistedSurface> _children = <PersistedSurface>[];

  @override
  void visitChildren(PersistedSurfaceVisitor visitor) {
    _children.forEach(visitor);
  }

  /// Adds a child to this container.
  void appendChild(PersistedSurface child) {
    assert(
      debugAssertSurfaceState(
        child,
        PersistedSurfaceState.created,
        PersistedSurfaceState.pendingRetention,
        PersistedSurfaceState.pendingUpdate,
      ),
    );
    _children.add(child);
    child.parent = this;
  }

  @override
  void preroll(PrerollSurfaceContext prerollContext) {
    super.preroll(prerollContext);
    final int length = _children.length;
    for (int i = 0; i < length; i += 1) {
      _children[i].preroll(prerollContext);
    }
  }

  @override
  void recomputeTransformAndClip() {
    transform = parent!.transform;
    localClipBounds = null;
    projectedClip = null;
  }

  @override
  void build() {
    super.build();
    // Memoize length for efficiency.
    final int len = _children.length;
    // Memoize container element for efficiency. [childContainer] is polymorphic
    final DomElement? containerElement = childContainer;
    for (int i = 0; i < len; i++) {
      final PersistedSurface child = _children[i];
      if (child.isPendingRetention) {
        assert(child.rootElement != null);
        child.retain();
      } else if (child is PersistedContainerSurface && child.oldLayer != null) {
        final PersistedSurface oldLayer = child.oldLayer!;
        assert(oldLayer.rootElement != null);
        assert(debugAssertSurfaceState(oldLayer, PersistedSurfaceState.pendingUpdate));
        child.update(oldLayer as PersistedContainerSurface);
      } else {
        assert(debugAssertSurfaceState(child, PersistedSurfaceState.created));
        assert(child.rootElement == null);
        child.build();
      }
      containerElement!.append(child.rootElement!);
      child._index = i;
    }
    _debugValidateContainerNewState();
  }

  @override
  double matchForUpdate(PersistedContainerSurface? existingSurface) {
    assert(existingSurface!.runtimeType == runtimeType);
    // Intermediate container nodes don't have many resources worth comparing,
    // so we always return 1.0 to signal that it doesn't matter which one to
    // choose.
    // TODO(yjbanov): while the container doesn't have own resources, imperfect
    //                matching can lead to unnecessary reparenting of DOM
    //                subtrees. One trick we could try is to look at children's
    //                oldLayer values and see if we can use those to match
    //                intermediate surfaces better.
    return 1.0;
  }

  @override
  void update(PersistedContainerSurface oldSurface) {
    assert(
      debugAssertSurfaceState(
        oldSurface,
        PersistedSurfaceState.active,
        PersistedSurfaceState.pendingUpdate,
      ),
    );
    assert(runtimeType == oldSurface.runtimeType);
    super.update(oldSurface);
    assert(debugAssertSurfaceState(oldSurface, PersistedSurfaceState.released));

    if (oldSurface._children.isEmpty) {
      _updateZeroToMany(oldSurface);
    } else if (_children.length == 1) {
      _updateManyToOne(oldSurface);
    } else if (_children.isEmpty) {
      _discardActiveChildren(oldSurface);
    } else {
      _updateManyToMany(oldSurface);
    }

    assert(() {
      _debugValidateContainerUpdate(oldSurface);
      return true;
    }());
  }

  // Children should override if they are performing clipping.
  //
  // Used by BackdropFilter to locate it's ancestor clip element.
  bool get isClipping => false;

  void _debugValidateContainerUpdate(PersistedContainerSurface oldSurface) {
    // At the end of this all children should have an element each, and it
    // should be attached to this container's element.
    assert(() {
      for (int i = 0; i < oldSurface._children.length; i++) {
        final PersistedSurface oldChild = oldSurface._children[i];
        assert(
          !oldChild.isActive && !oldChild.isCreated,
          'Old child is in incorrect state ${oldChild.state}',
        );
        if (oldChild.isReleased) {
          assert(oldChild.rootElement == null);
          assert(oldChild.childContainer == null);
        }
      }
      _debugValidateContainerNewState();
      return true;
    }());
  }

  void _debugValidateContainerNewState() {
    assert(() {
      for (int i = 0; i < _children.length; i++) {
        final PersistedSurface newChild = _children[i];
        assert(newChild._index == i);
        assert(
          debugAssertSurfa