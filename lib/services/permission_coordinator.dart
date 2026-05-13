import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/vs_toast.dart';

enum AppPermissionStatus {
  granted,
  denied,
  blocked,
  restricted,
  limited,
  cancelled,
  serviceDisabled,
}

class AppPermissionResult {
  const AppPermissionResult(this.status);

  final AppPermissionStatus status;

  bool get isGranted =>
      status == AppPermissionStatus.granted ||
      status == AppPermissionStatus.limited;
}

class PermissionCoordinator {
  PermissionCoordinator._();

  static final PermissionCoordinator instance = PermissionCoordinator._();

  static const _accent = Color(0xFF0D9488);
  static const _blockedStatus = {
    PermissionStatus.permanentlyDenied,
    PermissionStatus.restricted,
  };

  Future<AppPermissionResult> requestPatientPhotoCamera(BuildContext context) {
    return _requestPermission(
      context,
      permission: Permission.camera,
      icon: Icons.camera_alt_rounded,
      rationaleTitle: 'Camera access required',
      rationaleMessage:
          'Allow camera access to take patient photos during screening.',
      deniedMessage:
          'Camera access is required to take a patient photo for this screening.',
      blockedTitle: 'Turn on camera access',
      blockedMessage:
          'Camera access is currently blocked. Open app settings to allow patient photos during screening.',
    );
  }

  Future<AppPermissionResult> requestFaceDistanceCamera(BuildContext context) {
    return _requestPermission(
      context,
      permission: Permission.camera,
      icon: Icons.center_focus_strong_rounded,
      rationaleTitle: 'Camera access required',
      rationaleMessage:
          'Allow camera access to measure patient distance before the vision test starts.',
      deniedMessage:
          'Camera access is required to measure patient distance for this step.',
      blockedTitle: 'Turn on camera access',
      blockedMessage:
          'Camera access is currently blocked. Open app settings to allow distance setup for screening.',
    );
  }

  Future<AppPermissionResult> requestProfilePhotoCamera(BuildContext context) {
    return _requestPermission(
      context,
      permission: Permission.camera,
      icon: Icons.camera_alt_rounded,
      rationaleTitle: 'Camera access required',
      rationaleMessage: 'Allow camera access to take your profile photo.',
      deniedMessage: 'Camera access is required to take a profile photo.',
      blockedTitle: 'Turn on camera access',
      blockedMessage:
          'Camera access is currently blocked. Open app settings to take a profile photo.',
    );
  }

  Future<AppPermissionResult> requestProfilePhotoLibrary(
    BuildContext context,
  ) async {
    if (!Platform.isIOS) {
      return const AppPermissionResult(AppPermissionStatus.granted);
    }
    return _requestPermission(
      context,
      permission: Permission.photos,
      icon: Icons.photo_library_rounded,
      rationaleTitle: 'Photo library access required',
      rationaleMessage:
          'Allow photo library access to choose your profile photo.',
      deniedMessage:
          'Photo library access is required to choose a profile photo.',
      blockedTitle: 'Turn on photo library access',
      blockedMessage:
          'Photo library access is currently blocked. Open app settings to choose a profile photo.',
      allowLimited: true,
    );
  }

  Future<AppPermissionResult> requestScreeningLocation(BuildContext context) {
    return _requestLocationPermission(
      context,
      icon: Icons.location_on_rounded,
      rationaleTitle: 'Location access required',
      rationaleMessage:
          'Allow location access to fill in the screening location for this patient.',
      deniedMessage:
          'Location access is required to detect the screening location.',
      blockedTitle: 'Turn on location access',
      blockedMessage:
          'Location access is currently blocked. Open app settings to allow screening location lookup.',
      servicesMessage:
          'Location Services are turned off. Enable them to detect the screening location.',
    );
  }

