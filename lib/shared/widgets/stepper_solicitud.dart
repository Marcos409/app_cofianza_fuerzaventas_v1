import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StepperSolicitud extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepperSolicitud({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isCompleted = i < currentStep;
        final isActive = i == currentStep;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 4,
              right: i == totalSteps - 1 ? 0 : 4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : isActive
                            ? AppColors.secondary
                            : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paso ${i + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
