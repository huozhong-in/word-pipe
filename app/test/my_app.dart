import "package:flutter/material.dart";
import "dart:collection";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "dart:async";
import "package:flutter/scheduler.dart";
import "dart:convert";
import "dart:html" as html;
import "dart:math";
import "dart:typed_data";
import "dart:ui";
import "package:flutter/cupertino.dart";
import "package:flutter/gestures.dart";
import "dart:developer" as dev;

class MixinBuilder<T extends GetxController> extends StatelessWidget {
  final Widget Function(T) builder;
  final bool global;
  final String? id;
  final bool autoRemove;
  final void Function(State state)? initState, dispose, didChangeDependencies;
  final void Function(GetBuilder oldWidget, State state)? didUpdateWidget;
  final T? init;
  const MixinBuilder({
    Key? key,
    this.init,
    this.global = true,
    required this.builder,
    this.autoRemove = true,
    this.initState,
    this.dispose,
    this.id,
    this.didChangeDependencies,
    this.didUpdateWidget,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetBuilder<T>(
        init: init,
        global: global,
        autoRemove: autoRemove,
        initState: initState,
        dispose: dispose,
        id: id,
        didChangeDependencies: didChangeDependencies,
        didUpdateWidget: didUpdateWidget,
        builder: (controller) => Obx(() => builder.call(controller)));
  }
}

typedef Disposer = void Function();
typedef GetStateUpdate = void Function();

class ListNotifier extends Listenable with ListenableMixin, ListNotifierMixin {}

mixin ListenableMixin implements Listenable {}
mixin ListNotifierMixin on ListenableMixin {
  List<GetStateUpdate?>? _updaters = <GetStateUpdate?>[];
  HashMap<Object?, List<GetStateUpdate>>? _updatersGroupIds =
      HashMap<Object?, List<GetStateUpdate>>();
  @protected
  void refresh() {
    assert(_debugAssertNotDisposed());
    _notifyUpdate();
  }

  void _notifyUpdate() {
    for (var element in _updaters!) {
      element!();
    }
  }

  void _notifyIdUpdate(Object id) {
    if (_updatersGroupIds!.containsKey(id)) {
      final listGroup = _updatersGroupIds![id]!;
      for (var item in listGroup) {
        item();
      }
    }
  }

  @protected
  void refreshGroup(Object id) {
    assert(_debugAssertNotDisposed());
    _notifyIdUpdate(id);
  }

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_updaters == null) {
        throw FlutterError(
            '''A $runtimeType was used after being disposed.\n 'Once you have called dispose() on a $runtimeType, it can no longer be used.''');
      }
      return true;
    }());
    return true;
  }

  @protected
  void notifyChildrens() {
    TaskManager.instance.notify(_updaters);
  }

  bool get hasListeners {
    assert(_debugAssertNotDisposed());
    return _updaters!.isNotEmpty;
  }

  int get listeners {
    assert(_debugAssertNotDisposed());
    return _updaters!.length;
  }

  @override
  void removeListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _updaters!.remove(listener);
  }

  void removeListenerId(Object id, VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    if (_updatersGroupIds!.containsKey(id)) {
      _updatersGroupIds![id]!.remove(listener);
    }
    _updaters!.remove(listener);
  }

  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updaters = null;
    _updatersGroupIds = null;
  }

  @override
  Disposer addListener(GetStateUpdate listener) {
    assert(_debugAssertNotDisposed());
    _updaters!.add(listener);
    return () => _updaters!.remove(listener);
  }

  Disposer addListenerId(Object? key, GetStateUpdate listener) {
    _updatersGroupIds![key] ??= <GetStateUpdate>[];
    _updatersGroupIds![key]!.add(listener);
    return () => _updatersGroupIds![key]!.remove(listener);
  }

  void disposeId(Object id) {
    _updatersGroupIds!.remove(id);
  }
}

class TaskManager {
  TaskManager._();
  static TaskManager? _instance;
  static TaskManager get instance => _instance ??= TaskManager._();
  GetStateUpdate? _setter;
  List<VoidCallback>? _remove;
  void notify(List<GetStateUpdate?>? _updaters) {
    if (_setter != null) {
      if (!_updaters!.contains(_setter)) {
        _updaters.add(_setter);
        _remove!.add(() => _updaters.remove(_setter));
      }
    }
  }

  Widget exchange(
    List<VoidCallback> disposers,
    GetStateUpdate setState,
    Widget Function(BuildContext) builder,
    BuildContext context,
  ) {
    _remove = disposers;
    _setter = setState;
    final result = builder(context);
    _remove = null;
    _setter = null;
    return result;
  }
}

mixin GetStateUpdaterMixin<T extends StatefulWidget> on State<T> {
  void getUpdate() {
    if (mounted) setState(() {});
  }
}
typedef GetControllerBuilder<T extends DisposableInterface> = Widget Function(
    T controller);

class GetBuilder<T extends GetxController> extends StatefulWidget {
  final GetControllerBuilder<T> builder;
  final bool global;
  final Object? id;
  final String? tag;
  final bool autoRemove;
  final bool assignId;
  final Object Function(T value)? filter;
  final void Function(GetBuilderState<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(GetBuilder oldWidget, GetBuilderState<T> state)?
      didUpdateWidget;
  final T? init;
  const GetBuilder({
    Key? key,
    this.init,
    this.global = true,
    required this.builder,
    this.autoRemove = true,
    this.assignId = false,
    this.initState,
    this.filter,
    this.tag,
    this.dispose,
    this.id,
    this.didChangeDependencies,
    this.didUpdateWidget,
  }) : super(key: key);
  @override
  GetBuilderState<T> createState() => GetBuilderState<T>();
}

class GetBuilderState<T extends GetxController> extends State<GetBuilder<T>>
    with GetStateUpdaterMixin {
  T? controller;
  bool? _isCreator = false;
  VoidCallback? _remove;
  Object? _filter;
  @override
  void initState() {
    super.initState();
    widget.initState?.call(this);
    var isRegistered = GetInstance().isRegistered<T>(tag: widget.tag);
    if (widget.global) {
      if (isRegistered) {
        if (GetInstance().isPrepared<T>(tag: widget.tag)) {
          _isCreator = true;
        } else {
          _isCreator = false;
        }
        controller = GetInstance().find<T>(tag: widget.tag);
      } else {
        controller = widget.init;
        _isCreator = true;
        GetInstance().put<T>(controller!, tag: widget.tag);
      }
    } else {
      controller = widget.init;
      _isCreator = true;
      controller?.onStart();
    }
    if (widget.filter != null) {
      _filter = widget.filter!(controller!);
    }
    _subscribeToController();
  }

  void _subscribeToController() {
    _remove?.call();
    _remove = (widget.id == null)
        ? controller?.addListener(
            _filter != null ? _filterUpdate : getUpdate,
          )
        : controller?.addListenerId(
            widget.id,
            _filter != null ? _filterUpdate : getUpdate,
          );
  }

  void _filterUpdate() {
    var newFilter = widget.filter!(controller!);
    if (newFilter != _filter) {
      _filter = newFilter;
      getUpdate();
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.dispose?.call(this);
    if (_isCreator! || widget.assignId) {
      if (widget.autoRemove && GetInstance().isRegistered<T>(tag: widget.tag)) {
        GetInstance().delete<T>(tag: widget.tag);
      }
    }
    _remove?.call();
    controller = null;
    _isCreator = null;
    _remove = null;
    _filter = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call(this);
  }

  @override
  void didUpdateWidget(GetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget as GetBuilder<T>);
    if (oldWidget.id != widget.id) {
      _subscribeToController();
    }
    widget.didUpdateWidget?.call(oldWidget, this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(controller!);
  }
}

abstract class GetxController extends DisposableInterface
    with ListenableMixin, ListNotifierMixin {
  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) {
      return;
    }
    if (ids == null) {
      refresh();
    } else {
      for (final id in ids) {
        refreshGroup(id);
      }
    }
  }
}

mixin ScrollMixin on GetLifeCycleBase {
  final ScrollController scroll = ScrollController();
  @override
  void onInit() {
    super.onInit();
    scroll.addListener(_listener);
  }

  bool _canFetchBottom = true;
  bool _canFetchTop = true;
  void _listener() {
    if (scroll.position.atEdge) {
      _checkIfCanLoadMore();
    }
  }

  Future<void> _checkIfCanLoadMore() async {
    if (scroll.position.pixels == 0) {
      if (!_canFetchTop) return;
      _canFetchTop = false;
      await onTopScroll();
      _canFetchTop = true;
    } else {
      if (!_canFetchBottom) return;
      _canFetchBottom = false;
      await onEndScroll();
      _canFetchBottom = true;
    }
  }

  Future<void> onEndScroll();
  Future<void> onTopScroll();
  @override
  void onClose() {
    scroll.removeListener(_listener);
    super.onClose();
  }
}

abstract class RxController extends DisposableInterface {}

abstract class SuperController<T> extends FullLifeCycleController
    with FullLifeCycle, StateMixin<T> {}

abstract class FullLifeCycleController extends GetxController
    with WidgetsBindingObserver {}

mixin FullLifeCycle on FullLifeCycleController {
  @mustCallSuper
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @mustCallSuper
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @mustCallSuper
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.inactive:
        onInactive();
        break;
      case AppLifecycleState.paused:
        onPaused();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
    }
  }

  void onResumed();
  void onPaused();
  void onInactive();
  void onDetached();
}
typedef ValueBuilderUpdateCallback<T> = void Function(T snapshot);
typedef ValueBuilderBuilder<T> = Widget Function(
    T snapshot, ValueBuilderUpdateCallback<T> updater);

class ValueBuilder<T> extends StatefulWidget {
  final T? initialValue;
  final ValueBuilderBuilder<T> builder;
  final void Function()? onDispose;
  final void Function(T)? onUpdate;
  const ValueBuilder({
    Key? key,
    this.initialValue,
    this.onDispose,
    this.onUpdate,
    required this.builder,
  }) : super(key: key);
  @override
  _ValueBuilderState<T> createState() => _ValueBuilderState<T>();
}

class _ValueBuilderState<T> extends State<ValueBuilder<T?>> {
  T? value;
  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) => widget.builder(value, updater);
  void updater(T? newValue) {
    if (widget.onUpdate != null) {
      widget.onUpdate!(newValue);
    }
    setState(() {
      value = newValue;
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.onDispose?.call();
    if (value is ChangeNotifier) {
      (value as ChangeNotifier?)?.dispose();
    } else if (value is StreamController) {
      (value as StreamController?)?.close();
    }
    value = null;
  }
}

class SimpleBuilder extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  const SimpleBuilder({Key? key, required this.builder}) : super(key: key);
  @override
  _SimpleBuilderState createState() => _SimpleBuilderState();
}

class _SimpleBuilderState extends State<SimpleBuilder>
    with GetStateUpdaterMixin {
  final disposers = <Disposer>[];
  @override
  void dispose() {
    super.dispose();
    for (final disposer in disposers) {
      disposer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaskManager.instance.exchange(
      disposers,
      getUpdate,
      widget.builder,
      context,
    );
  }
}

abstract class GetView<T> extends StatelessWidget {
  const GetView({Key? key}) : super(key: key);
  final String? tag = null;
  T get controller => GetInstance().find<T>(tag: tag)!;
  @override
  Widget build(BuildContext context);
}

abstract class GetWidget<S extends GetLifeCycleBase?> extends GetWidgetCache {
  const GetWidget({Key? key}) : super(key: key);
  @protected
  final String? tag = null;
  S get controller => GetWidget._cache[this] as S;
  static final _cache = Expando<GetLifeCycleBase>();
  @protected
  Widget build(BuildContext context);
  @override
  WidgetCache createWidgetCache() => _GetCache<S>();
}

class _GetCache<S extends GetLifeCycleBase?> extends WidgetCache<GetWidget<S>> {
  S? _controller;
  bool _isCreator = false;
  InstanceInfo? info;
  @override
  void onInit() {
    info = GetInstance().getInstanceInfo<S>(tag: widget!.tag);
    _isCreator = info!.isPrepared && info!.isCreate;
    if (info!.isRegistered) {
      _controller = Get.find<S>(tag: widget!.tag);
    }
    GetWidget._cache[widget!] = _controller;
    super.onInit();
  }

  @override
  void onClose() {
    if (_isCreator) {
      Get.asap(() {
        widget!.controller!.onDelete();
        Get.log('"${widget!.controller.runtimeType}" onClose() called');
        Get.log('"${widget!.controller.runtimeType}" deleted from memory');
        GetWidget._cache[widget!] = null;
      });
    }
    info = null;
    super.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return widget!.build(context);
  }
}

mixin GetResponsiveMixin on Widget {
  ResponsiveScreen get screen;
  bool get alwaysUseBuilder;
  @protected
  Widget build(BuildContext context) {
    screen.context = context;
    Widget? widget;
    if (alwaysUseBuilder) {
      widget = builder();
      if (widget != null) return widget;
    }
    if (screen.isDesktop) {
      widget = desktop() ?? widget;
      if (widget != null) return widget;
    }
    if (screen.isTablet) {
      widget = tablet() ?? desktop();
      if (widget != null) return widget;
    }
    if (screen.isPhone) {
      widget = phone() ?? tablet() ?? desktop();
      if (widget != null) return widget;
    }
    return watch() ?? phone() ?? tablet() ?? desktop() ?? builder()!;
  }

  Widget? builder() => null;
  Widget? desktop() => null;
  Widget? phone() => null;
  Widget? tablet() => null;
  Widget? watch() => null;
}

class GetResponsiveView<T> extends GetView<T> with GetResponsiveMixin {
  @override
  final bool alwaysUseBuilder;
  @override
  final ResponsiveScreen screen;
  GetResponsiveView({
    this.alwaysUseBuilder = false,
    ResponsiveScreenSettings settings = const ResponsiveScreenSettings(),
    Key? key,
  })  : screen = ResponsiveScreen(settings),
        super(key: key);
}

class GetResponsiveWidget<T extends GetLifeCycleBase?> extends GetWidget<T>
    with GetResponsiveMixin {
  @override
  final bool alwaysUseBuilder;
  @override
  final ResponsiveScreen screen;
  GetResponsiveWidget({
    this.alwaysUseBuilder = false,
    ResponsiveScreenSettings settings = const ResponsiveScreenSettings(),
    Key? key,
  })  : screen = ResponsiveScreen(settings),
        super(key: key);
}

class ResponsiveScreenSettings {
  final double desktopChangePoint;
  final double tabletChangePoint;
  final double watchChangePoint;
  const ResponsiveScreenSettings(
      {this.desktopChangePoint = 1200,
      this.tabletChangePoint = 600,
      this.watchChangePoint = 300});
}

class ResponsiveScreen {
  late BuildContext context;
  final ResponsiveScreenSettings settings;
  late bool _isPaltformDesktop;
  ResponsiveScreen(this.settings) {
    _isPaltformDesktop = GetPlatform.isDesktop;
  }
  double get height => context.height;
  double get width => context.width;
  bool get isDesktop => (screenType == ScreenType.Desktop);
  bool get isTablet => (screenType == ScreenType.Tablet);
  bool get isPhone => (screenType == ScreenType.Phone);
  bool get isWatch => (screenType == ScreenType.Watch);
  double get _getdeviceWidth {
    if (_isPaltformDesktop) {
      return width;
    }
    return context.mediaQueryShortestSide;
  }

  ScreenType get screenType {
    final deviceWidth = _getdeviceWidth;
    if (deviceWidth >= settings.desktopChangePoint) return ScreenType.Desktop;
    if (deviceWidth >= settings.tabletChangePoint) return ScreenType.Tablet;
    if (deviceWidth < settings.watchChangePoint) return ScreenType.Watch;
    return ScreenType.Phone;
  }

  T? responsiveValue<T>({
    T? mobile,
    T? tablet,
    T? desktop,
    T? watch,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    if (isPhone && mobile != null) return mobile;
    return watch;
  }
}

enum ScreenType {
  Watch,
  Phone,
  Tablet,
  Desktop,
}

abstract class GetWidgetCache extends Widget {
  const GetWidgetCache({Key? key}) : super(key: key);
  @override
  GetWidgetCacheElement createElement() => GetWidgetCacheElement(this);
  @protected
  @factory
  WidgetCache createWidgetCache();
}

class GetWidgetCacheElement extends ComponentElement {
  GetWidgetCacheElement(GetWidgetCache widget)
      : cache = widget.createWidgetCache(),
        super(widget) {
    cache._element = this;
    cache._widget = widget;
  }
  @override
  void mount(Element? parent, dynamic newSlot) {
    cache.onInit();
    super.mount(parent, newSlot);
  }

  @override
  Widget build() => cache.build(this);
  final WidgetCache<GetWidgetCache> cache;
  @override
  void performRebuild() {
    super.performRebuild();
  }

  @override
  void activate() {
    super.activate();
    markNeedsBuild();
  }

  @override
  void unmount() {
    super.unmount();
    cache.onClose();
    cache._element = null;
  }
}

@optionalTypeArgs
abstract class WidgetCache<T extends GetWidgetCache> {
  T? get widget => _widget;
  T? _widget;
  BuildContext? get context => _element;
  GetWidgetCacheElement? _element;
  @protected
  @mustCallSuper
  void onInit() {}
  @protected
  @mustCallSuper
  void onClose() {}
  @protected
  Widget build(BuildContext context);
}

mixin SingleGetTickerProviderMixin on DisposableInterface
    implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

abstract class GetxService extends DisposableInterface with GetxServiceMixin {}

abstract class DisposableInterface extends GetLifeCycle {
  @override
  @mustCallSuper
  void onInit() {
    super.onInit();
    SchedulerBinding.instance.addPostFrameCallback((_) => onReady());
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}

typedef WidgetCallback = Widget Function();

abstract class ObxWidget extends StatefulWidget {
  const ObxWidget({Key? key}) : super(key: key);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(ObjectFlagProperty<Function>.has('builder', build));
  }

  @override
  _ObxState createState() => _ObxState();
  @protected
  Widget build();
}

class _ObxState extends State<ObxWidget> {
  final _observer = RxNotifier();
  late StreamSubscription subs;
  @override
  void initState() {
    super.initState();
    subs = _observer.listen(_updateTree, cancelOnError: false);
  }

  void _updateTree(_) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    subs.cancel();
    _observer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RxInterface.notifyChildren(_observer, widget.build);
}

class Obx extends ObxWidget {
  final WidgetCallback builder;
  const Obx(this.builder);
  @override
  Widget build() => builder();
}

class ObxValue<T extends RxInterface> extends ObxWidget {
  final Widget Function(T) builder;
  final T data;
  const ObxValue(this.builder, this.data, {Key? key}) : super(key: key);
  @override
  Widget build() => builder(data);
}

typedef GetXControllerBuilder<T extends DisposableInterface> = Widget Function(
    T controller);

class GetX<T extends DisposableInterface> extends StatefulWidget {
  final GetXControllerBuilder<T> builder;
  final bool global;
  final bool autoRemove;
  final bool assignId;
  final void Function(GetXState<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(GetX oldWidget, GetXState<T> state)? didUpdateWidget;
  final T? init;
  final String? tag;
  const GetX({
    this.tag,
    required this.builder,
    this.global = true,
    this.autoRemove = true,
    this.initState,
    this.assignId = false,
    this.dispose,
    this.didChangeDependencies,
    this.didUpdateWidget,
    this.init,
  });
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<T>('controller', init),
      )
      ..add(DiagnosticsProperty<String>('tag', tag))
      ..add(
          ObjectFlagProperty<GetXControllerBuilder<T>>.has('builder', builder));
  }

  @override
  GetXState<T> createState() => GetXState<T>();
}

class GetXState<T extends DisposableInterface> extends State<GetX<T>> {
  final _observer = RxNotifier();
  T? controller;
  bool? _isCreator = false;
  late StreamSubscription _subs;
  @override
  void initState() {
    final isRegistered = GetInstance().isRegistered<T>(tag: widget.tag);
    if (widget.global) {
      if (isRegistered) {
        _isCreator = GetInstance().isPrepared<T>(tag: widget.tag);
        controller = GetInstance().find<T>(tag: widget.tag);
      } else {
        controller = widget.init;
        _isCreator = true;
        GetInstance().put<T>(controller!, tag: widget.tag);
      }
    } else {
      controller = widget.init;
      _isCreator = true;
      controller?.onStart();
    }
    widget.initState?.call(this);
    if (widget.global && Get.smartManagement == SmartManagement.onlyBuilder) {
      controller?.onStart();
    }
    _subs = _observer.listen((data) => setState(() {}), cancelOnError: false);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.didChangeDependencies != null) {
      widget.didChangeDependencies!(this);
    }
  }

  @override
  void didUpdateWidget(GetX oldWidget) {
    super.didUpdateWidget(oldWidget as GetX<T>);
    widget.didUpdateWidget?.call(oldWidget, this);
  }

  @override
  void dispose() {
    if (widget.dispose != null) widget.dispose!(this);
    if (_isCreator! || widget.assignId) {
      if (widget.autoRemove && GetInstance().isRegistered<T>(tag: widget.tag)) {
        GetInstance().delete<T>(tag: widget.tag);
      }
    }
    _subs.cancel();
    _observer.close();
    controller = null;
    _isCreator = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('controller', controller));
  }

  @override
  Widget build(BuildContext context) => RxInterface.notifyChildren(
        _observer,
        () => widget.builder(controller!),
      );
}

mixin StateMixin<T> on ListNotifierMixin {
  T? _value;
  RxStatus? _status;
  bool _isNullOrEmpty(dynamic val) {
    if (val == null) return true;
    var result = false;
    if (val is Iterable) {
      result = val.isEmpty;
    } else if (val is String) {
      result = val.isEmpty;
    } else if (val is Map) {
      result = val.isEmpty;
    }
    return result;
  }

  void _fillEmptyStatus() {
    _status = _isNullOrEmpty(_value) ? RxStatus.loading() : RxStatus.success();
  }

  RxStatus get status {
    notifyChildrens();
    return _status ??= _status = RxStatus.loading();
  }

  T? get state => value;
  @protected
  T? get value {
    notifyChildrens();
    return _value;
  }

  @protected
  set value(T? newValue) {
    if (_value == newValue) return;
    _value = newValue;
    refresh();
  }

  @protected
  void change(T? newState, {RxStatus? status}) {
    var _canUpdate = false;
    if (status != null) {
      _status = status;
      _canUpdate = true;
    }
    if (newState != _value) {
      _value = newState;
      _canUpdate = true;
    }
    if (_canUpdate) {
      refresh();
    }
  }

  void append(Future<T> Function() body(), {String? errorMessage}) {
    final compute = body();
    compute().then((newValue) {
      change(newValue, status: RxStatus.success());
    }, onError: (err) {
      change(state, status: RxStatus.error(errorMessage ?? err.toString()));
    });
  }
}

class Value<T> extends ListNotifier
    with StateMixin<T>
    implements ValueListenable<T?> {
  Value(T val) {
    _value = val;
    _fillEmptyStatus();
  }
  @override
  T? get value {
    notifyChildrens();
    return _value;
  }

  @override
  set value(T? newValue) {
    if (_value == newValue) return;
    _value = newValue;
    refresh();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  void update(void fn(T? value)) {
    fn(value);
    refresh();
  }

  @override
  String toString() => value.toString();
  dynamic toJson() => (value as dynamic)?.toJson();
}

extension ReactiveT<T> on T {
  Value<T> get reactive => Value<T>(this);
}

typedef Condition = bool Function();

abstract class GetNotifier<T> extends Value<T> with GetLifeCycleBase {
  GetNotifier(T initial) : super(initial) {
    $configureLifeCycle();
  }
  @override
  @mustCallSuper
  void onInit() {
    super.onInit();
    SchedulerBinding.instance.addPostFrameCallback((_) => onReady());
  }
}

extension StateExt<T> on StateMixin<T> {
  Widget obx(
    NotifierBuilder<T?> widget, {
    Widget Function(String? error)? onError,
    Widget? onLoading,
    Widget? onEmpty,
  }) {
    return SimpleBuilder(builder: (_) {
      if (status.isLoading) {
        return onLoading ?? const Center(child: CircularProgressIndicator());
      } else if (status.isError) {
        return onError != null
            ? onError(status.errorMessage)
            : Center(child: Text('A error occurred: ${status.errorMessage}'));
      } else if (status.isEmpty) {
        return onEmpty != null ? onEmpty : SizedBox.shrink();
      }
      return widget(value);
    });
  }
}

class RxStatus {
  final bool isLoading;
  final bool isError;
  final bool isSuccess;
  final bool isEmpty;
  final bool isLoadingMore;
  final String? errorMessage;
  RxStatus._({
    this.isEmpty = false,
    this.isLoading = false,
    this.isError = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isLoadingMore = false,
  });
  factory RxStatus.loading() {
    return RxStatus._(isLoading: true);
  }
  factory RxStatus.loadingMore() {
    return RxStatus._(isSuccess: true, isLoadingMore: true);
  }
  factory RxStatus.success() {
    return RxStatus._(isSuccess: true);
  }
  factory RxStatus.error([String? message]) {
    return RxStatus._(isError: true, errorMessage: message);
  }
  factory RxStatus.empty() {
    return RxStatus._(isEmpty: true);
  }
}

typedef NotifierBuilder<T> = Widget Function(T state);

class GetSocket extends BaseWebSocket {
  GetSocket(String url,
      {Duration ping = const Duration(seconds: 5), bool allowSelfSigned = true})
      : super(url, ping: ping, allowSelfSigned: allowSelfSigned);
}

class Close {
  final String? message;
  final int? reason;
  Close(this.message, this.reason);
  @override
  String toString() {
    return 'Closed by server [$reason => $message]!';
  }
}

typedef OpenSocket = void Function();
typedef CloseSocket = void Function(Close);
typedef MessageSocket = void Function(dynamic val);

class SocketNotifier {
  List<void Function(dynamic)>? _onMessages = <MessageSocket>[];
  Map<String, void Function(dynamic)>? _onEvents = <String, MessageSocket>{};
  List<void Function(Close)>? _onCloses = <CloseSocket>[];
  List<void Function(Close)>? _onErrors = <CloseSocket>[];
  late OpenSocket open;
  void addMessages(MessageSocket socket) {
    _onMessages!.add((socket));
  }

  void addEvents(String event, MessageSocket socket) {
    _onEvents![event] = socket;
  }

  void addCloses(CloseSocket socket) {
    _onCloses!.add(socket);
  }

  void addErrors(CloseSocket socket) {
    _onErrors!.add((socket));
  }

  void notifyData(dynamic data) {
    for (var item in _onMessages!) {
      item(data);
    }
    if (data is String) {
      _tryOn(data);
    }
  }

  void notifyClose(Close err) {
    for (var item in _onCloses!) {
      item(err);
    }
  }

  void notifyError(Close err) {
    for (var item in _onErrors!) {
      item(err);
    }
  }

  void _tryOn(String message) {
    try {
      var msg = jsonDecode(message);
      final event = msg['type'];
      final data = msg['data'];
      if (_onEvents!.containsKey(event)) {
        _onEvents![event]!(data);
      }
    } on Exception catch (_) {
      return;
    }
  }

  void dispose() {
    _onMessages = null;
    _onEvents = null;
    _onCloses = null;
    _onErrors = null;
  }
}

enum ConnectionStatus {
  connecting,
  connected,
  closed,
}

class BaseWebSocket {
  String url;
  html.WebSocket? socket;
  SocketNotifier? socketNotifier = SocketNotifier();
  Duration ping;
  bool isDisposed = false;
  bool allowSelfSigned;
  BaseWebSocket(
    this.url, {
    this.ping = const Duration(seconds: 5),
    this.allowSelfSigned = true,
  }) {
    url = url.startsWith('https')
        ? url.replaceAll('https:', 'wss:')
        : url.replaceAll('http:', 'ws:');
  }
  ConnectionStatus? connectionStatus;
  Timer? _t;
  void connect() {
    try {
      connectionStatus = ConnectionStatus.connecting;
      socket = html.WebSocket(url);
      socket!.onOpen.listen((e) {
        socketNotifier?.open();
        _t = Timer?.periodic(ping, (t) {
          socket!.send('');
        });
        connectionStatus = ConnectionStatus.connected;
      });
      socket!.onMessage.listen((event) {
        socketNotifier!.notifyData(event.data);
      });
      socket!.onClose.listen((e) {
        _t?.cancel();
        connectionStatus = ConnectionStatus.closed;
        socketNotifier!.notifyClose(Close(e.reason, e.code));
      });
      socket!.onError.listen((event) {
        _t?.cancel();
        socketNotifier!.notifyError(Close(event.toString(), 0));
        connectionStatus = ConnectionStatus.closed;
      });
    } on Exception catch (e) {
      _t?.cancel();
      socketNotifier!.notifyError(Close(e.toString(), 500));
      connectionStatus = ConnectionStatus.closed;
    }
  }

  void onOpen(OpenSocket fn) {
    socketNotifier!.open = fn;
  }

  void onClose(CloseSocket fn) {
    socketNotifier!.addCloses(fn);
  }

  void onError(CloseSocket fn) {
    socketNotifier!.addErrors(fn);
  }

  void onMessage(MessageSocket fn) {
    socketNotifier!.addMessages(fn);
  }

  void on(String event, MessageSocket message) {
    socketNotifier!.addEvents(event, message);
  }

  void close([int? status, String? reason]) {
    socket?.close(status, reason);
  }

  void send(dynamic data) {
    if (connectionStatus == ConnectionStatus.closed) {
      connect();
    }
    if (socket != null && socket!.readyState == html.WebSocket.OPEN) {
      socket!.send(data);
    } else {
      Get.log('WebSocket not connected, message $data not sent');
    }
  }

  void emit(String event, dynamic data) {
    send(jsonEncode({'type': event, 'data': data}));
  }

  void dispose() {
    socketNotifier!.dispose();
    socketNotifier = null;
    isDisposed = true;
  }
}

typedef RequestModifier<T> = FutureOr<Request<T>> Function(Request<T?> request);
typedef ResponseModifier<T> = FutureOr Function(
    Request<T?> request, Response<T?> response);
typedef HandlerExecute<T> = Future<Request<T>> Function();

class GetModifier<T> {
  final _requestModifiers = <RequestModifier>[];
  final _responseModifiers = <ResponseModifier>[];
  RequestModifier? authenticator;
  void addRequestModifier<T>(RequestModifier<T> interceptor) {
    _requestModifiers.add(interceptor as RequestModifier);
  }

  void removeRequestModifier<T>(RequestModifier<T> interceptor) {
    _requestModifiers.remove(interceptor);
  }

  void addResponseModifier<T>(ResponseModifier<T> interceptor) {
    _responseModifiers.add(interceptor as ResponseModifier);
  }

  void removeResponseModifier<T>(ResponseModifier<T> interceptor) {
    _requestModifiers.remove(interceptor);
  }

  Future<Request<T>> modifyRequest<T>(Request<T> request) async {
    var newRequest = request;
    if (_requestModifiers.isNotEmpty) {
      for (var interceptor in _requestModifiers) {
        newRequest = await interceptor(newRequest) as Request<T>;
      }
    }
    return newRequest;
  }

  Future<Response<T>> modifyResponse<T>(
      Request<T> request, Response<T> response) async {
    var newResponse = response;
    if (_responseModifiers.isNotEmpty) {
      for (var interceptor in _responseModifiers) {
        newResponse = await interceptor(request, response) as Response<T>;
      }
    }
    return newResponse;
  }
}

class GraphQLResponse<T> extends Response<T> {
  final List<GraphQLError>? graphQLErrors;
  GraphQLResponse({T? body, this.graphQLErrors}) : super(body: body);
  GraphQLResponse.fromResponse(Response res)
      : graphQLErrors = null,
        super(
            request: res.request,
            statusCode: res.statusCode,
            bodyBytes: res.bodyBytes,
            bodyString: res.bodyString,
            statusText: res.statusText,
            headers: res.headers,
            body: res.body['data'] as T?);
}

class Response<T> {
  const Response({
    this.request,
    this.statusCode,
    this.bodyBytes,
    this.bodyString,
    this.statusText = '',
    this.headers = const {},
    this.body,
  });
  final Request? request;
  final Map<String, String>? headers;
  final int? statusCode;
  final String? statusText;
  HttpStatus get status => HttpStatus(statusCode);
  bool get hasError => status.hasError;
  bool get isOk => !hasError;
  bool get unauthorized => status.isUnauthorized;
  final Stream<List<int>>? bodyBytes;
  final String? bodyString;
  final T? body;
}

Future<String> bodyBytesToString(
    Stream<List<int>> bodyBytes, Map<String, String> headers) {
  return bodyBytes.bytesToString(_encodingForHeaders(headers));
}

Encoding _encodingForHeaders(Map<String, String> headers) =>
    _encodingForCharset(_contentTypeForHeaders(headers).parameters!['charset']);
Encoding _encodingForCharset(String? charset, [Encoding fallback = utf8]) {
  if (charset == null) return fallback;
  return Encoding.getByName(charset) ?? fallback;
}

HeaderValue _contentTypeForHeaders(Map<String, String> headers) {
  var contentType = headers['content-type'];
  if (contentType != null) return HeaderValue.parse(contentType);
  return HeaderValue('application/octet-stream');
}

class HeaderValue {
  String _value;
  Map<String, String?>? _parameters;
  Map<String, String?>? _unmodifiableParameters;
  HeaderValue([this._value = '', Map<String, String>? parameters]) {
    if (parameters != null) {
      _parameters = HashMap<String, String>.from(parameters);
    }
  }
  static HeaderValue parse(String value,
      {String parameterSeparator = ';',
      String? valueSeparator,
      bool preserveBackslash = false}) {
    var result = HeaderValue();
    result._parse(value, parameterSeparator, valueSeparator, preserveBackslash);
    return result;
  }

  String get value => _value;
  void _ensureParameters() {
    _parameters ??= HashMap<String, String>();
  }

  Map<String, String?>? get parameters {
    _ensureParameters();
    _unmodifiableParameters ??= UnmodifiableMapView(_parameters!);
    return _unmodifiableParameters;
  }

  @override
  String toString() {
    var stringBuffer = StringBuffer();
    stringBuffer.write(_value);
    if (parameters != null && parameters!.isNotEmpty) {
      _parameters!.forEach((name, value) {
        stringBuffer
          ..write('; ')
          ..write(name)
          ..write('=')
          ..write(value);
      });
    }
    return stringBuffer.toString();
  }

  void _parse(String value, String parameterSeparator, String? valueSeparator,
      bool preserveBackslash) {
    var index = 0;
    bool done() => index == value.length;
    void bump() {
      while (!done()) {
        if (value[index] != ' ' && value[index] != '\t') return;
        index++;
      }
    }

    String parseValue() {
      var start = index;
      while (!done()) {
        if (value[index] == ' ' ||
            value[index] == '\t' ||
            value[index] == valueSeparator ||
            value[index] == parameterSeparator) {
          break;
        }
        index++;
      }
      return value.substring(start, index);
    }

    void expect(String expected) {
      if (done() || value[index] != expected) {
        throw StateError('Failed to parse header value');
      }
      index++;
    }

    void maybeExpect(String expected) {
      if (value[index] == expected) index++;
    }

    void parseParameters() {
      var parameters = HashMap<String, String?>();
      _parameters = UnmodifiableMapView(parameters);
      String parseParameterName() {
        var start = index;
        while (!done()) {
          if (value[index] == ' ' ||
              value[index] == '\t' ||
              value[index] == '=' ||
              value[index] == parameterSeparator ||
              value[index] == valueSeparator) {
            break;
          }
          index++;
        }
        return value.substring(start, index).toLowerCase();
      }

      String? parseParameterValue() {
        if (!done() && value[index] == '\"') {
          var stringBuffer = StringBuffer();
          index++;
          while (!done()) {
            if (value[index] == '\\') {
              if (index + 1 == value.length) {
                throw StateError('Failed to parse header value');
              }
              if (preserveBackslash && value[index + 1] != '\"') {
                stringBuffer.write(value[index]);
              }
              index++;
            } else if (value[index] == '\"') {
              index++;
              break;
            }
            stringBuffer.write(value[index]);
            index++;
          }
          return stringBuffer.toString();
        } else {
          var val = parseValue();
          return val == '' ? null : val;
        }
      }

      while (!done()) {
        bump();
        if (done()) return;
        var name = parseParameterName();
        bump();
        if (done()) {
          parameters[name] = null;
          return;
        }
        maybeExpect('=');
        bump();
        if (done()) {
          parameters[name] = null;
          return;
        }
        var valueParameter = parseParameterValue();
        if (name == 'charset' && valueParameter != null) {
          valueParameter = valueParameter.toLowerCase();
        }
        parameters[name] = valueParameter;
        bump();
        if (done()) return;
        if (value[index] == valueSeparator) return;
        expect(parameterSeparator);
      }
    }

    bump();
    _value = parseValue();
    bump();
    if (done()) return;
    maybeExpect(parameterSeparator);
    parseParameters();
  }
}

bool isTokenChar(int byte) {
  return byte > 31 && byte < 128 && !SEPARATOR_MAP[byte];
}

bool isValueChar(int byte) {
  return (byte > 31 && byte < 128) ||
      (byte == CharCode.SP) ||
      (byte == CharCode.HT);
}

class CharCode {
  static const int HT = 9;
  static const int LF = 10;
  static const int CR = 13;
  static const int SP = 32;
  static const int COMMA = 44;
  static const int SLASH = 47;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int COLON = 58;
  static const int SEMI_COLON = 59;
}

const bool F = false;
const bool T = true;
const SEPARATOR_MAP = [
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  T,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  T,
  F,
  T,
  F,
  F,
  F,
  F,
  F,
  T,
  T,
  F,
  F,
  T,
  F,
  F,
  T,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  T,
  T,
  T,
  T,
  T,
  T,
  T,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  T,
  T,
  T,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  T,
  F,
  T,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F,
  F
];
String validateField(String field) {
  for (var i = 0; i < field.length; i++) {
    if (!isTokenChar(field.codeUnitAt(i))) {
      throw FormatException(
          'Invalid HTTP header field name: ${json.encode(field)}', field, i);
    }
  }
  return field.toLowerCase();
}

final _asciiOnly = RegExp(r'^[\x00-\x7F]+$');
final newlineRegExp = RegExp(r'\r\n|\r|\n');
bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);
const String GET_BOUNDARY = 'getx-http-boundary-';
String browserEncode(String value) {
  return value.replaceAll(newlineRegExp, '%0D%0A').replaceAll('"', '%22');
}

