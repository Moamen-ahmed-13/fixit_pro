import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final done    = i + 1 < currentStep;
        final current = i + 1 == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: done
                        ? AppColors.accent
                        : current
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                ),
              ),
              if (i < totalSteps - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}
