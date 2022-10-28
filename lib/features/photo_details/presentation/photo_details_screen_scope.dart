import 'package:belt_app/features/common/presentation/sketcher.dart';
import 'package:belt_app/features/photo_details/presentation/bloc/photo_details_screen_mode_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class PhotoDetailsScreenScope extends StatelessWidget {
  final Widget child;

  const PhotoDetailsScreenScope({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhotoDetailsScreenModeBloc(),
      child: ChangeNotifierProvider(
        create: (_) => SketcherController(),
        child: BlocListener<PhotoDetailsScreenModeBloc, PhotoDetailsScreenModeState>(
          listenWhen: (prev, curr) => prev.editModeEnabled != curr.editModeEnabled,
          listener: (context, state) {
            if (state.editModeEnabled == false) {
              PhotoDetailsScreenScope.sketcherController(context).reset();
            }
          },
          child: child,
        ),
      ),
    );
  }

  static PhotoDetailsScreenModeBloc photoDetailsScreenModeBloc(BuildContext context) =>
      context.read<PhotoDetailsScreenModeBloc>();

  static void switchEditMode(BuildContext context) =>
      photoDetailsScreenModeBloc(context).add(const PhotoDetailsScreenModeEvent.switchEditMode());

  static SketcherController sketcherController(BuildContext context) => context.read<SketcherController>();

  static void removeLastDrawnLine(BuildContext context) => sketcherController(context).removeLastLine();
}
