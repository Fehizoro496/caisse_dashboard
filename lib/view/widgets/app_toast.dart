import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// Nature du retour d'action : décide la couleur et l'icône, rien d'autre.
enum AppToastType { success, error, warning, info }

/// Toasts empilés en bas à droite — la convention Windows.
///
/// Appelable depuis n'importe où (contrôleur, service) sans `BuildContext` :
/// la pile vit dans l'overlay racine et se sert des jetons du thème courant.
/// Sans overlay monté (tests, tout début du démarrage) l'appel est ignoré.
///
/// ```dart
/// AppToast.success('Exportation effectuée', message: path);
/// AppToast.error('Importation impossible', message: '$e');
/// ```
class AppToast {
  AppToast._();

  /// Au-delà, les plus anciens sortent : une pile qui déborde ne se lit plus.
  static const int _maxVisible = 4;

  static final List<_ToastData> _items = [];
  static final ValueNotifier<int> _revision = ValueNotifier(0);
  static OverlayEntry? _entry;
  static int _seq = 0;

  static void success(String title, {String? message, Duration? duration}) =>
      show(
        title: title,
        message: message,
        duration: duration,
        type: AppToastType.success,
      );

  static void error(String title, {String? message, Duration? duration}) =>
      show(
        title: title,
        message: message,
        // Une erreur qu'on n'a pas eu le temps de lire n'a servi à rien.
        duration: duration ?? const Duration(seconds: 7),
        type: AppToastType.error,
      );

  static void warning(String title, {String? message, Duration? duration}) =>
      show(
        title: title,
        message: message,
        duration: duration,
        type: AppToastType.warning,
      );

  static void info(String title, {String? message, Duration? duration}) => show(
    title: title,
    message: message,
    duration: duration,
    type: AppToastType.info,
  );

  static void show({
    required String title,
    String? message,
    AppToastType type = AppToastType.info,
    Duration? duration,
  }) {
    final data = _ToastData(
      id: _seq++,
      type: type,
      title: title,
      message: message,
      duration: duration ?? const Duration(seconds: 4),
    );
    _afterBuild(() {
      if (!_mount()) return;
      _items.add(data);
      // On ne retire pas de force : on demande la sortie, l'animation suit.
      final excess = _items.where((i) => !i.closing.value).length - _maxVisible;
      for (var i = 0, dropped = 0; i < _items.length && dropped < excess; i++) {
        if (_items[i].closing.value) continue;
        _items[i].closing.value = true;
        dropped++;
      }
      _revision.value++;
    });
  }

  /// Vide la pile (changement d'écran, action annulée).
  static void dismissAll() {
    for (final i in _items) {
      i.closing.value = true;
    }
  }

  static bool _mount() {
    if (_entry != null) return true;
    final overlay = _overlay();
    if (overlay == null || !overlay.mounted) return false;
    _entry = OverlayEntry(builder: (_) => const _ToastStack());
    overlay.insert(_entry!);
    return true;
  }

  /// L'overlay du navigator racine. `Overlay.maybeOf(Get.overlayContext)` ne
  /// le trouve pas — le contexte exposé par GetX est déjà à l'intérieur de
  /// l'overlay, hors de portée de la remontée d'ancêtres.
  static OverlayState? _overlay() {
    final direct = Get.key.currentState?.overlay;
    if (direct != null) return direct;
    final context = Get.overlayContext;
    return context == null ? null : Overlay.maybeOf(context, rootOverlay: true);
  }

  static void _remove(int id) {
    _items.removeWhere((i) => i.id == id);
    if (_items.isEmpty) {
      _entry?.remove();
      _entry = null;
      return;
    }
    _revision.value++;
  }

  /// Un toast part souvent d'un `catch` déclenché pendant une frame : on
  /// attend qu'elle soit finie avant de toucher à l'overlay.
  static void _afterBuild(VoidCallback fn) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final building =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (building) {
      WidgetsBinding.instance.addPostFrameCallback((_) => fn());
    } else {
      fn();
    }
  }
}

