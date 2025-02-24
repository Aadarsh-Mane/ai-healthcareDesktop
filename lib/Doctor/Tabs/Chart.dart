import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartGraphWidget extends StatelessWidget {
  final List<double> dataPoints;

  const LineChartGraphWidget({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue[700]!.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${value.toInt()}', style: style),
                  );
                },
                reservedSize: 35,
                interval: 10,
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  return SideTitleWidget(
                    meta: meta,
                    space: 20,
                    child: Text('Day ${value.toInt() + 1}', style: style),
                  );
                },
                reservedSize: 40,
                interval: 1,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: (dataPoints.isNotEmpty
                  ? dataPoints.reduce((a, b) => a < b ? a : b)
                  : 0) -
              5,
          maxY: (dataPoints.isNotEmpty
                  ? dataPoints.reduce((a, b) => a > b ? a : b)
                  : 50) +
              5,
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              color: Colors.pink,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.pink.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
