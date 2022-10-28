import 'dart:io';

import 'package:belt_app/features/core/presentation/bloc/photos_holder_bloc.dart';
import 'package:belt_app/features/core/presentation/photos_scope.dart';
import 'package:belt_app/features/photos_overview/domain/photo_data.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:photo_manager/photo_manager.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late bool _initializationFailed;

  @override
  void initState() {
    super.initState();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _initializationFailed = false;
    final cameras = await availableCameras();

    if (cameras.isEmpty) return;

    final backCameras = cameras.where((camera) => camera.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      backCameras.isNotEmpty ? backCameras.first : cameras.first,
      ResolutionPreset.max,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.auto);
    } on Object catch (e) {
      _initializationFailed = true;
      if (e is CameraException) {}
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _controller == null
              ? const Text('Подождите, камера инициализируется...')
              : _initializationFailed
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Произошла ошибка инициализации камеры'),
                        TextButton(
                          onPressed: () async {
                            await PhotoManager.openSetting();
                            // этот пустой future нужен из-за странного бага открытия экрана настроек
                            // если эту future убрать, системное окно с настройками никогда не откроется и будет редиректить обратно в приложение
                            // (ошибка воспроизводится на android 12)
                            await Future.delayed(const Duration(milliseconds: 50));
                            _initializeCamera();
                          },
                          child: const Text('Открыть настройки приложения'),
                        ),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        Expanded(
                          child: CameraPreview(_controller!),
                        ),
                      ],
                    ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () async {
                if (_initializationFailed || _controller == null || _controller!.value.isTakingPicture) return;

                final holderBloc = PhotosScope.photosHolderBloc(context);
                final picture = await _controller!.takePicture();
                final bytes = await picture.readAsBytes();
                await ImageGallerySaver.saveImage(bytes, quality: 100);
                final file = File(picture.path);

                holderBloc.add(PhotosHolderEvent.addPhoto(PhotoData(file)));
              },
              child: const Icon(Icons.photo_camera_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
