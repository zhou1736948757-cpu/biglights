import SwiftUI
import ApplicationServices
import AppKit
import UniformTypeIdentifiers

private enum SettingsSection: String, CaseIterable, Identifiable {
    case display
    case appearance
    case behavior
    case actions
    case updates

    var id: String { rawValue }

    func title(_ localized: (AppString) -> String) -> String {
        switch self {
        case .display: return localized(.sectionDisplay)
        case .appearance: return localized(.sectionAppearance)
        case .behavior: return localized(.sectionBehavior)
        case .actions: return localized(.buttonActions)
        case .updates: return localized(.softwareUpdates)
        }
    }

    var icon: String {
        switch self {
        case .display: return "display"
        case .appearance: return "paintbrush"
        case .behavior: return "slider.horizontal.3"
        case .actions: return "square.grid.2x2"
        case .updates: return "arrow.triangle.2.circlepath"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var updateController: UpdateController
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var selectedSection: SettingsSection? = .display

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(selection: $selectedSection) {
                    ForEach(SettingsSection.allCases) { section in
                        Label(
                            section.title { AppLocalization.string($0, language: preferences.language) },
                            systemImage: section.icon
                        )
                        .tag(section)
                    }
                }
                .navigationSplitViewColumnWidth(min: 170, ideal: 180, max: 220)
            } detail: {
                detailContent
            }
            .frame(minWidth: 560, minHeight: 420)

            Divider()
            permissionStatus
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        .frame(width: 640, height: 520)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            accessibilityGranted = AXIsProcessTrusted()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                header
                switch selectedSection {
                case .display:
                    displaySection
                case .appearance:
                    appearanceSection
                case .behavior:
                    behaviorSection
                case .actions:
                    buttonActions
                case .updates:
                    softwareUpdates
                case nil:
                    EmptyView()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("BigLights")
                    .font(.title2.bold())
                Text(localized(.settingsSubtitle))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var displaySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                languageSelector
                Divider()
                menuBarIconToggle
                Divider()
                overlayToggle
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(localized(.sectionDisplay), systemImage: "display")
                .font(.headline)
        }
    }

