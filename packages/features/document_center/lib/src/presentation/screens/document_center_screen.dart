import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';

import '../../locator.dart';
import '../bloc/document_center_cubit.dart';
import '../bloc/document_center_state.dart';
import '../views/export_center_view.dart';
import '../views/import_center_view.dart';
import '../views/report_center_view.dart';

/// The document_center feature's main dashboard screen.
class DocumentCenterScreen extends StatelessWidget {
  const DocumentCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => getIt<DocumentCenterCubit>()..load(),
      child: BlocBuilder<DocumentCenterCubit, DocumentCenterState>(
        builder: (context, state) {
          final cubit = context.read<DocumentCenterCubit>();

          return DefaultTabController(
            length: 3,
            initialIndex: state.currentTabIndex,
            child: AppScaffold(
              title: l10n.documentCenterTitle,
              body: Column(
                children: [
                  TabBar(
                    onTap: cubit.changeTab,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.upload_file),
                        text: l10n.documentCenterTabImport,
                      ),
                      Tab(
                        icon: const Icon(Icons.download),
                        text: l10n.documentCenterTabExport,
                      ),
                      Tab(
                        icon: const Icon(Icons.picture_as_pdf),
                        text: l10n.documentCenterTabReports,
                      ),
                    ],
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: state.currentTabIndex,
                      children: const [
                        ImportCenterView(),
                        ExportCenterView(),
                        ReportCenterView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