const List<int> boundaryCharacters = <int>[
  43,
  95,
  45,
  46,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  97,
  98,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  107,
  108,
  109,
  110,
  111,
  112,
  113,
  114,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122
];

class TrustedCertificate {
  final List<int> bytes;
  TrustedCertificate(this.bytes);
}

class HttpStatus {
  HttpStatus(this.code);
  final int? code;
  static const int continue_ = 100;
  static const int switchingProtocols = 101;
  static const int processing = 102;
  static const int earlyHints = 103;
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int nonAuthoritativeInformation = 203;
  static const int noContent = 204;
  static const int resetContent = 205;
  static const int partialContent = 206;
  static const int multiStatus = 207;
  static const int alreadyReported = 208;
  static const int imUsed = 226;
  static const int multipleChoices = 300;
  static const int movedPermanently = 301;
  static const int found = 302;
  static const int movedTemporarily = 302;
  static const int seeOther = 303;
  static const int notModified = 304;
  static const int useProxy = 305;
  static const int switchProxy = 306;
  static const int temporaryRedirect = 307;
  static const int permanentRedirect = 308;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int paymentRequired = 402;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int notAcceptable = 406;
  static const int proxyAuthenticationRequired = 407;
  static const int requestTimeout = 408;
  static const int conflict = 409;
  static const int gone = 410;
  static const int lengthRequired = 411;
  static const int preconditionFailed = 412;
  static const int requestEntityTooLarge = 413;
  static const int requestUriTooLong = 414;
  static const int unsupportedMediaType = 415;
  static const int requestedRangeNotSatisfiable = 416;
  static const int expectationFailed = 417;
  static const int imATeapot = 418;
  static const int misdirectedRequest = 421;
  static const int unprocessableEntity = 422;
  static const int locked = 423;
  static const int failedDependency = 424;
  static const int tooEarly = 425;
  static const int upgradeRequired = 426;
  static const int preconditionRequired = 428;
  static const int tooManyRequests = 429;
  static const int requestHeaderFieldsTooLarge = 431;
  static const int connectionClosedWithoutResponse = 444;
  static const int unavailableForLegalReasons = 451;
  static const int clientClosedRequest = 499;
  static const int internalServerError = 500;
  static const int notImplemented = 501;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
  static const int httpVersionNotSupported = 505;
  static const int variantAlsoNegotiates = 506;
  static const int insufficientStorage = 507;
  static const int loopDetected = 508;
  static const int notExtended = 510;
  static const int networkAuthenticationRequired = 511;
  static const int networkConnectTimeoutError = 599;
  bool get connectionError => code == null;
  bool get isUnauthorized => code == unauthorized;
  bool get isForbidden => code == forbidden;
  bool get isNotFound => code == notFound;
  bool get isServerError =>
      between(internalServerError, networkConnectTimeoutError);
  bool between(int begin, int end) {
    return !connectionError && code! >= begin && code! <= end;
  }

  bool get isOk => between(200, 299);
  bool get hasError => !isOk;
}

class GetHttpException implements Exception {
  final String message;
  final Uri? uri;
  GetHttpException(this.message, [this.uri]);
  @override
  String toString() => message;
}

class GraphQLError {
  GraphQLError({this.code, this.message});
  final String? message;
  final String? code;
  @override
  String toString() => 'GETCONNECT ERROR:\n\tcode:$code\n\tmessage:$message';
}

class UnauthorizedException implements Exception {
  @override
  String toString() {
    return 'Operation Unauthorized';
  }
}

class UnexpectedFormat implements Exception {
  final String message;
  UnexpectedFormat(this.message);
  @override
  String toString() {
    return 'Unexpected format: $message';
  }
}

class FormData {
  FormData(Map<String, dynamic> map) : boundary = _getBoundary() {
    map.forEach((key, value) {
      if (value == null) return null;
      if (value is MultipartFile) {
        files.add(MapEntry(key, value));
      } else if (value is List<MultipartFile>) {
        files.addAll(value.map((e) => MapEntry(key, e)));
      } else if (value is List) {
        fields.addAll(value.map((e) => MapEntry(key, e.toString())));
      } else {
        fields.add(MapEntry(key, value.toString()));
      }
    });
  }
  static const int _maxBoundaryLength = 70;
  static String _getBoundary() {
    final _random = Random();
    var list = List<int>.generate(_maxBoundaryLength - GET_BOUNDARY.length,
        (_) => boundaryCharacters[_random.nextInt(boundaryCharacters.length)],
        growable: false);
    return '$GET_BOUNDARY${String.fromCharCodes(list)}';
  }

  final String boundary;
  final fields = <MapEntry<String, String>>[];
  final files = <MapEntry<String, MultipartFile>>[];
  String _fieldHeader(String name, String value) {
    var header =
        'content-disposition: form-data; name="${browserEncode(name)}"';
    if (!isPlainAscii(value)) {
      header = '$header\r\n'
          'content-type: text/plain; charset=utf-8\r\n'
          'content-transfer-encoding: binary';
    }
    return '$header\r\n\r\n';
  }

  String _fileHeader(MapEntry<String, MultipartFile> file) {
    var header =
        'content-disposition: form-data; name="${browserEncode(file.key)}"';
    header = '$header; filename="${browserEncode(file.value.filename)}"';
    header = '$header\r\n' 'content-type: ${file.value.contentType}';
    return '$header\r\n\r\n';
  }

  int get length {
    var length = 0;
    for (final item in fields) {
      length += '--'.length +
          _maxBoundaryLength +
          '\r\n'.length +
          utf8.encode(_fieldHeader(item.key, item.value)).length +
          utf8.encode(item.value).length +
          '\r\n'.length;
    }
    for (var file in files) {
      length += '--'.length +
          _maxBoundaryLength +
          '\r\n'.length +
          utf8.encode(_fileHeader(file)).length +
          file.value.length! +
          '\r\n'.length;
    }
    return length + '--'.length + _maxBoundaryLength + '--\r\n'.length;
  }

  Future<List<int>> toBytes() {
    return BodyBytesStream(_encode()).toBytes();
  }

  Stream<List<int>> _encode() async* {
    const line = [13, 10];
    final separator = utf8.encode('--$boundary\r\n');
    final close = utf8.encode('--$boundary--\r\n');
    for (var field in fields) {
      yield separator;
      yield utf8.encode(_fieldHeader(field.key, field.value));
      yield utf8.encode(field.value);
      yield line;
    }
    for (final file in files) {
      yield separator;
      yield utf8.encode(_fileHeader(file));
      yield* file.value.stream!;
      yield line;
    }
    yield close;
  }
}

class MultipartFile {
  MultipartFile(
    dynamic data, {
    required this.filename,
    this.contentType = 'application/octet-stream',
  }) : _bytes = fileToBytes(data) {
    _length = _bytes.length;
    _stream = BodyBytesStream.fromBytes(_bytes);
  }
  final List<int> _bytes;
  final String contentType;
  Stream<List<int>>? _stream;
  int? _length;
  Stream<List<int>>? get stream => _stream;
  int? get length => _length;
  final String filename;
}

abstract class HttpRequestBase {
  Future<Response<T>> send<T>(Request<T> request);
  void close();
  Duration? timeout;
}

typedef MockClientHandler = Future<Response> Function(Request request);

class MockClient extends HttpRequestBase {
  final MockClientHandler _handler;
  MockClient(this._handler);
  @override
  Future<Response<T>> send<T>(Request<T> request) async {
    var requestBody = await request.bodyBytes.toBytes();
    var bodyBytes = BodyBytesStream.fromBytes(requestBody);
    var response = await _handler(request);
    final stringBody = await bodyBytesToString(bodyBytes, response.headers!);
    var mimeType = response.headers!.containsKey('content-type')
        ? response.headers!['content-type']
        : '';
    final body = bodyDecoded<T>(
      request,
      stringBody,
      mimeType,
    );
    return Response(
      headers: response.headers,
      request: request,
      statusCode: response.statusCode,
      statusText: response.statusText,
      bodyBytes: bodyBytes,
      body: body,
      bodyString: stringBody,
    );
  }

  @override
  void close() {}
}

T? bodyDecoded<T>(Request<T> request, String stringBody, String? mimeType) {
  T? body;
  var bodyToDecode;
  if (mimeType != null && mimeType.contains('application/json')) {
    try {
      bodyToDecode = jsonDecode(stringBody);
    } on FormatException catch (_) {
      Get.log('Cannot decode server response to json');
      bodyToDecode = stringBody;
    }
  } else {
    bodyToDecode = stringBody;
  }
  try {
    if (stringBody == '') {
      body = null;
    } else if (request.decoder == null) {
      body = bodyToDecode as T?;
    } else {
      body = request.decoder!(bodyToDecode);
    }
  } on Exception catch (_) {
    body = stringBody as T;
  }
  return body;
}

List<int> fileToBytes(dynamic data) {
  if (data is List<int>) {
    return data;
  } else {
    throw FormatException('File is not "File" or "String" or "List<int>"');
  }
}

class HttpRequestImpl implements HttpRequestBase {
  HttpRequestImpl({
    bool allowAutoSignedCert = true,
    List<TrustedCertificate>? trustedCertificates,
    this.withCredentials = false,
  });
  final _xhrs = <html.HttpRequest>{};
  final bool withCredentials;
  @override
  Duration? timeout;
  @override
  Future<Response<T>> send<T>(Request<T> request) async {
    var bytes = await request.bodyBytes.toBytes();
    html.HttpRequest xhr;
    xhr = html.HttpRequest()
      ..timeout = timeout?.inMilliseconds
      ..open(request.method, '${request.url}', async: true);
    _xhrs.add(xhr);
    xhr
      ..responseType = 'blob'
      ..withCredentials = withCredentials;
    request.headers.forEach(xhr.setRequestHeader);
    var completer = Completer<Response<T>>();
    xhr.onLoad.first.then((_) {
      var blob = xhr.response as html.Blob? ?? html.Blob([]);
      var reader = html.FileReader();
      reader.onLoad.first.then((_) async {
        var bodyBytes = BodyBytesStream.fromBytes(reader.result as List<int>);
        final stringBody =
            await bodyBytesToString(bodyBytes, xhr.responseHeaders);
        String? contentType;
        if (xhr.responseHeaders.containsKey('content-type')) {
          contentType = xhr.responseHeaders['content-type'];
        } else {
          contentType = 'application/json';
        }
        final body = bodyDecoded<T>(
          request,
          stringBody,
          contentType,
        );
        final response = Response<T>(
          bodyBytes: bodyBytes,
          statusCode: xhr.status,
          request: request,
          headers: xhr.responseHeaders,
          statusText: xhr.statusText,
          body: body,
          bodyString: stringBody,
        );
        completer.complete(response);
      });
      reader.onError.first.then((error) {
        completer.completeError(
          GetHttpException(error.toString(), request.url),
          StackTrace.current,
        );
      });
      reader.readAsArrayBuffer(blob);
    });
    xhr.onError.first.then((_) {
      completer.completeError(
          GetHttpException('XMLHttpRequest error.', request.url),
          StackTrace.current);
    });
    xhr.send(bytes);
    try {
      return await completer.future;
    } finally {
      _xhrs.remove(xhr);
    }
  }

  @override
  void close() {
    for (var xhr in _xhrs) {
      xhr.abort();
    }
  }
}

class Request<T> {
  final Map<String, String> headers;
  final Uri url;
  final Decoder<T>? decoder;
  final String method;
  final int? contentLength;
  final Stream<List<int>> bodyBytes;
  final bool followRedirects;
  final int maxRedirects;
  final bool persistentConnection;
  final FormData? files;
  const Request._({
    required this.method,
    required this.bodyBytes,
    required this.url,
    required this.headers,
    required this.contentLength,
    required this.followRedirects,
    required this.maxRedirects,
    required this.files,
    required this.persistentConnection,
    required this.decoder,
  });
  factory Request({
    required Uri url,
    required String method,
    required Map<String, String> headers,
    Stream<List<int>>? bodyBytes,
    bool followRedirects = true,
    int maxRedirects = 4,
    int? contentLength,
    FormData? files,
    bool persistentConnection = true,
    Decoder<T>? decoder,
  }) {
    if (followRedirects) {
      assert(maxRedirects > 0);
    }
    return Request._(
      url: url,
      method: method,
      bodyBytes: bodyBytes ??= BodyBytesStream.fromBytes(const []),
      headers: Map.from(headers),
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      contentLength: contentLength,
      files: files,
      persistentConnection: persistentConnection,
      decoder: decoder,
    );
  }
  Request copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    Stream<List<int>>? bodyBytes,
    bool followRedirects = true,
    int maxRedirects = 4,
    int? contentLength,
    FormData? files,
    bool persistentConnection = true,
    Decoder<T>? decoder,
    bool appendHeader = true,
  }) {
    if (followRedirects) {
      assert(maxRedirects > 0);
    }
    if (appendHeader && headers != null) {
      headers.addAll(this.headers);
    }
    return Request._(
      url: url ?? this.url,
      method: method ?? this.method,
      bodyBytes: bodyBytes ??= BodyBytesStream.fromBytes(const []),
      headers: headers == null ? this.headers : Map.from(headers),
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      contentLength: contentLength,
      files: files,
      persistentConnection: persistentConnection,
      decoder: decoder,
    );
  }
}

extension BodyBytesStream on Stream<List<int>> {
  static Stream<List<int>> fromBytes(List<int> bytes) =>
      Stream.fromIterable([bytes]);
  Future<Uint8List> toBytes() {
    var completer = Completer<Uint8List>();
    var sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(
        Uint8List.fromList(bytes),
      ),
    );
    listen((val) => sink.add(val),
        onError: completer.completeError,
        onDone: sink.close,
        cancelOnError: true);
    return completer.future;
  }

  Future<String> bytesToString([Encoding encoding = utf8]) =>
      encoding.decodeStream(this);
}

typedef Decoder<T> = T Function(dynamic data);
typedef Progress = Function(double percent);

class GetHttpClient {
  String userAgent;
  String? baseUrl;
  String defaultContentType = 'application/json; charset=utf-8';
  bool followRedirects;
  int maxRedirects;
  int maxAuthRetries;
  bool sendUserAgent;
  Decoder? defaultDecoder;
  Duration timeout;
  bool errorSafety = true;
  final HttpRequestBase _httpClient;
  final GetModifier _modifier;
  GetHttpClient({
    this.userAgent = 'getx-client',
    this.timeout = const Duration(seconds: 8),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.sendUserAgent = false,
    this.maxAuthRetries = 1,
    bool allowAutoSignedCert = false,
    this.baseUrl,
    List<TrustedCertificate>? trustedCertificates,
    bool withCredentials = false,
  })  : _httpClient = HttpRequestImpl(
          allowAutoSignedCert: allowAutoSignedCert,
          trustedCertificates: trustedCertificates,
          withCredentials: withCredentials,
        ),
        _modifier = GetModifier();
  void addAuthenticator<T>(RequestModifier<T> auth) {
    _modifier.authenticator = auth as RequestModifier;
  }

  void addRequestModifier<T>(RequestModifier<T> interceptor) {
    _modifier.addRequestModifier<T>(interceptor);
  }

  void removeRequestModifier<T>(RequestModifier<T> interceptor) {
    _modifier.removeRequestModifier(interceptor);
  }

  void addResponseModifier<T>(ResponseModifier<T> interceptor) {
    _modifier.addResponseModifier(interceptor);
  }

  void removeResponseModifier<T>(ResponseModifier<T> interceptor) {
    _modifier.removeResponseModifier<T>(interceptor);
  }

  Uri _createUri(String? url, Map<String, dynamic>? query) {
    if (baseUrl != null) {
      url = baseUrl! + url!;
    }
    final uri = Uri.parse(url!);
    if (query != null) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Future<Request<T>> _requestWithBody<T>(
    String? url,
    String? contentType,
    dynamic body,
    String method,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  ) async {
    List<int>? bodyBytes;
    Stream<List<int>>? bodyStream;
    final headers = <String, String>{};
    if (sendUserAgent) {
      headers['user-agent'] = userAgent;
    }
    if (body is FormData) {
      bodyBytes = await body.toBytes();
      headers['content-length'] = bodyBytes.length.toString();
      headers['content-type'] =
          'multipart/form-data; boundary=${body.boundary}';
    } else if (contentType != null &&
        contentType.toLowerCase() == 'application/x-www-form-urlencoded' &&
        body is Map) {
      var parts = [];
      (body as Map<String, dynamic>).forEach((key, value) {
        parts.add('${Uri.encodeQueryComponent(key)}='
            '${Uri.encodeQueryComponent(value.toString())}');
      });
      var formData = parts.join('&');
      bodyBytes = utf8.encode(formData);
      headers['content-length'] = bodyBytes.length.toString();
      headers['content-type'] = contentType;
    } else if (body is Map || body is List) {
      var jsonString = json.encode(body);
      bodyBytes = utf8.encode(jsonString);
      headers['content-length'] = bodyBytes.length.toString();
      headers['content-type'] = contentType ?? defaultContentType;
    } else if (body is String) {
      bodyBytes = utf8.encode(body);
      headers['content-length'] = bodyBytes.length.toString();
      headers['content-type'] = contentType ?? defaultContentType;
    } else if (body == null) {
      headers['content-type'] = contentType ?? defaultContentType;
      headers['content-length'] = '0';
    } else {
      if (!errorSafety) {
        throw UnexpectedFormat('body cannot be ${body.runtimeType}');
      }
    }
    if (bodyBytes != null) {
      bodyStream = _trackProgress(bodyBytes, uploadProgress);
    }
    final uri = _createUri(url, query);
    return Request<T>(
      method: method,
      url: uri,
      headers: headers,
      bodyBytes: bodyStream,
      contentLength: bodyBytes?.length ?? 0,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      decoder: decoder,
    );
  }

  Stream<List<int>> _trackProgress(
    List<int> bodyBytes,
    Progress? uploadProgress,
  ) {
    var total = 0;
    var length = bodyBytes.length;
    var byteStream =
        Stream.fromIterable(bodyBytes.map((i) => [i])).transform<List<int>>(
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        total += data.length;
        if (uploadProgress != null) {
          var percent = total / length * 100;
          uploadProgress(percent);
        }
        sink.add(data);
      }),
    );
    return byteStream;
  }

  void _setSimpleHeaders(
    Map<String, String> headers,
    String? contentType,
  ) {
    headers['content-type'] = contentType ?? defaultContentType;
    if (sendUserAgent) {
      headers['user-agent'] = userAgent;
    }
  }

  Future<Response<T>> _performRequest<T>(
    HandlerExecute<T> handler, {
    bool authenticate = false,
    int requestNumber = 1,
    Map<String, String>? headers,
  }) async {
    try {
      var request = await handler();
      headers?.forEach((key, value) {
        request.headers[key] = value;
      });
      if (authenticate) await _modifier.authenticator!(request);
      final newRequest = await _modifier.modifyRequest<T>(request);
      _httpClient.timeout = timeout;
      var response = await _httpClient.send<T>(newRequest);
      final newResponse =
          await _modifier.modifyResponse<T>(newRequest, response);
      if (HttpStatus.unauthorized == newResponse.statusCode &&
          _modifier.authenticator != null &&
          requestNumber <= maxAuthRetries) {
        return _performRequest<T>(
          handler,
          authenticate: true,
          requestNumber: requestNumber + 1,
          headers: newRequest.headers,
        );
      } else if (HttpStatus.unauthorized == newResponse.statusCode) {
        if (!errorSafety) {
          throw UnauthorizedException();
        } else {
          return Response<T>(
            request: newRequest,
            headers: newResponse.headers,
            statusCode: newResponse.statusCode,
            body: newResponse.body,
            bodyBytes: newResponse.bodyBytes,
            bodyString: newResponse.bodyString,
            statusText: newResponse.statusText,
          );
        }
      }
      return newResponse;
    } on Exception catch (err) {
      if (!errorSafety) {
        throw GetHttpException(err.toString());
      } else {
        return Response<T>(
          request: null,
          headers: null,
          statusCode: null,
          body: null,
          statusText: "$err",
        );
      }
    }
  }

  Future<Request<T>> _get<T>(
    String url,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  ) {
    final headers = <String, String>{};
    _setSimpleHeaders(headers, contentType);
    final uri = _createUri(url, query);
    return Future.value(Request<T>(
      method: 'get',
      url: uri,
      headers: headers,
      decoder: decoder ?? (defaultDecoder as Decoder<T>?),
      contentLength: 0,
    ));
  }

  Future<Request<T>> _request<T>(
    String? url,
    String method, {
    String? contentType,
    required dynamic body,
    required Map<String, dynamic>? query,
    Decoder<T>? decoder,
    required Progress? uploadProgress,
  }) {
    return _requestWithBody<T>(
      url,
      contentType,
      body,
      method,
      query,
      decoder ?? (defaultDecoder as Decoder<T>?),
      uploadProgress,
    );
  }

  Request<T> _delete<T>(
    String url,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  ) {
    final headers = <String, String>{};
    _setSimpleHeaders(headers, contentType);
    final uri = _createUri(url, query);
    return Request<T>(
      method: 'delete',
      url: uri,
      headers: headers,
      decoder: decoder ?? (defaultDecoder as Decoder<T>?),
    );
  }

  Future<Response<T>> patch<T>(
    String url, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    try {
      var response = await _performRequest<T>(
        () => _request<T>(
          url,
          'patch',
          contentType: contentType,
          body: body,
          query: query,
          decoder: decoder,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(Response<T>(
        statusText: 'Can not connect to server. Reason: $e',
      ));
    }
  }

  Future<Response<T>> post<T>(
    String? url, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    try {
      var response = await _performRequest<T>(
        () => _request<T>(
          url,
          'post',
          contentType: contentType,
          body: body,
          query: query,
          decoder: decoder,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(Response<T>(
        statusText: 'Can not connect to server. Reason: $e',
      ));
    }
  }

  Future<Response<T>> request<T>(
    String url,
    String method, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    try {
      var response = await _performRequest<T>(
        () => _request<T>(
          url,
          method,
          contentType: contentType,
          query: query,
          body: body,
          decoder: decoder,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(Response<T>(
        statusText: 'Can not connect to server. Reason: $e',
      ));
    }
  }

  Future<Response<T>> put<T>(
    String url, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    try {
      var response = await _performRequest<T>(
        () => _request<T>(
          url,
          'put',
          contentType: contentType,
          query: query,
          body: body,
          decoder: decoder,
          uploadProgress: uploadProgress,
        ),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(Response<T>(
        statusText: 'Can not connect to server. Reason: $e',
      ));
    }
  }

  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    try {
      var response = await _performRequest<T>(
        () => _get<T>(url, contentType, query, decoder),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(Response<T>(
        statusText: 'Can not connect to server. Reason: $e',
      ));
    }
  }

  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    try {
      var response = await _performRequest<T>(
        () async => _delete<T>(url, contentType, query, decoder),
        headers: headers,
      );
      return response;
    } on Exception catch (e) {
      if (!errorSafety) {
        throw GetHttpException(e.toString());
      }
      return Future.value(Response<T>(
        statusText: 'Can not connect to server. Reason: $e',
      ));
    }
  }

  void close() {
    _httpClient.close();
  }
}

abstract class GetConnectInterface with GetLifeCycleBase {
  List<GetSocket>? sockets;
  GetHttpClient get httpClient;
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });
  Future<Response<T>> request<T>(
    String url,
    String method, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });
  Future<Response<T>> post<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });
  Future<Response<T>> put<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  });
  Future<Response<T>> patch<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  });
  Future<GraphQLResponse<T>> query<T>(
    String query, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  });
  Future<GraphQLResponse<T>> mutation<T>(
    String mutation, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  });
  GetSocket socket(
    String url, {
    Duration ping = const Duration(seconds: 5),
  });
}