  Future<AppPermissionResult> requestHomeLocation(BuildContext context) {
    return _requestLocationPermission(
      context,
      icon: Icons.location_on_rounded,
      rationaleTitle: 'Location access required',
      rationaleMessage:
          'Allow location access to look up your current area on the home screen.',
      deniedMessage:
          'Location access is required to look up your current area.',
      blockedTitle: 'Turn on location access',
      blockedMessage:
          'Location access is currently blocked. Open app settings to allow home location lookup.',
      servicesMessage:
          'Location Services are turned off. Enable them to check your current area.',
    );
  }

  Future<AppPermissionResult> _requestLocationPermission(
    BuildContext context, {
    required IconData icon,
    required String rationaleTitle,
    required String rationaleMessage,
    required String deniedMessage,
    required String blockedTitle,
    required String blockedMessage,
    required String servicesMessage,
  }) async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      if (context.mounted) {
        await _showServiceDisabledDialog(
          context,
          icon: icon,
          message: servicesMessage,
        );
      }
      return const AppPermissionResult(AppPermissionStatus.serviceDisabled);
    }
    if (!context.mounted) {
      return const AppPermissionResult(AppPermissionStatus.cancelled);
    }

    return _requestPermission(
      context,
      permission: Permission.locationWhenInUse,
      icon: icon,
      rationaleTitle: rationaleTitle,
      rationaleMessage: rationaleMessage,
      deniedMessage: deniedMessage,
      blockedTitle: blockedTitle,
      blockedMessage: blockedMessage,
    );
  }

  Future<AppPermissionResult> _requestPermission(
    BuildContext context, {
    required Permission permission,
    required IconData icon,
    required String rationaleTitle,
    required String rationaleMessage,
    required String deniedMessage,
    required String blockedTitle,
    required String blockedMessage,
    bool allowLimited = false,
  }) async {
    final current = await permission.status;
    final currentResult = _resultFromStatus(
      current,
      allowLimited: allowLimited,
    );
    if (currentResult.isGranted) {
      return currentResult;
    }
    if (_blockedStatus.contains(current)) {
      if (context.mounted) {
        await _showBlockedDialog(
          context,
          icon: icon,
          title: blockedTitle,
          message: blockedMessage,
        );
      }
      return currentResult;
    }

    if (!context.mounted) {
      return const AppPermissionResult(AppPermissionStatus.cancelled);
    }
    final shouldRequest = await _showRationaleDialog(
      context,
      icon: icon,
      title: rationaleTitle,
      message: rationaleMessage,
    );
    if (shouldRequest != true || !context.mounted) {
      return const AppPermissionResult(AppPermissionStatus.cancelled);
    }

    final requested = await permission.request();
    final requestedResult = _resultFromStatus(
      requested,
      allowLimited: allowLimited,
    );
    if (requestedResult.isGranted || !context.mounted) {
      return requestedResult;
    }

    if (_blockedStatus.contains(requested)) {
      await _showBlockedDialog(
        context,
        icon: icon,
        title: blockedTitle,
        message: blockedMessage,
      );
      return requestedResult;
    }

    _showRetryToast(context, deniedMessage);
    return requestedResult;
  }

  AppPermissionResult _resultFromStatus(
    PermissionStatus status, {
    required bool allowLimited,
  }) {
    if (status.isGranted) {
      return const AppPermissionResult(AppPermissionStatus.granted);
    }
    if (allowLimited && status.isLimited) {
      return const AppPermissionResult(AppPermissionStatus.limited);
    }
    if (status.isRestricted) {
      return const AppPermissionResult(AppPermissionStatus.restricted);
    }
    if (status.isPermanentlyDenied) {
      return const AppPermissionResult(AppPermissionStatus.blocked);
    }
    return const AppPermissionResult(AppPermissionStatus.denied);
  }

  Future<bool?> _showRationaleDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(icon, color: _accent),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBlockedDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(icon, color: _accent),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showServiceDisabledDialog(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(icon, color: _accent),
          title: const Text('Location Services are off'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showRetryToast(BuildContext context, String message) {
    VsToast.showText(context, message);
  }
}
