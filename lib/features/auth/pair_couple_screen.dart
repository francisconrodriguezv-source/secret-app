import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/gradient_button.dart';

/// Pantalla de emparejamiento con la pareja. Se muestra cuando el usuario
/// está autenticado pero aún no está en ningún couple (`appUser.coupleId
/// == null`).
///
/// Dos modos, elegidos por tabs:
/// - **Crear código**: crea el couple + genera un código de 6 dígitos y
///   lo muestra para compartir. Cuando la pareja lo ingresa, este
///   dispositivo automáticamente avanza (via [AuthGate]).
/// - **Ingresar código**: pide un código, valida, y une al usuario al
///   couple que lo creó.
class PairCoupleScreen extends StatefulWidget {
  const PairCoupleScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<PairCoupleScreen> createState() => _PairCoupleScreenState();
}

enum _PairMode { create, enter }

class _PairCoupleScreenState extends State<PairCoupleScreen> {
  _PairMode _mode = _PairMode.create;
  final _authService = AuthService();
  final _coupleService = CoupleService();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: CozyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: CozyColors.onSurface,
        actions: [
          IconButton(
            tooltip: l.authLogout,
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CozySpacing.stackGapMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.pairTitle, style: CozyTypography.headlineLgMobile),
              const SizedBox(height: 6),
              Text(
                l.pairSubtitle,
                style: CozyTypography.bodyMd.copyWith(
                  color: CozyColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: CozySpacing.stackGapMd),
              _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: CozySpacing.stackGapMd),
              Expanded(
                child: _mode == _PairMode.create
                    ? _CreateFlow(
                        appUser: widget.appUser,
                        coupleService: _coupleService,
                      )
                    : _EnterFlow(
                        appUser: widget.appUser,
                        coupleService: _coupleService,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _PairMode mode;
  final ValueChanged<_PairMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CozyColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _Segment(
            label: l.pairCreateCode,
            active: mode == _PairMode.create,
            onTap: () => onChanged(_PairMode.create),
          ),
          _Segment(
            label: l.pairEnterCode,
            active: mode == _PairMode.enter,
            onTap: () => onChanged(_PairMode.enter),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? CozyColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: CozyTypography.labelMd.copyWith(
                color: active
                    ? CozyColors.onPrimaryContainer
                    : CozyColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Flujo "Crear código"
// -----------------------------------------------------------------------------

class _CreateFlow extends StatefulWidget {
  const _CreateFlow({required this.appUser, required this.coupleService});

  final AppUser appUser;
  final CoupleService coupleService;

  @override
  State<_CreateFlow> createState() => _CreateFlowState();
}

class _CreateFlowState extends State<_CreateFlow> {
  bool _busy = false;
  String? _code;
  String? _coupleId;
  DateTime? _expiresAt;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _finalizing = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _createAndGenerate() async {
    setState(() => _busy = true);
    try {
      // Si el usuario ya tiene coupleId (por si se recarga la pantalla),
      // sólo generamos código sin crear couple nuevo.
      String coupleId = widget.appUser.coupleId ?? '';
      if (coupleId.isEmpty) {
        coupleId = await widget.coupleService.createCouple(
          creatorUid: widget.appUser.uid,
          creatorDisplayName: widget.appUser.displayName,
        );
      }
      final code = await widget.coupleService.generateInviteCode(coupleId);
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      setState(() {
        _code = code;
        _coupleId = coupleId;
        _expiresAt = expiresAt;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.authGenericError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final expires = _expiresAt;
    if (expires == null) return;
    final left = expires.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _secondsLeft = 0;
          _code = null;
          _expiresAt = null;
        });
      }
    } else {
      if (mounted) setState(() => _secondsLeft = left);
    }
  }

  Future<void> _copyCode() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.pairCodeCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_code == null) {
      return _EmptyPanel(
        title: l.pairCreateCode,
        body: l.pairCreateBody,
        cta: _busy
            ? const CircularProgressIndicator()
            : GradientButton(
                label: l.pairCreateCode,
                icon: Icons.qr_code_2_rounded,
                onPressed: _createAndGenerate,
              ),
      );
    }

    // Cuando el código existe, escuchamos su doc para detectar cuando
    // la pareja lo consumió. En ese momento escribimos
    // `users/{creator}.coupleId = coupleId` (via `finalizeCoupleForCreator`)
    // — sólo entonces el AuthGate hará `hasCouple==true` y navegará a
    // HomeShell. Mientras tanto seguimos mostrando el código.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('invite_codes')
          .doc(_code)
          .snapshots(),
      builder: (context, snapshot) {
        final consumed = snapshot.data?.data()?['consumedBy'] != null;
        if (consumed && !_finalizing && _coupleId != null) {
          _finalizing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.coupleService.finalizeCoupleForCreator(
              creatorUid: widget.appUser.uid,
              coupleId: _coupleId!,
            );
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Text(
              l.pairGeneratedLabel,
              style: CozyTypography.bodyMd.copyWith(
                color: CozyColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _BigCodeDisplay(code: _code!),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l.pairInviteExpires.replaceAll(
                  '{minutes}',
                  ((_secondsLeft + 59) ~/ 60).toString(),
                ),
                style: CozyTypography.labelMd.copyWith(
                  color: CozyColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyCode,
              icon: const Icon(Icons.copy_all_outlined),
              label: Text(l.pairCopyCode),
            ),
            const SizedBox(height: 16),
            if (consumed)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.pairWaitingForPartner,
                    style: CozyTypography.bodyMd.copyWith(
                      color: CozyColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Muestra el código de 6 dígitos con celdas grandes tipo "OTP".
class _BigCodeDisplay extends StatelessWidget {
  const _BigCodeDisplay({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final digits = code.padRight(6).substring(0, 6).split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final d in digits)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 44,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CozyColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CozyColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                d.trim().isEmpty ? '-' : d,
                style: CozyTypography.headlineLg.copyWith(
                  color: CozyColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Flujo "Ingresar código"
// -----------------------------------------------------------------------------

class _EnterFlow extends StatefulWidget {
  const _EnterFlow({required this.appUser, required this.coupleService});

  final AppUser appUser;
  final CoupleService coupleService;

  @override
  State<_EnterFlow> createState() => _EnterFlowState();
}

class _EnterFlowState extends State<_EnterFlow> {
  final _codeCtl = TextEditingController();
  bool _busy = false;
  String? _errorText;

  @override
  void dispose() {
    _codeCtl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtl.text.trim();
    if (code.length != 6) {
      setState(() => _errorText = context.l10n.authRequired);
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      await widget.coupleService.joinCoupleWithCode(
        code: code,
        joinerUid: widget.appUser.uid,
        joinerDisplayName: widget.appUser.displayName,
      );
      // AuthGate detectará que appUser.coupleId cambió → HomeShell.
    } catch (e) {
      if (!mounted) return;
      final l = context.l10n;
      final code = e.toString();
      String msg;
      if (code.contains('invite_not_found')) {
        msg = l.pairErrorNotFound;
      } else if (code.contains('invite_expired')) {
        msg = l.pairErrorExpired;
      } else if (code.contains('invite_already_used')) {
        msg = l.pairErrorAlreadyUsed;
      } else if (code.contains('couple_full')) {
        msg = l.pairErrorFull;
      } else {
        msg = l.pairErrorGeneric;
      }
      setState(() => _errorText = msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _EmptyPanel(
      title: l.pairEnterCode,
      body: l.pairEnterBody,
      cta: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtl,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: CozyTypography.headlineLg.copyWith(
              letterSpacing: 8,
              color: CozyColors.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: l.pairCodeHint,
              hintStyle: CozyTypography.bodyMd.copyWith(
                letterSpacing: 0,
                color: CozyColors.outline,
              ),
              counterText: '',
              filled: true,
              fillColor: CozyColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: CozyTypography.labelMd.copyWith(color: CozyColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          GradientButton(
            label: l.pairJoin,
            icon: Icons.link,
            onPressed: _busy ? null : _join,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Panel visual reutilizado por ambos flujos.
// -----------------------------------------------------------------------------

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.body,
    required this.cta,
  });

  final String title;
  final String body;
  final Widget cta;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CozyColors.primaryContainer,
                    CozyColors.secondaryContainer,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.favorite,
                color: CozyColors.primary,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapMd),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CozyTypography.headlineMd,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: CozyTypography.bodyMd.copyWith(
              color: CozyColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          cta,
        ],
      ),
    );
  }
}
