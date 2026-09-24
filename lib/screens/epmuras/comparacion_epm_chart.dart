import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ComparacionEPMChart extends StatelessWidget {
  final List<Map<String, dynamic>> evaluations;

  const ComparacionEPMChart({Key? key, required this.evaluations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 6,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                const labels = ['E', 'P', 'M', 'U', 'R', 'A', 'S'];
                if (value.toInt() < labels.length) {
                  return Text(labels[value.toInt()]);
                }
                return Text('');
              },
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: evaluations[0]['epmuras']['E']?.toDouble() ?? 0, width: 10),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: evaluations[0]['epmuras']['P']?.toDouble() ?? 0, width: 10),
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: evaluations[0]['epmuras']['M']?.toDouble() ?? 0, width: 10),
          ]),
          BarChartGroupData(x: 3, barRods: [
            BarChartRodData(toY: evaluations[0]['epmuras']['U']?.toDouble() ?? 0, width: 10),
          ]),
          BarChartGroupData(x: 4, barRods: [
            BarChartRodData(toY: evaluations[0]['epmuras']['R']?.toDouble() ?? 0, width: 10),
          ]),
          BarChartGroupData(x: 5, barRods: [
            BarChartRodData(toY: evaluations[0]['epmuras']['A']?.toDouble() ?? 0, width: 10),
          ]),
          BarChartGroupData(x: 6, barRods: [
            BarChartRodData(toY: evaluations[0]['epmuras']['S']?.toDouble() ?? 0, width: 10),
          ]),
        ],
      ),
    );
  }
}



