import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported IPTV protocol types. Keeping this scoped to the login flow
/// avoids scattering string literals across the UI layer.
enum LoginProviderType { m3u, xtream, stalker }

/// Distinguishes between the two M3U ingestion modes described in the design.
enum M3uInputMode { url, file }

/// Enumerates the steps shown in the "Test & Connect" feedback sequence.
enum LoginTestStep {
  reachServer,
  authenticate,
  fetchChannels,
  fetchEpg,
  saveProfile,
}

/// Tracks the lifecycle of a single test step so the UI can present
/// determinate progress and contextual messages.
class LoginTestStepState {
  final LoginTestStep step;
  final StepStatus status;
  final String? message;

  const LoginTestStepState({
    required this.step,
    this.status = StepStatus.pending,
    this.message,
  });

  LoginTestStepState copyWith({StepStatus? status, String? message}) {
    return LoginTestStepState(
      step: step,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

/// Simple status enum for each test step.
enum StepStatus { pending, inProgress, success, failure }

/// Shared shape for simple text field state. Maintains the current value and
/// an optional validation error string that the UI can surface directly.
@immutable
class FieldState {
  final String value;
  final String? error;

  const FieldState({this.value = '', this.error});

  FieldState copyWith({String? value, String? error, bool clearError = false}) {
    return FieldState(
      value: value ?? this.value,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Captures all user input associated with the M3U pathway.
@immutable
class M3uFormState {
  final M3uInputMode inputMode;
  final FieldState playlistUrl;
  final FieldState playlistFilePath;
  final FieldState epgUrl;
  final FieldState username;
  final FieldState password;
  final bool autoUpdate;
  final bool followRedirects;
  final bool advancedExpanded;

  const M3uFormState({
    this.inputMode = M3uInputMode.url,
    this.playlistUrl = const FieldState(),
    this.playlistFilePath = const FieldState(),
    this.epgUrl = const FieldState(),
    this.username = const FieldState(),
    this.password = const FieldState(),
    this.autoUpdate = true,
    this.followRedirects = true,
    this.advancedExpanded = false,
  });

  M3uFormState copyWith({
    M3uInputMode? inputMode,
    FieldState? playlistUrl,
    FieldState? playlistFilePath,
    FieldState? epgUrl,
    FieldState? username,
    FieldState? password,
    bool? autoUpdate,
    bool? followRedirects,
    bool? advancedExpanded,
  }) {
    return M3uFormState(
      inputMode: inputMode ?? this.inputMode,
      playlistUrl: playlistUrl ?? this.playlistUrl,
      playlistFilePath: playlistFilePath ?? this.playlistFilePath,
      epgUrl: epgUrl ?? this.epgUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      followRedirects: followRedirects ?? this.followRedirects,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
    );
  }
}

/// Captures user input for the Xtream protocol flow.
@immutable
class XtreamFormState {
  final FieldState serverUrl;
  final FieldState username;
  final FieldState password;
  final String outputFormat;
  final bool allowSelfSignedTls;
  final bool advancedExpanded;

  const XtreamFormState({
    this.serverUrl = const FieldState(),
    this.username = const FieldState(),
    this.password = const FieldState(),
    this.outputFormat = 'ts',
    this.allowSelfSignedTls = false,
    this.advancedExpanded = false,
  });

  XtreamFormState copyWith({
    FieldState? serverUrl,
    FieldState? username,
    FieldState? password,
    String? outputFormat,
    bool? allowSelfSignedTls,
    bool? advancedExpanded,
  }) {
    return XtreamFormState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      outputFormat: outputFormat ?? this.outputFormat,
      allowSelfSignedTls: allowSelfSignedTls ?? this.allowSelfSignedTls,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
    );
  }
}

/// Captures user input for the Stalker/Ministra flow.
@immutable
class StalkerFormState {
  final FieldState portalUrl;
  final FieldState macAddress;
  final String deviceProfile;
  final bool allowSelfSignedTls;
  final bool advancedExpanded;

  const StalkerFormState({
    this.portalUrl = const FieldState(),
    this.macAddress = const FieldState(value: '00:1A:79:'),
    this.deviceProfile = 'MAG250',
    this.allowSelfSignedTls = false,
    this.advancedExpanded = false,
  });

  StalkerFormState copyWith({
    FieldState? portalUrl,
    FieldState? macAddress,
    String? deviceProfile,
    bool? allowSelfSignedTls,
    bool? advancedExpanded,
  }) {
    return StalkerFormState(
      portalUrl: portalUrl ?? this.portalUrl,
      macAddress: macAddress ?? this.macAddress,
      deviceProfile: deviceProfile ?? this.deviceProfile,
      allowSelfSignedTls: allowSelfSignedTls ?? this.allowSelfSignedTls,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
    );
  }
}

/// Describes the overall test progress panel state.
@immutable
class LoginTestProgress {
  final bool inProgress;
  final List<LoginTestStepState> steps;

  const LoginTestProgress({this.inProgress = false, this.steps = const []});

  LoginTestProgress copyWith({
    bool? inProgress,
    List<LoginTestStepState>? steps,
  }) {
    return LoginTestProgress(
      inProgress: inProgress ?? this.inProgress,
      steps: steps ?? this.steps,
    );
  }

  static List<LoginTestStepState> initialSteps({bool includeEpg = true}) {
    final base = <LoginTestStepState>[
      const LoginTestStepState(step: LoginTestStep.reachServer),
      const LoginTestStepState(step: LoginTestStep.authenticate),
      const LoginTestStepState(step: LoginTestStep.fetchChannels),
    ];
    if (includeEpg) {
      base.add(const LoginTestStepState(step: LoginTestStep.fetchEpg));
    }
    base.add(const LoginTestStepState(step: LoginTestStep.saveProfile));
    return base;
  }
}

/// Root state exposed to the UI. This collects the individual protocol
/// form snapshots, the active provider choice, progress indicator data,
/// and any banner-level messaging.
@immutable
class LoginFlowState {
  final LoginProviderType providerType;
  final M3uFormState m3u;
  final XtreamFormState xtream;
  final StalkerFormState stalker;
  final LoginTestProgress testProgress;
  final String? bannerMessage;

  const LoginFlowState({
    this.providerType = LoginProviderType.stalker,
    this.m3u = const M3uFormState(),
    this.xtream = const XtreamFormState(),
    this.stalker = const StalkerFormState(),
    this.testProgress = const LoginTestProgress(),
    this.bannerMessage,
  });

  LoginFlowState copyWith({
    LoginProviderType? providerType,
    M3uFormState? m3u,
    XtreamFormState? xtream,
    StalkerFormState? stalker,
    LoginTestProgress? testProgress,
    String? bannerMessage,
    bool clearBanner = false,
  }) {
    return LoginFlowState(
      providerType: providerType ?? this.providerType,
      m3u: m3u ?? this.m3u,
      xtream: xtream ?? this.xtream,
      stalker: stalker ?? this.stalker,
      testProgress: testProgress ?? this.testProgress,
      bannerMessage: clearBanner ? null : bannerMessage ?? this.bannerMessage,
    );
  }
}

/// Drives the login state machine. This controller centralises updates so
/// the UI can stay declarative and free of imperative bookkeeping.
class LoginFlowController extends StateNotifier<LoginFlowState> {
  LoginFlowController() : super(const LoginFlowState());

  /// Switches the active provider tab while preserving the previous form data.
  void selectProvider(LoginProviderType type) {
    if (state.providerType == type) {
      return;
    }
    state = state.copyWith(providerType: type);
  }

  /// Updates the M3U input mode and clears incompatible errors.
  void selectM3uInputMode(M3uInputMode mode) {
    if (state.m3u.inputMode == mode) {
      return;
    }
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        inputMode: mode,
        playlistUrl: mode == M3uInputMode.url
            ? state.m3u.playlistUrl.copyWith(clearError: true)
            : state.m3u.playlistUrl,
        playlistFilePath: mode == M3uInputMode.file
            ? state.m3u.playlistFilePath.copyWith(clearError: true)
            : state.m3u.playlistFilePath,
      ),
    );
  }

  void updateM3uPlaylistUrl(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        playlistUrl: state.m3u.playlistUrl.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void updateM3uPlaylistFilePath(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        playlistFilePath: state.m3u.playlistFilePath.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void updateM3uEpgUrl(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        epgUrl: state.m3u.epgUrl.copyWith(value: value, clearError: true),
      ),
    );
  }

  void updateM3uUsername(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        username: state.m3u.username.copyWith(value: value),
      ),
    );
  }

  void updateM3uPassword(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        password: state.m3u.password.copyWith(value: value),
      ),
    );
  }

  void toggleM3uAutoUpdate(bool value) {
    state = state.copyWith(m3u: state.m3u.copyWith(autoUpdate: value));
  }

  void toggleM3uFollowRedirects(bool value) {
    state = state.copyWith(m3u: state.m3u.copyWith(followRedirects: value));
  }

  void toggleM3uAdvanced(bool expanded) {
    state = state.copyWith(m3u: state.m3u.copyWith(advancedExpanded: expanded));
  }

  void updateXtreamServerUrl(String value) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        serverUrl: state.xtream.serverUrl.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void updateXtreamUsername(String value) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        username: state.xtream.username.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void updateXtreamPassword(String value) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        password: state.xtream.password.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void setXtreamOutputFormat(String format) {
    state = state.copyWith(xtream: state.xtream.copyWith(outputFormat: format));
  }

  void toggleXtreamTlsOverride(bool allow) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(allowSelfSignedTls: allow),
    );
  }

  void toggleXtreamAdvanced(bool expanded) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(advancedExpanded: expanded),
    );
  }

  void updateStalkerPortalUrl(String value) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(
        portalUrl: state.stalker.portalUrl.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void updateStalkerMacAddress(String value) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(
        macAddress: state.stalker.macAddress.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void toggleStalkerTlsOverride(bool allow) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(allowSelfSignedTls: allow),
    );
  }

  void toggleStalkerAdvanced(bool expanded) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(advancedExpanded: expanded),
    );
  }

  void setBannerMessage(String? message) {
    state = state.copyWith(
      bannerMessage: message,
      clearBanner: message == null,
    );
  }

  /// Validates the currently selected form and updates field errors inline.
  /// Returns true when the form is valid.
  bool validateActiveForm() {
    switch (state.providerType) {
      case LoginProviderType.m3u:
        return _validateM3u();
      case LoginProviderType.xtream:
        return _validateXtream();
      case LoginProviderType.stalker:
        return _validateStalker();
    }
  }

  bool _validateM3u() {
    var form = state.m3u;
    var playlistUrl = form.playlistUrl;
    var playlistFile = form.playlistFilePath;
    var epgUrl = form.epgUrl;

    if (form.inputMode == M3uInputMode.url) {
      if (!_looksLikeUrl(playlistUrl.value)) {
        playlistUrl = playlistUrl.copyWith(
          error: 'Enter a playlist URL, e.g. https://example.com/list.m3u8',
        );
      }
    } else {
      if (playlistFile.value.trim().isEmpty) {
        playlistFile = playlistFile.copyWith(
          error: 'Select a local M3U file to continue.',
        );
      }
    }

    if (epgUrl.value.trim().isNotEmpty && !_looksLikeUrl(epgUrl.value)) {
      epgUrl = epgUrl.copyWith(
        error: 'EPG URL needs to start with http:// or https://',
      );
    }

    final hasErrors = [
      playlistUrl.error,
      playlistFile.error,
      epgUrl.error,
    ].any((error) => error != null);

    state = state.copyWith(
      m3u: form.copyWith(
        playlistUrl: playlistUrl,
        playlistFilePath: playlistFile,
        epgUrl: epgUrl,
      ),
    );
    return !hasErrors;
  }

  bool _validateXtream() {
    var form = state.xtream;
    var url = form.serverUrl;
    var username = form.username;
    var password = form.password;

    if (!_looksLikeUrl(url.value)) {
      url = url.copyWith(
        error: 'Enter the Xtream base URL, e.g. http://host:8080',
      );
    }
    if (username.value.trim().isEmpty) {
      username = username.copyWith(error: 'Username is required.');
    }
    if (password.value.trim().isEmpty) {
      password = password.copyWith(error: 'Password is required.');
    }

    final hasErrors = [
      url.error,
      username.error,
      password.error,
    ].any((error) => error != null);

    state = state.copyWith(
      xtream: form.copyWith(
        serverUrl: url,
        username: username,
        password: password,
      ),
    );
    return !hasErrors;
  }

  bool _validateStalker() {
    var form = state.stalker;
    var portal = form.portalUrl;
    var mac = form.macAddress;

    if (!_looksLikeUrl(portal.value)) {
      portal = portal.copyWith(
        error: 'Enter the portal URL, e.g. http://portal.example.com/',
      );
    }
    if (!_looksLikeMac(mac.value)) {
      mac = mac.copyWith(
        error: 'MAC address should look like 00:1A:79:12:34:56',
      );
    }

    final hasErrors = [portal.error, mac.error].any((error) => error != null);

    state = state.copyWith(
      stalker: form.copyWith(portalUrl: portal, macAddress: mac),
    );
    return !hasErrors;
  }

  /// Begins a test run by resetting the progress step list.
  void beginTestSequence({bool includeEpgStep = true}) {
    state = state.copyWith(
      testProgress: LoginTestProgress(
        inProgress: true,
        steps: LoginTestProgress.initialSteps(includeEpg: includeEpgStep),
      ),
      clearBanner: true,
    );
  }

  /// Marks a specific step as active, allowing the UI to highlight it.
  void markStepActive(LoginTestStep target) {
    final updated = state.testProgress.steps.map((step) {
      if (step.step == target) {
        return step.copyWith(status: StepStatus.inProgress);
      }
      return step;
    }).toList();
    state = state.copyWith(
      testProgress: state.testProgress.copyWith(steps: updated),
    );
  }

  /// Marks a test step as complete (success).
  void markStepSuccess(LoginTestStep target, {String? message}) {
    final updated = state.testProgress.steps.map((step) {
      if (step.step == target) {
        return step.copyWith(
          status: StepStatus.success,
          message: message ?? step.message,
        );
      }
      return step;
    }).toList();
    state = state.copyWith(
      testProgress: state.testProgress.copyWith(steps: updated),
    );
  }

  /// Marks a test step as failed and stops the sequence.
  void markStepFailure(LoginTestStep target, {required String message}) {
    final updated = state.testProgress.steps.map((step) {
      if (step.step == target) {
        return step.copyWith(status: StepStatus.failure, message: message);
      }
      return step.copyWith(
        status: step.status == StepStatus.pending
            ? StepStatus.pending
            : step.status,
      );
    }).toList();
    state = state.copyWith(
      testProgress: state.testProgress.copyWith(
        inProgress: false,
        steps: updated,
      ),
      bannerMessage: message,
    );
  }

  /// Resets the test panel after success or when the user cancels.
  void resetTestProgress() {
    state = state.copyWith(
      testProgress: const LoginTestProgress(),
      clearBanner: true,
    );
  }

  /// Returns the list of step states for convenience.
  List<LoginTestStepState> get steps => state.testProgress.steps;

  /// Simple URL pattern check; intentionally lenient to keep the UX friendly.
  bool _looksLikeUrl(String input) {
    final value = input.trim();
    if (value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool _looksLikeMac(String input) {
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(input.trim());
  }
}

/// Public provider so widgets can watch the state or issue commands.
final loginFlowControllerProvider =
    StateNotifierProvider<LoginFlowController, LoginFlowState>(
      (ref) => LoginFlowController(),
    );
