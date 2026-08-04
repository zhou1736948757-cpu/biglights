import Foundation
import ServiceManagement
import OSLog

enum MaxRefreshRate: Double, CaseIterable {
    case hz60 = 60
    case hz120 = 120

    func title(language: AppLanguage) -> String {
        switch self {
        case .hz60: return AppLocalization.string(.refreshRate60, language: language)
        case .hz120: return AppLocalization.string(.refreshRate120, language: language)
        }
    }

    var interval: TimeInterval { 1.0 / rawValue }
}

enum ControlStyle: String, CaseIterable {
    case macOS
    case edgeSquares

    func title(language: AppLanguage) -> String {
        switch self {
        case .macOS: return AppLocalization.string(.appearanceMacOS, language: language)
        case .edgeSquares: return AppLocalization.string(.appearanceEdgeSquares, language: language)
        }
    }
}

enum HiddenTrafficLightRevealMode: String, CaseIterable {
    case group
    case nearest

    func title(language: AppLanguage) -> String {
        switch self {
        case .group: return AppLocalization.string(.revealGroup, language: language)
        case .nearest: return AppLocalization.string(.revealSingle, language: language)
        }
    }
}

final class Preferences: ObservableObject {
    private enum Key {
        static let language = "appLanguage"
        static let menuBarIconVisible = "menuBarIconVisible"
        static let enabled = "enabled"
        static let size = "controlSize"
        static let spacing = "controlSpacingAdjustment"
        static let style = "controlStyle"
        static let hiddenTrafficLightsEnabled = "hiddenTrafficLightsEnabled"
        static let hiddenTrafficLightRevealMode = "hiddenTrafficLightRevealMode"
        static let showInFullScreen = "showInFullScreen"
        static let activeAppOnly = "activeAppOnly"
        static let maxRefreshRate = "maxRefreshRate"
        static let launchAtLogin = "launchAtLogin"
        static let dockClickMinimizesActiveWindow = "dockClickMinimizesActiveWindow"
        static let stageManagerCloseButtonsEnabled = "stageManagerCloseButtonsEnabled"
        static let closeBehavior = "closeButtonBehavior"
        static let minimizeBehavior = "minimizeButtonBehavior"
        static let zoomBehavior = "zoomButtonBehavior"
    }