class GetConnect extends GetConnectInterface {
  GetConnect({
    this.userAgent = 'getx-client',
    this.timeout = const Duration(seconds: 5),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.sendUserAgent = false,
    this.maxAuthRetries = 1,
    this.allowAutoSignedCert = false,
    this.withCredentials = false,
  }) {
    $configureLifeCycle();
  }
  bool allowAutoSignedCert;
  String userAgent;
  bool sendUserAgent;
  String? baseUrl;
  String defaultContentType = 'application/json; charset=utf-8';
  bool followRedirects;
  int maxRedirects;
  int maxAuthRetries;
  Decoder? defaultDecoder;
  Duration timeout;
  List<TrustedCertificate>? trustedCertificates;
  GetHttpClient? _httpClient;
  List<GetSocket>? _sockets;
  bool withCredentials;
  @override
  List<GetSocket> get sockets => _sockets ??= <GetSocket>[];
  @override
  GetHttpClient get httpClient => _httpClient ??= GetHttpClient(
        userAgent: userAgent,
        sendUserAgent: sendUserAgent,
        timeout: timeout,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        maxAuthRetries: maxAuthRetries,
        allowAutoSignedCert: allowAutoSignedCert,
        baseUrl: baseUrl,
        trustedCertificates: trustedCertificates,
        withCredentials: withCredentials,
      );
  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    _checkIfDisposed();
    return httpClient.get<T>(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.post<T>(
      url,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.put<T>(
      url,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.patch<T>(
      url,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> request<T>(
    String url,
    String method, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    _checkIfDisposed();
    return httpClient.request<T>(
      url,
      method,
      body: body,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    _checkIfDisposed();
    return httpClient.delete(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );
  }

  @override
  GetSocket socket(
    String url, {
    Duration ping = const Duration(seconds: 5),
  }) {
    _checkIfDisposed(isHttp: false);
    final _socket = GetSocket(_concatUrl(url)!, ping: ping);
    sockets.add(_socket);
    return _socket;
  }

  String? _concatUrl(String? url) {
    if (url == null) return baseUrl;
    return baseUrl == null ? url : baseUrl! + url;
  }

  @override
  Future<GraphQLResponse<T>> query<T>(
    String query, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await post(
        url,
        {'query': query, 'variables': variables},
        headers: headers,
      );
      final listError = res.body['errors'];
      if ((listError is List) && listError.isNotEmpty) {
        return GraphQLResponse<T>(
            graphQLErrors: listError
                .map((e) => GraphQLError(
                      code: e['extensions']['code']?.toString(),
                      message: e['message']?.toString(),
                    ))
                .toList());
      }
      return GraphQLResponse<T>.fromResponse(res);
    } on Exception catch (_) {
      return GraphQLResponse<T>(graphQLErrors: [
        GraphQLError(
          code: null,
          message: _.toString(),
        )
      ]);
    }
  }

  @override
  Future<GraphQLResponse<T>> mutation<T>(
    String mutation, {
    String? url,
    Map<String, dynamic>? variables,
    Map<String, String>? headers,
  }) async {
    try {
      final res = await post(
        url,
        {'query': mutation, 'variables': variables},
        headers: headers,
      );
      final listError = res.body['errors'];
      if ((listError is List) && listError.isNotEmpty) {
        return GraphQLResponse<T>(
            graphQLErrors: listError
                .map((e) => GraphQLError(
                      code: e['extensions']['code']?.toString(),
                      message: e['message']?.toString(),
                    ))
                .toList());
      }
      return GraphQLResponse<T>.fromResponse(res);
    } on Exception catch (_) {
      return GraphQLResponse<T>(graphQLErrors: [
        GraphQLError(
          code: null,
          message: _.toString(),
        )
      ]);
    }
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;
  void _checkIfDisposed({bool isHttp = true}) {
    if (_isDisposed) {
      throw 'Can not emit events to disposed clients';
    }
  }

  void dispose() {
    if (_sockets != null) {
      for (var socket in sockets) {
        socket.close();
      }
      _sockets?.clear();
      sockets = null;
    }
    if (_httpClient != null) {
      httpClient.close();
      _httpClient = null;
    }
    _isDisposed = true;
  }
}

abstract class Bindings {
  void dependencies();
}

class BindingsBuilder<T> extends Bindings {
  final BindingBuilderCallback builder;
  factory BindingsBuilder.put(InstanceBuilderCallback<T> builder,
      {String? tag, bool permanent = false}) {
    return BindingsBuilder(
        () => GetInstance().put<T>(builder(), tag: tag, permanent: permanent));
  }
  BindingsBuilder(this.builder);
  @override
  void dependencies() {
    builder();
  }
}

typedef BindingBuilderCallback = void Function();

extension Inst on GetInterface {
  void lazyPut<S>(InstanceBuilderCallback<S> builder,
      {String? tag, bool fenix = false}) {
    GetInstance().lazyPut<S>(builder, tag: tag, fenix: fenix);
  }

  Future<S> putAsync<S>(AsyncInstanceBuilderCallback<S> builder,
          {String? tag, bool permanent = false}) async =>
      GetInstance().putAsync<S>(builder, tag: tag, permanent: permanent);
  void create<S>(InstanceBuilderCallback<S> builder,
          {String? tag, bool permanent = true}) =>
      GetInstance().create<S>(builder, tag: tag, permanent: permanent);
  S find<S>({String? tag}) => GetInstance().find<S>(tag: tag);
  S put<S>(S dependency,
          {String? tag,
          bool permanent = false,
          InstanceBuilderCallback<S>? builder}) =>
      GetInstance().put<S>(dependency, tag: tag, permanent: permanent);
  Future<bool> delete<S>({String? tag, bool force = false}) async =>
      GetInstance().delete<S>(tag: tag, force: force);
  Future<void> deleteAll({bool force = false}) async =>
      GetInstance().deleteAll(force: force);
  void reloadAll({bool force = false}) => GetInstance().reloadAll(force: force);
  void reload<S>({String? tag, String? key, bool force = false}) =>
      GetInstance().reload<S>(tag: tag, key: key, force: force);
  bool isRegistered<S>({String? tag}) =>
      GetInstance().isRegistered<S>(tag: tag);
  bool isPrepared<S>({String? tag}) => GetInstance().isPrepared<S>(tag: tag);
  void replace<P>(P child, {String? tag}) {
    final info = GetInstance().getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    put(child, tag: tag, permanent: permanent);
  }

  void lazyReplace<P>(InstanceBuilderCallback<P> builder,
      {String? tag, bool? fenix}) {
    final info = GetInstance().getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    lazyPut(builder, tag: tag, fenix: fenix ?? permanent);
  }
}

class InternalFinalCallback<T> {
  ValueUpdater<T>? _callback;
  InternalFinalCallback({ValueUpdater<T>? callback}) : _callback = callback;
  T call() => _callback!.call();
}

mixin GetLifeCycleBase {
  final onStart = InternalFinalCallback<void>();
  final onDelete = InternalFinalCallback<void>();
  void onInit() {}
  void onReady() {}
  void onClose() {}
  bool _initialized = false;
  bool get initialized => _initialized;
  void _onStart() {
    if (_initialized) return;
    onInit();
    _initialized = true;
  }

  bool _isClosed = false;
  bool get isClosed => _isClosed;
  void _onDelete() {
    if (_isClosed) return;
    _isClosed = true;
    onClose();
  }

  void $configureLifeCycle() {
    _checkIfAlreadyConfigured();
    onStart._callback = _onStart;
    onDelete._callback = _onDelete;
  }

  void _checkIfAlreadyConfigured() {
    if (_initialized) {
      throw """You can only call configureLifeCycle once.  The proper place to insert it is in your class's constructor  that inherits GetLifeCycle.""";
    }
  }
}

abstract class GetLifeCycle with GetLifeCycleBase {
  GetLifeCycle() {
    $configureLifeCycle();
  }
}

mixin GetxServiceMixin {}

class InstanceInfo {
  final bool? isPermanent;
  final bool? isSingleton;
  bool get isCreate => !isSingleton!;
  final bool isRegistered;
  final bool isPrepared;
  final bool? isInit;
  const InstanceInfo({
    required this.isPermanent,
    required this.isSingleton,
    required this.isRegistered,
    required this.isPrepared,
    required this.isInit,
  });
}

class GetInstance {
  factory GetInstance() => _getInstance ??= GetInstance._();
  const GetInstance._();
  static GetInstance? _getInstance;
  T call<T>() => find<T>();
  static final Map<String, _InstanceBuilderFactory> _singl = {};
  void injector<S>(
    InjectorBuilderCallback<S> fn, {
    String? tag,
    bool fenix = false,
  }) {
    lazyPut(
      () => fn(this),
      tag: tag,
      fenix: fenix,
    );
  }

  Future<S> putAsync<S>(
    AsyncInstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = false,
  }) async {
    return put<S>(await builder(), tag: tag, permanent: permanent);
  }

  S put<S>(
    S dependency, {
    String? tag,
    bool permanent = false,
    @deprecated InstanceBuilderCallback<S>? builder,
  }) {
    _insert(
        isSingleton: true,
        name: tag,
        permanent: permanent,
        builder: builder ?? (() => dependency));
    return find<S>(tag: tag);
  }

  void lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool? fenix,
    bool permanent = false,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: builder,
      fenix: fenix ?? Get.smartManagement == SmartManagement.keepFactory,
    );
  }

  void create<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    _insert(
      isSingleton: false,
      name: tag,
      builder: builder,
      permanent: permanent,
    );
  }

  void _insert<S>({
    bool? isSingleton,
    String? name,
    bool permanent = false,
    required InstanceBuilderCallback<S> builder,
    bool fenix = false,
  }) {
    final key = _getKey(S, name);
    if (_singl.containsKey(key)) {
      final dep = _singl[key];
      if (dep != null && dep.isDirty) {
        _singl[key] = _InstanceBuilderFactory<S>(
          isSingleton,
          builder,
          permanent,
          false,
          fenix,
          name,
          lateRemove: dep as _InstanceBuilderFactory<S>,
        );
      }
    } else {
      _singl[key] = _InstanceBuilderFactory<S>(
        isSingleton,
        builder,
        permanent,
        false,
        fenix,
        name,
      );
    }
  }

  S? _initDependencies<S>({String? name}) {
    final key = _getKey(S, name);
    final isInit = _singl[key]!.isInit;
    S? i;
    if (!isInit) {
      i = _startController<S>(tag: name);
      if (_singl[key]!.isSingleton!) {
        _singl[key]!.isInit = true;
        if (Get.smartManagement != SmartManagement.onlyBuilder) {
          RouterReportManager.reportDependencyLinkedToRoute(_getKey(S, name));
        }
      }
    }
    return i;
  }

  InstanceInfo getInstanceInfo<S>({String? tag}) {
    final build = _getDependency<S>(tag: tag);
    return InstanceInfo(
      isPermanent: build?.permanent,
      isSingleton: build?.isSingleton,
      isRegistered: isRegistered<S>(tag: tag),
      isPrepared: !(build?.isInit ?? true),
      isInit: build?.isInit,
    );
  }

  _InstanceBuilderFactory? _getDependency<S>({String? tag, String? key}) {
    final newKey = key ?? _getKey(S, tag);
    if (!_singl.containsKey(newKey)) {
      Get.log('Instance "$newKey" is not registered.', isError: true);
      return null;
    } else {
      return _singl[newKey];
    }
  }

  void markAsDirty<S>({String? tag, String? key}) {
    final newKey = key ?? _getKey(S, tag);
    if (_singl.containsKey(newKey)) {
      final dep = _singl[newKey];
      if (dep != null) {
        dep.isDirty = true;
      }
    }
  }

  S _startController<S>({String? tag}) {
    final key = _getKey(S, tag);
    final i = _singl[key]!.getDependency() as S;
    if (i is GetLifeCycleBase) {
      i.onStart();
      if (tag == null) {
        Get.log('Instance "$S" has been initialized');
      } else {
        Get.log('Instance "$S" with tag "$tag" has been initialized');
      }
      if (!_singl[key]!.isSingleton!) {
        RouterReportManager.appendRouteByCreate(i);
      }
    }
    return i;
  }

  S putOrFind<S>(InstanceBuilderCallback<S> dep, {String? tag}) {
    final key = _getKey(S, tag);
    if (_singl.containsKey(key)) {
      return _singl[key]!.getDependency() as S;
    } else {
      return GetInstance().put(dep(), tag: tag);
    }
  }

  S find<S>({String? tag}) {
    final key = _getKey(S, tag);
    if (isRegistered<S>(tag: tag)) {
      final dep = _singl[key];
      if (dep == null) {
        if (tag == null) {
          throw 'Class "$S" is not registered';
        } else {
          throw 'Class "$S" with tag "$tag" is not registered';
        }
      }
      final i = _initDependencies<S>(name: tag);
      return i ?? dep.getDependency() as S;
    } else {
      throw '"$S" not found. You need to call "Get.put($S())" or "Get.lazyPut(()=>$S())"';
    }
  }

  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }

  bool resetInstance(
      {@deprecated bool clearFactory = true, bool clearRouteBindings = true}) {
    if (clearRouteBindings) RouterReportManager.clearRouteKeys();
    _singl.clear();
    return true;
  }

  bool delete<S>({String? tag, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, tag);
    if (!_singl.containsKey(newKey)) {
      Get.log('Instance "$newKey" already removed.', isError: true);
      return false;
    }
    final dep = _singl[newKey];
    if (dep == null) return false;
    final _InstanceBuilderFactory builder;
    if (dep.isDirty) {
      builder = dep.lateRemove ?? dep;
    } else {
      builder = dep;
    }
    if (builder.permanent && !force) {
      Get.log(
        '"$newKey" has been marked as permanent, SmartManagement is not authorized to delete it.',
        isError: true,
      );
      return false;
    }
    final i = builder.dependency;
    if (i is GetxServiceMixin && !force) {
      return false;
    }
    if (i is GetLifeCycleBase) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }
    if (builder.fenix) {
      builder.dependency = null;
      builder.isInit = false;
      return true;
    } else {
      if (dep.lateRemove != null) {
        dep.lateRemove = null;
        Get.log('"$newKey" deleted from memory');
        return false;
      } else {
        _singl.remove(newKey);
        if (_singl.containsKey(newKey)) {
          Get.log('Error removing object "$newKey"', isError: true);
        } else {
          Get.log('"$newKey" deleted from memory');
        }
        return true;
      }
    }
  }

  void deleteAll({bool force = false}) {
    final keys = _singl.keys.toList();
    for (final key in keys) {
      delete(key: key, force: force);
    }
  }

  void reloadAll({bool force = false}) {
    _singl.forEach((key, value) {
      if (value.permanent && !force) {
        Get.log('Instance "$key" is permanent. Skipping reload');
      } else {
        value.dependency = null;
        value.isInit = false;
        Get.log('Instance "$key" was reloaded.');
      }
    });
  }

  void reload<S>({
    String? tag,
    String? key,
    bool force = false,
  }) {
    final newKey = key ?? _getKey(S, tag);
    final builder = _getDependency<S>(tag: tag, key: newKey);
    if (builder == null) return;
    if (builder.permanent && !force) {
      Get.log(
        '''Instance "$newKey" is permanent. Use [force = true] to force the restart.''',
        isError: true,
      );
      return;
    }
    final i = builder.dependency;
    if (i is GetxServiceMixin && !force) {
      return;
    }
    if (i is GetLifeCycleBase) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }
    builder.dependency = null;
    builder.isInit = false;
    Get.log('Instance "$newKey" was restarted.');
  }

  bool isRegistered<S>({String? tag}) => _singl.containsKey(_getKey(S, tag));
  bool isPrepared<S>({String? tag}) {
    final newKey = _getKey(S, tag);
    final builder = _getDependency<S>(tag: tag, key: newKey);
    if (builder == null) {
      return false;
    }
    if (!builder.isInit) {
      return true;
    }
    return false;
  }
}

typedef InstanceBuilderCallback<S> = S Function();
typedef InjectorBuilderCallback<S> = S Function(GetInstance);
typedef AsyncInstanceBuilderCallback<S> = Future<S> Function();

class _InstanceBuilderFactory<S> {
  bool? isSingleton;
  bool fenix;
  S? dependency;
  InstanceBuilderCallback<S> builderFunc;
  bool permanent = false;
  bool isInit = false;
  _InstanceBuilderFactory<S>? lateRemove;
  bool isDirty = false;
  String? tag;
  _InstanceBuilderFactory(
    this.isSingleton,
    this.builderFunc,
    this.permanent,
    this.isInit,
    this.fenix,
    this.tag, {
    this.lateRemove,
  });
  void _showInitLog() {
    if (tag == null) {
      Get.log('Instance "$S" has been created');
    } else {
      Get.log('Instance "$S" has been created with tag "$tag"');
    }
  }

  S getDependency() {
    if (isSingleton!) {
      if (dependency == null) {
        _showInitLog();
        dependency = builderFunc();
      }
      return dependency!;
    } else {
      return builderFunc();
    }
  }
}

class GetStream<T> {
  void Function()? onListen;
  void Function()? onPause;
  void Function()? onResume;
  FutureOr<void> Function()? onCancel;
  GetStream({this.onListen, this.onPause, this.onResume, this.onCancel});
  List<LightSubscription<T>>? _onData = <LightSubscription<T>>[];
  bool? _isBusy = false;
  FutureOr<bool?> removeSubscription(LightSubscription<T> subs) async {
    if (!_isBusy!) {
      return _onData!.remove(subs);
    } else {
      await Future.delayed(Duration.zero);
      return _onData?.remove(subs);
    }
  }

  FutureOr<void> addSubscription(LightSubscription<T> subs) async {
    if (!_isBusy!) {
      return _onData!.add(subs);
    } else {
      await Future.delayed(Duration.zero);
      return _onData!.add(subs);
    }
  }

  int? get length => _onData?.length;
  bool get hasListeners => _onData!.isNotEmpty;
  void _notifyData(T data) {
    _isBusy = true;
    for (final item in _onData!) {
      if (!item.isPaused) {
        item._data?.call(data);
      }
    }
    _isBusy = false;
  }

  void _notifyError(Object error, [StackTrace? stackTrace]) {
    assert(!isClosed, 'You cannot add errors to a closed stream.');
    _isBusy = true;
    var itemsToRemove = <LightSubscription<T>>[];
    for (final item in _onData!) {
      if (!item.isPaused) {
        if (stackTrace != null) {
          item._onError?.call(error, stackTrace);
        } else {
          item._onError?.call(error);
        }
        if (item.cancelOnError ?? false) {
          itemsToRemove.add(item);
          item.pause();
          item._onDone?.call();
        }
      }
    }
    for (final item in itemsToRemove) {
      _onData!.remove(item);
    }
    _isBusy = false;
  }

  void _notifyDone() {
    assert(!isClosed, 'You cannot close a closed stream.');
    _isBusy = true;
    for (final item in _onData!) {
      if (!item.isPaused) {
        item._onDone?.call();
      }
    }
    _isBusy = false;
  }

  T? _value;
  T? get value => _value;
  void add(T event) {
    assert(!isClosed, 'You cannot add event to closed Stream');
    _value = event;
    _notifyData(event);
  }

  bool get isClosed => _onData == null;
  void addError(Object error, [StackTrace? stackTrace]) {
    assert(!isClosed, 'You cannot add error to closed Stream');
    _notifyError(error, stackTrace);
  }

  void close() {
    assert(!isClosed, 'You cannot close a closed Stream');
    _notifyDone();
    _onData = null;
    _isBusy = null;
    _value = null;
  }

  LightSubscription<T> listen(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final subs = LightSubscription<T>(
      removeSubscription,
      onPause: onPause,
      onResume: onResume,
      onCancel: onCancel,
    )
      ..onData(onData)
      ..onError(onError)
      ..onDone(onDone)
      ..cancelOnError = cancelOnError;
    addSubscription(subs);
    onListen?.call();
    return subs;
  }

  Stream<T> get stream =>
      GetStreamTransformation(addSubscription, removeSubscription);
}

class LightSubscription<T> extends StreamSubscription<T> {
  final RemoveSubscription<T> _removeSubscription;
  LightSubscription(this._removeSubscription,
      {this.onPause, this.onResume, this.onCancel});
  final void Function()? onPause;
  final void Function()? onResume;
  final FutureOr<void> Function()? onCancel;
  bool? cancelOnError = false;
  @override
  Future<void> cancel() {
    _removeSubscription(this);
    onCancel?.call();
    return Future.value();
  }

  OnData<T>? _data;
  Function? _onError;
  Callback? _onDone;
  bool _isPaused = false;
  @override
  void onData(OnData<T>? handleData) => _data = handleData;
  @override
  void onError(Function? handleError) => _onError = handleError;
  @override
  void onDone(Callback? handleDone) => _onDone = handleDone;
  @override
  void pause([Future<void>? resumeSignal]) {
    _isPaused = true;
    onPause?.call();
  }

  @override
  void resume() {
    _isPaused = false;
    onResume?.call();
  }

  @override
  bool get isPaused => _isPaused;
  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue);
}

class GetStreamTransformation<T> extends Stream<T> {
  final AddSubscription<T> _addSubscription;
  final RemoveSubscription<T> _removeSubscription;
  GetStreamTransformation(this._addSubscription, this._removeSubscription);
  @override
  LightSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final subs = LightSubscription<T>(_removeSubscription)
      ..onData(onData)
      ..onError(onError)
      ..onDone(onDone);
    _addSubscription(subs);
    return subs;
  }
}

typedef RemoveSubscription<T> = FutureOr<bool?> Function(
    LightSubscription<T> subs);
typedef AddSubscription<T> = FutureOr<void> Function(LightSubscription<T> subs);

class Node<T> {
  T? data;
  Node<T>? next;
  Node({this.data, this.next});
}

class MiniSubscription<T> {
  const MiniSubscription(
      this.data, this.onError, this.onDone, this.cancelOnError, this.listener);
  final OnData<T> data;
  final Function? onError;
  final Callback? onDone;
  final bool cancelOnError;
  Future<void> cancel() async => listener.removeListener(this);
  final FastList<T> listener;
}

class MiniStream<T> {
  FastList<T> listenable = FastList<T>();
  late T _value;
  T get value => _value;
  set value(T val) {
    add(val);
  }

  void add(T event) {
    _value = event;
    listenable._notifyData(event);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    listenable._notifyError(error, stackTrace);
  }

  int get length => listenable.length;
  bool get hasListeners => listenable.isNotEmpty;
  bool get isClosed => _isClosed;
  MiniSubscription<T> listen(void Function(T event) onData,
      {Function? onError,
      void Function()? onDone,
      bool cancelOnError = false}) {
    final subs = MiniSubscription<T>(
      onData,
      onError,
      onDone,
      cancelOnError,
      listenable,
    );
    listenable.addListener(subs);
    return subs;
  }

  bool _isClosed = false;
  void close() {
    if (_isClosed) {
      throw 'You can not close a closed Stream';
    }
    listenable._notifyDone();
    listenable.clear();
    _isClosed = true;
  }
}

class FastList<T> {
  Node<MiniSubscription<T>>? _head;
  void _notifyData(T data) {
    var currentNode = _head;
    do {
      currentNode?.data?.data(data);
      currentNode = currentNode?.next;
    } while (currentNode != null);
  }

  void _notifyDone() {
    var currentNode = _head;
    do {
      currentNode?.data?.onDone?.call();
      currentNode = currentNode?.next;
    } while (currentNode != null);
  }

  void _notifyError(Object error, [StackTrace? stackTrace]) {
    var currentNode = _head;
    while (currentNode != null) {
      currentNode.data!.onError?.call(error, stackTrace);
      currentNode = currentNode.next;
    }
  }

  bool get isEmpty => _head == null;
  bool get isNotEmpty => !isEmpty;
  int get length {
    var length = 0;
    var currentNode = _head;
    while (currentNode != null) {
      currentNode = currentNode.next;
      length++;
    }
    return length;
  }

  MiniSubscription<T>? _elementAt(int position) {
    if (isEmpty || length < position || position < 0) return null;
    var node = _head;
    var current = 0;
    while (current != position) {
      node = node!.next;
      current++;
    }
    return node!.data;
  }

  void addListener(MiniSubscription<T> data) {
    var newNode = Node(data: data);
    if (isEmpty) {
      _head = newNode;
    } else {
      var currentNode = _head!;
      while (currentNode.next != null) {
        currentNode = currentNode.next!;
      }
      currentNode.next = newNode;
    }
  }

  bool contains(T element) {
    var length = this.length;
    for (var i = 0; i < length; i++) {
      if (_elementAt(i) == element) return true;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return false;
  }

  void removeListener(MiniSubscription<T> element) {
    var length = this.length;
    for (var i = 0; i < length; i++) {
      if (_elementAt(i) == element) {
        _removeAt(i);
        break;
      }
    }
  }

  void clear() {
    var length = this.length;
    for (var i = 0; i < length; i++) {
      _removeAt(i);
    }
  }

  MiniSubscription<T>? _removeAt(int position) {
    var index = 0;
    var currentNode = _head;
    Node<MiniSubscription<T>>? previousNode;
    if (isEmpty || length < position || position < 0) {
      throw Exception('Invalid position');
    } else if (position == 0) {
      _head = _head!.next;
    } else {
      while (index != position) {
        previousNode = currentNode;
        currentNode = currentNode!.next;
        index++;
      }
      if (previousNode == null) {
        _head = null;
      } else {
        previousNode.next = currentNode!.next;
      }
      currentNode!.next = null;
    }
    return currentNode!.data;
  }
}

bool _conditional(dynamic condition) {
  if (condition == null) return true;
  if (condition is bool) return condition;
  if (condition is bool Function()) return condition();
  return true;
}

typedef WorkerCallback<T> = Function(T callback);

class Workers {
  Workers(this.workers);
  final List<Worker> workers;
  void dispose() {
    for (final worker in workers) {
      if (!worker._disposed) {
        worker.dispose();
      }
    }
  }
}

Worker ever<T>(
  RxInterface<T> listener,
  WorkerCallback<T> callback, {
  dynamic condition = true,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  StreamSubscription sub = listener.listen(
    (event) {
      if (_conditional(condition)) callback(event);
    },
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  return Worker(sub.cancel, '[ever]');
}

Worker everAll(
  List<RxInterface> listeners,
  WorkerCallback callback, {
  dynamic condition = true,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  final evers = <StreamSubscription>[];
  for (var i in listeners) {
    final sub = i.listen(
      (event) {
        if (_conditional(condition)) callback(event);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    evers.add(sub);
  }
  Future<void> cancel() {
    for (var i in evers) {
      i.cancel();
    }
    return Future.value(() {});
  }

  return Worker(cancel, '[everAll]');
}

Worker once<T>(
  RxInterface<T> listener,
  WorkerCallback<T> callback, {
  dynamic condition = true,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  late Worker ref;
  StreamSubscription? sub;
  sub = listener.listen(
    (event) {
      if (!_conditional(condition)) return;
      ref._disposed = true;
      ref._log('called');
      sub?.cancel();
      callback(event);
    },
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  ref = Worker(sub.cancel, '[once]');
  return ref;
}

Worker interval<T>(
  RxInterface<T> listener,
  WorkerCallback<T> callback, {
  Duration time = const Duration(seconds: 1),
  dynamic condition = true,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  var debounceActive = false;
  StreamSubscription sub = listener.listen(
    (event) async {
      if (debounceActive || !_conditional(condition)) return;
      debounceActive = true;
      await Future.delayed(time);
      debounceActive = false;
      callback(event);
    },
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  return Worker(sub.cancel, '[interval]');
}

Worker debounce<T>(
  RxInterface<T> listener,
  WorkerCallback<T> callback, {
  Duration? time,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  final _debouncer =
      Debouncer(delay: time ?? const Duration(milliseconds: 800));
  StreamSubscription sub = listener.listen(
    (event) {
      _debouncer(() {
        callback(event);
      });
    },
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  return Worker(sub.cancel, '[debounce]');
}

class Worker {
  Worker(this.worker, this.type);
  final Future<void> Function() worker;
  final String type;
  bool _disposed = false;
  bool get disposed => _disposed;
  void _log(String msg) {
    Get.log('$runtimeType $type $msg');
  }

  void dispose() {
    if (_disposed) {
      _log('already disposed');
      return;
    }
    _disposed = true;
    worker();
    _log('disposed');
  }

  void call() => dispose();
}

class Debouncer {
  final Duration? delay;
  Timer? _timer;
  Debouncer({this.delay});
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay!, action);
  }

  bool get isRunning => _timer?.isActive ?? false;
  void cancel() => _timer?.cancel();
}

class RxList<E> extends ListMixin<E>
    with NotifyManager<List<E>>, RxObjectMixin<List<E>>
    implements RxInterface<List<E>> {
  RxList([List<E> initial = const []]) {
    _value = List.from(initial);
  }
  factory RxList.filled(int length, E fill, {bool growable = false}) {
    return RxList(List.filled(length, fill, growable: growable));
  }
  factory RxList.empty({bool growable = false}) {
    return RxList(List.empty(growable: growable));
  }
  factory RxList.from(Iterable elements, {bool growable = true}) {
    return RxList(List.from(elements, growable: growable));
  }
  factory RxList.of(Iterable<E> elements, {bool growable = true}) {
    return RxList(List.of(elements, growable: growable));
  }
  factory RxList.generate(int length, E generator(int index),
      {bool growable = true}) {
    return RxList(List.generate(length, generator, growable: growable));
  }
  factory RxList.unmodifiable(Iterable elements) {
    return RxList(List.unmodifiable(elements));
  }
  @override
  Iterator<E> get iterator => value.iterator;
  @override
  void operator []=(int index, E val) {
    _value[index] = val;
    refresh();
  }

  @override
  RxList<E> operator +(Iterable<E> val) {
    addAll(val);
    refresh();
    return this;
  }

  @override
  E operator [](int index) {
    return value[index];
  }

  @override
  void add(E item) {
    _value.add(item);
    refresh();
  }

  @override
  void addAll(Iterable<E> item) {
    _value.addAll(item);
    refresh();
  }

  @override
  int get length => value.length;
  @override
  @protected
  List<E> get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }

  @override
  set length(int newLength) {
    _value.length = newLength;
    refresh();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _value.insertAll(index, iterable);
    refresh();
  }

  @override
  Iterable<E> get reversed => value.reversed;
  @override
  Iterable<E> where(bool Function(E) test) {
    return value.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return value.whereType<T>();
  }

  @override
  void sort([int compare(E a, E b)?]) {
    _value.sort(compare);
    refresh();
  }
}

extension ListExtension<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);
  void addNonNull(E item) {
    if (item != null) add(item);
  }

  void addIf(dynamic condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  void addAllIf(dynamic condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
  }

  void assign(E item) {
    clear();
    add(item);
  }

  void assignAll(Iterable<E> items) {
    clear();
    addAll(items);
  }
}

class RxMap<K, V> extends MapMixin<K, V>
    with NotifyManager<Map<K, V>>, RxObjectMixin<Map<K, V>>
    implements RxInterface<Map<K, V>> {
  RxMap([Map<K, V> initial = const {}]) {
    _value = Map.from(initial);
  }
  factory RxMap.from(Map<K, V> other) {
    return RxMap(Map.from(other));
  }
  factory RxMap.of(Map<K, V> other) {
    return RxMap(Map.of(other));
  }
  factory RxMap.unmodifiable(Map<dynamic, dynamic> other) {
    return RxMap(Map.unmodifiable(other));
  }
  factory RxMap.identity() {
    return RxMap(Map.identity());
  }
  @override
  V? operator [](Object? key) {
    return value[key as K];
  }

  @override
  void operator []=(K key, V value) {
    _value[key] = value;
    refresh();
  }

  @override
  void clear() {
    _value.clear();
    refresh();
  }

  @override
  Iterable<K> get keys => value.keys;
  @override
  V? remove(Object? key) {
    final val = _value.remove(key);
    refresh();
    return val;
  }

  @override
  @protected
  Map<K, V> get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }
}

extension MapExtension<K, V> on Map<K, V> {
  RxMap<K, V> get obs {
    return RxMap<K, V>(this);
  }

  void addIf(dynamic condition, K key, V value) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) {
      this[key] = value;
    }
  }

  void addAllIf(dynamic condition, Map<K, V> values) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(values);
  }

  void assign(K key, V val) {
    if (this is RxMap) {
      final map = (this as RxMap);
      map._value.clear();
      this[key] = val;
    } else {
      clear();
      this[key] = val;
    }
  }

  void assignAll(Map<K, V> val) {
    if (val is RxMap && this is RxMap) {
      if ((val as RxMap)._value == (this as RxMap)._value) return;
    }
    if (this is RxMap) {
      final map = (this as RxMap);
      if (map._value == val) return;
      map._value = val;
      map.refresh();
    } else {
      if (this == val) return;
      clear();
      addAll(val);
    }
  }
}

class RxSet<E> extends SetMixin<E>
    with NotifyManager<Set<E>>, RxObjectMixin<Set<E>>
    implements RxInterface<Set<E>> {
  RxSet([Set<E> initial = const {}]) {
    _value = Set.from(initial);
  }
  RxSet<E> operator +(Set<E> val) {
    addAll(val);
    refresh();
    return this;
  }

  void update(void fn(Iterable<E>? value)) {
    fn(value);
    refresh();
  }

  @override
  @protected
  Set<E> get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }

  @override
  @protected
  set value(Set<E> val) {
    if (_value == val) return;
    _value = val;
    refresh();
  }

  @override
  bool add(E value) {
    final val = _value.add(value);
    refresh();
    return val;
  }

  @override
  bool contains(Object? element) {
    return value.contains(element);
  }

  @override
  Iterator<E> get iterator => value.iterator;
  @override
  int get length => value.length;
  @override
  E? lookup(Object? object) {
    return value.lookup(object);
  }

  @override
  bool remove(Object? item) {
    var hasRemoved = _value.remove(item);
    if (hasRemoved) {
      refresh();
    }
    return hasRemoved;
  }

  @override
  Set<E> toSet() {
    return value.toSet();
  }

  @override
  void addAll(Iterable<E> item) {
    _value.addAll(item);
    refresh();
  }

  @override
  void clear() {
    _value.clear();
    refresh();
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    _value.removeAll(elements);
    refresh();
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    _value.retainAll(elements);
    refresh();
  }

  @override
  void retainWhere(bool Function(E) E) {
    _value.retainWhere(E);
    refresh();
  }
}

extension SetExtension<E> on Set<E> {
  RxSet<E> get obs {
    return RxSet<E>(<E>{})..addAll(this);
  }

  void addIf(dynamic condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  void addAllIf(dynamic condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
  }

  void assign(E item) {
    clear();
    add(item);
  }

  void assignAll(Iterable<E> items) {
    clear();
    addAll(items);
  }
}

abstract class RxInterface<T> {
  bool get canUpdate;
  void addListener(GetStream<T> rxGetx);
  void close();
  static RxInterface? proxy;
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError});
  static T notifyChildren<T>(RxNotifier observer, ValueGetter<T> builder) {
    final _observer = RxInterface.proxy;
    RxInterface.proxy = observer;
    final result = builder();
    if (!observer.canUpdate) {
      RxInterface.proxy = _observer;
      throw """   [Get] the improper use of a GetX has been detected.    You should only use GetX or Obx for the specific widget that will be updated.   If you are seeing this error, you probably did not insert any observable variables into GetX/Obx    or insert them outside the scope that GetX considers suitable for an update    (example: GetX => HeavyWidget => variableObservable).   If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.   """;
    }
    RxInterface.proxy = _observer;
    return result;
  }
}

mixin RxObjectMixin<T> on NotifyManager<T> {
  late T _value;
  void refresh() {
    subject.add(value);
  }

  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  bool firstRebuild = true;
  String get string => value.toString();
  @override
  String toString() => value.toString();
  dynamic toJson() => value;
  @override
  bool operator ==(Object o) {
    if (o is T) return value == o;
    if (o is RxObjectMixin<T>) return value == o.value;
    return false;
  }

  @override
  int get hashCode => _value.hashCode;
  set value(T val) {
    if (subject.isClosed) return;
    if (_value == val && !firstRebuild) return;
    firstRebuild = false;
    _value = val;
    subject.add(_value);
  }

  T get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }

  Stream<T> get stream => subject.stream;
  StreamSubscription<T> listenAndPump(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final subscription = listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    subject.add(value);
    return subscription;
  }

  void bindStream(Stream<T> stream) {
    final listSubscriptions =
        _subscriptions[subject] ??= <StreamSubscription>[];
    listSubscriptions.add(stream.listen((va) => value = va));
  }
}
class RxNotifier<T> = RxInterface<T> with NotifyManager<T>;
mixin NotifyManager<T> {
  GetStream<T> subject = GetStream<T>();
  final _subscriptions = <GetStream, List<StreamSubscription>>{};
  bool get canUpdate => _subscriptions.isNotEmpty;
  void addListener(GetStream<T> rxGetx) {
    if (!_subscriptions.containsKey(rxGetx)) {
      final subs = rxGetx.listen((data) {
        if (!subject.isClosed) subject.add(data);
      });
      final listSubscriptions =
          _subscriptions[rxGetx] ??= <StreamSubscription>[];
      listSubscriptions.add(subs);
    }
  }

  StreamSubscription<T> listen(
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      subject.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError ?? false,
      );
  void close() {
    _subscriptions.forEach((getStream, _subscriptions) {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
    });
    _subscriptions.clear();
    subject.close();
  }
}

abstract class _RxImpl<T> extends RxNotifier<T> with RxObjectMixin<T> {
  _RxImpl(T initial) {
    _value = initial;
  }
  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }

