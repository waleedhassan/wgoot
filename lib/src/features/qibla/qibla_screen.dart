import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_text.dart';
import '../../data/models/city.dart';
import '../../data/qibla.dart';
import '../../settings/settings_controller.dart';
import 'compass_sensor.dart';

/// Within this many degrees of the bearing the user counts as facing the Qibla.
const double kQiblaTolerance = 3;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, this.sensor = const CompassSensor()});

  static const String routeName = '/qibla';

  final CompassSensor sensor;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

enum _CompassState { checking, live, unavailable }

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  StreamSubscription<CompassReading>? _subscription;
  _CompassState _state = _CompassState.checking;
  CompassAccuracy _accuracy = CompassAccuracy.high;

  /// Smoothed true heading, left unwrapped so the dial never spins the long
  /// way round when it crosses north.
  double? _heading;
  bool _wasAligned = false;

  City? _qiblaCity;
  late QiblaInfo _qibla;

  /// Readings arrive many times a second; the magnetic model only needs
  /// evaluating again when the city changes.
  QiblaInfo _qiblaFor(City city) {
    if (city != _qiblaCity) {
      _qiblaCity = city;
      _qibla = QiblaInfo.forCity(city);
    }
    return _qibla;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state != _CompassState.live) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _listen();
    } else if (state == AppLifecycleState.paused) {
      unawaited(_subscription?.cancel());
      _subscription = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _start() async {
    final bool available = await widget.sensor.isAvailable();
    if (!mounted) {
      return;
    }
    setState(() {
      _state = available ? _CompassState.live : _CompassState.unavailable;
    });
    if (available) {
      _listen();
    }
  }

  void _listen() {
    _subscription ??= widget.sensor.readings().listen(
      _onReading,
      onError: (Object _) {
        if (mounted) {
          setState(() => _state = _CompassState.unavailable);
        }
      },
    );
  }

  void _onReading(CompassReading reading) {
    if (!mounted) {
      return;
    }
    final QiblaInfo qibla = _qiblaFor(context.read<SettingsController>().city);
    final double target = reading.magneticHeading + qibla.declination;
    final double? previous = _heading;
    final double heading = previous == null
        ? normalizeDegrees(target)
        : previous + 0.3 * angleBetween(previous, target);

    final bool aligned =
        !qibla.isAtKaaba &&
        angleBetween(heading, qibla.bearing).abs() <= kQiblaTolerance;
    if (aligned && !_wasAligned) {
      unawaited(HapticFeedback.mediumImpact());
    }
    setState(() {
      _heading = heading;
      _accuracy = reading.accuracy;
      _wasAligned = aligned;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final City city = settings.city;
    final QiblaInfo qibla = _qiblaFor(city);
    final bool live = _state == _CompassState.live && _heading != null;
    final double heading = live ? _heading! : 0;
    final double offset = angleBetween(heading, qibla.bearing);
    final bool aligned =
        live && !qibla.isAtKaaba && offset.abs() <= kQiblaTolerance;

    return Scaffold(
      appBar: AppBar(title: const Text('اتجاه القبلة')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: <Widget>[
          if (_state == _CompassState.unavailable)
            const _Hint(
              icon: Icons.explore_off_rounded,
              message:
                  'لا تتوفر بوصلة في هذا الجهاز. وجّه أعلى الشاشة نحو الشمال '
                  'الجغرافي، ثم اتجه حيث يشير السهم.',
            )
          else if (live && _accuracy.index <= CompassAccuracy.low.index)
            const _Hint(
              icon: Icons.screen_rotation_alt_rounded,
              message:
                  'البوصلة تحتاج إلى معايرة: حرّك الجهاز في الهواء على شكل '
                  'الرقم ٨ عدة مرات، وأبعده عن المعادن والمغناطيس.',
            ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 1,
                child: _QiblaCompass(
                  heading: heading,
                  bearing: qibla.bearing,
                  showNeedle: !qibla.isAtKaaba,
                  aligned: aligned,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Status(
            qibla: qibla,
            state: _state,
            live: live,
            offset: offset,
            aligned: aligned,
          ),
          const SizedBox(height: 20),
          _Details(city: city, qibla: qibla),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
            child: Text(
              'يُحسب الاتجاه من إحداثيات ${city.name} بأقصر طريق على سطح '
              'الأرض. للحصول على أدق نتيجة ضع الجهاز أفقياً بعيداً عن المعادن '
              'والأجهزة الكهربائية.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.qibla,
    required this.state,
    required this.live,
    required this.offset,
    required this.aligned,
  });

  final QiblaInfo qibla;
  final _CompassState state;
  final bool live;
  final double offset;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;

    final String title;
    String? subtitle;
    if (qibla.isAtKaaba) {
      title = 'أنت في مكة المكرمة';
      subtitle = 'استقبل عين الكعبة المشرّفة.';
    } else if (!live) {
      title =
          '${formatDegrees(qibla.bearing)} ${compassPointName(qibla.bearing)}';
      subtitle = state != _CompassState.unavailable
          ? 'جارٍ تشغيل البوصلة…'
          : 'مقيسة من الشمال الجغرافي باتجاه عقارب الساعة.';
    } else if (aligned) {
      title = 'أنت متّجه إلى القبلة';
      subtitle = 'الكعبة المشرّفة أمامك مباشرة.';
    } else {
      final String side = offset > 0 ? 'يميناً' : 'يساراً';
      title = 'استدر $side ${formatDegrees(offset.abs())}';
      subtitle = 'حتى يستقر السهم أعلى البوصلة.';
    }

    return Column(
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: aligned ? palette.gold : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.city, required this.qibla});

  final City city;
  final QiblaInfo qibla;

  @override
  Widget build(BuildContext context) {
    final double declination = qibla.declination;
    final String declinationSide = declination >= 0 ? 'شرقاً' : 'غرباً';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: <Widget>[
            _Line(
              icon: Icons.location_on_outlined,
              label: 'المدينة',
              value: '${city.name} · ${city.country}',
            ),
            if (!qibla.isAtKaaba) ...<Widget>[
              const Divider(),
              _Line(
                icon: Icons.explore_outlined,
                label: 'زاوية القبلة',
                value:
                    '${formatDegrees(qibla.bearing)} — '
                    '${compassPointName(qibla.bearing)}',
              ),
              const Divider(),
              _Line(
                icon: Icons.straighten_rounded,
                label: 'المسافة إلى الكعبة',
                value: '${formatDistanceKm(qibla.distanceKm)} كم',
              ),
            ],
            const Divider(),
            _Line(
              icon: Icons.compass_calibration_outlined,
              label: 'الانحراف المغناطيسي',
              value:
                  '${formatDegrees(declination.abs(), fractionDigits: 1)} '
                  '$declinationSide',
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.goldSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: palette.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaCompass extends StatelessWidget {
  const _QiblaCompass({
    required this.heading,
    required this.bearing,
    required this.showNeedle,
    required this.aligned,
  });

  /// Unwrapped true heading the top of the screen faces.
  final double heading;
  final double bearing;
  final bool showNeedle;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    final Color accent = aligned ? palette.gold : theme.colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedRotation(
          turns: -heading / 360,
          duration: const Duration(milliseconds: 160),
          child: CustomPaint(
            painter: _DialPainter(
              bearing: bearing,
              showNeedle: showNeedle,
              face: palette.cardGradientStart,
              faceEdge: palette.cardGradientEnd,
              ring: aligned ? palette.gold : palette.divider,
              tick: theme.colorScheme.onSurfaceVariant,
              north: theme.colorScheme.error,
              label: theme.colorScheme.onSurface,
              needle: accent,
              kaaba: theme.colorScheme.onSurface,
              kaabaBand: palette.gold,
            ),
          ),
        ),
        CustomPaint(painter: _LubberPainter(color: accent)),
      ],
    );
  }
}

/// The rotating dial: ticks, cardinal letters and the needle to the Kaaba.
class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.bearing,
    required this.showNeedle,
    required this.face,
    required this.faceEdge,
    required this.ring,
    required this.tick,
    required this.north,
    required this.label,
    required this.needle,
    required this.kaaba,
    required this.kaabaBand,
  });

  final double bearing;
  final bool showNeedle;
  final Color face;
  final Color faceEdge;
  final Color ring;
  final Color tick;
  final Color north;
  final Color label;
  final Color needle;
  final Color kaaba;
  final Color kaabaBand;

  static const List<String> _cardinals = <String>['ش', 'ق', 'ج', 'غ'];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = _dialRadius(size);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[face, faceEdge],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ring,
    );

    final Paint tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = tick;
    for (int degree = 0; degree < 360; degree += 5) {
      final bool major = degree % 30 == 0;
      tickPaint
        ..strokeWidth = major ? 2 : 1
        ..color = degree == 0
            ? north
            : tick.withValues(alpha: major ? 0.9 : 0.45);
      final double inner = radius - (major ? 16 : 9);
      canvas.drawLine(
        center + _polar(degree.toDouble(), inner),
        center + _polar(degree.toDouble(), radius - 4),
        tickPaint,
      );
    }

    for (int i = 0; i < 4; i++) {
      final double degree = i * 90;
      final TextPainter text = TextPainter(
        text: TextSpan(
          text: _cardinals[i],
          style: TextStyle(
            fontFamily: AppTheme.uiFontFamily,
            fontSize: radius * 0.13,
            fontWeight: FontWeight.w700,
            color: i == 0 ? north : label,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final Offset at = center + _polar(degree, radius - 34);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(degree * math.pi / 180);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }

    if (!showNeedle) {
      _paintKaaba(canvas, center, radius * 0.16);
      return;
    }

    final double needleLength = radius - 58;
    final Offset tip = center + _polar(bearing, needleLength);
    final Offset tail = center + _polar(bearing + 180, needleLength * 0.35);
    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = needle,
    );
    final Path head = Path()
      ..moveTo(
        center.dx + _polar(bearing, needleLength + 14).dx,
        center.dy + _polar(bearing, needleLength + 14).dy,
      )
      ..lineTo(
        center.dx + _polar(bearing - 7, needleLength - 6).dx,
        center.dy + _polar(bearing - 7, needleLength - 6).dy,
      )
      ..lineTo(
        center.dx + _polar(bearing + 7, needleLength - 6).dx,
        center.dy + _polar(bearing + 7, needleLength - 6).dy,
      )
      ..close();
    canvas.drawPath(head, Paint()..color = needle);
    canvas.drawCircle(center, 9, Paint()..color = needle);
    canvas.drawCircle(center, 4, Paint()..color = face);

    final double kaabaHalf = radius * 0.07;
    _paintKaaba(
      canvas,
      center + _polar(bearing, radius + kaabaHalf + 6),
      kaabaHalf,
    );
  }

  /// A small Kaaba: a dark cube with its gold band.
  void _paintKaaba(Canvas canvas, Offset at, double half) {
    final Rect body = Rect.fromCenter(
      center: at,
      width: half * 2,
      height: half * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(half * 0.18)),
      Paint()..color = kaaba,
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top + half * 0.5, body.width, half * 0.3),
      Paint()..color = kaabaBand,
    );
  }

  static Offset _polar(double degrees, double length) {
    final double radians = degrees * math.pi / 180;
    return Offset(math.sin(radians) * length, -math.cos(radians) * length);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.bearing != bearing ||
      old.showNeedle != showNeedle ||
      old.ring != ring ||
      old.needle != needle ||
      old.face != face;
}

/// Leaves room outside the ring for the Kaaba marker.
double _dialRadius(Size size) => size.shortestSide / 2 - 30;

/// The fixed marker at the top of the dial, just inside the ring: where the
/// device is pointing. Facing the Qibla puts the Kaaba directly above it.
class _LubberPainter extends CustomPainter {
  const _LubberPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double top = size.height / 2 - _dialRadius(size) + 3;
    final Path marker = Path()
      ..moveTo(cx, top + 16)
      ..lineTo(cx - 9, top)
      ..lineTo(cx + 9, top)
      ..close();
    canvas.drawPath(marker, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LubberPainter old) => old.color != color;
}
