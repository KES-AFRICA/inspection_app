import 'package:pdf/widgets.dart' as pw;

/// Représente une entrée dans le sommaire dynamique du rapport PDF.
class SommaireEntry {
  final String titre;
  final String key;
  final int level;
  final bool isBold;
  final bool isUppercase;

  SommaireEntry({
    required this.titre,
    required this.key,
    required this.level,
    this.isBold = false,
    this.isUppercase = false,
  });
}

typedef _SommaireEntry = SommaireEntry;

/// Widget de tracking de page dans le moteur 2-passes de PdfReportService.
/// Enregistre dans le registre de pages (`Map<String, int>`) le numéro de page physique
/// exact au moment du rendu sans altérer la mise en page.
class PageTracker extends pw.SingleChildWidget {
  final String key;
  final Map<String, int> registry;
  final int offset;

  PageTracker({
    required this.key,
    required pw.Widget child,
    required this.registry,
    this.offset = 0,
  }) : super(child: child);

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    super.layout(context, constraints, parentUsesSize: parentUsesSize);
    registry[key] = context.pageNumber + offset;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context);
  }
}

/// Affiche dynamiquement le numéro de page résolu associé à une clé donnée.
class PageNumberText extends pw.Widget {
  final String keyName;
  final Map<String, int> registry;
  final pw.TextStyle style;

  PageNumberText({
    required this.keyName,
    required this.registry,
    required this.style,
  });

  String _getText() {
    final pageNum = registry[keyName];
    return pageNum != null ? pageNum.toString() : '--';
  }

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final textWidget = pw.Text(_getText(), style: style);
    textWidget.layout(context, constraints, parentUsesSize: parentUsesSize);
    box = textWidget.box;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final textWidget = pw.Text(
      _getText(),
      style: style,
      textAlign: pw.TextAlign.right,
    );
    textWidget.layout(context, pw.BoxConstraints.tight(box!.size));
    textWidget.box = box;
    textWidget.paint(context);
  }
}