  Stream<R> map<R>(R mapper(T? data)) => stream.map(mapper);
  void update(void fn(T? val)) {
    fn(_value);
    subject.add(_value);
  }

  void trigger(T v) {
    var firstRebuild = this.firstRebuild;
    value = v;
    if (!firstRebuild) {
      subject.add(v);
    }
  }
}

class RxBool extends Rx<bool> {
  RxBool(bool initial) : super(initial);
  @override
  String toString() {
    return value ? "true" : "false";
  }
}

class RxnBool extends Rx<bool?> {
  RxnBool([bool? initial]) : super(initial);
  @override
  String toString() {
    return "$value";
  }
}

extension RxBoolExt on Rx<bool> {
  bool get isTrue => value;
  bool get isFalse => !isTrue;
  bool operator &(bool other) => other && value;
  bool operator |(bool other) => other || value;
  bool operator ^(bool other) => !other == value;
  Rx<bool> toggle() {
    subject.add(_value = !_value);
    return this;
  }
}

extension RxnBoolExt on Rx<bool?> {
  bool? get isTrue => value;
  bool? get isFalse {
    if (value != null) return !isTrue!;
  }

  bool? operator &(bool other) {
    if (value != null) {
      return other && value!;
    }
  }

  bool? operator |(bool other) {
    if (value != null) {
      return other || value!;
    }
  }

  bool? operator ^(bool other) => !other == value;
  Rx<bool?>? toggle() {
    if (_value != null) {
      subject.add(_value = !_value!);
      return this;
    }
  }
}

class Rx<T> extends _RxImpl<T> {
  Rx(T initial) : super(initial);
  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }
}

class Rxn<T> extends Rx<T?> {
  Rxn([T? initial]) : super(initial);
  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }
}

extension StringExtension on String {
  RxString get obs => RxString(this);
}

extension IntExtension on int {
  RxInt get obs => RxInt(this);
}

extension DoubleExtension on double {
  RxDouble get obs => RxDouble(this);
}

extension BoolExtension on bool {
  RxBool get obs => RxBool(this);
}

extension RxT<T> on T {
  Rx<T> get obs => Rx<T>(this);
}

extension RxNumExt<T extends num> on Rx<T> {
  num operator *(num other) => value * other;
  num operator %(num other) => value % other;
  double operator /(num other) => value / other;
  int operator ~/(num other) => value ~/ other;
  num operator -() => -value;
  num remainder(num other) => value.remainder(other);
  bool operator <(num other) => value < other;
  bool operator <=(num other) => value <= other;
  bool operator >(num other) => value > other;
  bool operator >=(num other) => value >= other;
  bool get isNaN => value.isNaN;
  bool get isNegative => value.isNegative;
  bool get isInfinite => value.isInfinite;
  bool get isFinite => value.isFinite;
  num abs() => value.abs();
  num get sign => value.sign;
  int round() => value.round();
  int floor() => value.floor();
  int ceil() => value.ceil();
  int truncate() => value.truncate();
  double roundToDouble() => value.roundToDouble();
  double floorToDouble() => value.floorToDouble();
  double ceilToDouble() => value.ceilToDouble();
  double truncateToDouble() => value.truncateToDouble();
  num clamp(num lowerLimit, num upperLimit) =>
      value.clamp(lowerLimit, upperLimit);
  int toInt() => value.toInt();
  double toDouble() => value.toDouble();
  String toStringAsFixed(int fractionDigits) =>
      value.toStringAsFixed(fractionDigits);
  String toStringAsExponential([int? fractionDigits]) =>
      value.toStringAsExponential(fractionDigits);
  String toStringAsPrecision(int precision) =>
      value.toStringAsPrecision(precision);
}

extension RxnNumExt<T extends num> on Rx<T?> {
  num? operator *(num other) {
    if (value != null) {
      return value! * other;
    }
  }

  num? operator %(num other) {
    if (value != null) {
      return value! % other;
    }
  }

  double? operator /(num other) {
    if (value != null) {
      return value! / other;
    }
  }

  int? operator ~/(num other) {
    if (value != null) {
      return value! ~/ other;
    }
  }

  num? operator -() {
    if (value != null) {
      return -value!;
    }
  }

  num? remainder(num other) => value?.remainder(other);
  bool? operator <(num other) {
    if (value != null) {
      return value! < other;
    }
  }

  bool? operator <=(num other) {
    if (value != null) {
      return value! <= other;
    }
  }

  bool? operator >(num other) {
    if (value != null) {
      return value! > other;
    }
  }

  bool? operator >=(num other) {
    if (value != null) {
      return value! >= other;
    }
  }

  bool? get isNaN => value?.isNaN;
  bool? get isNegative => value?.isNegative;
  bool? get isInfinite => value?.isInfinite;
  bool? get isFinite => value?.isFinite;
  num? abs() => value?.abs();
  num? get sign => value?.sign;
  int? round() => value?.round();
  int? floor() => value?.floor();
  int? ceil() => value?.ceil();
  int? truncate() => value?.truncate();
  double? roundToDouble() => value?.roundToDouble();
  double? floorToDouble() => value?.floorToDouble();
  double? ceilToDouble() => value?.ceilToDouble();
  double? truncateToDouble() => value?.truncateToDouble();
  num? clamp(num lowerLimit, num upperLimit) =>
      value?.clamp(lowerLimit, upperLimit);
  int? toInt() => value?.toInt();
  double? toDouble() => value?.toDouble();
  String? toStringAsFixed(int fractionDigits) =>
      value?.toStringAsFixed(fractionDigits);
  String? toStringAsExponential([int? fractionDigits]) =>
      value?.toStringAsExponential(fractionDigits);
  String? toStringAsPrecision(int precision) =>
      value?.toStringAsPrecision(precision);
}

class RxNum extends Rx<num> {
  RxNum(num initial) : super(initial);
  num operator +(num other) {
    value += other;
    return value;
  }

  num operator -(num other) {
    value -= other;
    return value;
  }
}

class RxnNum extends Rx<num?> {
  RxnNum([num? initial]) : super(initial);
  num? operator +(num other) {
    if (value != null) {
      value = value! + other;
      return value;
    }
  }

  num? operator -(num other) {
    if (value != null) {
      value = value! - other;
      return value;
    }
  }
}

extension RxDoubleExt on Rx<double> {
  Rx<double> operator +(num other) {
    value = value + other;
    return this;
  }

  Rx<double> operator -(num other) {
    value = value - other;
    return this;
  }

  double operator *(num other) => value * other;
  double operator %(num other) => value % other;
  double operator /(num other) => value / other;
  int operator ~/(num other) => value ~/ other;
  double operator -() => -value;
  double abs() => value.abs();
  double get sign => value.sign;
  int round() => value.round();
  int floor() => value.floor();
  int ceil() => value.ceil();
  int truncate() => value.truncate();
  double roundToDouble() => value.roundToDouble();
  double floorToDouble() => value.floorToDouble();
  double ceilToDouble() => value.ceilToDouble();
  double truncateToDouble() => value.truncateToDouble();
}

extension RxnDoubleExt on Rx<double?> {
  Rx<double?>? operator +(num other) {
    if (value != null) {
      value = value! + other;
      return this;
    }
  }

  Rx<double?>? operator -(num other) {
    if (value != null) {
      value = value! + other;
      return this;
    }
  }

  double? operator *(num other) {
    if (value != null) {
      return value! * other;
    }
  }

  double? operator %(num other) {
    if (value != null) {
      return value! % other;
    }
  }

  double? operator /(num other) {
    if (value != null) {
      return value! / other;
    }
  }

  int? operator ~/(num other) {
    if (value != null) {
      return value! ~/ other;
    }
  }

  double? operator -() {
    if (value != null) {
      return -value!;
    }
  }

  double? abs() {
    return value?.abs();
  }

  double? get sign => value?.sign;
  int? round() => value?.round();
  int? floor() => value?.floor();
  int? ceil() => value?.ceil();
  int? truncate() => value?.truncate();
  double? roundToDouble() => value?.roundToDouble();
  double? floorToDouble() => value?.floorToDouble();
  double? ceilToDouble() => value?.ceilToDouble();
  double? truncateToDouble() => value?.truncateToDouble();
}

class RxDouble extends Rx<double> {
  RxDouble(double initial) : super(initial);
}

class RxnDouble extends Rx<double?> {
  RxnDouble([double? initial]) : super(initial);
}

class RxInt extends Rx<int> {
  RxInt(int initial) : super(initial);
  RxInt operator +(int other) {
    value = value + other;
    return this;
  }

  RxInt operator -(int other) {
    value = value - other;
    return this;
  }
}

class RxnInt extends Rx<int?> {
  RxnInt([int? initial]) : super(initial);
  RxnInt operator +(int other) {
    if (value != null) {
      value = value! + other;
    }
    return this;
  }

  RxnInt operator -(int other) {
    if (value != null) {
      value = value! - other;
    }
    return this;
  }
}

extension RxIntExt on Rx<int> {
  int operator &(int other) => value & other;
  int operator |(int other) => value | other;
  int operator ^(int other) => value ^ other;
  int operator ~() => ~value;
  int operator <<(int shiftAmount) => value << shiftAmount;
  int operator >>(int shiftAmount) => value >> shiftAmount;
  int modPow(int exponent, int modulus) => value.modPow(exponent, modulus);
  int modInverse(int modulus) => value.modInverse(modulus);
  int gcd(int other) => value.gcd(other);
  bool get isEven => value.isEven;
  bool get isOdd => value.isOdd;
  int get bitLength => value.bitLength;
  int toUnsigned(int width) => value.toUnsigned(width);
  int toSigned(int width) => value.toSigned(width);
  int operator -() => -value;
  int abs() => value.abs();
  int get sign => value.sign;
  int round() => value.round();
  int floor() => value.floor();
  int ceil() => value.ceil();
  int truncate() => value.truncate();
  double roundToDouble() => value.roundToDouble();
  double floorToDouble() => value.floorToDouble();
  double ceilToDouble() => value.ceilToDouble();
  double truncateToDouble() => value.truncateToDouble();
}

extension RxnIntExt on Rx<int?> {
  int? operator &(int other) {
    if (value != null) {
      return value! & other;
    }
  }

  int? operator |(int other) {
    if (value != null) {
      return value! | other;
    }
  }

  int? operator ^(int other) {
    if (value != null) {
      return value! ^ other;
    }
  }

  int? operator ~() {
    if (value != null) {
      return ~value!;
    }
  }

  int? operator <<(int shiftAmount) {
    if (value != null) {
      return value! << shiftAmount;
    }
  }

  int? operator >>(int shiftAmount) {
    if (value != null) {
      return value! >> shiftAmount;
    }
  }

  int? modPow(int exponent, int modulus) => value?.modPow(exponent, modulus);
  int? modInverse(int modulus) => value?.modInverse(modulus);
  int? gcd(int other) => value?.gcd(other);
  bool? get isEven => value?.isEven;
  bool? get isOdd => value?.isOdd;
  int? get bitLength => value?.bitLength;
  int? toUnsigned(int width) => value?.toUnsigned(width);
  int? toSigned(int width) => value?.toSigned(width);
  int? operator -() {
    if (value != null) {
      return -value!;
    }
  }

  int? abs() => value?.abs();
  int? get sign => value?.sign;
  int? round() => value?.round();
  int? floor() => value?.floor();
  int? ceil() => value?.ceil();
  int? truncate() => value?.truncate();
  double? roundToDouble() => value?.roundToDouble();
  double? floorToDouble() => value?.floorToDouble();
  double? ceilToDouble() => value?.ceilToDouble();
  double? truncateToDouble() => value?.truncateToDouble();
}

extension RxStringExt on Rx<String> {
  String operator +(String val) => _value + val;
  int compareTo(String other) {
    return value.compareTo(other);
  }

  bool endsWith(String other) {
    return value.endsWith(other);
  }

  bool startsWith(Pattern pattern, [int index = 0]) {
    return value.startsWith(pattern, index);
  }

  int indexOf(Pattern pattern, [int start = 0]) {
    return value.indexOf(pattern, start);
  }

  int lastIndexOf(Pattern pattern, [int? start]) {
    return value.lastIndexOf(pattern, start);
  }

  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => !isEmpty;
  String substring(int startIndex, [int? endIndex]) {
    return value.substring(startIndex, endIndex);
  }

  String trim() {
    return value.trim();
  }

  String trimLeft() {
    return value.trimLeft();
  }

  String trimRight() {
    return value.trimRight();
  }

  String padLeft(int width, [String padding = ' ']) {
    return value.padLeft(width, padding);
  }

  String padRight(int width, [String padding = ' ']) {
    return value.padRight(width, padding);
  }

  bool contains(Pattern other, [int startIndex = 0]) {
    return value.contains(other, startIndex);
  }

  String replaceAll(Pattern from, String replace) {
    return value.replaceAll(from, replace);
  }

  List<String> split(Pattern pattern) {
    return value.split(pattern);
  }

  List<int> get codeUnits => value.codeUnits;
  Runes get runes => value.runes;
  String toLowerCase() {
    return value.toLowerCase();
  }

  String toUpperCase() {
    return value.toUpperCase();
  }

  Iterable<Match> allMatches(String string, [int start = 0]) {
    return value.allMatches(string, start);
  }

  Match? matchAsPrefix(String string, [int start = 0]) {
    return value.matchAsPrefix(string, start);
  }
}

extension RxnStringExt on Rx<String?> {
  String operator +(String val) => (_value ?? '') + val;
  int? compareTo(String other) {
    return value?.compareTo(other);
  }

  bool? endsWith(String other) {
    return value?.endsWith(other);
  }

  bool? startsWith(Pattern pattern, [int index = 0]) {
    return value?.startsWith(pattern, index);
  }

  int? indexOf(Pattern pattern, [int start = 0]) {
    return value?.indexOf(pattern, start);
  }

  int? lastIndexOf(Pattern pattern, [int? start]) {
    return value?.lastIndexOf(pattern, start);
  }

  bool? get isEmpty => value?.isEmpty;
  bool? get isNotEmpty => value?.isNotEmpty;
  String? substring(int startIndex, [int? endIndex]) {
    return value?.substring(startIndex, endIndex);
  }

  String? trim() {
    return value?.trim();
  }

  String? trimLeft() {
    return value?.trimLeft();
  }

  String? trimRight() {
    return value?.trimRight();
  }

  String? padLeft(int width, [String padding = ' ']) {
    return value?.padLeft(width, padding);
  }

  String? padRight(int width, [String padding = ' ']) {
    return value?.padRight(width, padding);
  }

  bool? contains(Pattern other, [int startIndex = 0]) {
    return value?.contains(other, startIndex);
  }

  String? replaceAll(Pattern from, String replace) {
    return value?.replaceAll(from, replace);
  }

  List<String>? split(Pattern pattern) {
    return value?.split(pattern);
  }

  List<int>? get codeUnits => value?.codeUnits;
  Runes? get runes => value?.runes;
  String? toLowerCase() {
    return value?.toLowerCase();
  }

  String? toUpperCase() {
    return value?.toUpperCase();
  }

  Iterable<Match>? allMatches(String string, [int start = 0]) {
    return value?.allMatches(string, start);
  }

  Match? matchAsPrefix(String string, [int start = 0]) {
    return value?.matchAsPrefix(string, start);
  }
}

class RxString extends Rx<String> implements Comparable<String>, Pattern {
  RxString(String initial) : super(initial);
  @override
  Iterable<Match> allMatches(String string, [int start = 0]) {
    return value.allMatches(string, start);
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    return value.matchAsPrefix(string, start);
  }

  @override
  int compareTo(String other) {
    return value.compareTo(other);
  }
}

class RxnString extends Rx<String?> implements Comparable<String>, Pattern {
  RxnString([String? initial]) : super(initial);
  @override
  Iterable<Match> allMatches(String string, [int start = 0]) {
    return value!.allMatches(string, start);
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    return value!.matchAsPrefix(string, start);
  }

  @override
  int compareTo(String other) {
    return value!.compareTo(other);
  }
}

typedef OnData<T> = void Function(T data);
typedef Callback = void Function();
html.Navigator _navigator = html.window.navigator;

class GeneralPlatform {
  static bool get isWeb => true;
  static bool get isMacOS =>
      _navigator.appVersion.contains('Mac OS') && !GeneralPlatform.isIOS;
  static bool get isWindows => _navigator.appVersion.contains('Win');
  static bool get isLinux =>
      (_navigator.appVersion.contains('Linux') ||
          _navigator.appVersion.contains('x11')) &&
      !isAndroid;
  static bool get isAndroid => _navigator.appVersion.contains('Android ');
  static bool get isIOS {
    return GetUtils.hasMatch(_navigator.platform, r'/iPad|iPhone|iPod/') ||
        (_navigator.platform == 'MacIntel' && _navigator.maxTouchPoints! > 1);
  }

  static bool get isFuchsia => false;
  static bool get isDesktop => isMacOS || isWindows || isLinux;
}

class GetPlatform {
  static bool get isWeb => GeneralPlatform.isWeb;
  static bool get isMacOS => GeneralPlatform.isMacOS;
  static bool get isWindows => GeneralPlatform.isWindows;
  static bool get isLinux => GeneralPlatform.isLinux;
  static bool get isAndroid => GeneralPlatform.isAndroid;
  static bool get isIOS => GeneralPlatform.isIOS;
  static bool get isFuchsia => GeneralPlatform.isFuchsia;
  static bool get isMobile => GetPlatform.isIOS || GetPlatform.isAndroid;
  static bool get isDesktop =>
      GetPlatform.isMacOS || GetPlatform.isWindows || GetPlatform.isLinux;
}

extension LoopEventsExt on GetInterface {
  Future<T> toEnd<T>(FutureOr<T> computation()) async {
    await Future.delayed(Duration.zero);
    final val = computation();
    return val;
  }

  FutureOr<T> asap<T>(T computation(), {bool Function()? condition}) async {
    T val;
    if (condition == null || !condition()) {
      await Future.delayed(Duration.zero);
      val = computation();
    } else {
      val = computation();
    }
    return val;
  }
}

extension Precision on double {
  double toPrecision(int fractionDigits) {
    var mod = pow(10, fractionDigits.toDouble()).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<TRes> mapMany<TRes>(
      Iterable<TRes>? Function(T item) selector) sync* {
    for (var item in this) {
      final res = selector(item);
      if (res != null) yield* res;
    }
  }
}

extension GetDurationUtils on Duration {
  Future delay([FutureOr callback()?]) async => Future.delayed(this, callback);
}

extension GetDynamicUtils on dynamic {
  @Deprecated('isNull is deprecated and cannot be used, use "==" operator')
  bool get isNull => GetUtils.isNull(this);
  bool? get isBlank => GetUtils.isBlank(this);
  @Deprecated(
      'isNullOrBlank is deprecated and cannot be used, use "isBlank" instead')
  bool? get isNullOrBlank => GetUtils.isNullOrBlank(this);
  void printError(
          {String info = '', Function logFunction = GetUtils.printFunction}) =>
      logFunction('Error: ${this.runtimeType}', this, info, isError: true);
  void printInfo(
          {String info = '',
          Function printFunction = GetUtils.printFunction}) =>
      printFunction('Info: ${this.runtimeType}', this, info);
}

extension Trans on String {
  String get tr {
    if (Get.locale?.languageCode == null) return this;
    if (Get.translations.containsKey(
            "${Get.locale!.languageCode}_${Get.locale!.countryCode}") &&
        Get.translations[
                "${Get.locale!.languageCode}_${Get.locale!.countryCode}"]!
            .containsKey(this)) {
      return Get.translations[
          "${Get.locale!.languageCode}_${Get.locale!.countryCode}"]![this]!;
    } else if (Get.translations.containsKey(Get.locale!.languageCode) &&
        Get.translations[Get.locale!.languageCode]!.containsKey(this)) {
      return Get.translations[Get.locale!.languageCode]![this]!;
    } else if (Get.fallbackLocale != null) {
      final fallback = Get.fallbackLocale!;
      final key = "${fallback.languageCode}_${fallback.countryCode}";
      if (Get.translations.containsKey(key) &&
          Get.translations[key]!.containsKey(this)) {
        return Get.translations[key]![this]!;
      }
      if (Get.translations.containsKey(fallback.languageCode) &&
          Get.translations[fallback.languageCode]!.containsKey(this)) {
        return Get.translations[fallback.languageCode]![this]!;
      }
      return this;
    } else {
      return this;
    }
  }

  String trArgs([List<String> args = const []]) {
    var key = tr;
    if (args.isNotEmpty) {
      for (final arg in args) {
        key = key.replaceFirst(RegExp(r'%s'), arg.toString());
      }
    }
    return key;
  }

  String trPlural([String? pluralKey, int? i, List<String> args = const []]) {
    return i == 1 ? trArgs(args) : pluralKey!.trArgs(args);
  }

  String trParams([Map<String, String> params = const {}]) {
    var trans = tr;
    if (params.isNotEmpty) {
      params.forEach((key, value) {
        trans = trans.replaceAll('@$key', value);
      });
    }
    return trans;
  }

  String trPluralParams(
      [String? pluralKey, int? i, Map<String, String> params = const {}]) {
    return i == 1 ? trParams(params) : pluralKey!.trParams(params);
  }
}

class _IntlHost {
  Locale? locale;
  Locale? fallbackLocale;
  Map<String, Map<String, String>> translations = {};
}

extension LocalesIntl on GetInterface {
  static final _intlHost = _IntlHost();
  Locale? get locale => _intlHost.locale;
  Locale? get fallbackLocale => _intlHost.fallbackLocale;
  set locale(Locale? newLocale) => _intlHost.locale = newLocale;
  set fallbackLocale(Locale? newLocale) => _intlHost.fallbackLocale = newLocale;
  Map<String, Map<String, String>> get translations => _intlHost.translations;
  void addTranslations(Map<String, Map<String, String>> tr) {
    translations.addAll(tr);
  }

  void clearTranslations() {
    translations.clear();
  }

  void appendTranslations(Map<String, Map<String, String>> tr) {
    tr.forEach((key, map) {
      if (translations.containsKey(key)) {
        translations[key]!.addAll(map);
      } else {
        translations[key] = map;
      }
    });
  }
}

extension ContextExtensionss on BuildContext {
  Size get mediaQuerySize => MediaQuery.of(this).size;
  double get height => mediaQuerySize.height;
  double get width => mediaQuerySize.width;
  double heightTransformer({double dividedBy = 1, double reducedBy = 0.0}) {
    return (mediaQuerySize.height -
            ((mediaQuerySize.height / 100) * reducedBy)) /
        dividedBy;
  }

  double widthTransformer({double dividedBy = 1, double reducedBy = 0.0}) {
    return (mediaQuerySize.width - ((mediaQuerySize.width / 100) * reducedBy)) /
        dividedBy;
  }

  double ratio({
    double dividedBy = 1,
    double reducedByW = 0.0,
    double reducedByH = 0.0,
  }) {
    return heightTransformer(dividedBy: dividedBy, reducedBy: reducedByH) /
        widthTransformer(dividedBy: dividedBy, reducedBy: reducedByW);
  }

  ThemeData get theme => Theme.of(this);
  bool get isDarkMode => (theme.brightness == Brightness.dark);
  Color? get iconColor => theme.iconTheme.color;
  TextTheme get textTheme => Theme.of(this).textTheme;
  EdgeInsets get mediaQueryPadding => MediaQuery.of(this).padding;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  EdgeInsets get mediaQueryViewPadding => MediaQuery.of(this).viewPadding;
  EdgeInsets get mediaQueryViewInsets => MediaQuery.of(this).viewInsets;
  Orientation get orientation => MediaQuery.of(this).orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;
  double get textScaleFactor => MediaQuery.of(this).textScaleFactor;
  double get mediaQueryShortestSide => mediaQuerySize.shortestSide;
  bool get showNavbar => (width > 800);
  bool get isPhone => (mediaQueryShortestSide < 600);
  bool get isSmallTablet => (mediaQueryShortestSide >= 600);
  bool get isLargeTablet => (mediaQueryShortestSide >= 720);
  bool get isTablet => isSmallTablet || isLargeTablet;
  T responsiveValue<T>({
    T? mobile,
    T? tablet,
    T? desktop,
    T? watch,
  }) {
    var deviceWidth = mediaQuerySize.shortestSide;
    if (GetPlatform.isDesktop) {
      deviceWidth = mediaQuerySize.width;
    }
    if (deviceWidth >= 1200 && desktop != null) {
      return desktop;
    } else if (deviceWidth >= 600 && tablet != null) {
      return tablet;
    } else if (deviceWidth < 300 && watch != null) {
      return watch;
    } else {
      return mobile!;
    }
  }
}

extension GetNumUtils on num {
  bool isLowerThan(num b) => GetUtils.isLowerThan(this, b);
  bool isGreaterThan(num b) => GetUtils.isGreaterThan(this, b);
  bool isEqual(num b) => GetUtils.isEqual(this, b);
  Future delay([FutureOr callback()?]) async => Future.delayed(
        Duration(milliseconds: (this * 1000).round()),
        callback,
      );
  Duration get milliseconds => Duration(microseconds: (this * 1000).round());
  Duration get seconds => Duration(milliseconds: (this * 1000).round());
  Duration get minutes =>
      Duration(seconds: (this * Duration.secondsPerMinute).round());
  Duration get hours =>
      Duration(minutes: (this * Duration.minutesPerHour).round());
  Duration get days => Duration(hours: (this * Duration.hoursPerDay).round());
}

extension WidgetPaddingX on Widget {
  Widget paddingAll(double padding) =>
      Padding(padding: EdgeInsets.all(padding), child: this);
  Widget paddingSymmetric({double horizontal = 0.0, double vertical = 0.0}) =>
      Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          child: this);
  Widget paddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) =>
      Padding(
          padding: EdgeInsets.only(
              top: top, left: left, right: right, bottom: bottom),
          child: this);
  Widget get paddingZero => Padding(padding: EdgeInsets.zero, child: this);
}

extension WidgetMarginX on Widget {
  Widget marginAll(double margin) =>
      Container(margin: EdgeInsets.all(margin), child: this);
  Widget marginSymmetric({double horizontal = 0.0, double vertical = 0.0}) =>
      Container(
          margin:
              EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          child: this);
  Widget marginOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) =>
      Container(
          margin: EdgeInsets.only(
              top: top, left: left, right: right, bottom: bottom),
          child: this);
  Widget get marginZero => Container(margin: EdgeInsets.zero, child: this);
}

extension WidgetSliverBoxX on Widget {
  Widget get sliverBox => SliverToBoxAdapter(child: this);
}

extension GetStringUtils on String {
  bool get isNum => GetUtils.isNum(this);
  bool get isNumericOnly => GetUtils.isNumericOnly(this);
  bool get isAlphabetOnly => GetUtils.isAlphabetOnly(this);
  bool get isBool => GetUtils.isBool(this);
  bool get isVectorFileName => GetUtils.isVector(this);
  bool get isImageFileName => GetUtils.isImage(this);
  bool get isAudioFileName => GetUtils.isAudio(this);
  bool get isVideoFileName => GetUtils.isVideo(this);
  bool get isTxtFileName => GetUtils.isTxt(this);
  bool get isDocumentFileName => GetUtils.isWord(this);
  bool get isExcelFileName => GetUtils.isExcel(this);
  bool get isPPTFileName => GetUtils.isPPT(this);
  bool get isAPKFileName => GetUtils.isAPK(this);
  bool get isPDFFileName => GetUtils.isPDF(this);
  bool get isHTMLFileName => GetUtils.isHTML(this);
  bool get isURL => GetUtils.isURL(this);
  bool get isEmail => GetUtils.isEmail(this);
  bool get isPhoneNumber => GetUtils.isPhoneNumber(this);
  bool get isDateTime => GetUtils.isDateTime(this);
  bool get isMD5 => GetUtils.isMD5(this);
  bool get isSHA1 => GetUtils.isSHA1(this);
  bool get isSHA256 => GetUtils.isSHA256(this);
  bool get isBinary => GetUtils.isBinary(this);
  bool get isIPv4 => GetUtils.isIPv4(this);
  bool get isIPv6 => GetUtils.isIPv6(this);
  bool get isHexadecimal => GetUtils.isHexadecimal(this);
  bool get isPalindrom => GetUtils.isPalindrom(this);
  bool get isPassport => GetUtils.isPassport(this);
  bool get isCurrency => GetUtils.isCurrency(this);
  bool get isCpf => GetUtils.isCpf(this);
  bool get isCnpj => GetUtils.isCnpj(this);
  bool isCaseInsensitiveContains(String b) =>
      GetUtils.isCaseInsensitiveContains(this, b);
  bool isCaseInsensitiveContainsAny(String b) =>
      GetUtils.isCaseInsensitiveContainsAny(this, b);
  String? get capitalize => GetUtils.capitalize(this);
  String? get capitalizeFirst => GetUtils.capitalizeFirst(this);
  String get removeAllWhitespace => GetUtils.removeAllWhitespace(this);
  String? get camelCase => GetUtils.camelCase(this);
  String? get paramCase => GetUtils.paramCase(this);
  String numericOnly({bool firstWordOnly = false}) =>
      GetUtils.numericOnly(this, firstWordOnly: firstWordOnly);
  String createPath([Iterable? segments]) {
    final path = startsWith('/') ? this : '/$this';
    return GetUtils.createPath(path, segments);
  }
}

class GetMicrotask {
  int _version = 0;
  int _microtask = 0;
  int get version => _version;
  int get microtask => _microtask;
  void exec(Function callback) {
    if (_microtask == _version) {
      _microtask++;
      scheduleMicrotask(() {
        _version++;
        _microtask = _version;
        callback();
      });
    }
  }
}

class GetQueue {
  final List<_Item> _queue = [];
  bool _active = false;
  void _check() async {
    if (!_active && _queue.isNotEmpty) {
      _active = true;
      var item = _queue.removeAt(0);
      try {
        item.completer.complete(await item.job());
      } on Exception catch (e) {
        item.completer.completeError(e);
      }
      _active = false;
      _check();
    }
  }

  Future<T> add<T>(Function job) {
    var completer = Completer<T>();
    _queue.add(_Item(completer, job));
    _check();
    return completer.future;
  }
}

class _Item {
  final dynamic completer;
  final dynamic job;
  _Item(this.completer, this.job);
}

bool? _isEmpty(dynamic value) {
  if (value is String) {
    return value.toString().trim().isEmpty;
  }
  if (value is Iterable || value is Map) {
    return value.isEmpty as bool?;
  }
  return false;
}

bool _hasLength(dynamic value) {
  return value is Iterable || value is String || value is Map;
}

int? _obtainDynamicLength(dynamic value) {
  if (value == null) {
    return null;
  }
  if (_hasLength(value)) {
    return value.length as int?;
  }
  if (value is int) {
    return value.toString().length;
  }
  if (value is double) {
    return value.toString().replaceAll('.', '').length;
  }
  return null;
}

class GetUtils {
  GetUtils._();
  static bool isNull(dynamic value) => value == null;
  static dynamic nil(dynamic s) => s == null ? null : s;
  static bool? isNullOrBlank(dynamic value) {
    if (isNull(value)) {
      return true;
    }
    return _isEmpty(value);
  }

  static bool? isBlank(dynamic value) {
    return _isEmpty(value);
  }

