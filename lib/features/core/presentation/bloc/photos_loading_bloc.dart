import 'dart:async';

import 'package:belt_app/features/photos_overview/domain/photo_data.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart' as bloc_concurrency;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photo_manager/photo_manager.dart';

part 'photos_loading_bloc.freezed.dart';

const _pageSize = 5;

class PhotosLoadingBloc extends Bloc<PhotosLoadingEvent, PhotosLoadingState> {
  PhotosLoadingBloc() : super(const PhotosLoadingState.notInitialized()) {
    on<PhotosLoadingEvent>(
      (event, emit) async {
        await event.map<FutureOr>(
          loadNextPage: (event) => _onLoadNextPage(event, emit),
        );
      },
      transformer: bloc_concurrency.droppable(),
    );
  }

  Future<void> _onLoadNextPage(_PhotosLoadingEventLoadNextPage event, Emitter emit) async {
    final readPermission = await PhotoManager.requestPermissionExtend();

    switch (readPermission) {
      case PermissionState.notDetermined:
      case PermissionState.restricted:
      case PermissionState.denied:
        emit(const PhotosLoadingState.failed(PhotoLoadingFailureReason.accessDenied));
        return;
      case PermissionState.authorized:
      case PermissionState.limited:
    }

    final albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);

    if (albums.isEmpty) {
      emit(const PhotosLoadingState.failed(PhotoLoadingFailureReason.other));
      return;
    }

    final resolvedPage = state.maybeMap(
      orElse: () => 0,
      completed: (state) => state.currentPage + 1,
    );
    final album = albums.first;
    final photos = await album.getAssetListPaged(page: resolvedPage, size: _pageSize);
    final photoData = <PhotoData>[];
    for (final photo in photos) {
      final ioFile = await photo.originFile;

      if (ioFile == null) continue;

      photoData.add(PhotoData(ioFile));
    }

    emit(PhotosLoadingState.completed(photoData, resolvedPage));
  }
}

@freezed
class PhotosLoadingEvent with _$PhotosLoadingEvent {
  const PhotosLoadingEvent._();

  const factory PhotosLoadingEvent.loadNextPage() = _PhotosLoadingEventLoadNextPage;
}

@freezed
class PhotosLoadingState with _$PhotosLoadingState {
  const PhotosLoadingState._();

  const factory PhotosLoadingState.notInitialized() = _PhotosLoadingStateNotInitialized;

  const factory PhotosLoadingState.inProgress() = _PhotosLoadingStateInProgress;

  const factory PhotosLoadingState.completed(
    List<PhotoData> photos,
    int currentPage,
  ) = _PhotosLoadingStateCompleted;

  const factory PhotosLoadingState.failed(
    PhotoLoadingFailureReason reason,
  ) = _PhotosLoadingStateFailed;
}

enum PhotoLoadingFailureReason { accessDenied, other }
