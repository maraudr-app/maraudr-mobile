abstract class AssociationSelectorEvent {}

class LoadAssociations extends AssociationSelectorEvent {}

class SelectAssociation extends AssociationSelectorEvent {
  final String id;
  SelectAssociation(this.id);
}
