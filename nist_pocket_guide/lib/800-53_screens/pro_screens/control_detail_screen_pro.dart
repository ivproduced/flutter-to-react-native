import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/bottom_nav_bar_pro.dart';
import 'package:nist_pocket_guide/models/llm_objective_data.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/services/feedback_service.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_header.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_statement_section.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/assessment_section.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/guidance_section.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/notes_section.dart';
import 'package:nist_pocket_guide/services/utils/params_util.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_status_section.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';

class ControlDetailScreenPro extends StatefulWidget {
  final Control control;
  final PurchaseService purchaseService;
  final String? returnRoute;
  final String? returnLabel;

  const ControlDetailScreenPro({
    super.key,
    required this.control,
    required this.purchaseService,
    this.returnRoute,
    this.returnLabel,
  });

  @override
  State<ControlDetailScreenPro> createState() => _ControlDetailScreenProState();
}

class _ControlDetailScreenProState extends State<ControlDetailScreenPro> {
  late List<Control> sortedEnhancementControls; // We'll address this later
  bool isAssessmentView =
      false; // false = Control Statement, true = Assessment Objectives

  @override
  void initState() {
    super.initState();

    // Initialize sortedEnhancementControls (example, adjust as needed)
    sortedEnhancementControls = List.from(widget.control.enhancements);
    sortedEnhancementControls.sort(
      (a, b) => controlIdComparator(a.id, b.id),
    ); // Assuming you have controlIdComparator

    // Call addRecentControl after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if the widget is still in the tree
        AppDataManager.instance.addRecentControl(widget.control.id);
        // Track control view for feedback prompts
        FeedbackService.trackControlViewed(context);
      }
    });
  }

  Widget buildViewToggle() {
    // Don't show toggle for withdrawn controls
    if (widget.control.props.any(
      (p) => p.name == 'status' && p.value.toLowerCase() == 'withdrawn',
    )) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Control Statement Button
            GestureDetector(
              onTap: () {
                setState(() {
                  isAssessmentView = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      !isAssessmentView
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Text(
                  'Control Statement',
                  style: TextStyle(
                    color:
                        !isAssessmentView
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Assessment Objectives Button
            GestureDetector(
              onTap: () {
                setState(() {
                  isAssessmentView = true;
                });
                // Track assessment objectives usage for feedback prompts
                FeedbackService.trackAssessmentUsage(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isAssessmentView
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Text(
                  'Assessment Objectives',
                  style: TextStyle(
                    color:
                        isAssessmentView
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildControlContent() {
    if (widget.control.props.any(
      (p) => p.name == 'status' && p.value.toLowerCase() == 'withdrawn',
    )) {
      return ControlStatusSection(
        control: widget.control,
        purchaseService: widget.purchaseService,
      );
    } else {
      return ControlStatementSection(
        parts: widget.control.parts.where((p) => p.isStatement).toList(),
        params: expandParams(widget.control.params),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Track recent controls for ALL users (not feature-gated)
    final guidance =
        widget.control.parts.where((p) => p.isGuidance).firstOrNull?.prose;

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
        title: Text(widget.control.id.toUpperCase()),
      ),
      // Show bottom navigation bar for ALL users - feature gating is inside the buttons
      bottomNavigationBar: StatementNavBar(
        enhancements: widget.control.enhancements,
        control: widget.control,
        purchaseService: widget.purchaseService,
        selectedIndex: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ControlHeader(
                  id: widget.control.id,
                  title: widget.control.title,
                  purchaseService: widget.purchaseService,
                  baselines: widget.control.baselines,
                  control: widget.control,
                ),
                const SizedBox(height: 16),
                buildViewToggle(),
                // Only add spacing if toggle is visible (not withdrawn controls)
                if (!widget.control.props.any(
                  (p) =>
                      p.name == 'status' &&
                      p.value.toLowerCase() == 'withdrawn',
                ))
                  const SizedBox(height: 16),
                // Conditional content based on toggle
                if (isAssessmentView)
                  AssessmentSection(controlId: widget.control.id)
                else ...[
                  buildControlContent(),
                  const SizedBox(height: 16),
                  GuidanceSection(guidanceText: guidance),
                ],
                const SizedBox(height: 16),
                // Feature gate: Notes section shows upgrade prompt for free users
                NotesSection(
                  controlId: widget.control.id,
                  purchaseService: widget.purchaseService,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
