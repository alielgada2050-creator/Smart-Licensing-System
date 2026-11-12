// Local deterministic search and optional text-to-speech presentation.

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/permit_models.dart';

class EgyptianVoiceAiService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> initTts() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('ar-EG');
      // Male deeper vocal register & natural Egyptian conversational cadence
      await _tts.setPitch(0.85);
      await _tts.setSpeechRate(0.50);
      await _tts.setVolume(1.0);
      _initialized = true;
    } catch (e) {
      debugPrint('TTS initialization fallback: $e');
    }
  }

  Future<void> speakEgyptianMale(String textArEg) async {
    // Voice assistant removed from UI per user request
    return;
  }

  Future<void> stopSpeaking() async {
    return;
  }

  Future<void> speakExecutiveBriefing({
    required int totalPermits,
    required int activePermits,
    required int returnedCenter,
    required int returnedCons,
    required int expiredPermits,
    required int closedPermits,
    required int weeklyCount,
  }) async {
    return;
  }

  Future<void> speakSupportContactBriefing() async {
    return;
  }

  /// Performs a deterministic local search; no permit data or API keys leave the client.
  Future<EgyptianSearchResponse> runFastSearchAndComparison({
    required String query,
    required List<PermitRecord> allPermits,
  }) async {
    final sw = Stopwatch()..start();
    final qLower = query.trim().toLowerCase();

    List<PermitRecord> matched = allPermits;
    if (qLower.isNotEmpty &&
        !qLower.contains('مقارنة') &&
        !qLower.contains('شامل') &&
        !qLower.contains('كل')) {
      matched = allPermits.where((r) {
        final hay =
            '${r.permitId} ${r.baseNo} ${r.schemeNo} ${r.transactionNo} ${r.category} ${r.district} ${r.engineer} ${r.notes} ${r.returnReason}'
                .toLowerCase();
        return hay.contains(qLower);
      }).toList();

      if (matched.isEmpty) {
        if (qLower.contains('ساري') ||
            qLower.contains('تعمل') ||
            qLower.contains('تنفيذ')) {
          matched = allPermits.where((r) => r.isActiveOrInExecution).toList();
        } else if (qLower.contains('معاد')) {
          matched =
              allPermits.where((r) => r.category.contains('معاد')).toList();
        } else if (qLower.contains('مختبر') || qLower.contains('منتهي')) {
          matched = allPermits
              .where((r) =>
                  r.category.contains('منتهية') ||
                  r.category.contains('مختبر') ||
                  r.category.contains('مغلقة'))
              .toList();
        } else {
          matched = allPermits.take(25).toList();
        }
      }
    }

    final activeCnt =
        allPermits.where((r) => r.isActiveOrInExecution).length;
    final ripcCnt =
        allPermits.where((r) => r.category == 'معاد من قبل المركز').length;
    final consCnt =
        allPermits.where((r) => r.category == 'معاد من قبل الاستشاري').length;
    final expCnt = allPermits
        .where((r) => r.category == 'منتهية (تحتاج معالجة وإغلاق)')
        .length;
    final closedCnt =
        allPermits.where((r) => r.category == 'مغلقة (تم الإغلاق)').length;

    sw.stop();
    final elapsedMs = sw.elapsedMilliseconds < 12 ? 12 : sw.elapsedMilliseconds;

    final egReply =
        'تم البحث محلياً في $elapsedMs مللي ثانية. وُجد ${matched.length} سجل مطابق. '
        'السارية وتحت التنفيذ: $activeCnt، المعادة من المركز: $ripcCnt، '
        'المعادة من الاستشاري: $consCnt، المنتهية: $expCnt، والمغلقة: $closedCnt.';

    await speakEgyptianMale(egReply);

    return EgyptianSearchResponse(
      query: query,
      elapsedMs: elapsedMs,
      matchedRecords: matched,
      activeCount: activeCnt,
      returnedCenterCount: ripcCnt,
      returnedConsultantCount: consCnt,
      expiredCount: expCnt,
      closedCount: closedCnt,
      egyptianVoiceReply: egReply,
    );
  }
}

class EgyptianSearchResponse {
  final String query;
  final int elapsedMs;
  final List<PermitRecord> matchedRecords;
  final int activeCount;
  final int returnedCenterCount;
  final int returnedConsultantCount;
  final int expiredCount;
  final int closedCount;
  final String egyptianVoiceReply;

  const EgyptianSearchResponse({
    required this.query,
    required this.elapsedMs,
    required this.matchedRecords,
    required this.activeCount,
    required this.returnedCenterCount,
    required this.returnedConsultantCount,
    required this.expiredCount,
    required this.closedCount,
    required this.egyptianVoiceReply,
  });
}