  static bool isNum(String value) {
    if (isNull(value)) {
      return false;
    }
    return num.tryParse(value) is num;
  }

  static bool isNumericOnly(String s) => hasMatch(s, r'^\d+$');
  static bool isAlphabetOnly(String s) => hasMatch(s, r'^[a-zA-Z]+$');
  static bool hasCapitalletter(String s) => hasMatch(s, r'[A-Z]');
  static bool isBool(String value) {
    if (isNull(value)) {
      return false;
    }
    return (value == 'true' || value == 'false');
  }

  static bool isVideo(String filePath) {
    var ext = filePath.toLowerCase();
    return ext.endsWith(".mp4") ||
        ext.endsWith(".avi") ||
        ext.endsWith(".wmv") ||
        ext.endsWith(".rmvb") ||
        ext.endsWith(".mpg") ||
        ext.endsWith(".mpeg") ||
        ext.endsWith(".3gp");
  }

  static bool isImage(String filePath) {
    final ext = filePath.toLowerCase();
    return ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".png") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".bmp");
  }

  static bool isAudio(String filePath) {
    final ext = filePath.toLowerCase();
    return ext.endsWith(".mp3") ||
        ext.endsWith(".wav") ||
        ext.endsWith(".wma") ||
        ext.endsWith(".amr") ||
        ext.endsWith(".ogg");
  }

  static bool isPPT(String filePath) {
    final ext = filePath.toLowerCase();
    return ext.endsWith(".ppt") || ext.endsWith(".pptx");
  }

  static bool isWord(String filePath) {
    final ext = filePath.toLowerCase();
    return ext.endsWith(".doc") || ext.endsWith(".docx");
  }

  static bool isExcel(String filePath) {
    final ext = filePath.toLowerCase();
    return ext.endsWith(".xls") || ext.endsWith(".xlsx");
  }

  static bool isAPK(String filePath) {
    return filePath.toLowerCase().endsWith(".apk");
  }

  static bool isPDF(String filePath) {
    return filePath.toLowerCase().endsWith(".pdf");
  }

  static bool isTxt(String filePath) {
    return filePath.toLowerCase().endsWith(".txt");
  }

  static bool isChm(String filePath) {
    return filePath.toLowerCase().endsWith(".chm");
  }

  static bool isVector(String filePath) {
    return filePath.toLowerCase().endsWith(".svg");
  }

  static bool isHTML(String filePath) {
    return filePath.toLowerCase().endsWith(".html");
  }

  static bool isUsername(String s) =>
      hasMatch(s, r'^[a-zA-Z0-9][a-zA-Z0-9_.]+[a-zA-Z0-9]$');
  static bool isURL(String s) => hasMatch(s,
      r"^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,6}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-]+))*$");
  static bool isEmail(String s) => hasMatch(s,
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  static bool isPhoneNumber(String s) {
    if (s.length > 16 || s.length < 9) return false;
    return hasMatch(s, r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
  }

  static bool isDateTime(String s) =>
      hasMatch(s, r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}.\d{3}Z?$');
  static bool isMD5(String s) => hasMatch(s, r'^[a-f0-9]{32}$');
  static bool isSHA1(String s) =>
      hasMatch(s, r'(([A-Fa-f0-9]{2}\:){19}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{40})');
  static bool isSHA256(String s) =>
      hasMatch(s, r'([A-Fa-f0-9]{2}\:){31}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{64}');
  static bool isSSN(String s) => hasMatch(s,
      r'^(?!0{3}|6{3}|9[0-9]{2})[0-9]{3}-?(?!0{2})[0-9]{2}-?(?!0{4})[0-9]{4}$');
  static bool isBinary(String s) => hasMatch(s, r'^[0-1]+$');
  static bool isIPv4(String s) =>
      hasMatch(s, r'^(?:(?:^|\.)(?:2(?:5[0-5]|[0-4]\d)|1?\d?\d)){4}$');
  static bool isIPv6(String s) => hasMatch(s,
      r'^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))$');
  static bool isHexadecimal(String s) =>
      hasMatch(s, r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');
  static bool isPalindrom(String string) {
    final cleanString = string
        .toLowerCase()
        .replaceAll(RegExp(r"\s+"), '')
        .replaceAll(RegExp(r"[^0-9a-zA-Z]+"), "");
    for (var i = 0; i < cleanString.length; i++) {
      if (cleanString[i] != cleanString[cleanString.length - i - 1]) {
        return false;
      }
    }
    return true;
  }

  static bool isOneAKind(dynamic value) {
    if ((value is String || value is List) && !isNullOrBlank(value)!) {
      final first = value[0];
      final len = value.length as num;
      for (var i = 0; i < len; i++) {
        if (value[i] != first) {
          return false;
        }
      }
      return true;
    }
    if (value is int) {
      final stringValue = value.toString();
      final first = stringValue[0];
      for (var i = 0; i < stringValue.length; i++) {
        if (stringValue[i] != first) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  static bool isPassport(String s) =>
      hasMatch(s, r'^(?!^0+$)[a-zA-Z0-9]{6,9}$');
  static bool isCurrency(String s) => hasMatch(s,
      r'^(S?\$|\₩|Rp|\¥|\€|\₹|\₽|fr|R\$|R)?[ ]?[-]?([0-9]{1,3}[,.]([0-9]{3}[,.])*[0-9]{3}|[0-9]+)([,.][0-9]{1,2})?( ?(USD?|AUD|NZD|CAD|CHF|GBP|CNY|EUR|JPY|IDR|MXN|NOK|KRW|TRY|INR|RUB|BRL|ZAR|SGD|MYR))?$');
  static bool isLengthGreaterThan(dynamic value, int maxLength) {
    final length = _obtainDynamicLength(value);
    if (length == null) {
      return false;
    }
    return length > maxLength;
  }

  static bool isLengthGreaterOrEqual(dynamic value, int maxLength) {
    final length = _obtainDynamicLength(value);
    if (length == null) {
      return false;
    }
    return length >= maxLength;
  }

  @deprecated
  static bool isLengthLowerThan(dynamic value, int maxLength) =>
      isLengthLessThan(value, maxLength);
  static bool isLengthLessThan(dynamic value, int maxLength) {
    final length = _obtainDynamicLength(value);
    if (length == null) {
      return false;
    }
    return length < maxLength;
  }

  @deprecated
  static bool isLengthLowerOrEqual(dynamic value, int maxLength) =>
      isLengthLessOrEqual(value, maxLength);
  static bool isLengthLessOrEqual(dynamic value, int maxLength) {
    final length = _obtainDynamicLength(value);
    if (length == null) {
      return false;
    }
    return length <= maxLength;
  }

  static bool isLengthEqualTo(dynamic value, int otherLength) {
    final length = _obtainDynamicLength(value);
    if (length == null) {
      return false;
    }
    return length == otherLength;
  }

  static bool isLengthBetween(dynamic value, int minLength, int maxLength) {
    if (isNull(value)) {
      return false;
    }
    return isLengthGreaterOrEqual(value, minLength) &&
        isLengthLessOrEqual(value, maxLength);
  }

  static bool isCaseInsensitiveContains(String a, String b) {
    return a.toLowerCase().contains(b.toLowerCase());
  }

  static bool isCaseInsensitiveContainsAny(String a, String b) {
    final lowA = a.toLowerCase();
    final lowB = b.toLowerCase();
    return lowA.contains(lowB) || lowB.contains(lowA);
  }

  static bool isLowerThan(num a, num b) => a < b;
  static bool isGreaterThan(num a, num b) => a > b;
  static bool isEqual(num a, num b) => a == b;
  static bool isCnpj(String cnpj) {
    final numbers = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 14) {
      return false;
    }
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }
    final digits = numbers.split('').map(int.parse).toList();
    var calcDv1 = 0;
    var j = 0;
    for (var i in Iterable<int>.generate(12, (i) => i < 4 ? 5 - i : 13 - i)) {
      calcDv1 += digits[j++] * i;
    }
    calcDv1 %= 11;
    final dv1 = calcDv1 < 2 ? 0 : 11 - calcDv1;
    if (digits[12] != dv1) {
      return false;
    }
    var calcDv2 = 0;
    j = 0;
    for (var i in Iterable<int>.generate(13, (i) => i < 5 ? 6 - i : 14 - i)) {
      calcDv2 += digits[j++] * i;
    }
    calcDv2 %= 11;
    final dv2 = calcDv2 < 2 ? 0 : 11 - calcDv2;
    if (digits[13] != dv2) {
      return false;
    }
    return true;
  }

  static bool isCpf(String cpf) {
    final numbers = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 11) {
      return false;
    }
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }
    final digits = numbers.split('').map(int.parse).toList();
    var calcDv1 = 0;
    for (var i in Iterable<int>.generate(9, (i) => 10 - i)) {
      calcDv1 += digits[10 - i] * i;
    }
    calcDv1 %= 11;
    final dv1 = calcDv1 < 2 ? 0 : 11 - calcDv1;
    if (digits[9] != dv1) {
      return false;
    }
    var calcDv2 = 0;
    for (var i in Iterable<int>.generate(10, (i) => 11 - i)) {
      calcDv2 += digits[11 - i] * i;
    }
    calcDv2 %= 11;
    final dv2 = calcDv2 < 2 ? 0 : 11 - calcDv2;
    if (digits[10] != dv2) {
      return false;
    }
    return true;
  }

  static String? capitalize(String value) {
    if (isNull(value)) return null;
    if (isBlank(value)!) return value;
    return value.split(' ').map(capitalizeFirst).join(' ');
  }

  static String? capitalizeFirst(String s) {
    if (isNull(s)) return null;
    if (isBlank(s)!) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String removeAllWhitespace(String value) {
    return value.replaceAll(' ', '');
  }

  static String? camelCase(String value) {
    if (isNullOrBlank(value)!) {
      return null;
    }
    final separatedWords =
        value.split(RegExp(r'[!@#<>?":`~;[\]\\|=+)(*&^%-\s_]+'));
    var newString = '';
    for (final word in separatedWords) {
      newString += word[0].toUpperCase() + word.substring(1).toLowerCase();
    }
    return newString[0].toLowerCase() + newString.substring(1);
  }

  static final RegExp _upperAlphaRegex = RegExp(r'[A-Z]');
  static final _symbolSet = {' ', '.', '/', '_', '\\', '-'};
  static List<String> _groupIntoWords(String text) {
    var sb = StringBuffer();
    var words = <String>[];
    var isAllCaps = text.toUpperCase() == text;
    for (var i = 0; i < text.length; i++) {
      var char = text[i];
      var nextChar = i + 1 == text.length ? null : text[i + 1];
      if (_symbolSet.contains(char)) {
        continue;
      }
      sb.write(char);
      var isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          _symbolSet.contains(nextChar);
      if (isEndOfWord) {
        words.add('$sb');
        sb.clear();
      }
    }
    return words;
  }

  static String? snakeCase(String? text, {String separator = '_'}) {
    if (isNullOrBlank(text)!) {
      return null;
    }
    return _groupIntoWords(text!)
        .map((word) => word.toLowerCase())
        .join(separator);
  }

  static String? paramCase(String? text) => snakeCase(text, separator: '-');
  static String numericOnly(String s, {bool firstWordOnly = false}) {
    var numericOnlyStr = '';
    for (var i = 0; i < s.length; i++) {
      if (isNumericOnly(s[i])) {
        numericOnlyStr += s[i];
      }
      if (firstWordOnly && numericOnlyStr.isNotEmpty && s[i] == " ") {
        break;
      }
    }
    return numericOnlyStr;
  }

  static bool hasMatch(String? value, String pattern) {
    return (value == null) ? false : RegExp(pattern).hasMatch(value);
  }

  static String createPath(String path, [Iterable? segments]) {
    if (segments == null || segments.isEmpty) {
      return path;
    }
    final list = segments.map((e) => '/$e');
    return path + list.join();
  }

  static void printFunction(
    String prefix,
    dynamic value,
    String info, {
    bool isError = false,
  }) {
    Get.log('$prefix $value $info'.trim(), isError: isError);
  }
}

typedef PrintFunctionCallback = void Function(
  String prefix,
  dynamic value,
  String info, {
  bool? isError,
});

class RouterReportManager<T> {
  static final Map<Route?, List<String>> _routesKey = {};
  static final Map<Route?, HashSet<Function>> _routesByCreate = {};
  void printInstanceStack() {
    Get.log(_routesKey.toString());
  }

  static Route? _current;
  static void reportCurrentRoute(Route newRoute) {
    _current = newRoute;
  }

  static void reportDependencyLinkedToRoute(String depedencyKey) {
    if (_current == null) return;
    if (_routesKey.containsKey(_current)) {
      _routesKey[_current!]!.add(depedencyKey);
    } else {
      _routesKey[_current] = <String>[depedencyKey];
    }
  }

  static void clearRouteKeys() {
    _routesKey.clear();
    _routesByCreate.clear();
  }

  static void appendRouteByCreate(GetLifeCycleBase i) {
    _routesByCreate[_current] ??= HashSet<Function>();
    _routesByCreate[_current]!.add(i.onDelete);
  }

  static void reportRouteDispose(Route disposed) {
    if (Get.smartManagement != SmartManagement.onlyBuilder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _removeDependencyByRoute(disposed);
      });
    }
  }

  static void reportRouteWillDispose(Route disposed) {
    final keysToRemove = <String>[];
    _routesKey[disposed]?.forEach(keysToRemove.add);
    if (_routesByCreate.containsKey(disposed)) {
      for (final onClose in _routesByCreate[disposed]!) {
        onClose();
      }
      _routesByCreate[disposed]!.clear();
      _routesByCreate.remove(disposed);
    }
    for (final element in keysToRemove) {
      GetInstance().markAsDirty(key: element);
    }
    keysToRemove.clear();
  }

  static void _removeDependencyByRoute(Route routeName) {
    final keysToRemove = <String>[];
    _routesKey[routeName]?.forEach(keysToRemove.add);
    if (_routesByCreate.containsKey(routeName)) {
      for (final onClose in _routesByCreate[routeName]!) {
        onClose();
      }
      _routesByCreate[routeName]!.clear();
      _routesByCreate.remove(routeName);
    }
    for (final element in keysToRemove) {
      final value = GetInstance().delete(key: element);
      if (value) {
        _routesKey[routeName]?.remove(element);
      }
    }
    keysToRemove.clear();
  }
}

class SnackRoute<T> extends OverlayRoute<T> {
  late Animation<double> _filterBlurAnimation;
  late Animation<Color?> _filterColorAnimation;
  SnackRoute({
    required this.snack,
    RouteSettings? settings,
  }) : super(settings: settings) {
    _builder = Builder(builder: (_) {
      return GestureDetector(
        child: snack,
        onTap: snack.onTap != null ? () => snack.onTap!(snack) : null,
      );
    });
    _configureAlignment(snack.snackPosition);
    _snackbarStatus = snack.snackbarStatus;
  }
  _configureAlignment(SnackPosition snackPosition) {
    switch (snack.snackPosition) {
      case SnackPosition.TOP:
        {
          _initialAlignment = Alignment(-1.0, -2.0);
          _endAlignment = Alignment(-1.0, -1.0);
          break;
        }
      case SnackPosition.BOTTOM:
        {
          _initialAlignment = Alignment(-1.0, 2.0);
          _endAlignment = Alignment(-1.0, 1.0);
          break;
        }
    }
  }

  GetBar snack;
  Builder? _builder;
  final Completer<T> _transitionCompleter = Completer<T>();
  late SnackbarStatusCallback _snackbarStatus;
  Alignment? _initialAlignment;
  Alignment? _endAlignment;
  bool _wasDismissedBySwipe = false;
  bool _onTappedDismiss = false;
  Timer? _timer;
  bool get opaque => false;
  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      if (snack.overlayBlur > 0.0) ...[
        OverlayEntry(
          builder: (context) {
            return GestureDetector(
              onTap: () {
                if (snack.isDismissible && !_onTappedDismiss) {
                  _onTappedDismiss = true;
                  Get.back();
                }
              },
              child: AnimatedBuilder(
                animation: _filterBlurAnimation,
                builder: (context, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: _filterBlurAnimation.value,
                        sigmaY: _filterBlurAnimation.value),
                    child: Container(
                      constraints: BoxConstraints.expand(),
                      color: _filterColorAnimation.value,
                    ),
                  );
                },
              ),
            );
          },
          maintainState: false,
          opaque: opaque,
        ),
      ],
      OverlayEntry(
        builder: (context) {
          final Widget annotatedChild = Semantics(
            child: AlignTransition(
              alignment: _animation!,
              child: snack.isDismissible
                  ? _getDismissibleSnack(_builder)
                  : _getSnack(),
            ),
            focused: false,
            container: true,
            explicitChildNodes: true,
          );
          return annotatedChild;
        },
        maintainState: false,
        opaque: opaque,
      ),
    ];
  }

  String dismissibleKeyGen = "";
  Widget _getDismissibleSnack(Widget? child) {
    return Dismissible(
      direction: _getDismissDirection(),
      resizeDuration: null,
      confirmDismiss: (_) {
        if (currentStatus == SnackbarStatus.OPENING ||
            currentStatus == SnackbarStatus.CLOSING) {
          return Future.value(false);
        }
        return Future.value(true);
      },
      key: Key(dismissibleKeyGen),
      onDismissed: (_) {
        dismissibleKeyGen += "1";
        _cancelTimer();
        _wasDismissedBySwipe = true;
        if (isCurrent) {
          navigator!.pop();
        } else {
          navigator!.removeRoute(this);
        }
      },
      child: _getSnack(),
    );
  }

  Widget _getSnack() {
    return Container(
      margin: snack.margin,
      child: _builder,
    );
  }

  DismissDirection _getDismissDirection() {
    if (snack.dismissDirection == SnackDismissDirection.HORIZONTAL) {
      return DismissDirection.horizontal;
    } else {
      if (snack.snackPosition == SnackPosition.TOP) {
        return DismissDirection.up;
      }
      return DismissDirection.down;
    }
  }

  @override
  bool get finishedWhenPopped =>
      _controller!.status == AnimationStatus.dismissed;
  Animation<Alignment>? _animation;
  AnimationController? _controller;
  AnimationController createAnimationController() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(snack.animationDuration >= Duration.zero);
    return AnimationController(
      duration: snack.animationDuration,
      debugLabel: debugLabel,
      vsync: navigator!,
    );
  }

  Animation<Alignment> createAnimation() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(_controller != null);
    return AlignmentTween(begin: _initialAlignment, end: _endAlignment).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: snack.forwardAnimationCurve,
        reverseCurve: snack.reverseAnimationCurve,
      ),
    );
  }

  Animation<double> createBlurFilterAnimation() {
    return Tween(begin: 0.0, end: snack.overlayBlur).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  Animation<Color?> createColorFilterAnimation() {
    return ColorTween(begin: Color(0x00000000), end: snack.overlayColor)
        .animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  T? _result;
  SnackbarStatus? currentStatus;
  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        currentStatus = SnackbarStatus.OPEN;
        _snackbarStatus(currentStatus);
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = opaque;
        break;
      case AnimationStatus.forward:
        currentStatus = SnackbarStatus.OPENING;
        _snackbarStatus(currentStatus);
        break;
      case AnimationStatus.reverse:
        currentStatus = SnackbarStatus.CLOSING;
        _snackbarStatus(currentStatus);
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.dismissed:
        assert(!overlayEntries.first.opaque);
        currentStatus = SnackbarStatus.CLOSED;
        _snackbarStatus(currentStatus);
        if (!isCurrent) {
          navigator!.finalizeRoute(this);
        }
        break;
    }
    changedInternalState();
  }

  @override
  void install() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot install a $runtimeType after disposing it.');
    _controller = createAnimationController();
    assert(_controller != null,
        '$runtimeType.createAnimationController() returned null.');
    _filterBlurAnimation = createBlurFilterAnimation();
    _filterColorAnimation = createColorFilterAnimation();
    _animation = createAnimation();
    assert(_animation != null, '$runtimeType.createAnimation() returned null.');
    super.install();
  }

  @override
  TickerFuture didPush() {
    super.didPush();
    assert(
      _controller != null,
      '$runtimeType.didPush called before calling install() or after calling dispose().',
    );
    assert(
      !_transitionCompleter.isCompleted,
      'Cannot reuse a $runtimeType after disposing it.',
    );
    _animation!.addStatusListener(_handleStatusChanged);
    _configureTimer();
    return _controller!.forward();
  }

  @override
  void didReplace(Route<dynamic>? oldRoute) {
    assert(
      _controller != null,
      '$runtimeType.didReplace called before calling install() or after calling dispose().',
    );
    assert(
      !_transitionCompleter.isCompleted,
      'Cannot reuse a $runtimeType after disposing it.',
    );
    if (oldRoute is SnackRoute) {
      _controller!.value = oldRoute._controller!.value;
    }
    _animation!.addStatusListener(_handleStatusChanged);
    super.didReplace(oldRoute);
  }

  @override
  bool didPop(T? result) {
    assert(
      _controller != null,
      '$runtimeType.didPop called before calling install() or after calling dispose().',
    );
    assert(
      !_transitionCompleter.isCompleted,
      'Cannot reuse a $runtimeType after disposing it.',
    );
    _result = result;
    _cancelTimer();
    if (_wasDismissedBySwipe) {
      Timer(Duration(milliseconds: 200), () {
        _controller!.reset();
      });
      _wasDismissedBySwipe = false;
    } else {
      _controller!.reverse();
    }
    return super.didPop(result);
  }

  void _configureTimer() {
    if (snack.duration != null) {
      if (_timer != null && _timer!.isActive) {
        _timer!.cancel();
      }
      _timer = Timer(snack.duration!, () {
        if (isCurrent) {
          navigator!.pop();
        } else if (isActive) {
          navigator!.removeRoute(this);
        }
      });
    } else {
      if (_timer != null) {
        _timer!.cancel();
      }
    }
  }

  void _cancelTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  bool canTransitionTo(SnackRoute<dynamic> nextRoute) => true;
  bool canTransitionFrom(SnackRoute<dynamic> previousRoute) => true;
  @override
  void dispose() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot dispose a $runtimeType twice.');
    _controller?.dispose();
    _transitionCompleter.complete(_result);
    super.dispose();
  }

  String get debugLabel => '$runtimeType';
}

typedef SnackbarStatusCallback = void Function(SnackbarStatus? status);
typedef OnTap = void Function(GetBar snack);

class GetBar<T extends Object> extends StatefulWidget {
  GetBar({
    Key? key,
    this.title,
    this.message,
    this.titleText,
    this.messageText,
    this.icon,
    this.shouldIconPulse = true,
    this.maxWidth,
    this.margin = const EdgeInsets.all(0.0),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 0.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor = const Color(0xFF303030),
    this.leftBarIndicatorColor,
    this.boxShadows,
    this.backgroundGradient,
    this.mainButton,
    this.onTap,
    this.duration,
    this.isDismissible = true,
    this.dismissDirection = SnackDismissDirection.VERTICAL,
    this.showProgressIndicator = false,
    this.progressIndicatorController,
    this.progressIndicatorBackgroundColor,
    this.progressIndicatorValueColor,
    this.snackPosition = SnackPosition.BOTTOM,
    this.snackStyle = SnackStyle.FLOATING,
    this.forwardAnimationCurve = Curves.easeOutCirc,
    this.reverseAnimationCurve = Curves.easeOutCirc,
    this.animationDuration = const Duration(seconds: 1),
    this.barBlur = 0.0,
    this.overlayBlur = 0.0,
    this.overlayColor = Colors.transparent,
    this.userInputForm,
    SnackbarStatusCallback? snackbarStatus,
  })  : snackbarStatus = (snackbarStatus ?? (status) {}),
        super(key: key);
  final SnackbarStatusCallback snackbarStatus;
  final String? title;
  final String? message;
  final Widget? titleText;
  final Widget? messageText;
  final Color backgroundColor;
  final Color? leftBarIndicatorColor;
  final List<BoxShadow>? boxShadows;
  final Gradient? backgroundGradient;
  final Widget? icon;
  final bool shouldIconPulse;
  final Widget? mainButton;
  final OnTap? onTap;
  final Duration? duration;
  final bool showProgressIndicator;
  final AnimationController? progressIndicatorController;
  final Color? progressIndicatorBackgroundColor;
  final Animation<Color>? progressIndicatorValueColor;
  final bool isDismissible;
  final double? maxWidth;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final SnackPosition snackPosition;
  final SnackDismissDirection dismissDirection;
  final SnackStyle snackStyle;
  final Curve forwardAnimationCurve;
  final Curve reverseAnimationCurve;
  final Duration animationDuration;
  final double? barBlur;
  final double overlayBlur;
  final Color? overlayColor;
  final Form? userInputForm;
  Future<T?>? show<T>() async {
    return Get.showSnackbar(this);
  }

  @override
  State createState() {
    return _GetBarState<T>();
  }
}

class _GetBarState<K extends Object> extends State<GetBar>
    with TickerProviderStateMixin {
  SnackbarStatus? currentStatus;
  AnimationController? _fadeController;
  late Animation<double> _fadeAnimation;
  final Widget _emptyWidget = SizedBox(width: 0.0, height: 0.0);
  final double _initialOpacity = 1.0;
  final double _finalOpacity = 0.4;
  final Duration _pulseAnimationDuration = Duration(seconds: 1);
  late bool _isTitlePresent;
  late double _messageTopMargin;
  FocusScopeNode? _focusNode;
  late FocusAttachment _focusAttachment;
  @override
  void initState() {
    super.initState();
    assert(
        widget.userInputForm != null ||
            ((widget.message != null && widget.message!.isNotEmpty) ||
                widget.messageText != null),
        """ A message is mandatory if you are not using userInputForm.  Set either a message or messageText""");
    _isTitlePresent = (widget.title != null || widget.titleText != null);
    _messageTopMargin = _isTitlePresent ? 6.0 : widget.padding.top;
    _configureLeftBarFuture();
    _configureProgressIndicatorAnimation();
    if (widget.icon != null && widget.shouldIconPulse) {
      _configurePulseAnimation();
      _fadeController?.forward();
    }
    _focusNode = FocusScopeNode();
    _focusAttachment = _focusNode!.attach(context);
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    widget.progressIndicatorController?.removeListener(_progressListener);
    widget.progressIndicatorController?.dispose();
    _focusAttachment.detach();
    _focusNode!.dispose();
    super.dispose();
  }

  final Completer<Size> _boxHeightCompleter = Completer<Size>();
  void _configureLeftBarFuture() {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        final keyContext = backgroundBoxKey.currentContext;
        if (keyContext != null) {
          final box = keyContext.findRenderObject() as RenderBox;
          _boxHeightCompleter.complete(box.size);
        }
      },
    );
  }

  void _configurePulseAnimation() {
    _fadeController =
        AnimationController(vsync: this, duration: _pulseAnimationDuration);
    _fadeAnimation = Tween(begin: _initialOpacity, end: _finalOpacity).animate(
      CurvedAnimation(
        parent: _fadeController!,
        curve: Curves.linear,
      ),
    );
    _fadeController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fadeController!.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        _fadeController!.forward();
      }
    });
    _fadeController!.forward();
  }

  late VoidCallback _progressListener;
  void _configureProgressIndicatorAnimation() {
    if (widget.showProgressIndicator &&
        widget.progressIndicatorController != null) {
      _progressListener = () {
        setState(() {});
      };
      widget.progressIndicatorController!.addListener(_progressListener);
      _progressAnimation = CurvedAnimation(
          curve: Curves.linear, parent: widget.progressIndicatorController!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      heightFactor: 1.0,
      child: Material(
        color: widget.snackStyle == SnackStyle.FLOATING
            ? Colors.transparent
            : widget.backgroundColor,
        child: SafeArea(
          minimum: widget.snackPosition == SnackPosition.BOTTOM
              ? EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom)
              : EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          bottom: widget.snackPosition == SnackPosition.BOTTOM,
          top: widget.snackPosition == SnackPosition.TOP,
          left: false,
          right: false,
          child: _getSnack(),
        ),
      ),
    );
  }

  Widget _getSnack() {
    Widget snack;
    if (widget.userInputForm != null) {
      snack = _generateInputSnack();
    } else {
      snack = _generateSnack();
    }
    return Stack(
      children: [
        FutureBuilder<Size>(
          future: _boxHeightCompleter.future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (widget.barBlur == 0) {
                return _emptyWidget;
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: widget.barBlur!, sigmaY: widget.barBlur!),
                  child: Container(
                    height: snapshot.data!.height,
                    width: snapshot.data!.width,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                ),
              );
            } else {
              return _emptyWidget;
            }
          },
        ),
        snack,
      ],
    );
  }

  Widget _generateInputSnack() {
    return Container(
      key: backgroundBoxKey,
      constraints: widget.maxWidth != null
          ? BoxConstraints(maxWidth: widget.maxWidth!)
          : null,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        gradient: widget.backgroundGradient,
        boxShadow: widget.boxShadows,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth!)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
            left: 8.0, right: 8.0, bottom: 8.0, top: 16.0),
        child: FocusScope(
          child: widget.userInputForm!,
          node: _focusNode,
          autofocus: true,
        ),
      ),
    );
  }

  late CurvedAnimation _progressAnimation;
  GlobalKey backgroundBoxKey = GlobalKey();
  Widget _generateSnack() {
    return Container(
      key: backgroundBoxKey,
      constraints: widget.maxWidth != null
          ? BoxConstraints(maxWidth: widget.maxWidth!)
          : null,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        gradient: widget.backgroundGradient,
        boxShadow: widget.boxShadows,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth!)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.showProgressIndicator
              ? LinearProgressIndicator(
                  value: widget.progressIndicatorController != null
                      ? _progressAnimation.value
                      : null,
                  backgroundColor: widget.progressIndicatorBackgroundColor,
                  valueColor: widget.progressIndicatorValueColor,
                )
              : _emptyWidget,
          Row(
            mainAxisSize: MainAxisSize.max,
            children: _getAppropriateRowLayout(),
          ),
        ],
      ),
    );
  }

  List<Widget> _getAppropriateRowLayout() {
    double buttonRightPadding;
    var iconPadding = 0.0;
    if (widget.padding.right - 12 < 0) {
      buttonRightPadding = 4;
    } else {
      buttonRightPadding = widget.padding.right - 12;
    }
    if (widget.padding.left > 16.0) {
      iconPadding = widget.padding.left;
    }
    if (widget.icon == null && widget.mainButton == null) {
      return [
        _buildLeftBarIndicator(),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: widget.padding.left,
                        right: widget.padding.right,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: widget.padding.left,
                  right: widget.padding.right,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
      ];
    } else if (widget.icon != null && widget.mainButton == null) {
      return <Widget>[
        _buildLeftBarIndicator(),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: 42.0 + iconPadding),
          child: _getIcon(),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: 4.0,
                        right: widget.padding.left,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: 4.0,
                  right: widget.padding.right,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
      ];
    } else if (widget.icon == null && widget.mainButton != null) {
      return <Widget>[
        _buildLeftBarIndicator(),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: widget.padding.left,
                        right: widget.padding.right,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: widget.padding.left,
                  right: 8.0,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: buttonRightPadding),
          child: _getMainActionButton(),
        ),
      ];
    } else {
      return <Widget>[
        _buildLeftBarIndicator(),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: 42.0 + iconPadding),
          child: _getIcon(),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: 4.0,
                        right: 8.0,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: 4.0,
                  right: 8.0,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: buttonRightPadding),
          child: _getMainActionButton(),
        ),
      ];
    }
  }

  Widget _buildLeftBarIndicator() {
    if (widget.leftBarIndicatorColor != null) {
      return FutureBuilder<Size>(
        future: _boxHeightCompleter.future,
        builder: (buildContext, snapshot) {
          if (snapshot.hasData) {
            return Container(
              color: widget.leftBarIndicatorColor,
              width: 5.0,
              height: snapshot.data!.height,
            );
          } else {
            return _emptyWidget;
          }
        },
      );
    } else {
      return _emptyWidget;
    }
  }

  Widget? _getIcon() {
    if (widget.icon != null && widget.icon is Icon && widget.shouldIconPulse) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: widget.icon,
      );
    } else if (widget.icon != null) {
      return widget.icon;
    } else {
      return _emptyWidget;
    }
  }

  Widget _getTitleText() {
    return widget.titleText ??
        Text(
          widget.title ?? "",
          style: TextStyle(
              fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.bold),
        );
  }

  Text _getDefaultNotificationText() {
    return Text(
      widget.message ?? "",
      style: TextStyle(fontSize: 14.0, color: Colors.white),
    );
  }

  Widget? _getMainActionButton() {
    return widget.mainButton;
  }
}

enum SnackPosition { TOP, BOTTOM }

enum SnackStyle { FLOATING, GROUNDED }

enum SnackDismissDirection { HORIZONTAL, VERTICAL }

