import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/utils/url_normalization.dart';

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

/// Captures the summary information displayed once all test steps succeed.
class LoginTestSummary {
  final LoginProviderType providerType;
  final int? channelCount;
  final int? epgDaySpan;

  const LoginTestSummary({
    required this.providerType,
    this.channelCount,
    this.epgDaySpan,
  });
}

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

const _unset = Object();

/// Captures all user input associated with the M3U pathway.
@immutable
class M3uFormState {
  final M3uInputMode inputMode;
  final FieldState playlistUrl;
  final FieldState playlistFilePath;
  final String? fileName;
  final int? fileSizeBytes;
  final DateTime? fileLastModified;
  final FieldState epgUrl;
  final FieldState username;
  final FieldState password;
  final FieldState userAgent;
  final FieldState customHeaders;
  final bool autoUpdate;
  final bool followRedirects;
  final bool allowSelfSignedTls;
  final bool advancedExpanded;
  final String? lockedPlaylistUri;
  final String? redactedPlaylistUri;
  final String? lockedEpgUri;

  const M3uFormState({
    this.inputMode = M3uInputMode.url,
    this.playlistUrl = const FieldState(),
    this.playlistFilePath = const FieldState(),
    this.fileName,
    this.fileSizeBytes,
    this.fileLastModified,
    this.epgUrl = const FieldState(),
    this.username = const FieldState(),
    this.password = const FieldState(),
    this.userAgent = const FieldState(),
    this.customHeaders = const FieldState(),
    this.autoUpdate = true,
    this.followRedirects = true,
    this.allowSelfSignedTls = false,
    this.advancedExpanded = false,
    this.lockedPlaylistUri,
    this.redactedPlaylistUri,
    this.lockedEpgUri,
  });

  M3uFormState copyWith({
    M3uInputMode? inputMode,
    FieldState? playlistUrl,
    FieldState? playlistFilePath,
    String? fileName,
    int? fileSizeBytes,
    DateTime? fileLastModified,
    FieldState? epgUrl,
    FieldState? username,
    FieldState? password,
    FieldState? userAgent,
    FieldState? customHeaders,
    bool? autoUpdate,
    bool? followRedirects,
    bool? allowSelfSignedTls,
    bool? advancedExpanded,
    String? lockedPlaylistUri,
    String? redactedPlaylistUri,
    String? lockedEpgUri,
    bool clearFileSelection = false,
    bool clearLockedPlaylist = false,
    bool clearLockedEpg = false,
  }) {
    return M3uFormState(
      inputMode: inputMode ?? this.inputMode,
      playlistUrl: playlistUrl ?? this.playlistUrl,
      playlistFilePath: playlistFilePath ?? this.playlistFilePath,
      fileName: clearFileSelection ? null : fileName ?? this.fileName,
      fileSizeBytes: clearFileSelection
          ? null
          : fileSizeBytes ?? this.fileSizeBytes,
      fileLastModified: clearFileSelection
          ? null
          : fileLastModified ?? this.fileLastModified,
      epgUrl: epgUrl ?? this.epgUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      userAgent: userAgent ?? this.userAgent,
      customHeaders: customHeaders ?? this.customHeaders,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      followRedirects: followRedirects ?? this.followRedirects,
      allowSelfSignedTls: allowSelfSignedTls ?? this.allowSelfSignedTls,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
      lockedPlaylistUri: clearLockedPlaylist
          ? null
          : lockedPlaylistUri ?? this.lockedPlaylistUri,
      redactedPlaylistUri: clearLockedPlaylist
          ? null
          : redactedPlaylistUri ?? this.redactedPlaylistUri,
      lockedEpgUri: clearLockedEpg ? null : lockedEpgUri ?? this.lockedEpgUri,
    );
  }
}

/// Captures user input for the Xtream protocol flow.
@immutable
class XtreamFormState {
  final FieldState serverUrl;
  final FieldState username;
  final FieldState password;
  final FieldState userAgent;
  final FieldState customHeaders;
  final String outputFormat;
  final bool allowSelfSignedTls;
  final bool advancedExpanded;
  final String? lockedBaseUri;