class _ToastData {
  _ToastData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.duration,
  });

  final int id;
  final AppToastType type;
  final String title;
  final String? message;
  final Duration duration;

  /// Passe à `true` quand la sortie est demandée de l'extérieur.
  final ValueNotifier<bool> closing = ValueNotifier(false);
}

class _ToastStack extends StatelessWidget {
  const _ToastStack();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 20,
      // Hors de tout Scaffold, l'overlay n'a pas de Material : sans lui les
      // textes tombent sur le style de secours souligné de jaune.
      child: Material(
        type: MaterialType.transparency,
        child: ValueListenableBuilder<int>(
          valueListenable: AppToast._revision,
          builder: (context, _, __) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final data in AppToast._items)
                _ToastCard(
                  key: ValueKey(data.id),
                  data: data,
                  onRemove: () => AppToast._remove(data.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    super.key,
    required this.data,
    required this.onRemove,
  });

  final _ToastData data;
  final VoidCallback onRemove;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 180),
  );

  /// Compte le temps restant : sert la barre de vie et déclenche la sortie.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: widget.data.duration,
  );

  late final Animation<double> _in = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  bool _leaving = false;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _anim.forward();
    _life.forward();
    _life.addStatusListener(_onLifeEnd);
    widget.data.closing.addListener(_onCloseRequested);
  }

  void _onLifeEnd(AnimationStatus s) {
    if (s == AnimationStatus.completed) _leave();
  }

  void _onCloseRequested() {
    if (widget.data.closing.value) _leave();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    _life.stop();
    try {
      await _anim.reverse().orCancel;
    } catch (_) {
      return; // Widget démonté en cours de sortie : plus rien à retirer.
    }
    if (mounted) widget.onRemove();
  }

  void _setHover(bool value) {
    if (_leaving) return;
    setState(() => _hover = value);
    // Survoler, c'est lire : on suspend le compte à rebours.
    if (value) {
      _life.stop();
    } else {
      _life.forward();
    }
  }

  @override
  void dispose() {
    widget.data.closing.removeListener(_onCloseRequested);
    _life.removeStatusListener(_onLifeEnd);
    _life.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _in,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _in,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.22, 0),
            end: Offset.zero,
          ).animate(_in),
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final accent = switch (widget.data.type) {
      AppToastType.success => t.success,
      AppToastType.error => t.danger,
      AppToastType.warning => t.warning,
      AppToastType.info => t.accent,
    };
    final icon = switch (widget.data.type) {
      AppToastType.success => Icons.check_rounded,
      AppToastType.error => Icons.priority_high_rounded,
      AppToastType.warning => Icons.warning_amber_rounded,
      AppToastType.info => Icons.info_outline_rounded,
    };

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 372,
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: _hover ? t.lineStrong : t.line),
          borderRadius: t.br,
          boxShadow: t.shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Le filet coloré porte le sens ; le fond reste neutre.
                  Container(width: 3, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(icon, size: 14, color: accent),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    widget.data.title,
                                    style: x.cardTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.data.message != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.data.message!,
                                    style: x.bodyMuted.copyWith(height: 1.45),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CloseButton(onTap: _leave),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _LifeBar(life: _life, color: accent, track: t.line),
          ],
        ),
      ),
    );
  }
}

/// Barre de vie : dit combien de temps il reste, se fige au survol.
class _LifeBar extends StatelessWidget {
  const _LifeBar({
    required this.life,
    required this.color,
    required this.track,
  });

  final Animation<double> life;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: ColoredBox(
        color: track,
        child: AnimatedBuilder(
          animation: life,
          builder: (context, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 1 - life.value,
              heightFactor: 1,
              child: ColoredBox(color: color.withValues(alpha: .55)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hover ? t.surfaceAlt : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 13,
            color: _hover ? t.text : t.faint,
          ),
        ),
      ),
    );
  }
}