    private var appearanceSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                preview
                Divider()
                appearancePicker
                Divider()
                sizeSlider
                if preferences.style == .macOS {
                    Divider()
                    spacingSlider
                }
                Divider()
                hiddenControls
                Divider()
                Toggle(localized(.fullScreenInDevelopment), isOn: .constant(false))
                    .disabled(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(localized(.sectionAppearance), systemImage: "paintbrush")
                .font(.headline)
        }
    }

    private var behaviorSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                activeAppOnlyToggle
                Divider()
                maxRefreshRatePicker
                Divider()
                dockClickToggle
                Divider()
                stageManagerToggle
                Divider()
                launchAtLoginToggle
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(localized(.sectionBehavior), systemImage: "slider.horizontal.3")
                .font(.headline)
        }
    }

    private var languageSelector: some View {
        HStack(spacing: 12) {
            Text(localized(.languageLabel))
                .font(.headline)
            Spacer()
            Picker(localized(.languageLabel), selection: $preferences.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)
        }
    }

    private var menuBarIconToggle: some View {
        HStack {
            Text(localized(.menuBarIconVisible))
                .font(.headline)
            Spacer()
            Toggle("", isOn: $preferences.menuBarIconVisible)
                .labelsHidden()
                .toggleStyle(.switch)
                .help(localized(.menuBarIconVisibleHelp))
                .accessibilityLabel(localized(.menuBarIconVisible))
        }
    }

    private var overlayToggle: some View {
        HStack {
            Text(localized(.overlayEnabled))
                .font(.headline)
            Spacer()
            Toggle("", isOn: $preferences.enabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel(localized(.overlayEnabled))
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized(.livePreview))
                .font(.headline)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color(nsColor: .separatorColor))
                            .frame(height: 1)
                    }
                previewButtons
                    .padding(.leading, preferences.style == .macOS ? 12 : 0)
                    .padding(.top, preferences.style == .macOS ? 8 : 0)
            }
            .frame(height: max(64, CGFloat(preferences.size) + 16))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            }
        }
    }

    private var previewButtons: some View {
        let size = CGFloat(preferences.size)
        let spacing: CGFloat = preferences.style == .macOS
            ? max(-size + 4, 8 + CGFloat(preferences.spacing))
            : 0
        return HStack(spacing: spacing) {
            PreviewControl(
                action: .close,
                behavior: preferences.closeBehavior,
                style: preferences.style,
                size: size,
                language: preferences.language
            )
                .frame(width: size, height: size)
            PreviewControl(
                action: .minimize,
                behavior: preferences.minimizeBehavior,
                style: preferences.style,
                size: size,
                language: preferences.language
            )
                .frame(width: size, height: size)
            PreviewControl(
                action: .zoom,
                behavior: preferences.zoomBehavior,
                style: preferences.style,
                size: size,
                language: preferences.language
            )
                .frame(width: size, height: size)
        }
    }

    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized(.appearance))
                .font(.headline)
            Picker(localized(.appearance), selection: $preferences.style) {
                ForEach(ControlStyle.allCases, id: \.self) { style in
                    Text(style.title(language: preferences.language)).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var sizeSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localized(.buttonSize))
                    .font(.headline)
                Spacer()
                Text("\(Int(preferences.size)) pt")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Button(localized(.restoreDefault)) { preferences.size = ControlLayout.defaultSize }
                    .buttonStyle(.link)
            }
            HStack(spacing: 10) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Slider(value: $preferences.size, in: ControlLayout.sizeRange, step: 1)
                    .accessibilityLabel(localized(.buttonSize))
                    .accessibilityValue("\(Int(preferences.size)) pt")
                Image(systemName: "circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var spacingSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localized(.buttonSpacing))
                    .font(.headline)
                Spacer()
                Text(spacingDescription)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Button(localized(.restoreSystemSpacing)) {
                    preferences.spacing = ControlLayout.defaultSpacingAdjustment
                }
                    .buttonStyle(.link)
            }
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.and.right")
                    .foregroundStyle(.secondary)
                Slider(
                    value: $preferences.spacing,
                    in: ControlLayout.spacingAdjustmentRange,
                    step: 1
                )
                .accessibilityLabel(localized(.buttonSpacing))
                .accessibilityValue(spacingDescription)
                Image(systemName: "arrow.left.and.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hiddenControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(localized(.hiddenTrafficLights), isOn: $preferences.hiddenTrafficLightsEnabled)

            if preferences.hiddenTrafficLightsEnabled {
                Picker(localized(.revealMode), selection: $preferences.hiddenTrafficLightRevealMode) {
                    ForEach(HiddenTrafficLightRevealMode.allCases, id: \.self) { mode in
                        Text(mode.title(language: preferences.language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    private var activeAppOnlyToggle: some View {
        HStack {
            Text(localized(.activeAppOnly))
                .font(.headline)
            Spacer()
            Toggle("", isOn: $preferences.activeAppOnly)
                .labelsHidden()
                .toggleStyle(.switch)
                .help(localized(.activeAppOnlyHelp))
                .accessibilityLabel(localized(.activeAppOnly))
        }
    }

    private var maxRefreshRatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized(.maxRefreshRate))
                .font(.headline)
            Picker(localized(.maxRefreshRate), selection: $preferences.maxRefreshRate) {
                ForEach(MaxRefreshRate.allCases, id: \.self) { rate in
                    Text(rate.title(language: preferences.language)).tag(rate)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var launchAtLoginToggle: some View {
        HStack {
            Text(localized(.launchAtLogin))
                .font(.headline)
            Spacer()
            Toggle("", isOn: $preferences.launchAtLogin)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel(localized(.launchAtLogin))
        }
    }

    private var dockClickToggle: some View {
        HStack {
            Text(localized(.dockClickMinimize))
                .font(.headline)
            Spacer()
            Toggle("", isOn: $preferences.dockClickMinimizesActiveWindow)
                .labelsHidden()
                .toggleStyle(.switch)
                .help(localized(.dockClickMinimizeHelp))
                .accessibilityLabel(localized(.dockClickMinimize))
        }
    }

    private var stageManagerToggle: some View {
        HStack {
            Text(localized(.stageManagerCloseButtons))
                .font(.headline)
            Spacer()
            Toggle("", isOn: $preferences.stageManagerCloseButtonsEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .help(localized(.stageManagerCloseButtonsHelp))
                .accessibilityLabel(localized(.stageManagerCloseButtons))
        }
    }

    private var buttonActions: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localized(.buttonActions))
                        .font(.headline)
                    Spacer()
                    Button(localized(.restoreDefault)) { preferences.resetButtonBehaviors() }
                        .buttonStyle(.link)
                }
                behaviorRow(
                    title: localized(.redButton),
                    color: Color(red: 1.0, green: 0.37255, blue: 0.34118),
                    selection: $preferences.closeBehavior
                )
                behaviorRow(
                    title: localized(.yellowButton),
                    color: Color(red: 0.99608, green: 0.73725, blue: 0.18039),
                    selection: $preferences.minimizeBehavior
                )
                behaviorRow(
                    title: localized(.greenButton),
                    color: Color(red: 0.15686, green: 0.78431, blue: 0.25098),
                    selection: $preferences.zoomBehavior
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(localized(.buttonActions), systemImage: "square.grid.2x2")
                .font(.headline)
        }
    }

    private var softwareUpdates: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(localized(.softwareUpdates))
                    .font(.headline)
                Toggle(
                    localized(.automaticallyCheckForUpdates),
                    isOn: Binding(
                        get: { updateController.automaticallyChecksForUpdates },
                        set: updateController.setAutomaticallyChecksForUpdates
                    )
                )
                .disabled(!updateController.updaterAvailable)
                Toggle(
                    localized(.automaticallyDownloadUpdates),
                    isOn: Binding(
                        get: { updateController.automaticallyDownloadsUpdates },
                        set: updateController.setAutomaticallyDownloadsUpdates
                    )
                )
                .disabled(!updateController.automaticDownloadsControlEnabled)
                Button(action: updateController.checkForUpdates) {
                    Label(localized(.checkForUpdates), systemImage: "arrow.clockwise")
                }
                .disabled(!updateController.canCheckForUpdates)
                if !updateController.updaterAvailable {
                    Text(localized(.updatesUnavailable))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(localized(.softwareUpdates), systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
        }
    }

    private var spacingDescription: String {
        let spacing = Int(preferences.spacing)
        if spacing == 0 { return localized(.systemSpacing) }
        return spacing > 0 ? "+\(spacing) pt" : "\(spacing) pt"
    }

    private func behaviorRow(
        title: String,
        color: Color,
        selection: Binding<ButtonBehavior>
    ) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(ButtonBehavior.allCases) { behavior in
                    Text(behavior.title(language: preferences.language)).tag(behavior)
                }
            }
            .labelsHidden()
            .frame(width: 190)
        }
    }

    private var permissionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accessibilityGranted ? Color.green : Color.orange)
                .frame(width: 9, height: 9)
            Text(localized(accessibilityGranted ? .accessibilityGranted : .accessibilityRequired))
                .foregroundStyle(.secondary)
            Spacer()
            if !accessibilityGranted {
                Button(localized(.openAccessibilitySettings)) { requestAccessibility() }
            }
        }
    }

    private func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func localized(_ key: AppString, arguments: CVarArg...) -> String {
        AppLocalization.string(key, language: preferences.language, arguments: arguments)
    }
}

private struct PreviewControl: NSViewRepresentable {
    let action: WindowAction
    let behavior: ButtonBehavior
    let style: ControlStyle
    let size: CGFloat
    let language: AppLanguage

    func makeNSView(context: Context) -> OverlayButtonView {
        OverlayButtonView(action: action)
    }

    func updateNSView(_ view: OverlayButtonView, context: Context) {
        view.style = style
        view.controlSize = size
        view.language = language
        view.behavior = behavior
        view.isWindowActive = true
        view.needsDisplay = true
    }
}