enum SnackbarStatus { OPEN, CLOSED, OPENING, CLOSING }

class GetDialogRoute<T> extends PopupRoute<T> {
  GetDialogRoute({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? settings,
  })  : widget = pageBuilder,
        _barrierDismissible = barrierDismissible,
        _barrierLabel = barrierLabel,
        _barrierColor = barrierColor,
        _transitionDuration = transitionDuration,
        _transitionBuilder = transitionBuilder,
        super(settings: settings) {
    RouterReportManager.reportCurrentRoute(this);
  }
  final RoutePageBuilder widget;
  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;
  @override
  void dispose() {
    RouterReportManager.reportRouteDispose(this);
    super.dispose();
  }

  @override
  String? get barrierLabel => _barrierLabel;
  final String? _barrierLabel;
  @override
  Color get barrierColor => _barrierColor;
  final Color _barrierColor;
  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;
  final RouteTransitionsBuilder? _transitionBuilder;
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      child: widget(context, animation, secondaryAnimation),
      scopesRoute: true,
      explicitChildNodes: true,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (_transitionBuilder == null) {
      return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.linear,
          ),
          child: child);
    }
    return _transitionBuilder!(context, animation, secondaryAnimation, child);
  }
}

class GetModalBottomSheetRoute<T> extends PopupRoute<T> {
  GetModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    this.backgroundColor,
    this.isPersistent,
    this.elevation,
    this.shape,
    this.removeTop = true,
    this.clipBehavior,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    required this.isScrollControlled,
    RouteSettings? settings,
    this.enterBottomSheetDuration = const Duration(milliseconds: 250),
    this.exitBottomSheetDuration = const Duration(milliseconds: 200),
  }) : super(settings: settings) {
    RouterReportManager.reportCurrentRoute(this);
  }
  final bool? isPersistent;
  final WidgetBuilder? builder;
  final ThemeData? theme;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final Duration enterBottomSheetDuration;
  final Duration exitBottomSheetDuration;
  final bool removeTop;
  @override
  Duration get transitionDuration => Duration(milliseconds: 700);
  @override
  bool get barrierDismissible => isDismissible;
  @override
  final String? barrierLabel;
  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black54;
  AnimationController? _animationController;
  @override
  void dispose() {
    RouterReportManager.reportRouteDispose(this);
    super.dispose();
  }

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController =
        BottomSheet.createAnimationController(navigator!.overlay!);
    _animationController!.duration = enterBottomSheetDuration;
    _animationController!.reverseDuration = exitBottomSheetDuration;
    return _animationController!;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final sheetTheme =
        theme?.bottomSheetTheme ?? Theme.of(context).bottomSheetTheme;
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: removeTop,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _GetModalBottomSheet<T>(
          route: this,
          backgroundColor: backgroundColor ??
              sheetTheme.modalBackgroundColor ??
              sheetTheme.backgroundColor,
          elevation:
              elevation ?? sheetTheme.modalElevation ?? sheetTheme.elevation,
          shape: shape,
          clipBehavior: clipBehavior,
          isScrollControlled: isScrollControlled,
          enableDrag: enableDrag,
        ),
      ),
    );
    if (theme != null) bottomSheet = Theme(data: theme!, child: bottomSheet);
    return bottomSheet;
  }
}

class _GetModalBottomSheet<T> extends StatefulWidget {
  const _GetModalBottomSheet({
    Key? key,
    this.route,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.isScrollControlled = false,
    this.enableDrag = true,
    this.isPersistent = false,
  }) : super(key: key);
  final bool isPersistent;
  final GetModalBottomSheetRoute<T>? route;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final bool enableDrag;
  @override
  _GetModalBottomSheetState<T> createState() => _GetModalBottomSheetState<T>();
}

class _GetModalBottomSheetState<T> extends State<_GetModalBottomSheet<T>> {
  String _getRouteLabel(MaterialLocalizations localizations) {
    if ((Theme.of(context).platform == TargetPlatform.android) ||
        (Theme.of(context).platform == TargetPlatform.fuchsia)) {
      return localizations.dialogLabel;
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final mediaQuery = MediaQuery.of(context);
    final localizations = MaterialLocalizations.of(context);
    final routeLabel = _getRouteLabel(localizations);
    return AnimatedBuilder(
      animation: widget.route!.animation!,
      builder: (context, child) {
        final animationValue = mediaQuery.accessibleNavigation
            ? 1.0
            : widget.route!.animation!.value;
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: CustomSingleChildLayout(
                delegate: _GetModalBottomSheetLayout(
                    animationValue, widget.isScrollControlled),
                child: widget.isPersistent == false
                    ? BottomSheet(
                        animationController: widget.route!._animationController,
                        onClosing: () {
                          if (widget.route!.isCurrent) {
                            Navigator.pop(context);
                          }
                        },
                        builder: widget.route!.builder!,
                        backgroundColor: widget.backgroundColor,
                        elevation: widget.elevation,
                        shape: widget.shape,
                        clipBehavior: widget.clipBehavior,
                        enableDrag: widget.enableDrag,
                      )
                    : Scaffold(
                        bottomSheet: BottomSheet(
                          animationController:
                              widget.route!._animationController,
                          onClosing: () {},
                          builder: widget.route!.builder!,
                          backgroundColor: widget.backgroundColor,
                          elevation: widget.elevation,
                          shape: widget.shape,
                          clipBehavior: widget.clipBehavior,
                          enableDrag: widget.enableDrag,
                        ),
                      )),
          ),
        );
      },
    );
  }
}

class _GetPerModalBottomSheet<T> extends StatefulWidget {
  const _GetPerModalBottomSheet({
    Key? key,
    this.route,
    this.isPersistent,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.isScrollControlled = false,
    this.enableDrag = true,
  }) : super(key: key);
  final bool? isPersistent;
  final GetModalBottomSheetRoute<T>? route;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final bool enableDrag;
  @override
  _GetPerModalBottomSheetState<T> createState() =>
      _GetPerModalBottomSheetState<T>();
}

class _GetPerModalBottomSheetState<T>
    extends State<_GetPerModalBottomSheet<T>> {
  String _getRouteLabel(MaterialLocalizations localizations) {
    if ((Theme.of(context).platform == TargetPlatform.android) ||
        (Theme.of(context).platform == TargetPlatform.fuchsia)) {
      return localizations.dialogLabel;
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final mediaQuery = MediaQuery.of(context);
    final localizations = MaterialLocalizations.of(context);
    final routeLabel = _getRouteLabel(localizations);
    return AnimatedBuilder(
      animation: widget.route!.animation!,
      builder: (context, child) {
        final animationValue = mediaQuery.accessibleNavigation
            ? 1.0
            : widget.route!.animation!.value;
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: CustomSingleChildLayout(
                delegate: _GetModalBottomSheetLayout(
                    animationValue, widget.isScrollControlled),
                child: widget.isPersistent == false
                    ? BottomSheet(
                        animationController: widget.route!._animationController,
                        onClosing: () {
                          if (widget.route!.isCurrent) {
                            Navigator.pop(context);
                          }
                        },
                        builder: widget.route!.builder!,
                        backgroundColor: widget.backgroundColor,
                        elevation: widget.elevation,
                        shape: widget.shape,
                        clipBehavior: widget.clipBehavior,
                        enableDrag: widget.enableDrag,
                      )
                    : Scaffold(
                        bottomSheet: BottomSheet(
                          animationController:
                              widget.route!._animationController,
                          onClosing: () {},
                          builder: widget.route!.builder!,
                          backgroundColor: widget.backgroundColor,
                          elevation: widget.elevation,
                          shape: widget.shape,
                          clipBehavior: widget.clipBehavior,
                          enableDrag: widget.enableDrag,
                        ),
                      )),
          ),
        );
      },
    );
  }
}

class _GetModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _GetModalBottomSheetLayout(this.progress, this.isScrollControlled);
  final double progress;
  final bool isScrollControlled;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: isScrollControlled
          ? constraints.maxHeight
          : constraints.maxHeight * 9.0 / 16.0,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_GetModalBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class GetCupertinoApp extends StatelessWidget {
  const GetCupertinoApp({
    Key? key,
    this.theme,
    this.navigatorKey,
    this.home,
    Map<String, Widget Function(BuildContext)> this.routes =
        const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    List<NavigatorObserver> this.navigatorObservers =
        const <NavigatorObserver>[],
    this.builder,
    this.translationsKeys,
    this.translations,
    this.textDirection,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.customTransition,
    this.onInit,
    this.onDispose,
    this.locale,
    this.fallbackLocale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.smartManagement = SmartManagement.full,
    this.initialBinding,
    this.unknownRoute,
    this.routingCallback,
    this.defaultTransition,
    this.onReady,
    this.getPages,
    this.opaqueRoute,
    this.enableLog,
    this.logWriterCallback,
    this.popGesture,
    this.transitionDuration,
    this.defaultGlobalState,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.actions,
  })  : routeInformationProvider = null,
        routeInformationParser = null,
        routerDelegate = null,
        backButtonDispatcher = null,
        super(key: key);
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? home;
  final Map<String, WidgetBuilder>? routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver>? navigatorObservers;
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final CustomTransition? customTransition;
  final Color? color;
  final Map<String, Map<String, String>>? translationsKeys;
  final Translations? translations;
  final TextDirection? textDirection;
  final Locale? locale;
  final Locale? fallbackLocale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<LogicalKeySet, Intent>? shortcuts;
  final ThemeData? highContrastTheme;
  final ThemeData? highContrastDarkTheme;
  final Map<Type, Action<Intent>>? actions;
  final Function(Routing?)? routingCallback;
  final Transition? defaultTransition;
  final bool? opaqueRoute;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;
  final bool? popGesture;
  final SmartManagement smartManagement;
  final Bindings? initialBinding;
  final Duration? transitionDuration;
  final bool? defaultGlobalState;
  final List<GetPage>? getPages;
  final GetPage? unknownRoute;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;
  final CupertinoThemeData? theme;
  GetCupertinoApp.router({
    Key? key,
    this.theme,
    this.routeInformationProvider,
    RouteInformationParser<Object>? routeInformationParser,
    RouterDelegate<Object>? routerDelegate,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.customTransition,
    this.translationsKeys,
    this.translations,
    this.textDirection,
    this.fallbackLocale,
    this.routingCallback,
    this.defaultTransition,
    this.opaqueRoute,
    this.onInit,
    this.onReady,
    this.onDispose,
    this.enableLog,
    this.logWriterCallback,
    this.popGesture,
    this.smartManagement = SmartManagement.full,
    this.initialBinding,
    this.transitionDuration,
    this.defaultGlobalState,
    this.getPages,
    this.unknownRoute,
  })  : routerDelegate = routerDelegate ??= Get.createDelegate(
          notFoundRoute: unknownRoute,
        ),
        routeInformationParser =
            routeInformationParser ??= Get.createInformationParser(
          initialRoute: getPages?.first.name ?? '/',
        ),
        navigatorObservers = null,
        navigatorKey = null,
        onGenerateRoute = null,
        home = null,
        onGenerateInitialRoutes = null,
        onUnknownRoute = null,
        routes = null,
        initialRoute = null,
        super(key: key) {
    Get.routerDelegate = routerDelegate;
    Get.routeInformationParser = routeInformationParser;
  }
  Route<dynamic> generator(RouteSettings settings) {
    return PageRedirect(settings: settings, unknownRoute: unknownRoute).page();
  }

  List<Route<dynamic>> initialRoutesGenerate(String name) {
    return [
      PageRedirect(
        settings: RouteSettings(name: name),
        unknownRoute: unknownRoute,
      ).page()
    ];
  }

  Widget defaultBuilder(BuildContext context, Widget? child) {
    return Directionality(
      textDirection: textDirection ??
          (rtlLanguages.contains(Get.locale?.languageCode)
              ? TextDirection.rtl
              : TextDirection.ltr),
      child: builder == null
          ? (child ?? Material())
          : builder!(context, child ?? Material()),
    );
  }

  @override
  Widget build(BuildContext context) => GetBuilder<GetMaterialController>(
        init: Get.rootController,
        dispose: (d) {
          onDispose?.call();
        },
        initState: (i) {
          Get.engine!.addPostFrameCallback((timeStamp) {
            onReady?.call();
          });
          if (locale != null) Get.locale = locale;
          if (fallbackLocale != null) Get.fallbackLocale = fallbackLocale;
          if (translations != null) {
            Get.addTranslations(translations!.keys);
          } else if (translationsKeys != null) {
            Get.addTranslations(translationsKeys!);
          }
          Get.customTransition = customTransition;
          initialBinding?.dependencies();
          if (getPages != null) {
            Get.addPages(getPages!);
          }
          Get.smartManagement = smartManagement;
          onInit?.call();
          Get.config(
            enableLog: enableLog ?? Get.isLogEnable,
            logWriterCallback: logWriterCallback,
            defaultTransition: defaultTransition ?? Get.defaultTransition,
            defaultOpaqueRoute: opaqueRoute ?? Get.isOpaqueRouteDefault,
            defaultPopGesture: popGesture ?? Get.isPopGestureEnable,
            defaultDurationTransition:
                transitionDuration ?? Get.defaultTransitionDuration,
          );
        },
        builder: (_) => routerDelegate != null
            ? CupertinoApp.router(
                routerDelegate: routerDelegate!,
                routeInformationParser: routeInformationParser!,
                backButtonDispatcher: backButtonDispatcher,
                routeInformationProvider: routeInformationProvider,
                key: _.unikey,
                theme: theme,
                builder: defaultBuilder,
                title: title,
                onGenerateTitle: onGenerateTitle,
                color: color,
                locale: Get.locale ?? locale,
                localizationsDelegates: localizationsDelegates,
                localeListResolutionCallback: localeListResolutionCallback,
                localeResolutionCallback: localeResolutionCallback,
                supportedLocales: supportedLocales,
                showPerformanceOverlay: showPerformanceOverlay,
                checkerboardRasterCacheImages: checkerboardRasterCacheImages,
                checkerboardOffscreenLayers: checkerboardOffscreenLayers,
                showSemanticsDebugger: showSemanticsDebugger,
                debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                shortcuts: shortcuts,
              )
            : CupertinoApp(
                key: _.unikey,
                theme: theme,
                navigatorKey: (navigatorKey == null
                    ? Get.key
                    : Get.addKey(navigatorKey!)),
                home: home,
                routes: routes ?? const <String, WidgetBuilder>{},
                initialRoute: initialRoute,
                onGenerateRoute:
                    (getPages != null ? generator : onGenerateRoute),
                onGenerateInitialRoutes: (getPages == null || home != null)
                    ? onGenerateInitialRoutes
                    : initialRoutesGenerate,
                onUnknownRoute: onUnknownRoute,
                navigatorObservers: (navigatorObservers == null
                    ? <NavigatorObserver>[
                        GetObserver(routingCallback, Get.routing)
                      ]
                    : <NavigatorObserver>[
                        GetObserver(routingCallback, Get.routing)
                      ]
                  ..addAll(navigatorObservers!)),
                builder: defaultBuilder,
                title: title,
                onGenerateTitle: onGenerateTitle,
                color: color,
                locale: Get.locale ?? locale,
                localizationsDelegates: localizationsDelegates,
                localeListResolutionCallback: localeListResolutionCallback,
                localeResolutionCallback: localeResolutionCallback,
                supportedLocales: supportedLocales,
                showPerformanceOverlay: showPerformanceOverlay,
                checkerboardRasterCacheImages: checkerboardRasterCacheImages,
                checkerboardOffscreenLayers: checkerboardOffscreenLayers,
                showSemanticsDebugger: showSemanticsDebugger,
                debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                shortcuts: shortcuts,
              ),
      );
}

class GetMaterialController extends GetxController {
  bool testMode = false;
  Key? unikey;
  ThemeData? theme;
  ThemeData? darkTheme;
  ThemeMode? themeMode;
  bool defaultPopGesture = GetPlatform.isIOS;
  bool defaultOpaqueRoute = true;
  Transition? defaultTransition;
  Duration defaultTransitionDuration = Duration(milliseconds: 300);
  Curve defaultTransitionCurve = Curves.easeOutQuad;
  Curve defaultDialogTransitionCurve = Curves.easeOutQuad;
  Duration defaultDialogTransitionDuration = Duration(milliseconds: 300);
  final routing = Routing();
  Map<String, String?> parameters = {};
  CustomTransition? customTransition;
  var _key = GlobalKey<NavigatorState>(debugLabel: 'Key Created by default');
  GlobalKey<NavigatorState> get key => _key;
  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    _key = newKey;
    return key;
  }

  Map<dynamic, GlobalKey<NavigatorState>> keys = {};
  void setTheme(ThemeData value) {
    if (darkTheme == null) {
      theme = value;
    } else {
      if (value.brightness == Brightness.light) {
        theme = value;
      } else {
        darkTheme = value;
      }
    }
    update();
  }

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    update();
  }

  void restartApp() {
    unikey = UniqueKey();
    update();
  }
}

class GetMaterialApp extends StatelessWidget {
  const GetMaterialApp({
    Key? key,
    this.navigatorKey,
    this.scaffoldMessengerKey,
    this.home,
    Map<String, Widget Function(BuildContext)> this.routes =
        const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    List<NavigatorObserver> this.navigatorObservers =
        const <NavigatorObserver>[],
    this.builder,
    this.textDirection,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.locale,
    this.fallbackLocale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.scrollBehavior,
    this.customTransition,
    this.translationsKeys,
    this.translations,
    this.onInit,
    this.onReady,
    this.onDispose,
    this.routingCallback,
    this.defaultTransition,
    this.getPages,
    this.opaqueRoute,
    this.enableLog,
    this.logWriterCallback,
    this.popGesture,
    this.transitionDuration,
    this.defaultGlobalState,
    this.smartManagement = SmartManagement.full,
    this.initialBinding,
    this.unknownRoute,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.actions,
  })  : routeInformationProvider = null,
        routeInformationParser = null,
        routerDelegate = null,
        backButtonDispatcher = null,
        super(key: key);
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final Widget? home;
  final Map<String, WidgetBuilder>? routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver>? navigatorObservers;
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;
  final CustomTransition? customTransition;
  final Color? color;
  final Map<String, Map<String, String>>? translationsKeys;
  final Translations? translations;
  final TextDirection? textDirection;
  final Locale? locale;
  final Locale? fallbackLocale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<LogicalKeySet, Intent>? shortcuts;
  final ScrollBehavior? scrollBehavior;
  final ThemeData? highContrastTheme;
  final ThemeData? highContrastDarkTheme;
  final Map<Type, Action<Intent>>? actions;
  final bool debugShowMaterialGrid;
  final ValueChanged<Routing?>? routingCallback;
  final Transition? defaultTransition;
  final bool? opaqueRoute;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;
  final bool? popGesture;
  final SmartManagement smartManagement;
  final Bindings? initialBinding;
  final Duration? transitionDuration;
  final bool? defaultGlobalState;
  final List<GetPage>? getPages;
  final GetPage? unknownRoute;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;
  GetMaterialApp.router({
    Key? key,
    this.routeInformationProvider,
    this.scaffoldMessengerKey,
    RouteInformationParser<Object>? routeInformationParser,
    RouterDelegate<Object>? routerDelegate,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.theme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode = ThemeMode.system,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.scrollBehavior,
    this.actions,
    this.customTransition,
    this.translationsKeys,
    this.translations,
    this.textDirection,
    this.fallbackLocale,
    this.routingCallback,
    this.defaultTransition,
    this.opaqueRoute,
    this.onInit,
    this.onReady,
    this.onDispose,
    this.enableLog,
    this.logWriterCallback,
    this.popGesture,
    this.smartManagement = SmartManagement.full,
    this.initialBinding,
    this.transitionDuration,
    this.defaultGlobalState,
    this.getPages,
    this.navigatorObservers,
    this.unknownRoute,
  })  : routerDelegate = routerDelegate ??= Get.createDelegate(
          notFoundRoute: unknownRoute,
        ),
        routeInformationParser =
            routeInformationParser ??= Get.createInformationParser(
          initialRoute: getPages?.first.name ?? '/',
        ),
        navigatorKey = null,
        onGenerateRoute = null,
        home = null,
        onGenerateInitialRoutes = null,
        onUnknownRoute = null,
        routes = null,
        initialRoute = null,
        super(key: key) {
    Get.routerDelegate = routerDelegate;
    Get.routeInformationParser = routeInformationParser;
  }
  Route<dynamic> generator(RouteSettings settings) {
    return PageRedirect(settings: settings, unknownRoute: unknownRoute).page();
  }

  List<Route<dynamic>> initialRoutesGenerate(String name) {
    return [
      PageRedirect(
        settings: RouteSettings(name: name),
        unknownRoute: unknownRoute,
      ).page()
    ];
  }

  Widget defaultBuilder(BuildContext context, Widget? child) {
    return Directionality(
      textDirection: textDirection ??
          (rtlLanguages.contains(Get.locale?.languageCode)
              ? TextDirection.rtl
              : TextDirection.ltr),
      child: builder == null
          ? (child ?? Material())
          : builder!(context, child ?? Material()),
    );
  }

  @override
  Widget build(BuildContext context) => GetBuilder<GetMaterialController>(
      init: Get.rootController,
      dispose: (d) {
        onDispose?.call();
      },
      initState: (i) {
        Get.engine!.addPostFrameCallback((timeStamp) {
          onReady?.call();
        });
        if (locale != null) Get.locale = locale;
        if (fallbackLocale != null) Get.fallbackLocale = fallbackLocale;
        if (translations != null) {
          Get.addTranslations(translations!.keys);
        } else if (translationsKeys != null) {
          Get.addTranslations(translationsKeys!);
        }
        Get.customTransition = customTransition;
        initialBinding?.dependencies();
        if (getPages != null) {
          Get.addPages(getPages!);
        }
        Get.smartManagement = smartManagement;
        onInit?.call();
        Get.config(
          enableLog: enableLog ?? Get.isLogEnable,
          logWriterCallback: logWriterCallback,
          defaultTransition: defaultTransition ?? Get.defaultTransition,
          defaultOpaqueRoute: opaqueRoute ?? Get.isOpaqueRouteDefault,
          defaultPopGesture: popGesture ?? Get.isPopGestureEnable,
          defaultDurationTransition:
              transitionDuration ?? Get.defaultTransitionDuration,
        );
      },
      builder: (_) => routerDelegate != null
          ? MaterialApp.router(
              routerDelegate: routerDelegate!,
              routeInformationParser: routeInformationParser!,
              scaffoldMessengerKey: scaffoldMessengerKey,
              backButtonDispatcher: backButtonDispatcher,
              routeInformationProvider: routeInformationProvider,
              key: _.unikey,
              builder: defaultBuilder,
              title: title,
              onGenerateTitle: onGenerateTitle,
              color: color,
              theme: _.theme ?? theme ?? ThemeData.fallback(),
              darkTheme:
                  _.darkTheme ?? darkTheme ?? theme ?? ThemeData.fallback(),
              themeMode: _.themeMode ?? themeMode,
              locale: Get.locale ?? locale,
              localizationsDelegates: localizationsDelegates,
              localeListResolutionCallback: localeListResolutionCallback,
              localeResolutionCallback: localeResolutionCallback,
              supportedLocales: supportedLocales,
              debugShowMaterialGrid: debugShowMaterialGrid,
              showPerformanceOverlay: showPerformanceOverlay,
              checkerboardRasterCacheImages: checkerboardRasterCacheImages,
              checkerboardOffscreenLayers: checkerboardOffscreenLayers,
              showSemanticsDebugger: showSemanticsDebugger,
              debugShowCheckedModeBanner: debugShowCheckedModeBanner,
              shortcuts: shortcuts,
              scrollBehavior: scrollBehavior,
            )
          : MaterialApp(
              key: _.unikey,
              navigatorKey:
                  (navigatorKey == null ? Get.key : Get.addKey(navigatorKey!)),
              scaffoldMessengerKey: scaffoldMessengerKey,
              home: home,
              routes: routes ?? const <String, WidgetBuilder>{},
              initialRoute: initialRoute,
              onGenerateRoute: (getPages != null ? generator : onGenerateRoute),
              onGenerateInitialRoutes: (getPages == null || home != null)
                  ? onGenerateInitialRoutes
                  : initialRoutesGenerate,
              onUnknownRoute: onUnknownRoute,
              navigatorObservers: (navigatorObservers == null
                  ? <NavigatorObserver>[
                      GetObserver(routingCallback, Get.routing)
                    ]
                  : <NavigatorObserver>[
                      GetObserver(routingCallback, Get.routing)
                    ]
                ..addAll(navigatorObservers!)),
              builder: defaultBuilder,
              title: title,
              onGenerateTitle: onGenerateTitle,
              color: color,
              theme: _.theme ?? theme ?? ThemeData.fallback(),
              darkTheme:
                  _.darkTheme ?? darkTheme ?? theme ?? ThemeData.fallback(),
              themeMode: _.themeMode ?? themeMode,
              locale: Get.locale ?? locale,
              localizationsDelegates: localizationsDelegates,
              localeListResolutionCallback: localeListResolutionCallback,
              localeResolutionCallback: localeResolutionCallback,
              supportedLocales: supportedLocales,
              debugShowMaterialGrid: debugShowMaterialGrid,
              showPerformanceOverlay: showPerformanceOverlay,
              checkerboardRasterCacheImages: checkerboardRasterCacheImages,
              checkerboardOffscreenLayers: checkerboardOffscreenLayers,
              showSemanticsDebugger: showSemanticsDebugger,
              debugShowCheckedModeBanner: debugShowCheckedModeBanner,
              shortcuts: shortcuts,
              scrollBehavior: scrollBehavior,
            ));
}

class RouteDecoder {
  final List<GetPage> treeBranch;
  GetPage? get route => treeBranch.isEmpty ? null : treeBranch.last;
  final Map<String, String> parameters;
  final Object? arguments;
  const RouteDecoder(
    this.treeBranch,
    this.parameters,
    this.arguments,
  );
  void replaceArguments(Object? arguments) {
    final _route = route;
    if (_route != null) {
      final index = treeBranch.indexOf(_route);
      treeBranch[index] = _route.copy(arguments: arguments);
    }
  }

  void replaceParameters(Object? arguments) {
    final _route = route;
    if (_route != null) {
      final index = treeBranch.indexOf(_route);
      treeBranch[index] = _route.copy(parameters: parameters);
    }
  }
}

class ParseRouteTree {
  ParseRouteTree({
    required this.routes,
  });
  final List<GetPage> routes;
  RouteDecoder matchRoute(String name, {Object? arguments}) {
    final uri = Uri.parse(name);
    final split = uri.path.split('/').where((element) => element.isNotEmpty);
    var curPath = '/';
    final cumulativePaths = <String>[
      '/',
    ];
    for (var item in split) {
      if (curPath.endsWith('/')) {
        curPath += '$item';
      } else {
        curPath += '/$item';
      }
      cumulativePaths.add(curPath);
    }
    final treeBranch = cumulativePaths
        .map((e) => MapEntry(e, _findRoute(e)))
        .where((element) => element.value != null)
        .map((e) => MapEntry(e.key, e.value!))
        .toList();
    final params = Map<String, String>.from(uri.queryParameters);
    if (treeBranch.isNotEmpty) {
      final lastRoute = treeBranch.last;
      final parsedParams = _parseParams(name, lastRoute.value.path);
      if (parsedParams.isNotEmpty) {
        params.addAll(parsedParams);
      }
      final mappedTreeBranch = treeBranch
          .map(
            (e) => e.value.copy(
              parameters: {
                if (e.value.parameters != null) ...e.value.parameters!,
                ...params,
              },
              name: e.key,
            ),
          )
          .toList();
      return RouteDecoder(
        mappedTreeBranch,
        params,
        arguments,
      );
    }
    return RouteDecoder(
      treeBranch.map((e) => e.value).toList(),
      params,
      arguments,
    );
  }

  void addRoutes(List<GetPage> getPages) {
    for (final route in getPages) {
      addRoute(route);
    }
  }

  void addRoute(GetPage route) {
    routes.add(route);
    for (var page in _flattenPage(route)) {
      addRoute(page);
    }
  }

  List<GetPage> _flattenPage(GetPage route) {
    final result = <GetPage>[];
    if (route.children.isEmpty) {
      return result;
    }
    final parentPath = route.name;
    for (var page in route.children) {
      final parentMiddlewares = [
        if (page.middlewares != null) ...page.middlewares!,
        if (route.middlewares != null) ...route.middlewares!
      ];
      result.add(
        _addChild(
          page,
          parentPath,
          parentMiddlewares,
        ),
      );
      final children = _flattenPage(page);
      for (var child in children) {
        result.add(_addChild(
          child,
          parentPath,
          [
            ...parentMiddlewares,
            if (child.middlewares != null) ...child.middlewares!,
          ],
        ));
      }
    }
    return result;
  }

  GetPage _addChild(
          GetPage origin, String parentPath, List<GetMiddleware> middlewares) =>
      origin.copy(
        middlewares: middlewares,
        name: (parentPath + origin.name).replaceAll(r'//', '/'),
      );
  GetPage? _findRoute(String name) {
    return routes.firstWhereOrNull(
      (route) => route.path.regex.hasMatch(name),
    );
  }

  Map<String, String> _parseParams(String path, PathDecoded routePath) {
    final params = <String, String>{};
    var idx = path.indexOf('?');
    if (idx > -1) {
      path = path.substring(0, idx);
      final uri = Uri.tryParse(path);
      if (uri != null) {
        params.addAll(uri.queryParameters);
      }
    }
    var paramsMatch = routePath.regex.firstMatch(path);
    for (var i = 0; i < routePath.keys.length; i++) {
      var param = Uri.decodeQueryComponent(paramsMatch![i + 1]!);
      params[routePath.keys[i]!] = param;
    }
    return params;
  }
}

extension FirstWhereExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

const List<String> rtlLanguages = <String>[
  'ar',
  'fa',
  'he',
  'ps',
  'ur',
];

abstract class Translations {
  Map<String, Map<String, String>> get keys;
}

extension ExtensionSnackbar on GetInterface {
  void rawSnackbar({
    String? title,
    String? message,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool instantInit = true,
    bool shouldIconPulse = true,
    double? maxWidth,
    EdgeInsets margin = const EdgeInsets.all(0.0),
    EdgeInsets padding = const EdgeInsets.all(16),
    double borderRadius = 0.0,
    Color? borderColor,
    double borderWidth = 1.0,
    Color backgroundColor = const Color(0xFF303030),
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    Widget? mainButton,
    OnTap? onTap,
    Duration duration = const Duration(seconds: 3),
    bool isDismissible = true,
    SnackDismissDirection dismissDirection = SnackDismissDirection.VERTICAL,
    bool showProgressIndicator = false,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    SnackStyle snackStyle = SnackStyle.FLOATING,
    Curve forwardAnimationCurve = Curves.easeOutCirc,
    Curve reverseAnimationCurve = Curves.easeOutCirc,
    Duration animationDuration = const Duration(seconds: 1),
    SnackbarStatusCallback? snackbarStatus,
    double? barBlur = 0.0,
    double overlayBlur = 0.0,
    Color? overlayColor,
    Form? userInputForm,
  }) async {
    final getBar = GetBar(
      snackbarStatus: snackbarStatus,
      title: title,
      message: message,
      titleText: titleText,
      messageText: messageText,
      snackPosition: snackPosition,
      borderRadius: borderRadius,
      margin: margin,
      duration: duration,
      barBlur: barBlur,
      backgroundColor: backgroundColor,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      padding: padding,
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      overlayBlur: overlayBlur,
      overlayColor: overlayColor,
      userInputForm: userInputForm,
    );
    if (instantInit) {
      getBar.show();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        getBar.show();
      });
    }
  }

  Future<T?>? showSnackbar<T>(GetBar snackbar) {
    return key.currentState?.push(SnackRoute<T>(snack: snackbar));
  }

  void snackbar<T>(
    String title,
    String message, {
    Color? colorText,
    Duration? duration,
    bool instantInit = true,
    SnackPosition? snackPosition,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool? shouldIconPulse,
    double? maxWidth,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    TextButton? mainButton,
    OnTap? onTap,
    bool? isDismissible,
    bool? showProgressIndicator,
    SnackDismissDirection? dismissDirection,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackStyle? snackStyle,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    Duration? animationDuration,
    double? barBlur,
    double? overlayBlur,
    SnackbarStatusCallback? snackbarStatus,
    Color? overlayColor,
    Form? userInputForm,
  }) async {
    final getBar = GetBar(
        snackbarStatus: snackbarStatus,
        titleText: titleText ??
            Text(
              title,
              style: TextStyle(
                color: colorText ?? iconColor ?? Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
        messageText: messageText ??
            Text(
              message,
              style: TextStyle(
                color: colorText ?? iconColor ?? Colors.black,
                fontWeight: FontWeight.w300,
                fontSize: 14,
              ),
            ),
        snackPosition: snackPosition ?? SnackPosition.TOP,
        borderRadius: borderRadius ?? 15,
        margin: margin ?? EdgeInsets.symmetric(horizontal: 10),
        duration: duration ?? Duration(seconds: 3),
        barBlur: barBlur ?? 7.0,
        backgroundColor: backgroundColor ?? Colors.grey.withOpacity(0.2),
        icon: icon,
        shouldIconPulse: shouldIconPulse ?? true,
        maxWidth: maxWidth,
        padding: padding ?? EdgeInsets.all(16),
        borderColor: borderColor,
        borderWidth: borderWidth,
        leftBarIndicatorColor: leftBarIndicatorColor,
        boxShadows: boxShadows,
        backgroundGradient: backgroundGradient,
        mainButton: mainButton,
        onTap: onTap,
        isDismissible: isDismissible ?? true,
        dismissDirection: dismissDirection ?? SnackDismissDirection.VERTICAL,
        showProgressIndicator: showProgressIndicator ?? false,
        progressIndicatorController: progressIndicatorController,
        progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
        progressIndicatorValueColor: progressIndicatorValueColor,
        snackStyle: snackStyle ?? SnackStyle.FLOATING,
        forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
        reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeOutCirc,
        animationDuration: animationDuration ?? Duration(seconds: 1),
        overlayBlur: overlayBlur ?? 0.0,
        overlayColor: overlayColor ?? Colors.transparent,
        userInputForm: userInputForm);
    if (instantInit) {
      showSnackbar<T>(getBar);
    } else {
      routing.isSnackbar = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showSnackbar<T>(getBar);
      });
    }
  }
}

