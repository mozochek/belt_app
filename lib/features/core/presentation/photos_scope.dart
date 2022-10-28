import 'package:belt_app/features/core/presentation/bloc/photos_holder_bloc.dart';
import 'package:belt_app/features/core/presentation/bloc/photos_loading_bloc.dart';
import 'package:belt_app/features/photos_overview/domain/photo_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PhotosScope extends StatelessWidget {
  final Widget child;

  const PhotosScope({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PhotosLoadingBloc()..add(const PhotosLoadingEvent.loadNextPage()),
        ),
        BlocProvider(
          create: (_) => PhotosHolderBloc(),
        ),
      ],
      child: BlocListener<PhotosLoadingBloc, PhotosLoadingState>(
        listener: (context, state) {
          state.mapOrNull(
            completed: (state) {
              if (state.currentPage == 0) {
                resetHolder(context);
              }
              // из галереи картинки идут в порядке от новых к старым.
              // добавляя условие addToEnd мы гарантируем соблюдение ожидаемого порядка изображений.
              // когда идет добавление картинок, созданных через приложение, addToEnd всегда будет указан как false,
              // т.к созданное изображение будет новее всех ранее загруженных.
              // тем самым будет продолжать соблюдаться порядок изображений от новых к старым.
              addPhotos(context, state.photos, addToEnd: state.currentPage != 0);
            },
            failed: (state) {
              setFailure(context, state.reason);
            },
          );
        },
        child: child,
      ),
    );
  }

  static PhotosLoadingBloc photosLoadingBloc(BuildContext context) => context.read<PhotosLoadingBloc>();

  static void loadNextGalleryPhotosPage(BuildContext context) =>
      photosLoadingBloc(context).add(const PhotosLoadingEvent.loadNextPage());

  static PhotosHolderBloc photosHolderBloc(BuildContext context) => context.read<PhotosHolderBloc>();

  static void resetHolder(BuildContext context) => photosHolderBloc(context).add(const PhotosHolderEvent.reset());

  static void addPhotos(
    BuildContext context,
    Iterable<PhotoData> photos, {
    bool addToEnd = false,
  }) =>
      photosHolderBloc(context).add(PhotosHolderEvent.addPhotos(photos, addToEnd: addToEnd));

  static void addPhoto(
    BuildContext context,
    PhotoData photo, {
    bool addToEnd = false,
  }) =>
      photosHolderBloc(context).add(PhotosHolderEvent.addPhoto(photo, addToEnd: addToEnd));

  static void setFailure(BuildContext context, PhotoLoadingFailureReason reason) =>
      photosHolderBloc(context).add(PhotosHolderEvent.setFailureReason(reason));
}
