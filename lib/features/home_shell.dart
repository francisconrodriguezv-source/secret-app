import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../services/fcm_service.dart';
import '../services/poke_service.dart';
import '../state/app_scope.dart';
import '../theme/cozy_colors.dart';
import '../widgets/cozy_bottom_nav.dart';
import '../widgets/cozy_top_bar.dart';
import 'calendar/calendar_screen.dart';
import 'create/create_moment_screen.dart';
import 'message_board/message_board_screen.dart';
import 'profile/profile_screen.dart';
import 'timeline/timeline_screen.dart';
import 'vault/vault_screen.dart';

/// Scaffold principal con las 4 tabs de la app (Timeline, Vault, Calendar,
/// Profile). El botón central "Create" abre `CreateMomentScreen` como
/// pantalla modal (push route). Message Board se accede desde el Profile.
///
/// Al crear, enlaza el [AppState] al `coupleId` del [appUser] para que
/// las colecciones (moments, notes, events, milestones) se sincronicen
/// via Firestore streams entre ambos miembros del couple.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  CozyNavDestination _current = CozyNavDestination.timeline;
  final _fcmService = FcmService();
  final _pokeService = PokeService();

  @override
  void initState() {
    super.initState();
    // Enlazar Firestore después del primer frame para tener acceso al
    // [AppScope] (no está disponible en initState directamente).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppScope.read(context);
      final coupleId = widget.appUser.coupleId;
      if (coupleId != null && coupleId.isNotEmpty) {
        state.bindCouple(coupleId: coupleId, currentUid: widget.appUser.uid);
      }
      // Inicializar FCM (registra token en users/{uid} para recibir
      // push cuando la pareja crea moments/notes o envía "pensando en ti").
      _fcmService.initialize(uid: widget.appUser.uid);
    });
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final coupleId = widget.appUser.coupleId;
    if (coupleId != null &&
        coupleId.isNotEmpty &&
        (oldWidget.appUser.coupleId != coupleId ||
            oldWidget.appUser.uid != widget.appUser.uid)) {
      final state = AppScope.read(context);
      state.bindCouple(coupleId: coupleId, currentUid: widget.appUser.uid);
    }
  }

  @override
  void dispose() {
    _fcmService.dispose();
    super.dispose();
  }

  int get _indexForStack {
    switch (_current) {
      case CozyNavDestination.timeline:
        return 0;
      case CozyNavDestination.vault:
        return 1;
      case CozyNavDestination.calendar:
        return 2;
      case CozyNavDestination.profile:
        return 3;
      case CozyNavDestination.create:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: CozyColors.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: CozyTopBar(topPadding: topPadding, onHeartTap: _sendThinking),
      body: IndexedStack(
        index: _indexForStack,
        children: [
          const TimelineScreen(),
          VaultScreen(onUploadTap: _openCreate),
          const CalendarScreen(),
          ProfileScreen(onMessageBoard: _openMessageBoard),
        ],
      ),
      bottomNavigationBar: CozyBottomNav(
        current: _current,
        onDestinationSelected: (dest) {
          if (dest == CozyNavDestination.create) {
            _openCreate();
          } else {
            setState(() => _current = dest);
          }
        },
      ),
    );
  }

  Future<void> _openCreate() {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const CreateMomentScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final offset =
              Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
      ),
    );
  }

  void _openMessageBoard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessageBoardScreen()));
  }

  /// Envía una notificación "[nombre] está pensando en ti" a la pareja.
  /// Escribe un doc en `couples/{coupleId}/pokes/`; una Cloud Function
  /// se encarga de mandar el FCM push al otro miembro y borrar el doc.
  Future<void> _sendThinking() async {
    final state = AppScope.read(context);
    final l = context.l10n;
    final coupleId = state.coupleId;
    final uid = state.currentUid;
    if (coupleId == null || uid == null) return;
    // El nombre del emisor es el del usuario actual (displayName del
    // AppUser, más confiable que couple.nameA/B en un dispositivo
    // que no siempre sabe qué rol tiene).
    final sender = widget.appUser.displayName.isNotEmpty
        ? widget.appUser.displayName
        : l.thinkingAnonymous;
    try {
      await _pokeService.send(
        coupleId: coupleId,
        fromUid: uid,
        fromName: sender,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.authGenericError)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.thinkingSentToast),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
      ),
    );
  }
}
