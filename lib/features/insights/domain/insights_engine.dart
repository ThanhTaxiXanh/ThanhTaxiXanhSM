// lib/features/insights/domain/insights_engine.dart
// AI Insights rules-based - Pure Dart, offline, không cần internet
// So sánh hôm nay/hôm qua, cảnh báo chi tiêu, thống kê tuần

import '../../transaction/data/transaction_repository.dart';

/// Loại insight
enum InsightType { positive, warning, info, achievement }

/// Một insight card
class InsightCard {
  const InsightCard({
    required this.emoji,
    required this.title,
    required this.message,
    required this.type,
  });

  final String emoji;
  final String title;
  final String message;
  final InsightType type;
}

/// Engine phân tích offline
class InsightsEngine {
  InsightsEngine._();

  /// Phân tích và tạo danh sách insights
  static List<InsightCard> analyze({
    required DailySummary today,
    required DailySummary yesterday,
    required List<DailySummary> thisWeek,
    required double avgPerTrip,
  }) {
    final insights = <InsightCard>[];

    // 1. So sánh thu nhập hôm nay vs hôm qua
    if (yesterday.totalIncome > 0 && today.totalIncome > 0) {
      final diff = today.totalIncome - yesterday.totalIncome;
      final pct = (diff / yesterday.totalIncome * 100).abs().round();

      if (diff > 0) {
        insights.add(InsightCard(
          emoji: '🚀',
          title: 'Hôm nay ngon hơn hôm qua!',
          message: 'Thu nhập tăng $pct% so với hôm qua. Giỏi lắm bạn ơi!',
          type: InsightType.positive,
        ));
      } else if (diff < -0.1 * yesterday.totalIncome) {
        insights.add(InsightCard(
          emoji: '📉',
          title: 'Thu nhập giảm nhẹ',
          message: 'Hôm nay giảm $pct% so với hôm qua. Cố lên nào!',
          type: InsightType.info,
        ));
      }
    }

    // 2. So sánh số cuốc hôm nay vs hôm qua
    if (yesterday.tripCount > 0 && today.tripCount > 0) {
      if (today.tripCount > yesterday.tripCount) {
        final extra = today.tripCount - yesterday.tripCount;
        insights.add(InsightCard(
          emoji: '🏆',
          title: 'Nhiều cuốc hơn hôm qua!',
          message: 'Đã chạy thêm $extra cuốc so với hôm qua. Xuất sắc!',
          type: InsightType.achievement,
        ));
      }
    }

    // 3. Cảnh báo chi tiêu > 50% thu nhập trong ngày
    if (today.totalIncome > 0 && today.totalExpense > 0) {
      final ratio = today.totalExpense / today.totalIncome;
      if (ratio > 0.5) {
        final pct = (ratio * 100).round();
        insights.add(InsightCard(
          emoji: '⚠️',
          title: 'Chi tiêu cao bất thường',
          message:
              'Chi tiêu hôm nay đạt $pct% thu nhập. Kiểm tra lại nhé!',
          type: InsightType.warning,
        ));
      }
    }

    // 4. Ngày cao điểm nhất tuần
    if (thisWeek.length >= 3) {
      final best = thisWeek.reduce((a, b) =>
          a.totalIncome > b.totalIncome ? a : b);
      final now = DateTime.now();
      final today0 = DateTime(now.year, now.month, now.day);
      final bestDay = DateTime(best.date.year, best.date.month, best.date.day);

      if (bestDay == today0 && best.totalIncome > 0) {
        insights.add(InsightCard(
          emoji: '🌟',
          title: 'Ngày tốt nhất tuần này!',
          message: 'Hôm nay là ngày thu nhập cao nhất trong tuần. Tiếp tục phát huy!',
          type: InsightType.achievement,
        ));
      }
    }

    // 5. Trung bình mỗi cuốc
    if (avgPerTrip > 0) {
      if (avgPerTrip >= 50000) {
        insights.add(InsightCard(
          emoji: '💰',
          title: 'Trung bình cuốc tốt',
          message: 'Bình quân mỗi cuốc đạt ${_formatK(avgPerTrip)}. Khá tốt!',
          type: InsightType.positive,
        ));
      } else if (avgPerTrip < 25000) {
        insights.add(InsightCard(
          emoji: '💡',
          title: 'Gợi ý cải thiện',
          message:
              'Trung bình cuốc ${_formatK(avgPerTrip)} hơi thấp. Thử chọn giờ cao điểm?',
          type: InsightType.info,
        ));
      }
    }

    // 6. Động viên khi không có dữ liệu
    if (insights.isEmpty) {
      if (today.totalIncome == 0) {
        insights.add(InsightCard(
          emoji: '🌅',
          title: 'Bắt đầu ngày mới!',
          message:
              'Chưa có giao dịch hôm nay. Chúc bạn một ngày chạy xe thuận lợi! 🚕',
          type: InsightType.info,
        ));
      } else {
        insights.add(InsightCard(
          emoji: '✅',
          title: 'Mọi thứ ổn định',
          message: 'Thu chi hôm nay cân bằng tốt. Tiếp tục duy trì nhé!',
          type: InsightType.positive,
        ));
      }
    }

    return insights;
  }

  static String _formatK(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