  const XtreamFormState({
    this.serverUrl = const FieldState(),
    this.username = const FieldState(),
    this.password = const FieldState(),
    this.userAgent = const FieldState(),
    this.customHeaders = const FieldState(),
    this.outputFormat = 'ts',
    this.allowSelfSignedTls = false,
    this.advancedExpanded = false,
    this.lockedBaseUri,
  });

  XtreamFormState copyWith({
    FieldState? serverUrl,
    FieldState? username,
    FieldState? password,
    FieldState? userAgent,
    FieldState? customHeaders,
    String? outputFormat,
    bool? allowSelfSignedTls,
    bool? advancedExpanded,
    Object? lockedBaseUri = _unset,
  }) {
    return XtreamFormState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      userAgent: userAgent ?? this.userAgent,
      customHeaders: customHeaders ?? this.customHeaders,
      outputFormat: outputFormat ?? this.outputFormat,
      allowSelfSignedTls: allowSelfSignedTls ?? this.allowSelfSignedTls,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
      lockedBaseUri: lockedBaseUri == _unset
          ? this.lockedBaseUri
          : lockedBaseUri as String?,
    );
  }
}

/// Captures user input for the Stalker/Ministra flow.
@immutable
class StalkerFormState {
  final FieldState portalUrl;
  final FieldState macAddress;
  final String? lockedBaseUri;
  final FieldState userAgent;
  final FieldState customHeaders;
  final String deviceProfile;
  final bool allowSelfSignedTls;
  final bool advancedExpanded;

  const StalkerFormState({
    this.portalUrl = const FieldState(),
    this.macAddress = const FieldState(value: '00:1A:79:'),
    this.lockedBaseUri,
    this.userAgent = const FieldState(),
    this.customHeaders = const FieldState(),
    this.deviceProfile = 'MAG250',
    this.allowSelfSignedTls = false,
    this.advancedExpanded = false,
  });

