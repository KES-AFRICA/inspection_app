import 'package:flutter/material.dart';

mixin PhotoSafeStateMixin<T extends StatefulWidget> on State<T> {
  bool _cameraBusy = false;

  bool get cameraBusy => _cameraBusy;

  @protected
  Future<void> runPhotoAction(Future<void> Function() action) async {
    if (_cameraBusy || !mounted) return;
    _cameraBusy = true;
    try {
      await action();
    } finally {
      if (mounted) {
        _cameraBusy = false;
      }
    }
  }
}