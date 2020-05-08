import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DialogLoadingController {
  GlobalKey<_DialogLoadingState> _key;
  BuildContext context;

  DialogLoadingController();

  GlobalKey<_DialogLoadingState> get key {
    return this._key;
  }

  void setLabel(String label) {
    if (!this.exists()) return;
    this._key.currentState.setLabel(label);
  }

  close() {
    print('dialog-->close--1-->'+(this?.key?.currentState?.isShowing == true).toString());
    print('dialog-->close--2-->'+(context != null).toString());
    if (this?.key?.currentState?.isShowing == true && context != null) {
      this._key = null;
      Navigator.of(this.context).pop();
      print('dialog-->close--->');
    }
  }

  bool exists() {
    return this._key != null && this._key.currentState != null;
  }

  Widget _buildMaterialDialogTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: child,
    );
  }

  Future<T> show<T>({
    @required BuildContext context,
    String message,
    bool canPop = true,
    bool barrierDismissible = false,
  }) {
    assert(debugCheckHasMaterialLocalizations(context));
    if (MaterialLocalizations.of(context) == null) return null;

    if (this.key != null) {
      close();
    }

    this._key = GlobalKey<_DialogLoadingState>();
    this.context = context;

    return showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        final ThemeData theme = Theme.of(context, shadowThemeOnly: true);
        final Widget pageChild = DialogLoading(key: this.key, label: message);
        //child ?? Builder(builder: builder);

        return WillPopScope(
            child: SafeArea(
              child: Builder(
                  builder: (BuildContext context) {
                    return theme != null ? Theme(data: theme, child: pageChild) : pageChild;
                  }
              ),
            ),
            onWillPop: () async {
              if (canPop) close();
              return false;
            }
        );
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 150),
      transitionBuilder: _buildMaterialDialogTransitions,
    );
  }
}

class DialogLoading extends StatefulWidget {
  final String label;

  DialogLoading({key, this.label}) : super(key: key);

  @override
  _DialogLoadingState createState() => _DialogLoadingState();
}

class _DialogLoadingState extends State<DialogLoading> {
  String _label;
  bool isShowing = false;

  @override
  void initState() {
    super.initState();
    this._label = this.widget.label;
    isShowing = true;
    print('dialog-->isShow--->'+isShowing.toString());
  }

  @override
  void dispose() {
    isShowing = false;
    super.dispose();
    print('dialog-->isShow--->'+isShowing.toString());
  }

  setLabel(String label) {
    if (!this.mounted) return;

    this.setState(() {
      this._label = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            BoxShadow(
                blurRadius: 0.0,
                spreadRadius: 0.0,
                offset: const Offset(0.0, 0.0),
                color: Color(0xFFE6E6E6)
            ),
          ],
          borderRadius: const BorderRadius.all(const Radius.circular(12.0)),
          color: Color(0xFFF5F5F5)
        ),
        width: 120.0,
        height: 120.0,
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(25.0),
              child: CircularProgressIndicator(),
            ),
            this._label != null
                ? Text(
                    this._label,
                    textScaleFactor: 1.0,
                    maxLines: 2,
                    style: TextStyle(
                      color: Color(0xB3202020),
                      fontSize: 12.0,
                      decoration: TextDecoration.none,
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