extension OverlayExt on GetInterface {
  Future<T> showOverlay<T>({
    required Future<T> Function() asyncFunction,
    Color opacityColor = Colors.black,
    Widget? loadingWidget,
    double opacity = .5,
  }) async {
    final navigatorState =
        Navigator.of(Get.overlayContext!, rootNavigator: false);
    final overlayState = navigatorState.overlay!;
    final overlayEntryOpacity = OverlayEntry(builder: (context) {
      return Opacity(
          opacity: opacity,
          child: Container(
            color: opacityColor,
          ));
    });
    final overlayEntryLoader = OverlayEntry(builder: (context) {
      return loadingWidget ??
          Center(
              child: Container(
            height: 90,
            width: 90,
            child: Text('Loading...'),
          ));
    });
    overlayState.insert(overlayEntryOpacity);
    overlayState.insert(overlayEntryLoader);
    T data;
    try {
      data = await asyncFunction();
    } on Exception catch (_) {
      overlayEntryLoader.remove();
      overlayEntryOpacity.remove();
      rethrow;
    }
    overlayEntryLoader.remove();
    overlayEntryOpacity.remove();
    return data;
  }
}

extension ExtensionDialog on GetInterface {
  Future<T?> dialog<T>(
    Widget widget, {
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    GlobalKey<NavigatorState>? navigatorKey,
    Object? arguments,
    Duration? transitionDuration,
    Curve? transitionCurve,
    String? name,
    RouteSettings? routeSettings,
  }) {
    assert(debugCheckHasMaterialLocalizations(context!));
    final theme = Theme.of(context!);
    return generalDialog<T>(
      pageBuilder: (buildContext, animation, secondaryAnimation) {
        final pageChild = widget;
        Widget dialog = Builder(builder: (context) {
          return Theme(data: theme, child: pageChild);
        });
        if (useSafeArea) {
          dialog = SafeArea(child: dialog);
        }
        return dialog;
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context!).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration ?? defaultDialogTransitionDuration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: transitionCurve ?? defaultDialogTransitionCurve,
          ),
          child: child,
        );
      },
      navigatorKey: navigatorKey,
      routeSettings:
          routeSettings ?? RouteSettings(arguments: arguments, name: name),
    );
  }

  Future<T?> generalDialog<T>({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = false,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    GlobalKey<NavigatorState>? navigatorKey,
    RouteSettings? routeSettings,
  }) {
    assert(!barrierDismissible || barrierLabel != null);
    final nav = navigatorKey?.currentState ??
        Navigator.of(overlayContext!, rootNavigator: true);
    return nav.push<T>(
      GetDialogRoute<T>(
        pageBuilder: pageBuilder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder,
        settings: routeSettings,
      ),
    );
  }

  Future<T?> defaultDialog<T>({
    String title = "Alert",
    EdgeInsetsGeometry? titlePadding,
    TextStyle? titleStyle,
    Widget? content,
    EdgeInsetsGeometry? contentPadding,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    VoidCallback? onCustom,
    Color? cancelTextColor,
    Color? confirmTextColor,
    String? textConfirm,
    String? textCancel,
    String? textCustom,
    Widget? confirm,
    Widget? cancel,
    Widget? custom,
    Color? backgroundColor,
    bool barrierDismissible = true,
    Color? buttonColor,
    String middleText = "Dialog made in 3 lines of code",
    TextStyle? middleTextStyle,
    double radius = 20.0,
    List<Widget>? actions,
    WillPopCallback? onWillPop,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    var leanCancel = onCancel != null || textCancel != null;
    var leanConfirm = onConfirm != null || textConfirm != null;
    actions ??= [];
    if (cancel != null) {
      actions.add(cancel);
    } else {
      if (leanCancel) {
        actions.add(TextButton(
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: buttonColor ?? theme.accentColor,
                    width: 2,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(100)),
          ),
          onPressed: () {
            onCancel?.call();
            back();
          },
          child: Text(
            textCancel ?? "Cancel",
            style: TextStyle(color: cancelTextColor ?? theme.accentColor),
          ),
        ));
      }
    }
    if (confirm != null) {
      actions.add(confirm);
    } else {
      if (leanConfirm) {
        actions.add(TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: buttonColor ?? theme.accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(
              textConfirm ?? "Ok",
              style:
                  TextStyle(color: confirmTextColor ?? theme.backgroundColor),
            ),
            onPressed: () {
              onConfirm?.call();
            }));
      }
    }
    Widget baseAlertDialog = AlertDialog(
      titlePadding: titlePadding ?? EdgeInsets.all(8),
      contentPadding: contentPadding ?? EdgeInsets.all(8),
      backgroundColor: backgroundColor ?? theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius))),
      title: Text(title, textAlign: TextAlign.center, style: titleStyle),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          content ??
              Text(middleText,
                  textAlign: TextAlign.center, style: middleTextStyle),
          SizedBox(height: 16),
          ButtonTheme(
            minWidth: 78.0,
            height: 34.0,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          )
        ],
      ),
      buttonPadding: EdgeInsets.zero,
    );
    return dialog<T>(
      onWillPop != null
          ? WillPopScope(
              onWillPop: onWillPop,
              child: baseAlertDialog,
            )
          : baseAlertDialog,
      barrierDismissible: barrierDismissible,
      navigatorKey: navigatorKey,
    );
  }
}

extension ExtensionBottomSheet on GetInterface {
  Future<T?> bottomSheet<T>(
    Widget bottomsheet, {
    Color? backgroundColor,
    double? elevation,
    bool persistent = true,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? barrierColor,
    bool? ignoreSafeArea,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? settings,
    Duration? enterBottomSheetDuration,
    Duration? exitBottomSheetDuration,
  }) {
    return Navigator.of(overlayContext!, rootNavigator: useRootNavigator)
        .push(GetModalBottomSheetRoute<T>(
      builder: (_) => bottomsheet,
      isPersistent: persistent,
      theme: Theme.of(key.currentContext!),
      isScrollControlled: isScrollControlled,
      barrierLabel: MaterialLocalizations.of(key.currentContext!)
          .modalBarrierDismissLabel,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shape: shape,
      removeTop: ignoreSafeArea ?? true,
      clipBehavior: clipBehavior,
      isDismissible: isDismissible,
      modalBarrierColor: barrierColor,
      settings: settings,
      enableDrag: enableDrag,
      enterBottomSheetDuration:
          enterBottomSheetDuration ?? const Duration(milliseconds: 250),
      exitBottomSheetDuration:
          exitBottomSheetDuration ?? const Duration(milliseconds: 200),
    ));
  }
}

extension GetNavigation on GetInterface {
  Future<T?>? to<T>(
    dynamic page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    int? id,
    String? routeName,
    bool fullscreenDialog = false,
    dynamic arguments,
    Bindings? binding,
    bool preventDuplicates = true,
    bool? popGesture,
    double Function(BuildContext context)? gestureWidth,
  }) {
    routeName ??= "/${page.runtimeType}";
    routeName = _cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return global(id).currentState?.push<T>(
          GetPageRoute<T>(
            opaque: opaque ?? true,
            page: _resolvePage(page, 'to'),
            routeName: routeName,
            gestureWidth: gestureWidth,
            settings: RouteSettings(
              name: routeName,
              arguments: arguments,
            ),
            popGesture: popGesture ?? defaultPopGesture,
            transition: transition ?? defaultTransition,
            curve: curve ?? defaultTransitionCurve,
            fullscreenDialog: fullscreenDialog,
            binding: binding,
            transitionDuration: duration ?? defaultTransitionDuration,
          ),
        );
  }

  GetPageBuilder _resolvePage(dynamic page, String method) {
    if (page is GetPageBuilder) {
      return page;
    } else if (page is Widget) {
      Get.log(
          '''WARNING, consider using: "Get.$method(() => Page())" instead of "Get.$method(Page())". Using a widget function instead of a widget fully guarantees that the widget and its controllers will be removed from memory when they are no longer used.   ''');
      return () => page;
    } else if (page is String) {
      throw '''Unexpected String, use toNamed() instead''';
    } else {
      throw '''Unexpected format, you can only use widgets and widget functions here''';
    }
  }

  Future<T?>? toNamed<T>(
    String page, {
    dynamic arguments,
    int? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    if (preventDuplicates && page == currentRoute) {
      return null;
    }
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return global(id).currentState?.pushNamed<T>(
          page,
          arguments: arguments,
        );
  }

  Future<T?>? offNamed<T>(
    String page, {
    dynamic arguments,
    int? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    if (preventDuplicates && page == currentRoute) {
      return null;
    }
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return global(id).currentState?.pushReplacementNamed(
          page,
          arguments: arguments,
        );
  }

  void until(RoutePredicate predicate, {int? id}) {
    return global(id).currentState?.popUntil(predicate);
  }

  Future<T?>? offUntil<T>(Route<T> page, RoutePredicate predicate, {int? id}) {
    return global(id).currentState?.pushAndRemoveUntil<T>(page, predicate);
  }

  Future<T?>? offNamedUntil<T>(
    String page,
    RoutePredicate predicate, {
    int? id,
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return global(id).currentState?.pushNamedAndRemoveUntil<T>(
          page,
          predicate,
          arguments: arguments,
        );
  }

  Future<T?>? offAndToNamed<T>(
    String page, {
    dynamic arguments,
    int? id,
    dynamic result,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return global(id).currentState?.popAndPushNamed(
          page,
          arguments: arguments,
          result: result,
        );
  }

  void removeRoute(Route<dynamic> route, {int? id}) {
    return global(id).currentState?.removeRoute(route);
  }

  Future<T?>? offAllNamed<T>(
    String newRouteName, {
    RoutePredicate? predicate,
    dynamic arguments,
    int? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: newRouteName, queryParameters: parameters);
      newRouteName = uri.toString();
    }
    return global(id).currentState?.pushNamedAndRemoveUntil<T>(
          newRouteName,
          predicate ?? (_) => false,
          arguments: arguments,
        );
  }

  bool get isOverlaysOpen =>
      (isSnackbarOpen! || isDialogOpen! || isBottomSheetOpen!);
  bool get isOverlaysClosed =>
      (!isSnackbarOpen! && !isDialogOpen! && !isBottomSheetOpen!);
  void back<T>({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
    int? id,
  }) {
    if (closeOverlays && isOverlaysOpen) {
      navigator?.popUntil((route) {
        return (isOverlaysClosed);
      });
    }
    if (canPop) {
      if (global(id).currentState?.canPop() == true) {
        global(id).currentState?.pop<T>(result);
      }
    } else {
      global(id).currentState?.pop<T>(result);
    }
  }

  void close(int times, [int? id]) {
    if (times < 1) {
      times = 1;
    }
    var count = 0;
    var back = global(id).currentState?.popUntil((route) => count++ == times);
    return back;
  }

  Future<T?>? off<T>(
    dynamic page, {
    bool opaque = false,
    Transition? transition,
    Curve? curve,
    bool? popGesture,
    int? id,
    String? routeName,
    dynamic arguments,
    Bindings? binding,
    bool fullscreenDialog = false,
    bool preventDuplicates = true,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return global(id).currentState?.pushReplacement(GetPageRoute(
        opaque: opaque,
        gestureWidth: gestureWidth,
        page: _resolvePage(page, 'off'),
        binding: binding,
        settings: RouteSettings(
          arguments: arguments,
          name: routeName,
        ),
        routeName: routeName,
        fullscreenDialog: fullscreenDialog,
        popGesture: popGesture ?? defaultPopGesture,
        transition: transition ?? defaultTransition,
        curve: curve ?? defaultTransitionCurve,
        transitionDuration: duration ?? defaultTransitionDuration));
  }

  Future<T?>? offAll<T>(
    dynamic page, {
    RoutePredicate? predicate,
    bool opaque = false,
    bool? popGesture,
    int? id,
    String? routeName,
    dynamic arguments,
    Bindings? binding,
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    return global(id).currentState?.pushAndRemoveUntil<T>(
        GetPageRoute<T>(
          opaque: opaque,
          popGesture: popGesture ?? defaultPopGesture,
          page: _resolvePage(page, 'offAll'),
          binding: binding,
          gestureWidth: gestureWidth,
          settings: RouteSettings(
            name: routeName,
            arguments: arguments,
          ),
          fullscreenDialog: fullscreenDialog,
          routeName: routeName,
          transition: transition ?? defaultTransition,
          curve: curve ?? defaultTransitionCurve,
          transitionDuration: duration ?? defaultTransitionDuration,
        ),
        predicate ?? (route) => false);
  }

  String _cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }

  void config(
      {bool? enableLog,
      LogWriterCallback? logWriterCallback,
      bool? defaultPopGesture,
      bool? defaultOpaqueRoute,
      Duration? defaultDurationTransition,
      bool? defaultGlobalState,
      Transition? defaultTransition}) {
    if (enableLog != null) {
      Get.isLogEnable = enableLog;
    }
    if (logWriterCallback != null) {
      Get.log = logWriterCallback;
    }
    if (defaultPopGesture != null) {
      _getxController.defaultPopGesture = defaultPopGesture;
    }
    if (defaultOpaqueRoute != null) {
      _getxController.defaultOpaqueRoute = defaultOpaqueRoute;
    }
    if (defaultTransition != null) {
      _getxController.defaultTransition = defaultTransition;
    }
    if (defaultDurationTransition != null) {
      _getxController.defaultTransitionDuration = defaultDurationTransition;
    }
  }

  void updateLocale(Locale l) {
    Get.locale = l;
    forceAppUpdate();
  }

  void forceAppUpdate() {
    engine!.performReassemble();
  }

  void appUpdate() => _getxController.update();
  void changeTheme(ThemeData theme) {
    _getxController.setTheme(theme);
  }

  void changeThemeMode(ThemeMode themeMode) {
    _getxController.setThemeMode(themeMode);
  }

  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    return _getxController.addKey(newKey);
  }

  GlobalKey<NavigatorState>? nestedKey(dynamic key) {
    keys.putIfAbsent(
      key,
      () => GlobalKey<NavigatorState>(
        debugLabel: 'Getx nested key: ${key.toString()}',
      ),
    );
    return keys[key];
  }

  GlobalKey<NavigatorState> global(int? k) {
    GlobalKey<NavigatorState> _key;
    if (k == null) {
      _key = key;
    } else {
      if (!keys.containsKey(k)) {
        throw 'Route id ($k) not found';
      }
      _key = keys[k]!;
    }
    if (_key.currentContext == null && !testMode) {
      throw """You are trying to use contextless navigation without   a GetMaterialApp or Get.key.   If you are testing your app, you can use:   [Get.testMode = true], or if you are running your app on   a physical device or emulator, you must exchange your [MaterialApp]   for a [GetMaterialApp].   """;
    }
    return _key;
  }

  dynamic get arguments => routing.args;
  String get currentRoute => routing.current;
  String get previousRoute => routing.previous;
  bool? get isSnackbarOpen => routing.isSnackbar;
  bool? get isDialogOpen => routing.isDialog;
  bool? get isBottomSheetOpen => routing.isBottomSheet;
  Route<dynamic>? get rawRoute => routing.route;
  bool get isPopGestureEnable => defaultPopGesture;
  bool get isOpaqueRouteDefault => defaultOpaqueRoute;
  BuildContext? get context => key.currentContext;
  BuildContext? get overlayContext {
    BuildContext? overlay;
    key.currentState?.overlay?.context.visitChildElements((element) {
      overlay = element;
    });
    return overlay;
  }

  ThemeData get theme {
    var _theme = ThemeData.fallback();
    if (context != null) {
      _theme = Theme.of(context!);
    }
    return _theme;
  }

  WidgetsBinding? get engine {
    if (WidgetsBinding.instance == null) {
      WidgetsFlutterBinding();
    }
    return WidgetsBinding.instance;
  }

  SingletonFlutterWindow get window => window;
  Locale? get deviceLocale => window.locale;
  double get pixelRatio => window.devicePixelRatio;
  Size get size => window.physicalSize / pixelRatio;
  double get width => size.width;
  double get height => size.height;
  double get statusBarHeight => window.padding.top;
  double get bottomBarHeight => window.padding.bottom;
  double get textScaleFactor => window.textScaleFactor;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(context!);
  bool get isDarkMode => (theme.brightness == Brightness.dark);
  bool get isPlatformDarkMode => (window.platformBrightness == Brightness.dark);
  Color? get iconColor => theme.iconTheme.color;
  FocusNode? get focusScope => FocusManager.instance.primaryFocus;
  GlobalKey<NavigatorState> get key => _getxController.key;
  Map<dynamic, GlobalKey<NavigatorState>> get keys => _getxController.keys;
  GetMaterialController get rootController => _getxController;
  bool get defaultPopGesture => _getxController.defaultPopGesture;
  bool get defaultOpaqueRoute => _getxController.defaultOpaqueRoute;
  Transition? get defaultTransition => _getxController.defaultTransition;
  Duration get defaultTransitionDuration {
    return _getxController.defaultTransitionDuration;
  }

  Curve get defaultTransitionCurve => _getxController.defaultTransitionCurve;
  Curve get defaultDialogTransitionCurve {
    return _getxController.defaultDialogTransitionCurve;
  }

  Duration get defaultDialogTransitionDuration {
    return _getxController.defaultDialogTransitionDuration;
  }

  Routing get routing => _getxController.routing;
  Map<String, String?> get parameters => _getxController.parameters;
  set parameters(Map<String, String?> newParameters) =>
      _getxController.parameters = newParameters;
  CustomTransition? get customTransition => _getxController.customTransition;
  set customTransition(CustomTransition? newTransition) =>
      _getxController.customTransition = newTransition;
  bool get testMode => _getxController.testMode;
  set testMode(bool isTest) => _getxController.testMode = isTest;
  void resetRootNavigator() {
    _getxController = GetMaterialController();
  }

  static GetMaterialController _getxController = GetMaterialController();
}

extension NavTwoExt on GetInterface {
  void addPages(List<GetPage> getPages) {
    routeTree.addRoutes(getPages);
  }

  void clearRouteTree() {
    _routeTree.routes.clear();
  }

  static late final _routeTree = ParseRouteTree(routes: []);
  ParseRouteTree get routeTree => _routeTree;
  void addPage(GetPage getPage) {
    routeTree.addRoute(getPage);
  }

  TDelegate? delegate<TDelegate extends RouterDelegate<TPage>, TPage>() =>
      routerDelegate as TDelegate?;
  GetInformationParser createInformationParser({String initialRoute = '/'}) {
    if (routeInformationParser == null) {
      return routeInformationParser = GetInformationParser(
        initialRoute: initialRoute,
      );
    } else {
      return routeInformationParser as GetInformationParser;
    }
  }

  GetDelegate get rootDelegate => createDelegate();
  GetDelegate createDelegate({
    GetPage<dynamic>? notFoundRoute,
    List<NavigatorObserver>? navigatorObservers,
    TransitionDelegate<dynamic>? transitionDelegate,
    PopMode backButtonPopMode = PopMode.History,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.ReorderRoutes,
  }) {
    if (routerDelegate == null) {
      return routerDelegate = GetDelegate(
        notFoundRoute: notFoundRoute,
        navigatorObservers: navigatorObservers,
        transitionDelegate: transitionDelegate,
        backButtonPopMode: backButtonPopMode,
        preventDuplicateHandlingMode: preventDuplicateHandlingMode,
      );
    } else {
      return routerDelegate as GetDelegate;
    }
  }
}

NavigatorState? get navigator => GetNavigation(Get).key.currentState;

class LeftToRightFadeTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.0, 0.0),
            ).animate(secondaryAnimation),
            child: child),
      ),
    );
  }
}

class RightToLeftFadeTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(secondaryAnimation),
            child: child),
      ),
    );
  }
}

class NoTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve curve,
      Alignment alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return child;
  }
}

class FadeInTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class SlideDownTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}

class SlideLeftTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}

class SlideRightTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}

class SlideTopTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0.0, -1.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}

class ZoomInTransition {
  Widget buildTransitions(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
}

class SizeTransitions {
  Widget buildTransitions(
      BuildContext context,
      Curve curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return Align(
      alignment: Alignment.center,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
        child: child,
      ),
    );
  }
}

abstract class _RouteMiddleware {
  int? priority;
  RouteSettings? redirect(String route);
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route);
  GetPage? onPageCalled(GetPage page);
  List<Bindings>? onBindingsStart(List<Bindings> bindings);
  GetPageBuilder? onPageBuildStart(GetPageBuilder page);
  Widget onPageBuilt(Widget page);
  void onPageDispose();
}

class GetMiddleware implements _RouteMiddleware {
  @override
  int? priority = 0;
  GetMiddleware({this.priority});
  @override
  RouteSettings? redirect(String? route) => null;
  @override
  GetPage? onPageCalled(GetPage? page) => page;
  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) => bindings;
  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) => page;
  @override
  Widget onPageBuilt(Widget page) => page;
  @override
  void onPageDispose() {}
  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) =>
      SynchronousFuture(route);
}

class MiddlewareRunner {
  MiddlewareRunner(this._middlewares);
  final List<GetMiddleware>? _middlewares;
  List<GetMiddleware> _getMiddlewares() {
    final _m = _middlewares ?? <GetMiddleware>[];
    return _m
      ..sort(
        (a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0),
      );
  }

  GetPage? runOnPageCalled(GetPage? page) {
    _getMiddlewares().forEach((element) {
      page = element.onPageCalled(page);
    });
    return page;
  }

  RouteSettings? runRedirect(String? route) {
    RouteSettings? to;
    for (final element in _getMiddlewares()) {
      to = element.redirect(route);
      if (to != null) {
        break;
      }
    }
    Get.log('Redirect to $to');
    return to;
  }

  List<Bindings>? runOnBindingsStart(List<Bindings>? bindings) {
    _getMiddlewares().forEach((element) {
      bindings = element.onBindingsStart(bindings);
    });
    return bindings;
  }

  GetPageBuilder? runOnPageBuildStart(GetPageBuilder? page) {
    _getMiddlewares().forEach((element) {
      page = element.onPageBuildStart(page);
    });
    return page;
  }

  Widget runOnPageBuilt(Widget page) {
    _getMiddlewares().forEach((element) {
      page = element.onPageBuilt(page);
    });
    return page;
  }

  void runOnPageDispose() =>
      _getMiddlewares().forEach((element) => element.onPageDispose());
}

class PageRedirect {
  GetPage? route;
  GetPage? unknownRoute;
  RouteSettings? settings;
  bool isUnknown;
  PageRedirect({
    this.route,
    this.unknownRoute,
    this.isUnknown = false,
    this.settings,
  });
  GetPageRoute<T> page<T>() {
    while (needRecheck()) {}
    final _r = (isUnknown ? unknownRoute : route)!;
    return GetPageRoute<T>(
      page: _r.page,
      parameter: _r.parameters,
      settings: isUnknown
          ? RouteSettings(
              name: _r.name,
              arguments: settings!.arguments,
            )
          : settings,
      curve: _r.curve,
      opaque: _r.opaque,
      showCupertinoParallax: _r.showCupertinoParallax,
      gestureWidth: _r.gestureWidth,
      customTransition: _r.customTransition,
      binding: _r.binding,
      bindings: _r.bindings,
      transitionDuration:
          _r.transitionDuration ?? Get.defaultTransitionDuration,
      transition: _r.transition,
      popGesture: _r.popGesture,
      fullscreenDialog: _r.fullscreenDialog,
      middlewares: _r.middlewares,
    );
  }

  GetPageRoute<T> getPageToRoute<T>(GetPage rou, GetPage? unk) {
    while (needRecheck()) {}
    final _r = (isUnknown ? unk : rou)!;
    return GetPageRoute<T>(
      page: _r.page,
      parameter: _r.parameters,
      alignment: _r.alignment,
      title: _r.title,
      maintainState: _r.maintainState,
      routeName: _r.name,
      settings: _r,
      curve: _r.curve,
      showCupertinoParallax: _r.showCupertinoParallax,
      gestureWidth: _r.gestureWidth,
      opaque: _r.opaque,
      customTransition: _r.customTransition,
      binding: _r.binding,
      bindings: _r.bindings,
      transitionDuration:
          _r.transitionDuration ?? Get.defaultTransitionDuration,
      transition: _r.transition,
      popGesture: _r.popGesture,
      fullscreenDialog: _r.fullscreenDialog,
      middlewares: _r.middlewares,
    );
  }

  bool needRecheck() {
    if (settings == null && route != null) {
      settings = route;
    }
    final match = Get.routeTree.matchRoute(settings!.name!);
    Get.parameters = match.parameters;
    if (match.route == null) {
      isUnknown = true;
      return false;
    }
    final runner = MiddlewareRunner(match.route!.middlewares);
    route = runner.runOnPageCalled(match.route);
    addPageParameter(route!);
    if (match.route!.middlewares == null || match.route!.middlewares!.isEmpty) {
      return false;
    }
    final newSettings = runner.runRedirect(settings!.name);
    if (newSettings == null) {
      return false;
    }
    settings = newSettings;
    return true;
  }

  void addPageParameter(GetPage route) {
    if (route.parameters == null) return;
    final parameters = Get.parameters;
    parameters.addEntries(route.parameters!.entries);
    Get.parameters = parameters;
  }
}

