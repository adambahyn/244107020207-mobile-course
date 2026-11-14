import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Pengukur frame nyata. Sumber datanya sama dengan tab Performance DevTools:
/// `SchedulerBinding.addTimingsCallback` yang menerima [FrameTiming] dari engine
/// (build + raster + total per frame). Dipakai supaya angka before/after bisa
/// dibaca langsung di layar perangkat dan di logcat, tanpa perlu membuka
/// DevTools berbasis browser.
class PerfProbe {
  PerfProbe._();

  static final PerfProbe instance = PerfProbe._();

  final List<double> _build = <double>[];
  final List<double> _raster = <double>[];
  final List<double> _total = <double>[];
  int _jank = 0;
  bool _on = false;

  void start() {
    if (_on) return;
    _on = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void reset() {
    _build.clear();
    _raster.clear();
    _total.clear();
    _jank = 0;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final total = t.totalSpan.inMicroseconds / 1000.0;
      _total.add(total);
      _build.add(t.buildDuration.inMicroseconds / 1000.0);
      _raster.add(t.rasterDuration.inMicroseconds / 1000.0);
      if (total > 16.67) _jank++;
    }
  }

  int get frames => _total.length;
  int get jankFrames => _jank;
  double get jankPct => frames == 0 ? 0 : _jank * 100 / frames;
  double get avgTotal => _avg(_total);
  double get avgBuild => _avg(_build);
  double get avgRaster => _avg(_raster);

  double get p90Total {
    if (_total.isEmpty) return 0;
    final sorted = [..._total]..sort();
    return sorted[((sorted.length * 0.9).floor()).clamp(0, sorted.length - 1)];
  }

  double get worstTotal =>
      _total.isEmpty ? 0 : _total.reduce((a, b) => a > b ? a : b);

  static double _avg(List<double> v) =>
      v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

  String get summary =>
      'frame=$frames jank=$_jank(${jankPct.toStringAsFixed(1)}%) '
      'avg=${avgTotal.toStringAsFixed(1)}ms '
      'build=${avgBuild.toStringAsFixed(1)}ms '
      'raster=${avgRaster.toStringAsFixed(1)}ms '
      'p90=${p90Total.toStringAsFixed(1)}ms '
      'max=${worstTotal.toStringAsFixed(1)}ms';

  /// Satu baris ringkas ke logcat dengan tag `PERF|`.
  void dump(String label) => debugPrint('PERF|$label|$summary');
}

/// Overlay kecil di bawah layar: angka frame terlihat langsung di screenshot
/// perangkat. Ketuk untuk mengosongkan hitungan sebelum skenario dijalankan.
class PerfOverlay extends StatefulWidget {
  const PerfOverlay({super.key, required this.label});

  final String label;

  @override
  State<PerfOverlay> createState() => _PerfOverlayState();
}

class _PerfOverlayState extends State<PerfOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    PerfProbe.instance.start();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {});
      PerfProbe.instance.dump(widget.label);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PerfProbe.instance;
    return IgnorePointer(
      ignoring: false,
      child: GestureDetector(
        onTap: p.reset,
        child: Container(
          key: const Key('perf-overlay'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.black87,
          child: Text(
            '${widget.label} | ${p.summary}',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
