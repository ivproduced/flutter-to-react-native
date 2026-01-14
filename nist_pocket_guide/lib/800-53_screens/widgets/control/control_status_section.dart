// --- widgets/control/control_status_section.dart ---

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../models/oscal_models.dart'; // adjust if your models live elsewhere
import 'package:nist_pocket_guide/app_data_manager.dart'; // for control lookup if needed
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_detail_screen_pro.dart'; // unified screen
import '../../../services/purchase_service.dart'; // for purchase service

class ControlStatusSection extends StatelessWidget {
  final Control control;
  final PurchaseService purchaseService;

  const ControlStatusSection({
    super.key,
    required this.control,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Building ControlStatusSection for control: ${control.id}');
    debugPrint(
      'Props: ${control.props.map((p) => '${p.name}: ${p.value}').join(', ')}',
    );
    debugPrint(
      'Links: ${control.links.map((l) => '${l.rel}: ${l.href}').join(', ')}',
    );
    final statusProp = control.props.firstWhere(
      (p) => p.name == 'status',
      orElse: () => Prop(name: '', value: ''),
    );
    final link = control.links.firstWhere(
      (l) => l.rel == 'incorporated-into',
      orElse: () => Link(href: '', rel: ''),
    );

    if (statusProp.value.toLowerCase() != 'withdrawn') {
      debugPrint('🔴 Status is not Withdrawn. Found: ${statusProp.value}');
      return const SizedBox.shrink();
    }

    final textSpans = <TextSpan>[];

    textSpans.add(
      TextSpan(
        text: '${statusProp.value}. ', // Withdrawn.
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    if (link.href.startsWith('#')) {
      final linkedControlId = link.href.substring(1);

      textSpans.add(TextSpan(text: 'Incorporated into '));

      textSpans.add(
        TextSpan(
          text: linkedControlId,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer:
              TapGestureRecognizer()
                ..onTap = () {
                  final linkedControl = AppDataManager().getControlById(
                    linkedControlId,
                  );
                  if (linkedControl != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ControlDetailScreenPro(
                              control: linkedControl,
                              purchaseService: purchaseService,
                            ),
                      ),
                    );
                  }
                },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: textSpans,
        ),
      ),
    );
  }
}