const double _kBackGestureWidth = 20.0;
const double _kMinFlingVelocity = 1.0;
const int _kMaxDroppedSwipePageForwardAnimationTime = 800;
const int _kMaxPageBackAnimationTime = 300;
mixin GetPageRouteTransitionMixin<T> on PageRoute<T> {
  @protected
  Widget buildContent(BuildContext context);
  String? get title;
  double Function(BuildContext context)? get gestureWidth;
  ValueNotifier<String?>? _previousTitle;
  ValueListenable<String?> get previousTitle {
    assert(
      _previousTitle != null,
      ''' Cannot read the previousTitle for a route that has not yet been installed''',
    );
    return _previousTitle!;
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    final previousTitleString = previousRoute is CupertinoRouteTransitionMixin
        ? previousRoute.title
        : null;
    if (_previousTitle == null) {
      _previousTitle = ValueNotifier<String?>(previousTitleString);
    } else {
      _previousTitle!.value = previousTitleString;
    }
    super.didChangePrevious(previousRoute);
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  bool get showCupertinoParallax;
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is GetPageRouteTransitionMixin &&
        !nextRoute.fullscreenDialog &&
        nextRoute.showCupertinoParallax;
  }

  static bool isPopGestureInProgress(PageRoute<dynamic> route) {
    return route.navigator!.userGestureInProgress;
  }

  bool get popGestureInProgress => isPopGestureInProgress(this);
  bool get popGestureEnabled => _isPopGestureEnabled(this);
  static bool _isPopGestureEnabled<T>(PageRoute<T> route) {
    if (route.isFirst) return false;
    if (route.willHandlePopInternally) return false;
    if (route.hasScopedWillPopCallback) return false;
    if (route.fullscreenDialog) return false;
    if (route.animation!.status != AnimationStatus.completed) return false;
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) {
      return false;
    }
    if (isPopGestureInProgress(route)) return false;
    return true;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final child = buildContent(context);
    final Widget result = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: child,
    );
    return result;
  }

  static CupertinoBackGestureController<T> _startPopGesture<T>(
      PageRoute<T> route) {
    assert(_isPopGestureEnabled(route));
    return CupertinoBackGestureController<T>(
      navigator: route.navigator!,
      controller: route.controller!,
    );
  }

  static Widget buildPageTransitions<T>(
    PageRoute<T> rawRoute,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final route = rawRoute as GetPageRoute<T>;
    final linearTransition = isPopGestureInProgress(route);
    final finalCurve = route.curve ?? Get.defaultTransitionCurve;
    final hasCurve = route.curve != null;
    if (route.fullscreenDialog && route.transition == null) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: hasCurve
            ? CurvedAnimation(parent: animation, curve: finalCurve)
            : animation,
        secondaryRouteAnimation: secondaryAnimation,
        child: child,
        linearTransition: linearTransition,
      );
    } else {
      if (route.customTransition != null) {
        return route.customTransition!.buildTransition(
          context,
          finalCurve,
          route.alignment,
          animation,
          secondaryAnimation,
          route.popGesture ?? Get.defaultPopGesture
              ? CupertinoBackGestureDetector<T>(
                  gestureWidth:
                      route.gestureWidth?.call(context) ?? _kBackGestureWidth,
                  enabledCallback: () => _isPopGestureEnabled<T>(route),
                  onStartPopGesture: () => _startPopGesture<T>(route),
                  child: child)
              : child,
        );
      }
      final iosAnimation = animation;
      animation = CurvedAnimation(parent: animation, curve: finalCurve);
      switch (route.transition ?? Get.defaultTransition) {
        case Transition.leftToRight:
          return SlideLeftTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.downToUp:
          return SlideDownTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.upToDown:
          return SlideTopTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.noTransition:
          return route.popGesture ?? Get.defaultPopGesture
              ? CupertinoBackGestureDetector<T>(
                  gestureWidth:
                      route.gestureWidth?.call(context) ?? _kBackGestureWidth,
                  enabledCallback: () => _isPopGestureEnabled<T>(route),
                  onStartPopGesture: () => _startPopGesture<T>(route),
                  child: child)
              : child;
        case Transition.rightToLeft:
          return SlideRightTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.zoom:
          return ZoomInTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.fadeIn:
          return FadeInTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.rightToLeftWithFade:
          return RightToLeftFadeTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.leftToRightWithFade:
          return LeftToRightFadeTransition().buildTransitions(
              context,
              route.curve,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.cupertino:
          return CupertinoPageTransition(
            primaryRouteAnimation: animation,
            secondaryRouteAnimation: secondaryAnimation,
            linearTransition: linearTransition,
            child: CupertinoBackGestureDetector<T>(
              gestureWidth:
                  route.gestureWidth?.call(context) ?? _kBackGestureWidth,
              enabledCallback: () => _isPopGestureEnabled<T>(route),
              onStartPopGesture: () => _startPopGesture<T>(route),
              child: child,
            ),
          );
        case Transition.size:
          return SizeTransitions().buildTransitions(
              context,
              route.curve!,
              route.alignment,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.fade:
          return FadeUpwardsPageTransitionsBuilder().buildTransitions(
              route,
              context,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.topLevel:
          return ZoomPageTransitionsBuilder().buildTransitions(
              route,
              context,
              animation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        case Transition.native:
          return PageTransitionsTheme().buildTransitions(
              route,
              context,
              iosAnimation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
        default:
          if (Get.customTransition != null) {
            return Get.customTransition!.buildTransition(context, route.curve,
                route.alignment, animation, secondaryAnimation, child);
          }
          return PageTransitionsTheme().buildTransitions(
              route,
              context,
              iosAnimation,
              secondaryAnimation,
              route.popGesture ?? Get.defaultPopGesture
                  ? CupertinoBackGestureDetector<T>(
                      gestureWidth: route.gestureWidth?.call(context) ??
                          _kBackGestureWidth,
                      enabledCallback: () => _isPopGestureEnabled<T>(route),
                      onStartPopGesture: () => _startPopGesture<T>(route),
                      child: child)
                  : child);
      }
    }
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(
        this, context, animation, secondaryAnimation, child);
  }
}

class CupertinoBackGestureDetector<T> extends StatefulWidget {
  const CupertinoBackGestureDetector({
    Key? key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
    required this.gestureWidth,
  }) : super(key: key);
  final Widget child;
  final double gestureWidth;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<CupertinoBackGestureController<T>> onStartPopGesture;
  @override
  CupertinoBackGestureDetectorState<T> createState() =>
      CupertinoBackGestureDetectorState<T>();
}

class CupertinoBackGestureDetectorState<T>
    extends State<CupertinoBackGestureDetector<T>> {
  CupertinoBackGestureController<T>? _backGestureController;
  late HorizontalDragGestureRecognizer _recognizer;
  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragUpdate(
        _convertToLogical(details.primaryDelta! / context.size!.width));
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragEnd(_convertToLogical(
        details.velocity.pixelsPerSecond.dx / context.size!.width));
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) _recognizer.addPointer(event);
  }

  double _convertToLogical(double value) {
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    var dragAreaWidth = Directionality.of(context) == TextDirection.ltr
        ? MediaQuery.of(context).padding.left
        : MediaQuery.of(context).padding.right;
    dragAreaWidth = max(dragAreaWidth, widget.gestureWidth);
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: dragAreaWidth,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class CupertinoBackGestureController<T> {
  CupertinoBackGestureController({
    required this.navigator,
    required this.controller,
  }) {
    navigator.didStartUserGesture();
  }
  final AnimationController controller;
  final NavigatorState navigator;
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastLinearToSlowEaseIn;
    final bool animateForward;
    if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }
    if (animateForward) {
      final droppedPageForwardAnimationTime = min(
        lerpDouble(
                _kMaxDroppedSwipePageForwardAnimationTime, 0, controller.value)!
            .floor(),
        _kMaxPageBackAnimationTime,
      );
      controller.animateTo(1.0,
          duration: Duration(milliseconds: droppedPageForwardAnimationTime),
          curve: animationCurve);
    } else {
      navigator.pop();
      if (controller.isAnimating) {
        final droppedPageBackAnimationTime = lerpDouble(
                0, _kMaxDroppedSwipePageForwardAnimationTime, controller.value)!
            .floor();
        controller.animateBack(0.0,
            duration: Duration(milliseconds: droppedPageBackAnimationTime),
            curve: animationCurve);
      }
    }
    if (controller.isAnimating) {
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}

enum Transition {
  fade,
  fadeIn,
  rightToLeft,
  leftToRight,
  upToDown,
  downToUp,
  rightToLeftWithFade,
  leftToRightWithFade,
  zoom,
  topLevel,
  noTransition,
  cupertino,
  cupertinoDialog,
  size,
  native
}

typedef GetPageBuilder = Widget Function();

abstract class CustomTransition {
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}

@immutable
class PathDecoded {
  const PathDecoded(this.regex, this.keys);
  final RegExp regex;
  final List<String?> keys;
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PathDecoded && other.regex == regex;
  }

  @override
  int get hashCode => regex.hashCode;
}

class GetPage<T> extends Page<T> {
  final GetPageBuilder page;
  final bool? popGesture;
  final Map<String, String>? parameters;
  final String? title;
  final Transition? transition;
  final Curve curve;
  final bool? participatesInRootNavigator;
  final Alignment? alignment;
  final bool maintainState;
  final bool opaque;
  final double Function(BuildContext context)? gestureWidth;
  final Bindings? binding;
  final List<Bindings> bindings;
  final CustomTransition? customTransition;
  final Duration? transitionDuration;
  final bool fullscreenDialog;
  final bool preventDuplicates;
  @override
  final Object? arguments;
  @override
  final String name;
  final List<GetPage> children;
  final List<GetMiddleware>? middlewares;
  final PathDecoded path;
  final GetPage? unknownRoute;
  final bool showCupertinoParallax;
  GetPage({
    required this.name,
    required this.page,
    this.title,
    this.participatesInRootNavigator,
    this.gestureWidth,
    this.maintainState = true,
    this.curve = Curves.linear,
    this.alignment,
    this.parameters,
    this.opaque = true,
    this.transitionDuration,
    this.popGesture,
    this.binding,
    this.bindings = const [],
    this.transition,
    this.customTransition,
    this.fullscreenDialog = false,
    this.children = const <GetPage>[],
    this.middlewares,
    this.unknownRoute,
    this.arguments,
    this.showCupertinoParallax = true,
    this.preventDuplicates = true,
  })  : path = _nameToRegex(name),
        assert(name.startsWith('/'),
            'It is necessary to start route name [$name] with a slash: /$name'),
        super(
          key: ValueKey(name),
          name: name,
          arguments: Get.arguments,
        );
  static PathDecoded _nameToRegex(String path) {
    var keys = <String?>[];
    String _replace(Match pattern) {
      var buffer = StringBuffer('(?:');
      if (pattern[1] != null) buffer.write('\.');
      buffer.write('([\\w%+-._~!\$&\'()*,;=:@]+))');
      if (pattern[3] != null) buffer.write('?');
      keys.add(pattern[2]);
      return "$buffer";
    }

    var stringPath = '$path/?'
        .replaceAllMapped(RegExp(r'(\.)?:(\w+)(\?)?'), _replace)
        .replaceAll('//', '/');
    return PathDecoded(RegExp('^$stringPath\$'), keys);
  }

  GetPage<T> copy({
    String? name,
    GetPageBuilder? page,
    bool? popGesture,
    Map<String, String>? parameters,
    String? title,
    Transition? transition,
    Curve? curve,
    Alignment? alignment,
    bool? maintainState,
    bool? opaque,
    Bindings? binding,
    List<Bindings>? bindings,
    CustomTransition? customTransition,
    Duration? transitionDuration,
    bool? fullscreenDialog,
    RouteSettings? settings,
    List<GetPage>? children,
    GetPage? unknownRoute,
    List<GetMiddleware>? middlewares,
    bool? preventDuplicates,
    final double Function(BuildContext context)? gestureWidth,
    bool? participatesInRootNavigator,
    Object? arguments,
    bool? showCupertinoParallax,
  }) {
    return GetPage(
      participatesInRootNavigator:
          participatesInRootNavigator ?? this.participatesInRootNavigator,
      preventDuplicates: preventDuplicates ?? this.preventDuplicates,
      name: name ?? this.name,
      page: page ?? this.page,
      popGesture: popGesture ?? this.popGesture,
      parameters: parameters ?? this.parameters,
      title: title ?? this.title,
      transition: transition ?? this.transition,
      curve: curve ?? this.curve,
      alignment: alignment ?? this.alignment,
      maintainState: maintainState ?? this.maintainState,
      opaque: opaque ?? this.opaque,
      binding: binding ?? this.binding,
      bindings: bindings ?? this.bindings,
      customTransition: customTransition ?? this.customTransition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      children: children ?? this.children,
      unknownRoute: unknownRoute ?? this.unknownRoute,
      middlewares: middlewares ?? this.middlewares,
      gestureWidth: gestureWidth ?? this.gestureWidth,
      arguments: arguments ?? this.arguments,
      showCupertinoParallax:
          showCupertinoParallax ?? this.showCupertinoParallax,
    );
  }

  late Future<T?> popped;
  @override
  Route<T> createRoute(BuildContext context) {
    final _page = PageRedirect(
      route: this,
      settings: this,
      unknownRoute: unknownRoute,
    ).getPageToRoute<T>(this, unknownRoute);
    popped = _page.popped;
    return _page;
  }
}

class Routing {
  String current;
  String previous;
  dynamic args;
  String removed;
  Route<dynamic>? route;
  bool? isBack;
  bool? isSnackbar;
  bool? isBottomSheet;
  bool? isDialog;
  Routing({
    this.current = '',
    this.previous = '',
    this.args,
    this.removed = '',
    this.route,
    this.isBack,
    this.isSnackbar,
    this.isBottomSheet,
    this.isDialog,
  });
  void update(void fn(Routing value)) {
    fn(this);
  }
}

String? _extractRouteName(Route? route) {
  if (route?.settings.name != null) {
    return route!.settings.name;
  }
  if (route is GetPageRoute) {
    return route.routeName;
  }
  if (route is GetDialogRoute) {
    return 'DIALOG ${route.hashCode}';
  }
  if (route is GetModalBottomSheetRoute) {
    return 'BOTTOMSHEET ${route.hashCode}';
  }
  return null;
}

class _RouteData {
  final bool isGetPageRoute;
  final bool isSnackbar;
  final bool isBottomSheet;
  final bool isDialog;
  final String? name;
  _RouteData({
    required this.name,
    required this.isGetPageRoute,
    required this.isSnackbar,
    required this.isBottomSheet,
    required this.isDialog,
  });
  factory _RouteData.ofRoute(Route? route) {
    return _RouteData(
      name: _extractRouteName(route),
      isGetPageRoute: route is GetPageRoute,
      isSnackbar: route is SnackRoute,
      isDialog: route is GetDialogRoute,
      isBottomSheet: route is GetModalBottomSheetRoute,
    );
  }
}

class GetObserver extends NavigatorObserver {
  final Function(Routing?)? routing;
  GetObserver([this.routing, this._routeSend]);
  final Routing? _routeSend;
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final newRoute = _RouteData.ofRoute(route);
    if (newRoute.isSnackbar) {
      Get.log("OPEN SNACKBAR");
    } else if (newRoute.isBottomSheet || newRoute.isDialog) {
      Get.log("OPEN ${newRoute.name}");
    } else if (newRoute.isGetPageRoute) {
      Get.log("GOING TO ROUTE ${newRoute.name}");
    }
    RouterReportManager.reportCurrentRoute(route);
    _routeSend?.update((value) {
      if (route is PageRoute) {
        value.current = newRoute.name ?? '';
      }
      value.args = route.settings.arguments;
      value.route = route;
      value.isBack = false;
      value.removed = '';
      value.previous = _extractRouteName(previousRoute) ?? '';
      value.isSnackbar = newRoute.isSnackbar ? true : value.isSnackbar ?? false;
      value.isBottomSheet =
          newRoute.isBottomSheet ? true : value.isBottomSheet ?? false;
      value.isDialog = newRoute.isDialog ? true : value.isDialog ?? false;
    });
    if (routing != null) {
      routing!(_routeSend);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final currentRoute = _RouteData.ofRoute(route);
    final newRoute = _RouteData.ofRoute(previousRoute);
    if (currentRoute.isSnackbar) {
      Get.log("CLOSE SNACKBAR");
    } else if (currentRoute.isBottomSheet || currentRoute.isDialog) {
      Get.log("CLOSE ${currentRoute.name}");
    } else if (currentRoute.isGetPageRoute) {
      Get.log("CLOSE TO ROUTE ${currentRoute.name}");
    }
    if (previousRoute != null) {
      RouterReportManager.reportCurrentRoute(previousRoute);
    }
    _routeSend?.update((value) {
      if (previousRoute is PageRoute) {
        value.current = _extractRouteName(previousRoute) ?? '';
      }
      value.args = previousRoute?.settings.arguments;
      value.route = previousRoute;
      value.isBack = true;
      value.removed = '';
      value.previous = newRoute.name ?? '';
      value.isSnackbar = newRoute.isSnackbar;
      value.isBottomSheet = newRoute.isBottomSheet;
      value.isDialog = newRoute.isDialog;
    });
    routing?.call(_routeSend);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = _extractRouteName(newRoute);
    final oldName = _extractRouteName(oldRoute);
    final currentRoute = _RouteData.ofRoute(oldRoute);
    Get.log("REPLACE ROUTE $oldName");
    Get.log("NEW ROUTE $newName");
    if (newRoute != null) {
      RouterReportManager.reportCurrentRoute(newRoute);
    }
    _routeSend?.update((value) {
      if (newRoute is PageRoute) {
        value.current = newName ?? '';
      }
      value.args = newRoute?.settings.arguments;
      value.route = newRoute;
      value.isBack = false;
      value.removed = '';
      value.previous = '$oldName';
      value.isSnackbar = currentRoute.isSnackbar ? false : value.isSnackbar;
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
      value.isDialog = currentRoute.isDialog ? false : value.isDialog;
    });
    if (oldRoute is GetPageRoute) {
      RouterReportManager.reportRouteWillDispose(oldRoute);
    }
    routing?.call(_routeSend);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    final routeName = _extractRouteName(route);
    final currentRoute = _RouteData.ofRoute(route);
    Get.log("REMOVING ROUTE $routeName");
    _routeSend?.update((value) {
      value.route = previousRoute;
      value.isBack = false;
      value.removed = routeName ?? '';
      value.previous = routeName ?? '';
      value.isSnackbar = currentRoute.isSnackbar ? false : value.isSnackbar;
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
      value.isDialog = currentRoute.isDialog ? false : value.isDialog;
    });
    if (route is GetPageRoute) {
      RouterReportManager.reportRouteWillDispose(route);
    }
    routing?.call(_routeSend);
  }
}

mixin PageRouteReportMixin<T> on Route<T> {
  @override
  void install() {
    super.install();
    RouterReportManager.reportCurrentRoute(this);
  }

  @override
  void dispose() {
    super.dispose();
    RouterReportManager.reportRouteDispose(this);
  }
}

class GetPageRoute<T> extends PageRoute<T>
    with GetPageRouteTransitionMixin<T>, PageRouteReportMixin {
  GetPageRoute({
    RouteSettings? settings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.parameter,
    this.gestureWidth,
    this.curve,
    this.alignment,
    this.transition,
    this.popGesture,
    this.customTransition,
    this.barrierDismissible = false,
    this.barrierColor,
    this.binding,
    this.bindings,
    this.routeName,
    this.page,
    this.title,
    this.showCupertinoParallax = true,
    this.barrierLabel,
    this.maintainState = true,
    bool fullscreenDialog = false,
    this.middlewares,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog);
  @override
  final Duration transitionDuration;
  final GetPageBuilder? page;
  final String? routeName;
  final CustomTransition? customTransition;
  final Bindings? binding;
  final Map<String, String>? parameter;
  final List<Bindings>? bindings;
  @override
  final bool showCupertinoParallax;
  @override
  final bool opaque;
  final bool? popGesture;
  @override
  final bool barrierDismissible;
  final Transition? transition;
  final Curve? curve;
  final Alignment? alignment;
  final List<GetMiddleware>? middlewares;
  @override
  final Color? barrierColor;
  @override
  final String? barrierLabel;
  @override
  final bool maintainState;
  @override
  void dispose() {
    super.dispose();
    final middlewareRunner = MiddlewareRunner(middlewares);
    middlewareRunner.runOnPageDispose();
  }

  Widget? _child;
  Widget _getChild() {
    if (_child != null) return _child!;
    final middlewareRunner = MiddlewareRunner(middlewares);
    final localbindings = [
      if (bindings != null) ...bindings!,
      if (binding != null) ...[binding!]
    ];
    final bindingsToBind = middlewareRunner.runOnBindingsStart(localbindings);
    if (bindingsToBind != null) {
      for (final binding in bindingsToBind) {
        binding.dependencies();
      }
    }
    final pageToBuild = middlewareRunner.runOnPageBuildStart(page)!;
    _child = middlewareRunner.runOnPageBuilt(pageToBuild());
    return _child!;
  }

  @override
  Widget buildContent(BuildContext context) {
    return _getChild();
  }

  @override
  final String? title;
  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
  @override
  final double Function(BuildContext context)? gestureWidth;
}

enum PopMode {
  History,
  Page,
}

enum PreventDuplicateHandlingMode {
  PopUntilOriginalRoute,
  DoNothing,
  ReorderRoutes
}

class GetDelegate extends RouterDelegate<GetNavConfig>
    with ListenableMixin, ListNotifierMixin {
  final List<GetNavConfig> history = <GetNavConfig>[];
  final PopMode backButtonPopMode;
  final PreventDuplicateHandlingMode preventDuplicateHandlingMode;
  final GetPage notFoundRoute;
  final List<NavigatorObserver>? navigatorObservers;
  final TransitionDelegate<dynamic>? transitionDelegate;
  GlobalKey<NavigatorState> get navigatorKey => Get.key;
  GetDelegate({
    GetPage? notFoundRoute,
    this.navigatorObservers,
    this.transitionDelegate,
    this.backButtonPopMode = PopMode.History,
    this.preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.ReorderRoutes,
  }) : notFoundRoute = notFoundRoute ??
            GetPage(
              name: '/404',
              page: () => Scaffold(
                body: Text('Route not found'),
              ),
            ) {
    Get.log('GetDelegate is created !');
  }
  Future<GetNavConfig?> runMiddleware(GetNavConfig config) async {
    final middlewares = config.currentTreeBranch.last.middlewares;
    if (middlewares == null) {
      return config;
    }
    var iterator = config;
    for (var item in middlewares) {
      var redirectRes = await item.redirectDelegate(iterator);
      if (redirectRes == null) return null;
      iterator = redirectRes;
    }
    return iterator;
  }

  Future<void> _unsafeHistoryAdd(GetNavConfig config) async {
    final res = await runMiddleware(config);
    if (res == null) return;
    history.add(res);
  }

  Future<void> _unsafeHistoryRemove(GetNavConfig config) async {
    var index = history.indexOf(config);
    if (index >= 0) await _unsafeHistoryRemoveAt(index);
  }

  Future<GetNavConfig?> _unsafeHistoryRemoveAt(int index) async {
    if (index == history.length - 1 && history.length > 1) {
      final toCheck = history[history.length - 2];
      final resMiddleware = await runMiddleware(toCheck);
      if (resMiddleware == null) return null;
      history[history.length - 2] = resMiddleware;
    }
    return history.removeAt(index);
  }

  T arguments<T>() {
    return currentConfiguration?.currentPage?.arguments as T;
  }

  Map<String, String> get parameters {
    return currentConfiguration?.currentPage?.parameters ?? {};
  }

  Future<void> pushHistory(
    GetNavConfig config, {
    bool rebuildStack = true,
  }) async {
    await _pushHistory(config);
    if (rebuildStack) {
      refresh();
    }
  }

  Future<void> _removeHistoryEntry(GetNavConfig entry) async {
    await _unsafeHistoryRemove(entry);
  }

  Future<void> _pushHistory(GetNavConfig config) async {
    if (config.currentPage!.preventDuplicates) {
      final originalEntryIndex =
          history.indexWhere((element) => element.location == config.location);
      if (originalEntryIndex >= 0) {
        switch (preventDuplicateHandlingMode) {
          case PreventDuplicateHandlingMode.PopUntilOriginalRoute:
            await backUntil(config.location!, popMode: PopMode.Page);
            break;
          case PreventDuplicateHandlingMode.ReorderRoutes:
            await _unsafeHistoryRemoveAt(originalEntryIndex);
            await _unsafeHistoryAdd(config);
            break;
          case PreventDuplicateHandlingMode.DoNothing:
          default:
            break;
        }
        return;
      }
    }
    await _unsafeHistoryAdd(config);
  }

  Future<GetNavConfig?> _popHistory() async {
    if (!_canPopHistory()) return null;
    return await _doPopHistory();
  }

  Future<GetNavConfig?> _doPopHistory() async {
    return await _unsafeHistoryRemoveAt(history.length - 1);
  }

  Future<GetNavConfig?> _popPage() async {
    if (!_canPopPage()) return null;
    return await _doPopPage();
  }

  Future<GetNavConfig?> _pop(PopMode mode) async {
    switch (mode) {
      case PopMode.History:
        return await _popHistory();
      case PopMode.Page:
        return await _popPage();
      default:
        return null;
    }
  }

  Future<GetNavConfig?> _doPopPage() async {
    final currentBranch = currentConfiguration?.currentTreeBranch;
    if (currentBranch != null && currentBranch.length > 1) {
      final remaining = currentBranch.take(currentBranch.length - 1);
      final prevHistoryEntry =
          history.length > 1 ? history[history.length - 2] : null;
      if (prevHistoryEntry != null) {
        final newLocation = remaining.last.name;
        final prevLocation = prevHistoryEntry.location;
        if (newLocation == prevLocation) {
          return await _popHistory();
        }
      }
      final res = await _popHistory();
      await _pushHistory(
        GetNavConfig(
          currentTreeBranch: remaining.toList(),
          location: remaining.last.name,
          state: null,
        ),
      );
      return res;
    } else {
      return await _popHistory();
    }
  }

  Future<GetNavConfig?> popHistory() async {
    return await _popHistory();
  }

  bool _canPopHistory() {
    return history.length > 1;
  }

  Future<bool> canPopHistory() {
    return SynchronousFuture(_canPopHistory());
  }

  bool _canPopPage() {
    final currentTreeBranch = currentConfiguration?.currentTreeBranch;
    if (currentTreeBranch == null) return false;
    return currentTreeBranch.length > 1 ? true : _canPopHistory();
  }

  Future<bool> canPopPage() {
    return SynchronousFuture(_canPopPage());
  }

  bool _canPop(PopMode mode) {
    switch (mode) {
      case PopMode.History:
        return _canPopHistory();
      case PopMode.Page:
      default:
        return _canPopPage();
    }
  }

  List<GetPage> getVisualPages() {
    final currentHistory = currentConfiguration;
    if (currentHistory == null) return <GetPage>[];
    final res = currentHistory.currentTreeBranch
        .where((r) => r.participatesInRootNavigator != null);
    if (res.length == 0) {
      return history.map((e) => e.currentPage!).toList();
    } else {
      return res
          .where((element) => element.participatesInRootNavigator == true)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = getVisualPages();
    if (pages.length == 0) return SizedBox.shrink();
    final extraObservers = navigatorObservers;
    return GetNavigator(
      key: navigatorKey,
      onPopPage: _onPopVisualRoute,
      pages: pages,
      observers: [
        GetObserver(),
        if (extraObservers != null) ...extraObservers,
      ],
      transitionDelegate:
          transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
    );
  }

  @override
  Future<void> setNewRoutePath(GetNavConfig configuration) async {
    await pushHistory(configuration);
  }

  @override
  GetNavConfig? get currentConfiguration {
    if (history.isEmpty) return null;
    final route = history.last;
    return route;
  }

  Future<T> toNamed<T>(
    String page, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) async {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    final decoder = Get.routeTree.matchRoute(page, arguments: arguments);
    decoder.replaceArguments(arguments);
    final completer = Completer<T>();
    if (decoder.route != null) {
      _allCompleters[decoder.route!] = completer;
      await pushHistory(
        GetNavConfig(
          currentTreeBranch: decoder.treeBranch,
          location: page,
          state: null,
        ),
      );
      return completer.future;
    } else {
      return Future.value();
    }
  }

  Future<T?>? offAndToNamed<T>(
    String page, {
    dynamic arguments,
    int? id,
    dynamic result,
    Map<String, String>? parameters,
    PopMode popMode = PopMode.History,
  }) async {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    await popRoute(result: result);
    return toNamed(page, arguments: arguments, parameters: parameters);
  }

  Future<T> offNamed<T>(
    String page, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) async {
    history.removeLast();
    return toNamed<T>(page, arguments: arguments, parameters: parameters);
  }

  Future<void> backUntil(
    String fullRoute, {
    PopMode popMode = PopMode.Page,
  }) async {
    var iterator = currentConfiguration;
    while (_canPop(popMode) &&
        iterator != null &&
        iterator.location != fullRoute) {
      await _pop(popMode);
      iterator = currentConfiguration;
    }
    refresh();
  }

  Future<bool> handlePopupRoutes({
    Object? result,
  }) async {
    Route? currentRoute;
    navigatorKey.currentState!.popUntil((route) {
      currentRoute = route;
      return true;
    });
    if (currentRoute is PopupRoute) {
      return await navigatorKey.currentState!.maybePop(result);
    }
    return false;
  }

  @override
  Future<bool> popRoute({
    Object? result,
    PopMode popMode = PopMode.Page,
  }) async {
    final wasPopup = await handlePopupRoutes(result: result);
    if (wasPopup) return true;
    final _popped = await _pop(popMode);
    refresh();
    if (_popped != null) {
      return true;
    }
    return false;
  }

  final _allCompleters = <GetPage, Completer>{};
  bool _onPopVisualRoute(Route<dynamic> route, dynamic result) {
    final didPop = route.didPop(result);
    if (!didPop) {
      return false;
    }
    final settings = route.settings;
    if (settings is GetPage) {
      final config = history.cast<GetNavConfig?>().firstWhere(
            (element) => element?.currentPage == settings,
            orElse: () => null,
          );
      if (config != null) {
        _removeHistoryEntry(config);
      }
      if (_allCompleters.containsKey(settings)) {
        _allCompleters[settings]?.complete(route.popped);
      }
    }
    refresh();
    return true;
  }
}

class GetNavigator extends Navigator {
  GetNavigator({
    GlobalKey<NavigatorState>? key,
    bool Function(Route<dynamic>, dynamic)? onPopPage,
    required List<Page> pages,
    List<NavigatorObserver>? observers,
    bool reportsRouteUpdateToEngine = false,
    TransitionDelegate? transitionDelegate,
  }) : super(
          key: key,
          onPopPage: onPopPage ??
              (route, result) {
                final didPop = route.didPop(result);
                if (!didPop) {
                  return false;
                }
                return true;
              },
          reportsRouteUpdateToEngine: reportsRouteUpdateToEngine,
          pages: pages,
          observers: [
            if (observers != null) ...observers,
          ],
          transitionDelegate:
              transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
        );
}

class GetInformationParser extends RouteInformationParser<GetNavConfig> {
  final String initialRoute;
  GetInformationParser({
    this.initialRoute = '/',
  }) {
    Get.log('GetInformationParser is created !');
  }
  @override
  SynchronousFuture<GetNavConfig> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    print('GetInformationParser: route location: ${routeInformation.location}');
    var location = routeInformation.location;
    if (location == '/') {
      if (!Get.routeTree.routes.any((element) => element.name == '/')) {
        location = initialRoute;
      }
    }
    final matchResult = Get.routeTree.matchRoute(location ?? initialRoute);
    return SynchronousFuture(
      GetNavConfig(
        currentTreeBranch: matchResult.treeBranch,
        location: location,
        state: routeInformation.state,
      ),
    );
  }

  @override
  RouteInformation restoreRouteInformation(GetNavConfig config) {
    return RouteInformation(
      location: config.location,
      state: config.state,
    );
  }
}

class RouterOutlet<TDelegate extends RouterDelegate<T>, T extends Object>
    extends StatefulWidget {
  final TDelegate routerDelegate;
  final Widget Function(
    BuildContext context,
    TDelegate delegate,
    T? currentRoute,
  ) builder;
  RouterOutlet.builder({
    TDelegate? delegate,
    required this.builder,
  })  : routerDelegate = delegate ?? Get.delegate<TDelegate, T>()!,
        super();
  RouterOutlet({
    TDelegate? delegate,
    required Iterable<GetPage> Function(T currentNavStack) pickPages,
    required Widget Function(
      BuildContext context,
      TDelegate,
      Iterable<GetPage>? page,
    )
        pageBuilder,
  }) : this.builder(
          builder: (context, rDelegate, currentConfig) {
            var picked =
                currentConfig == null ? null : pickPages(currentConfig);
            if (picked?.length == 0) {
              picked = null;
            }
            return pageBuilder(context, rDelegate, picked);
          },
          delegate: delegate,
        );
  @override
  _RouterOutletState<TDelegate, T> createState() =>
      _RouterOutletState<TDelegate, T>();
}

class _RouterOutletState<TDelegate extends RouterDelegate<T>, T extends Object>
    extends State<RouterOutlet<TDelegate, T>> {
  TDelegate get delegate => widget.routerDelegate;
  @override
  void initState() {
    super.initState();
    _getCurrentRoute();
    delegate.addListener(onRouterDelegateChanged);
  }

  @override
  void dispose() {
    delegate.removeListener(onRouterDelegateChanged);
    super.dispose();
  }

  T? currentRoute;
  void _getCurrentRoute() {
    currentRoute = delegate.currentConfiguration;
  }

  void onRouterDelegateChanged() {
    setState(_getCurrentRoute);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, delegate, currentRoute);
  }
}

class GetRouterOutlet extends RouterOutlet<GetDelegate, GetNavConfig> {
  GetRouterOutlet({
    String? anchorRoute,
    required String initialRoute,
    Iterable<GetPage> Function(Iterable<GetPage> afterAnchor)? filterPages,
    GlobalKey<NavigatorState>? key,
    GetDelegate? delegate,
  }) : this.pickPages(
          pickPages: (config) {
            Iterable<GetPage<dynamic>> ret;
            if (anchorRoute == null) {
              final length = Uri.parse(initialRoute).pathSegments.length;
              return config.currentTreeBranch
                  .skip(length)
                  .take(length)
                  .toList();
            }
            ret = config.currentTreeBranch.pickAfterRoute(anchorRoute);
            if (filterPages != null) {
              ret = filterPages(ret);
            }
            return ret;
          },
          emptyPage: (delegate) =>
              Get.routeTree.matchRoute(initialRoute).route ??
              delegate.notFoundRoute,
          key: key,
          delegate: delegate,
        );
  GetRouterOutlet.pickPages({
    Widget Function(GetDelegate delegate)? emptyWidget,
    GetPage Function(GetDelegate delegate)? emptyPage,
    required Iterable<GetPage> Function(GetNavConfig currentNavStack) pickPages,
    bool Function(Route<dynamic>, dynamic)? onPopPage,
    GlobalKey<NavigatorState>? key,
    GetDelegate? delegate,
  }) : super(
          pageBuilder: (context, rDelegate, pages) {
            final pageRes = <GetPage?>[
              ...?pages,
              if (pages == null || pages.length == 0)
                emptyPage?.call(rDelegate),
            ].whereType<GetPage>();
            if (pageRes.length > 0) {
              return GetNavigator(
                onPopPage: onPopPage ??
                    (route, result) {
                      final didPop = route.didPop(result);
                      if (!didPop) {
                        return false;
                      }
                      return true;
                    },
                pages: pageRes.toList(),
                key: key,
              );
            }
            return (emptyWidget?.call(rDelegate) ?? SizedBox.shrink());
          },
          pickPages: pickPages,
          delegate: delegate ?? Get.rootDelegate,
        );
  GetRouterOutlet.builder({
    required Widget Function(
      BuildContext context,
      GetDelegate delegate,
      GetNavConfig? currentRoute,
    )
        builder,
    GetDelegate? routerDelegate,
  }) : super.builder(
          builder: builder,
          delegate: routerDelegate,
        );
}

extension PagesListExt on List<GetPage> {
  Iterable<GetPage> pickAtRoute(String route) {
    return skipWhile((value) {
      return value.name != route;
    });
  }

  Iterable<GetPage> pickAfterRoute(String route) {
    return pickAtRoute(route).skip(1);
  }
}

class GetNavConfig extends RouteInformation {
  final List<GetPage> currentTreeBranch;
  GetPage? get currentPage => currentTreeBranch.last;
  GetNavConfig({
    required this.currentTreeBranch,
    required String? location,
    required Object? state,
  }) : super(
          location: location,
          state: state,
        );
  GetNavConfig copyWith({
    List<GetPage>? currentTreeBranch,
    required String? location,
    required Object? state,
  }) {
    return GetNavConfig(
      currentTreeBranch: currentTreeBranch ?? this.currentTreeBranch,
      location: location ?? this.location,
      state: state ?? this.state,
    );
  }

  static GetNavConfig? fromRoute(String route) {
    final res = Get.routeTree.matchRoute(route);
    if (res.treeBranch.isEmpty) return null;
    return GetNavConfig(
      currentTreeBranch: res.treeBranch,
      location: route,
      state: null,
    );
  }

  @override
  String toString() =>
      ''' ======GetNavConfig=====\ncurrentTreeBranch: $currentTreeBranch\ncurrentPage: $currentPage\n======GetNavConfig=====''';
}

extension GetResetExt on GetInterface {
  void reset(
      {@deprecated bool clearFactory = true, bool clearRouteBindings = true}) {
    GetInstance().resetInstance(clearRouteBindings: clearRouteBindings);
    Get.clearRouteTree();
    Get.clearTranslations();
    Get.resetRootNavigator();
  }
}

abstract class GetInterface {
  SmartManagement smartManagement = SmartManagement.full;
  RouterDelegate? routerDelegate;
  RouteInformationParser? routeInformationParser;
  bool isLogEnable = true;
  LogWriterCallback log = defaultLogWriterCallback;
}

typedef ValueUpdater<T> = T Function();

class _GetImpl extends GetInterface {}

final Get = _GetImpl();
typedef LogWriterCallback = void Function(String text, {bool isError});
void defaultLogWriterCallback(String value, {bool isError = false}) {
  if (isError || Get.isLogEnable) dev.log(value, name: 'GETX');
}

enum SmartManagement {
  full,
  onlyBuilder,
  keepFactory,
}

extension PercentSized on double {
  double get hp => (Get.height * (this / 100));
  double get wp => (Get.width * (this / 100));
}