    private let defaults: UserDefaults

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Key.language) }
    }

    @Published var menuBarIconVisible: Bool {
        didSet { defaults.set(menuBarIconVisible, forKey: Key.menuBarIconVisible) }
    }

    @Published var enabled: Bool {
        didSet { defaults.set(enabled, forKey: Key.enabled) }
    }

    @Published var size: Double {
        didSet { defaults.set(size, forKey: Key.size) }
    }

    @Published var spacing: Double {
        didSet { defaults.set(spacing, forKey: Key.spacing) }
    }

    @Published var style: ControlStyle {
        didSet { defaults.set(style.rawValue, forKey: Key.style) }
    }

    @Published var hiddenTrafficLightsEnabled: Bool {
        didSet { defaults.set(hiddenTrafficLightsEnabled, forKey: Key.hiddenTrafficLightsEnabled) }
    }

    @Published var hiddenTrafficLightRevealMode: HiddenTrafficLightRevealMode {
        didSet { defaults.set(hiddenTrafficLightRevealMode.rawValue, forKey: Key.hiddenTrafficLightRevealMode) }
    }

    @Published private(set) var showInFullScreen: Bool

    @Published var activeAppOnly: Bool {
        didSet { defaults.set(activeAppOnly, forKey: Key.activeAppOnly) }
    }

    @Published var maxRefreshRate: MaxRefreshRate {
        didSet { defaults.set(maxRefreshRate.rawValue, forKey: Key.maxRefreshRate) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
            Self.syncLaunchAtLogin(enabled: launchAtLogin)
        }
    }

    @Published var dockClickMinimizesActiveWindow: Bool {
        didSet { defaults.set(dockClickMinimizesActiveWindow, forKey: Key.dockClickMinimizesActiveWindow) }
    }

    @Published var stageManagerCloseButtonsEnabled: Bool {
        didSet { defaults.set(stageManagerCloseButtonsEnabled, forKey: Key.stageManagerCloseButtonsEnabled) }
    }

    @Published var closeBehavior: ButtonBehavior {
        didSet { defaults.set(closeBehavior.rawValue, forKey: Key.closeBehavior) }
    }

    @Published var minimizeBehavior: ButtonBehavior {
        didSet { defaults.set(minimizeBehavior.rawValue, forKey: Key.minimizeBehavior) }
    }

    @Published var zoomBehavior: ButtonBehavior {
        didSet { defaults.set(zoomBehavior.rawValue, forKey: Key.zoomBehavior) }
    }

    init(
        defaults: UserDefaults = .standard,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) {
        self.defaults = defaults
        let systemLanguage = AppLanguage.systemDefault(preferredLanguages: preferredLanguages)
        let storedLanguageValue = defaults.object(forKey: Key.language) as? String
        let initialLanguage = storedLanguageValue.flatMap(AppLanguage.init(rawValue:)) ?? systemLanguage
        defaults.register(defaults: [
            Key.menuBarIconVisible: true,
            Key.enabled: true,
            Key.size: ControlLayout.defaultSize,
            Key.spacing: ControlLayout.defaultSpacingAdjustment,
            Key.style: ControlStyle.macOS.rawValue,
            Key.hiddenTrafficLightsEnabled: true,
            Key.hiddenTrafficLightRevealMode: HiddenTrafficLightRevealMode.nearest.rawValue,
            Key.showInFullScreen: false,
            Key.activeAppOnly: true,
            Key.maxRefreshRate: MaxRefreshRate.hz120.rawValue,
            Key.launchAtLogin: false,
            Key.dockClickMinimizesActiveWindow: true,
            Key.stageManagerCloseButtonsEnabled: true,
            Key.closeBehavior: ButtonBehavior.closeWindow.rawValue,
            Key.minimizeBehavior: ButtonBehavior.minimizeWindow.rawValue,
            Key.zoomBehavior: ButtonBehavior.zoomWindow.rawValue
        ])
        language = initialLanguage
        if storedLanguageValue != nil, AppLanguage(rawValue: storedLanguageValue ?? "") == nil {
            defaults.set(initialLanguage.rawValue, forKey: Key.language)
        }
        menuBarIconVisible = defaults.bool(forKey: Key.menuBarIconVisible)
        enabled = defaults.bool(forKey: Key.enabled)
        size = Double(ControlLayout.effectiveSize(preferred: defaults.double(forKey: Key.size)))
        spacing = Double(ControlLayout.effectiveSpacingAdjustment(preferred: defaults.double(forKey: Key.spacing)))
        style = ControlStyle(rawValue: defaults.string(forKey: Key.style) ?? "") ?? .macOS
        hiddenTrafficLightsEnabled = defaults.bool(forKey: Key.hiddenTrafficLightsEnabled)
        hiddenTrafficLightRevealMode = HiddenTrafficLightRevealMode(
            rawValue: defaults.string(forKey: Key.hiddenTrafficLightRevealMode) ?? ""
        ) ?? .nearest
        showInFullScreen = false
        defaults.set(false, forKey: Key.showInFullScreen)
        activeAppOnly = defaults.bool(forKey: Key.activeAppOnly)
        maxRefreshRate = MaxRefreshRate(rawValue: defaults.double(forKey: Key.maxRefreshRate)) ?? .hz120
        // Sync launch-at-login state with SMAppService on startup.
        // Read the actual SMAppService status rather than the stored
        // preference so the toggle stays in sync if the user changes
        // it in System Settings > General > Login Items.
        launchAtLogin = Self.readLaunchAtLoginFromService()
        dockClickMinimizesActiveWindow = defaults.bool(forKey: Key.dockClickMinimizesActiveWindow)
        stageManagerCloseButtonsEnabled = defaults.bool(forKey: Key.stageManagerCloseButtonsEnabled)
        closeBehavior = ButtonBehavior(rawValue: defaults.string(forKey: Key.closeBehavior) ?? "") ?? .closeWindow
        minimizeBehavior = ButtonBehavior(rawValue: defaults.string(forKey: Key.minimizeBehavior) ?? "") ?? .minimizeWindow
        zoomBehavior = ButtonBehavior(rawValue: defaults.string(forKey: Key.zoomBehavior) ?? "") ?? .zoomWindow
    }

    func behavior(for action: WindowAction) -> ButtonBehavior {
        switch action {
        case .close: return closeBehavior
        case .minimize: return minimizeBehavior
        case .zoom: return zoomBehavior
        }
    }

    func resetButtonBehaviors() {
        closeBehavior = .closeWindow
        minimizeBehavior = .minimizeWindow
        zoomBehavior = .zoomWindow
    }

    var hasCloseWindowBehavior: Bool {
        [closeBehavior, minimizeBehavior, zoomBehavior].contains(.closeWindow)
    }

    private static func syncLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration can fail if the app is not code-signed with a
            // Developer ID.  Ad-hoc signed builds log the error but
            // otherwise continue gracefully.
            Logger(subsystem: "com.biglights.mac", category: "preferences")
                .error("Failed to \(enabled ? "register" : "unregister") launch-at-login: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func readLaunchAtLoginFromService() -> Bool {
        SMAppService.mainApp.status == .enabled
    }
}
