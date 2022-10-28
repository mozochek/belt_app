import 'package:belt_app/features/core/presentation/bloc/photos_loading_bloc.dart';
import 'package:belt_app/features/photos_overview/domain/photo_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'photos_holder_bloc.freezed.dart';

class PhotosHolderBloc extends Bloc<PhotosHolderEvent, PhotosHolderState> {
  PhotosHolderBloc() : super(const PhotosHolderState.notInitialized()) {
    on<PhotosHolderEvent>((event, emit) {
      event.map(
        addPhotos: (event) => _onAddPhotos(event, emit),
        addPhoto: (event) => _onAddPhoto(event, emit),
        reset: (event) => _onReset(event, emit),
        setFailureReason: (event) => _onFailureReason(event, emit),
      );
    });
  }

  void _addPhotos(Iterable<PhotoData> photos, Emitter<PhotosHolderState> emit, bool addToEnd) {
    state.maybeMap(
      orElse: () {
        emit(PhotosHolderState.withData(photos.toList()));
      },
      withData: (state) {
        final data = addToEnd ? [...state.photos, ...photos] : [...photos, ...state.photos];

        emit(PhotosHolderState.withData(data));
      },
    );
  }

  void _onAddPhotos(_PhotosHolderEventAddPhotos event, Emitter<PhotosHolderState> emit) {
    _addPhotos(event.photos, emit, event.addToEnd);
  }

  void _onAddPhoto(_PhotosHolderEventAddPhoto event, Emitter<PhotosHolderState> emit) {
    _addPhotos([event.photo], emit, event.addToEnd);
  }

  void _onReset(_PhotosHolderEventReset event, Emitter<PhotosHolderState> emit) {
    emit(const PhotosHolderState.notInitialized());
  }

  void _onFailureReason(_PhotosHolderEventSetFailureReason event, Emitter<PhotosHolderState> emit) {
    emit(PhotosHolderState.withError(event.reason));
  }
}

@freezed
class PhotosHolderEvent with _$PhotosHolderEvent {
  const PhotosHolderEvent._();

  const factory PhotosHolderEvent.addPhotos(
    Iterable<PhotoData> photos, {
    @Default(false) bool addToEnd,
  }) = _PhotosHolderEventAddPhotos;

  const factory PhotosHolderEvent.addPhoto(
    PhotoData photo, {
    @Default(false) bool addToEnd,
  }) = _PhotosHolderEventAddPhoto;

  const factory PhotosHolderEvent.reset() = _PhotosHolderEventReset;

  const factory PhotosHolderEvent.setFailureReason(
    PhotoLoadingFailureReason reason,
  ) = _PhotosHolderEventSetFailureReason;
}

@freezed
class PhotosHolderState with _$PhotosHolderState {
  const PhotosHolderState._();

  const factory PhotosHolderState.notInitialized() = _PhotosHolderStateNotInitialized;

  const factory PhotosHolderState.withData(
    List<PhotoData> photos,
  ) = _PhotosHolderStateWithData;

  const factory PhotosHolderState.withError(
    PhotoLoadingFailureReason reason,
  ) = _PhotosHolderStateWithError;
}
