import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_details_screen_mode_bloc.freezed.dart';

class PhotoDetailsScreenModeBloc extends Bloc<PhotoDetailsScreenModeEvent, PhotoDetailsScreenModeState> {
  PhotoDetailsScreenModeBloc() : super(const PhotoDetailsScreenModeState(editModeEnabled: false)) {
    on<PhotoDetailsScreenModeEvent>((event, emit) {
      event.map(switchEditMode: (event) => _onSwitchEditMode(event, emit));
    });
  }

  void _onSwitchEditMode(
    _PhotoDetailsScreenModeEventSwitchEditMode event,
    Emitter<PhotoDetailsScreenModeState> emit,
  ) {
    emit(state.copyWith(editModeEnabled: !state.editModeEnabled));
  }
}

@freezed
class PhotoDetailsScreenModeEvent with _$PhotoDetailsScreenModeEvent {
  const PhotoDetailsScreenModeEvent._();

  const factory PhotoDetailsScreenModeEvent.switchEditMode() = _PhotoDetailsScreenModeEventSwitchEditMode;
}

@freezed
class PhotoDetailsScreenModeState with _$PhotoDetailsScreenModeState {
  const PhotoDetailsScreenModeState._();

  const factory PhotoDetailsScreenModeState({
    required bool editModeEnabled,
  }) = PhotoDetailsScreenModeStateValues;
}
