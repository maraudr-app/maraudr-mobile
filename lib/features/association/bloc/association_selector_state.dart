abstract class AssociationSelectorState {}

class AssociationSelectorInitial extends AssociationSelectorState {}

class AssociationSelectorLoading extends AssociationSelectorState {}

class AssociationSelectorLoaded extends AssociationSelectorState {
  final List<Map<String, dynamic>> associations;
  final String? selectedId;

  AssociationSelectorLoaded(this.associations, this.selectedId);
}

class AssociationSelectorError extends AssociationSelectorState {
  final String message;

  AssociationSelectorError(this.message);
}
