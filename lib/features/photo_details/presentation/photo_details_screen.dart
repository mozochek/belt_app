import 'dart:io';

import 'package:belt_app/features/common/presentation/screenshot_widget.dart';
import 'package:belt_app/features/common/presentation/sketcher.dart';
import 'package:belt_app/features/core/presentation/bloc/photos_holder_bloc.dart';
import 'package:belt_app/features/core/presentation/photos_scope.dart';
import 'package:belt_app/features/photo_details/presentation/bloc/photo_details_screen_mode_bloc.dart';
import 'package:belt_app/features/photo_details/presentation/photo_details_screen_scope.dart';
import 'package:belt_app/features/photos_overview/domain/photo_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class PhotoDetailsScreen extends StatefulWidget {
  final PhotoData data;

  const PhotoDetailsScreen({
    required this.data,
    super.key,
  });

  @override
  State<PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<PhotoDetailsScreen> {
  late final GlobalKey _screenshotKey;

  @override
  void initState() {
    super.initState();

    _screenshotKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoDetailsScreenScope(
      child: Builder(
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              final screenState = PhotoDetailsScreenScope.photoDetailsScreenModeBloc(context).state;

              if (screenState.editModeEnabled) {
                PhotoDetailsScreenScope.switchEditMode(context);
                return SynchronousFuture(false);
              }

              return SynchronousFuture(true);
            },
            child: Scaffold(
              appBar: AppBar(
                leading: const _AppBarLeadingIcon(),
                title: const _AppBarTitle(),
              ),
              body: SafeArea(
                child: BlocBuilder<PhotoDetailsScreenModeBloc, PhotoDetailsScreenModeState>(
                  builder: (context, state) {
                    if (state.editModeEnabled) {
                      return Center(
                        child: ScreenshotWidget(
                          key: _screenshotKey,
                          child: _PhotoEditing(
                            file: widget.data.file,
                          ),
                        ),
                      );
                    }

                    final photoFile = widget.data.file;

                    return PhotoView.customChild(
                      heroAttributes: PhotoViewHeroAttributes(tag: photoFile.path),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.contained * 2,
                      backgroundDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
                      child: Image.file(
                        photoFile,
                        key: ValueKey(photoFile.path),
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              bottomNavigationBar: _BottomActionsBar(
                screenshotKey: _screenshotKey,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppBarLeadingIcon extends StatelessWidget {
  const _AppBarLeadingIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoDetailsScreenModeBloc, PhotoDetailsScreenModeState>(
      buildWhen: (prev, curr) => prev.editModeEnabled != curr.editModeEnabled,
      builder: (context, state) {
        final color = Theme.of(context).appBarTheme.iconTheme?.color;

        if (state.editModeEnabled) {
          return IconButton(
            onPressed: () => PhotoDetailsScreenScope.switchEditMode(context),
            tooltip: 'Закрыть редактирование',
            icon: Icon(
              Icons.close,
              color: color,
            ),
          );
        }

        return BackButton(color: color);
      },
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoDetailsScreenModeBloc, PhotoDetailsScreenModeState>(
      buildWhen: (prev, curr) => prev.editModeEnabled != curr.editModeEnabled,
      builder: (context, state) {
        if (state.editModeEnabled) {
          return Row(
            children: <Widget>[
              const Expanded(
                child: SizedBox.shrink(),
              ),
              Selector<SketcherController, bool>(
                selector: (_, controller) => controller.lines.isNotEmpty,
                builder: (context, canUndo, child) {
                  return GestureDetector(
                    onTap: canUndo ? () => PhotoDetailsScreenScope.removeLastDrawnLine(context) : null,
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.arrow_back_outlined,
                        color: canUndo ? Colors.black : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_forward_outlined, color: Colors.grey),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _PhotoEditing extends StatelessWidget {
  final File file;

  const _PhotoEditing({
    required this.file,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Sketcher(
      controller: PhotoDetailsScreenScope.sketcherController(context),
      child: Image.file(
        file,
        key: ValueKey(file.path),
        fit: BoxFit.contain,
      ),
    );
  }
}

class _BottomActionsBar extends StatefulWidget {
  final GlobalKey screenshotKey;

  const _BottomActionsBar({
    required this.screenshotKey,
    super.key,
  });

  @override
  State<_BottomActionsBar> createState() => _BottomActionsBarState();
}

class _BottomActionsBarState extends State<_BottomActionsBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kBottomNavigationBarHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: BlocBuilder<PhotoDetailsScreenModeBloc, PhotoDetailsScreenModeState>(
            builder: (context, state) {
              final buttons = state.editModeEnabled
                  ? <Widget>[
                      Expanded(
                        child: Center(
                          child: _BottomIconButton(
                            icon: const Icon(Icons.save_outlined),
                            text: 'Сохранить',
                            onPressed: () async {
                              final screenshotContext = widget.screenshotKey.currentContext;

                              if (screenshotContext == null) return;

                              final holderBloc = PhotosScope.photosHolderBloc(context);
                              PhotoDetailsScreenScope.switchEditMode(context);
                              final byteData = await ScreenshotWidget.takeScreenshot(
                                screenshotContext,
                                pixelRatio: MediaQuery.of(context).devicePixelRatio,
                              );
                              final bytes = byteData.buffer.asUint8List();

                              await ImageGallerySaver.saveImage(bytes, quality: 100);
                              final tempDir = await getTemporaryDirectory();
                              final file = File('${tempDir.path}/${DateTime.now().toIso8601String()}.png');
                              await file.writeAsBytes(bytes);
                              await file.create(recursive: true);
                              holderBloc.add(PhotosHolderEvent.addPhoto(PhotoData(file)));

                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    const SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: Text('Файл успешно сохранён в Галерею'),
                                    ),
                                  );
                              }
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _BottomIconButton(
                            icon: Selector<SketcherController, Color>(
                              selector: (context, controller) => controller.color,
                              builder: (context, color, child) => Container(
                                width: 24.0,
                                height: 24.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ),
                            ),
                            text: 'Цвет',
                            onPressed: () {
                              final sketchController = PhotoDetailsScreenScope.sketcherController(context);

                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return ChangeNotifierProvider.value(
                                    value: sketchController,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                                      child: SizedBox(
                                        height: 24.0,
                                        child: _ColorSelectorBottomSheet(),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _BottomIconButton(
                            icon: const Icon(Icons.circle_outlined),
                            text: 'Размер',
                            onPressed: () {
                              final sketchController = PhotoDetailsScreenScope.sketcherController(context);

                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return ChangeNotifierProvider.value(
                                    value: sketchController,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                                      child: SizedBox(
                                        height: 24.0,
                                        child: _StrokeSelectorBottomSheet(),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ]
                  : <Widget>[
                      _BottomIconButton(
                        icon: const Icon(Icons.edit_outlined),
                        text: 'Изменить',
                        onPressed: () => PhotoDetailsScreenScope.switchEditMode(context),
                      ),
                    ];

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: buttons,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback onPressed;

  const _BottomIconButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          icon,
          Text(text),
        ],
      ),
    );
  }
}

class _ColorSelectorBottomSheet extends StatelessWidget {
  const _ColorSelectorBottomSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: Center(
            child: _ColorSelectorButton(color: Colors.black),
          ),
        ),
        Expanded(
          child: Center(
            child: _ColorSelectorButton(color: Colors.green),
          ),
        ),
        Expanded(
          child: Center(
            child: _ColorSelectorButton(color: Colors.blue),
          ),
        ),
        Expanded(
          child: Center(
            child: _ColorSelectorButton(color: Colors.yellow),
          ),
        ),
        Expanded(
          child: Center(
            child: _ColorSelectorButton(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _ColorSelectorButton extends StatelessWidget {
  final Color color;

  const _ColorSelectorButton({
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PhotoDetailsScreenScope.sketcherController(context).color = color;
        Navigator.maybePop(context);
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _StrokeSelectorBottomSheet extends StatelessWidget {
  const _StrokeSelectorBottomSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: Center(
            child: _StrokeSelectorButton(value: 1.0),
          ),
        ),
        Expanded(
          child: Center(
            child: _StrokeSelectorButton(value: 2.0),
          ),
        ),
        Expanded(
          child: Center(
            child: _StrokeSelectorButton(value: 3.0),
          ),
        ),
        Expanded(
          child: Center(
            child: _StrokeSelectorButton(value: 4.0),
          ),
        ),
        Expanded(
          child: Center(
            child: _StrokeSelectorButton(value: 5.0),
          ),
        ),
      ],
    );
  }
}

class _StrokeSelectorButton extends StatelessWidget {
  final double value;

  const _StrokeSelectorButton({
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PhotoDetailsScreenScope.sketcherController(context).stroke = value;
        Navigator.maybePop(context);
      },
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 24.0,
        height: 24.0,
        child: FittedBox(
          child: Text(value.toStringAsFixed(1)),
        ),
      ),
    );
  }
}
