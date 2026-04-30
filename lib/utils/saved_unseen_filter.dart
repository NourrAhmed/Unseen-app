import '../models/unseen_model.dart';

class SavedUnseenFilter {
  List<UnSeenModel> filterSavedUnseens(
    List<UnSeenModel> allUnseens,
    List<String> savedIds,
  ) {
    return allUnseens
        .where((unseen) => savedIds.contains(unseen.unseenId))
        .toList();
  }
}