  StalkerFormState copyWith({
    FieldState? portalUrl,
    FieldState? macAddress,
    Object? lockedBaseUri = _unset,
    FieldState? userAgent,
    FieldState? customHeaders,
    String? deviceProfile,
    bool? allowSelfSignedTls,
    bool? advancedExpanded,
  }) {
    return StalkerFormState(
      portalUrl: portalUrl ?? this.portalUrl,
      macAddress: macAddress ?? this.macAddress,
      lockedBaseUri: lockedBaseUri == _unset
          ? this.lockedBaseUri
          : lockedBaseUri as String?,
      userAgent: userAgent ?? this.userAgent,
      customHeaders: customHeaders ?? this.customHeaders,
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
  final LoginTestSummary? testSummary;

  const LoginFlowState({
    this.providerType = LoginProviderType.stalker,
    this.m3u = const M3uFormState(),
    this.xtream = const XtreamFormState(),
    this.stalker = const StalkerFormState(),
    this.testProgress = const LoginTestProgress(),
    this.bannerMessage,
    this.testSummary,
  });

  LoginFlowState copyWith({
    LoginProviderType? providerType,
    M3uFormState? m3u,
    XtreamFormState? xtream,
    StalkerFormState? stalker,
    LoginTestProgress? testProgress,
    String? bannerMessage,
    bool clearBanner = false,
    LoginTestSummary? testSummary,
    bool clearSummary = false,
  }) {
    return LoginFlowState(
      providerType: providerType ?? this.providerType,
      m3u: m3u ?? this.m3u,
      xtream: xtream ?? this.xtream,
      stalker: stalker ?? this.stalker,
      testProgress: testProgress ?? this.testProgress,
      bannerMessage: clearBanner ? null : bannerMessage ?? this.bannerMessage,
      testSummary: clearSummary ? null : testSummary ?? this.testSummary,
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
        clearLockedPlaylist: true,
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
        clearLockedPlaylist: true,
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
        clearFileSelection: true,
        clearLockedPlaylist: true,
      ),
    );
  }

  void setM3uFileSelection({
    required String path,
    required String fileName,
    int? fileSizeBytes,
    DateTime? lastModified,
  }) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        playlistFilePath: state.m3u.playlistFilePath.copyWith(
          value: path,
          clearError: true,
        ),
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        fileLastModified: lastModified,
        clearLockedPlaylist: true,
      ),
    );
  }

  void updateM3uFileMetadata({int? fileSizeBytes, DateTime? lastModified}) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        fileSizeBytes: fileSizeBytes ?? state.m3u.fileSizeBytes,
        fileLastModified: lastModified ?? state.m3u.fileLastModified,
      ),
    );
  }

  void updateM3uEpgUrl(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        epgUrl: state.m3u.epgUrl.copyWith(value: value, clearError: true),
        clearLockedEpg: true,
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

  void updateM3uUserAgent(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        userAgent: state.m3u.userAgent.copyWith(value: value),
      ),
    );
  }

  void updateM3uCustomHeaders(String value) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        customHeaders: state.m3u.customHeaders.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void toggleM3uAutoUpdate(bool value) {
    state = state.copyWith(m3u: state.m3u.copyWith(autoUpdate: value));
  }

  void toggleM3uFollowRedirects(bool value) {
    state = state.copyWith(m3u: state.m3u.copyWith(followRedirects: value));
  }

  void toggleM3uTlsOverride(bool allow) {
    state = state.copyWith(m3u: state.m3u.copyWith(allowSelfSignedTls: allow));
  }

  void toggleM3uAdvanced(bool expanded) {
    state = state.copyWith(m3u: state.m3u.copyWith(advancedExpanded: expanded));
  }

  void setM3uFieldErrors({
    String? playlistMessage,
    String? epgMessage,
    String? customHeaderMessage,
  }) {
    var playlistUrl = state.m3u.playlistUrl;
    var playlistFile = state.m3u.playlistFilePath;
    if (state.m3u.inputMode == M3uInputMode.url) {
      playlistUrl = playlistUrl.copyWith(
        error: playlistMessage,
        clearError: playlistMessage == null,
      );
      playlistFile = playlistFile.copyWith(clearError: true);
    } else {
      playlistFile = playlistFile.copyWith(
        error: playlistMessage,
        clearError: playlistMessage == null,
      );
      playlistUrl = playlistUrl.copyWith(clearError: true);
    }
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        playlistUrl: playlistUrl,
        playlistFilePath: playlistFile,
        epgUrl: state.m3u.epgUrl.copyWith(
          error: epgMessage,
          clearError: epgMessage == null,
        ),
        customHeaders: state.m3u.customHeaders.copyWith(
          error: customHeaderMessage,
          clearError: customHeaderMessage == null,
        ),
      ),
    );
  }

  void setM3uLockedPlaylist({required String raw, required String redacted}) {
    state = state.copyWith(
      m3u: state.m3u.copyWith(
        lockedPlaylistUri: raw,
        redactedPlaylistUri: redacted,
      ),
    );
  }

  void clearM3uLockedPlaylist() {
    state = state.copyWith(m3u: state.m3u.copyWith(clearLockedPlaylist: true));
  }

  void setM3uLockedEpg(String? redacted) {
    if (redacted == null) {
      state = state.copyWith(m3u: state.m3u.copyWith(clearLockedEpg: true));
    } else {
      state = state.copyWith(m3u: state.m3u.copyWith(lockedEpgUri: redacted));
    }
  }

  void updateXtreamServerUrl(String value) {
    final trimmed = value.trim();
    final shouldClearLock =
        state.xtream.lockedBaseUri != null &&
        state.xtream.lockedBaseUri != trimmed;
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        serverUrl: state.xtream.serverUrl.copyWith(
          value: trimmed,
          clearError: true,
        ),
        lockedBaseUri: shouldClearLock ? null : state.xtream.lockedBaseUri,
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

  void setXtreamLockedBase(String baseUri) {
    final trimmed = baseUri.trim();
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        serverUrl: state.xtream.serverUrl.copyWith(
          value: trimmed,
          clearError: true,
        ),
        lockedBaseUri: trimmed,
      ),
    );
  }

  /// Removes any stored locked base once we detect the probe is outdated.
  void clearXtreamLockedBase() {
    if (state.xtream.lockedBaseUri == null) {
      return;
    }
    state = state.copyWith(xtream: state.xtream.copyWith(lockedBaseUri: null));
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

  void updateXtreamUserAgent(String value) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        userAgent: state.xtream.userAgent.copyWith(value: value),
      ),
    );
  }

  void updateXtreamCustomHeaders(String value) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        customHeaders: state.xtream.customHeaders.copyWith(
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

  void setXtreamFieldErrors({
    String? baseUrlMessage,
    String? usernameMessage,
    String? passwordMessage,
    String? customHeaderMessage,
  }) {
    state = state.copyWith(
      xtream: state.xtream.copyWith(
        serverUrl: state.xtream.serverUrl.copyWith(
          error: baseUrlMessage,
          clearError: baseUrlMessage == null,
        ),
        username: state.xtream.username.copyWith(
          error: usernameMessage,
          clearError: usernameMessage == null,
        ),
        password: state.xtream.password.copyWith(
          error: passwordMessage,
          clearError: passwordMessage == null,
        ),
        customHeaders: state.xtream.customHeaders.copyWith(
          error: customHeaderMessage,
          clearError: customHeaderMessage == null,
        ),
      ),
    );
  }

  void updateStalkerPortalUrl(String value) {
    final trimmed = value.trim();
    final shouldClearLock =
        state.stalker.lockedBaseUri != null &&
        state.stalker.lockedBaseUri != trimmed;
    state = state.copyWith(
      stalker: state.stalker.copyWith(
        portalUrl: state.stalker.portalUrl.copyWith(
          value: trimmed,
          clearError: true,
        ),
        lockedBaseUri: shouldClearLock ? null : state.stalker.lockedBaseUri,
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

  void updateStalkerUserAgent(String value) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(
        userAgent: state.stalker.userAgent.copyWith(value: value),
      ),
    );
  }

  void updateStalkerCustomHeaders(String value) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(
        customHeaders: state.stalker.customHeaders.copyWith(
          value: value,
          clearError: true,
        ),
      ),
    );
  }

  void updateStalkerDeviceProfile(String value) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(deviceProfile: value),
    );
  }

  void setStalkerLockedBase(String baseUri) {
    final trimmed = baseUri.trim();
    state = state.copyWith(
      stalker: state.stalker.copyWith(
        portalUrl: state.stalker.portalUrl.copyWith(
          value: trimmed,
          clearError: true,
        ),
        lockedBaseUri: trimmed,
      ),
    );
  }

  void clearStalkerLockedBase() {
    if (state.stalker.lockedBaseUri == null) {
      return;
    }
    state = state.copyWith(
      stalker: state.stalker.copyWith(lockedBaseUri: null),
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

  void setStalkerFieldErrors({
    String? portalMessage,
    String? macMessage,
    String? customHeaderMessage,
  }) {
    state = state.copyWith(
      stalker: state.stalker.copyWith(
        portalUrl: state.stalker.portalUrl.copyWith(
          error: portalMessage,
          clearError: portalMessage == null,
        ),
        macAddress: state.stalker.macAddress.copyWith(
          error: macMessage,
          clearError: macMessage == null,
        ),
        customHeaders: state.stalker.customHeaders.copyWith(
          error: customHeaderMessage,
          clearError: customHeaderMessage == null,
        ),
      ),
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
      clearSummary: true,
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
      clearSummary: true,
    );
  }

  /// Stores the success summary and marks the sequence as complete.
  void setTestSummary(LoginTestSummary summary) {
    final progress = state.testProgress;
    state = state.copyWith(
      testSummary: summary,
      testProgress: progress.copyWith(inProgress: false, steps: progress.steps),
      clearBanner: true,
    );
  }

  /// Resets the test panel after success or when the user cancels.
  void resetTestProgress() {
    state = state.copyWith(
      testProgress: const LoginTestProgress(),
      clearBanner: true,
      clearSummary: true,
    );
  }

  /// Returns the list of step states for convenience.
  List<LoginTestStepState> get steps => state.testProgress.steps;

  /// Simple URL pattern check; intentionally lenient to keep the UX friendly.
  bool _looksLikeUrl(String input) {
    final value = input.trim();
    if (value.isEmpty) return false;
    return tryParseLenientHttpUri(value) != null;
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
