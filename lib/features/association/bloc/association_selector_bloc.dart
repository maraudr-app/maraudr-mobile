import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/association_repository.dart';
import 'association_selector_event.dart';
import 'association_selector_state.dart';

class AssociationSelectorBloc extends Bloc<AssociationSelectorEvent, AssociationSelectorState> {
  final AssociationRepository repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _selectedAssociationKey = 'selected_association_id';

  AssociationSelectorBloc(this.repository) : super(AssociationSelectorInitial()) {
    on<LoadAssociations>((event, emit) async {
      emit(AssociationSelectorLoading());
      final list = await repository.fetchMemberships();
      String? selected = await _storage.read(key: _selectedAssociationKey);

      if (selected == null && list.isNotEmpty) {
        selected = list.first['id'] as String;
        await _storage.write(key: _selectedAssociationKey, value: selected);
      }

      emit(AssociationSelectorLoaded(list, selected));
    });

    on<SelectAssociation>((event, emit) async {
      await _storage.write(key: _selectedAssociationKey, value: event.id);
      final list = await repository.fetchMemberships();
      emit(AssociationSelectorLoaded(list, event.id));
    });
  }

  static Future<String?> getSelectedAssociationId() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: _selectedAssociationKey);
  }
}