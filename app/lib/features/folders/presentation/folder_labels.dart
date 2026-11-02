import '../../../l10n/app_localizations.dart';
import '../domain/trip_folder.dart';

extension FolderIconLabel on FolderIcon {
  String label(AppLocalizations l10n) => switch (this) {
    FolderIcon.camper => l10n.folderIconCamper,
    FolderIcon.mountains => l10n.folderIconMountains,
    FolderIcon.beach => l10n.folderIconBeach,
    FolderIcon.camping => l10n.folderIconCamping,
    FolderIcon.hiking => l10n.folderIconHiking,
    FolderIcon.cafe => l10n.folderIconCafe,
    FolderIcon.compass => l10n.folderIconCompass,
    FolderIcon.forest => l10n.folderIconForest,
    FolderIcon.city => l10n.folderIconCity,
    FolderIcon.castle => l10n.folderIconCastle,
    FolderIcon.food => l10n.folderIconFood,
    FolderIcon.wine => l10n.folderIconWine,
    FolderIcon.bike => l10n.folderIconBike,
    FolderIcon.kayak => l10n.folderIconKayak,
    FolderIcon.ski => l10n.folderIconSki,
  };
}

extension FolderColorLabel on FolderColor {
  String label(AppLocalizations l10n) => switch (this) {
    FolderColor.emerald => l10n.folderColorEmerald,
    FolderColor.amber => l10n.folderColorAmber,
    FolderColor.glacier => l10n.folderColorGlacier,
    FolderColor.heather => l10n.folderColorHeather,
    FolderColor.raspberry => l10n.folderColorRaspberry,
    FolderColor.sapphire => l10n.folderColorSapphire,
    FolderColor.meadow => l10n.folderColorMeadow,
    FolderColor.lagoon => l10n.folderColorLagoon,
    FolderColor.slate => l10n.folderColorSlate,
  };
}
