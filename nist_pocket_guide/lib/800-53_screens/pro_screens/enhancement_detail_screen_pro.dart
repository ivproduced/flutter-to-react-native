// enhancement_detail_view.dart

import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/bottom_nav_bar_pro.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/enhancement/enhancement_header.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/enhancement/enhancement_statement_section.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_status_section.dart';
import 'package:nist_pocket_guide/services/utils/params_util.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/guidance_section.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/notes_section.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:provider/provider.dart';


// Additional widgets to import as you modularize

class EnhancementDetailScreenPro extends StatefulWidget {
  final Control enhancement;
  final PurchaseService purchaseService;
  final String? returnRoute;
  final String? returnLabel;

  const EnhancementDetailScreenPro({
    super.key,
    required this.enhancement,
    required this.purchaseService,
    this.returnRoute,
    this.returnLabel,
  });

  @override
  State<EnhancementDetailScreenPro> createState() => _EnhancementDetailScreenProState();
}

class _EnhancementDetailScreenProState extends State<EnhancementDetailScreenPro> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appDataManager = Provider.of<AppDataManager>(context, listen: false);
      appDataManager.addRecentControl(widget.enhancement.id);
    });
  }

  Widget buildEnhancementContent() {
    if (widget.enhancement.props.any((p) => p.name == 'status' && p.value.toLowerCase() == 'withdrawn')) {
      return ControlStatusSection(
        control: widget.enhancement,
        purchaseService: widget.purchaseService,
      );
    } else {
      return EnhancementStatementSection(
        parts: widget.enhancement.parts.where((p) => p.name.toLowerCase() == 'statement').toList(),
        params: expandParams(widget.enhancement.params),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guidancePart = widget.enhancement.parts.cast<Part?>().firstWhere(
      (part) => part?.name == 'guidance',
      orElse: () => null,
    );

    // Format enhancement ID as AC-2(10) style
    final String displayId = '${widget.enhancement.id.toUpperCase().replaceFirst('.', '(')})';
    return Scaffold(
      appBar: AppBar(
        leading: widget.returnRoute != null && widget.returnLabel != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Simple pop back to previous screen
                  Navigator.pop(context);
                },
                tooltip: 'Back to ${widget.returnLabel}',
              )
            : null,
        title: Text(displayId),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EnhancementHeader(
              id: widget.enhancement.id,
              title: widget.enhancement.title,
              baselines: widget.enhancement.baselines,
              purchaseService: widget.purchaseService,
              control: widget.enhancement, // Pass the enhancement as control
            ),
            const SizedBox(height: 24),
            buildEnhancementContent(),
            const SizedBox(height: 24),
            if (guidancePart != null)
              GuidanceSection(
                guidanceText: guidancePart.prose,
              ),
            NotesSection(
              controlId: widget.enhancement.id,
              purchaseService: widget.purchaseService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: EnhancementNavBar(
        selectedIndex: 0,
        purchaseService: widget.purchaseService,
        enhancement: widget.enhancement,
      ),
    );
  }
}
