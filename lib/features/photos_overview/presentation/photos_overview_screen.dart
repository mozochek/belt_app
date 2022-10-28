import 'dart:async';

import 'package:belt_app/features/camera/presentation/camera_screen.dart';
import 'package:belt_app/features/core/presentation/bloc/photos_holder_bloc.dart';
import 'package:belt_app/features/core/presentation/bloc/photos_loading_bloc.dart';
import 'package:belt_app/features/core/presentation/photos_scope.dart';
import 'package:belt_app/features/photo_details/presentation/photo_details_screen.dart';
import 'package:belt_app/features/photos_overview/domain/photo_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';

class PhotosOverviewScreen extends StatelessWidget {
  const PhotosOverviewScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Все фото',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<PhotosHolderBloc, PhotosHolderState>(
          builder: (context, state) {
            return state.map<Widget>(
              notInitialized: (_) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              withData: (state) {
                return _PhotosGrid(photos: state.photos);
              },
              withError: (state) {
                return _PhotosNotLoaded(reason: state.reason);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CameraScreen()),
          );
        },
        child: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }
}

class _PhotosGrid extends StatefulWidget {
  final List<PhotoData> photos;

  const _PhotosGrid({
    required this.photos,
  });

  @override
  State<_PhotosGrid> createState() => _PhotosGridState();
}

class _PhotosGridState extends State<_PhotosGrid> {
  late final ScrollController _scrollController;
  late final VoidCallback _paginationListener;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _paginationListener = () {
      if (mounted && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        PhotosScope.loadNextGalleryPhotosPage(context);
      }
    };
    _scrollController.addListener(_paginationListener);
  }

  @override
  void didUpdateWidget(covariant _PhotosGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.photos != widget.photos) {
      _paginationListener.call();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_paginationListener);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    if (widget.photos.isEmpty) {
      return const Center(
        child: Text('Изображений нет'),
      );
    }

    return NotificationListener(
      onNotification: (notification) {
        if (notification is OverscrollIndicatorNotification) {
          notification.disallowIndicator();
          return false;
        }

        if (notification is ScrollMetricsNotification) {
          _paginationListener.call();
          return false;
        }

        return false;
      },
      child: GridView.builder(
        controller: _scrollController,
        itemCount: widget.photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 2.0,
          crossAxisSpacing: 2.0,
        ),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, index) {
          final photoFile = widget.photos[index].file;

          return GestureDetector(
            key: ValueKey(photoFile.path),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoDetailsScreen(
                    data: widget.photos[index],
                  ),
                ),
              );
            },
            child: PhotoView.customChild(
              heroAttributes: PhotoViewHeroAttributes(tag: photoFile.path),
              disableGestures: true,
              backgroundDecoration: BoxDecoration(color: scaffoldBgColor),
              child: Image.file(
                photoFile,
                fit: BoxFit.cover,
                cacheHeight: 300,
                cacheWidth: 300,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotosNotLoaded extends StatefulWidget {
  final PhotoLoadingFailureReason reason;

  const _PhotosNotLoaded({
    required this.reason,
  });

  @override
  State<_PhotosNotLoaded> createState() => _PhotosNotLoadedState();
}

class _PhotosNotLoadedState extends State<_PhotosNotLoaded> {
  @override
  Widget build(BuildContext context) {
    switch (widget.reason) {
      case PhotoLoadingFailureReason.accessDenied:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Flexible(
                  child: Text(
                    'Для отображения ваших фотографий, необходимо предоставить разрешение',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            TextButton(
              onPressed: () async {
                await PhotoManager.openSetting();
                // этот пустой future нужен из-за странного бага открытия экрана настроек
                // если эту future убрать, системное окно с настройками никогда не откроется и будет редиректить обратно в приложение
                // (ошибка воспроизводится на android 12)
                await Future.delayed(const Duration(milliseconds: 50));
                if (mounted) {
                  PhotosScope.loadNextGalleryPhotosPage(context);
                }
              },
              child: const Text('Предоставить разрешение'),
            ),
          ],
        );
      case PhotoLoadingFailureReason.other:
        return const Center(
          child: Text('Ошибка'),
        );
    }
  }
}
