import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SevenDayLineChart extends StatelessWidget {
  const SevenDayLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 3),
                    FlSpot(1, 1),
                    FlSpot(2, 4),
                    FlSpot(3, 2),
                    FlSpot(4, 5),
                    FlSpot(5, 3),
                    FlSpot(6, 4),
                  ],
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
