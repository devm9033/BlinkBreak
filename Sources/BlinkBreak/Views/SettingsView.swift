import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.colorScheme) var colorScheme

    public init() {}

    private var isLight: Bool {
        colorScheme == .light
    }

    private let breakPresets = [15, 20, 30, 45]

    public var body: some View {
        VStack(spacing: 0) {
            // Header: Clean app identity
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(isLight ? 0.15 : 0.22))
                        .frame(width: 44, height: 44)

                    Image(systemName: "eye.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("BlinkBreak")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("v2.0")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text("Ergonomic screen break & eye hydration reminders")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Content: Grouped cards
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {

                    // Section 1: Break Reminder
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.cyan)
                            Text("Break Reminder (Look Away)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        // Interval slider with haptics
                        VStack(spacing: 8) {
                            HStack {
                                Text("Interval:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 75, alignment: .leading)

                                Slider(
                                    value: Binding(
                                        get: { Double(settings.breakIntervalMinutes) },
                                        set: { newVal in
                                            let intVal = Int(round(newVal))
                                            if intVal != settings.breakIntervalMinutes {
                                                HapticManager.shared.sliderTick()
                                                settings.breakIntervalMinutes = intVal
                                            }
                                        }
                                    ),
                                    in: 5...60
                                )

                                Text("\(settings.breakIntervalMinutes) min")
                                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.primary)
                                    .frame(width: 58, alignment: .trailing)
                            }

                            // Quick Presets
                            HStack(spacing: 6) {
                                Text("Presets:")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .frame(width: 75, alignment: .leading)

                                ForEach(breakPresets, id: \.self) { preset in
                                    Button {
                                        if settings.breakIntervalMinutes != preset {
                                            HapticManager.shared.buttonClick()
                                            settings.breakIntervalMinutes = preset
                                        }
                                    } label: {
                                        Text("\(preset)m")
                                            .font(.system(size: 11, weight: settings.breakIntervalMinutes == preset ? .bold : .medium, design: .rounded))
                                            .foregroundColor(settings.breakIntervalMinutes == preset ? (isLight ? .white : .primary) : .secondary)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(settings.breakIntervalMinutes == preset ? Color.cyan : Color.secondary.opacity(0.12))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()
                            }
                        }

                        Divider().opacity(0.6)

                        // Duration slider with haptics
                        HStack {
                            Text("Duration:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 75, alignment: .leading)

                            Slider(
                                value: Binding(
                                    get: { Double(settings.breakDurationSeconds) },
                                    set: { newVal in
                                        let intVal = Int(round(newVal / 5.0) * 5.0)
                                        if intVal != settings.breakDurationSeconds {
                                            HapticManager.shared.sliderTick()
                                            settings.breakDurationSeconds = intVal
                                        }
                                    }
                                ),
                                in: 10...60
                            )

                            Text("\(settings.breakDurationSeconds) sec")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                                .frame(width: 58, alignment: .trailing)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )

                    // Section 2: Blink Reminder
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.cyan)
                            Text("Blink Reminder (Micro-Nudge)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        HStack {
                            Text("Interval:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 75, alignment: .leading)

                            Slider(
                                value: Binding(
                                    get: { Double(settings.blinkIntervalMinutes) },
                                    set: { newVal in
                                        let intVal = Int(round(newVal))
                                        if intVal != settings.blinkIntervalMinutes {
                                            HapticManager.shared.sliderTick()
                                            settings.blinkIntervalMinutes = intVal
                                        }
                                    }
                                ),
                                in: 1...20
                            )

                            Text("\(settings.blinkIntervalMinutes) min")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                                .frame(width: 58, alignment: .trailing)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )

                    // Section 3: Smart Video Playback Detection
                    VStack(alignment: .leading, spacing: 13) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.tv")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.cyan)
                            Text("Smart Video Detection")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        Text("Automatically detects video playback in browsers (Safari, Chrome, Arc) and media players (QuickTime, VLC, TV).")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)

                        Divider().opacity(0.6)

                        // Option 1: Pause Break Timer
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pause eye rest breaks")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Prevents fullscreen rest screens from interrupting videos")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $settings.pauseBreaksDuringVideo)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .onChange(of: settings.pauseBreaksDuringVideo) { _ in
                                    HapticManager.shared.buttonClick()
                                }
                        }

                        // Option 2: Pause Blink Reminder
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pause blink reminders")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Prevents notch micro-capsule popups during videos")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $settings.pauseBlinksDuringVideo)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .onChange(of: settings.pauseBlinksDuringVideo) { _ in
                                    HapticManager.shared.buttonClick()
                                }
                        }

                        Divider().opacity(0.6)

                        // Live status indicator
                        HStack(spacing: 7) {
                            Circle()
                                .fill(BreakManager.shared.isVideoPlaying ? Color.green : Color.secondary.opacity(0.4))
                                .frame(width: 7, height: 7)

                            if BreakManager.shared.isVideoPlaying {
                                let proc = BreakManager.shared.videoProcessName.map { " in \($0)" } ?? ""
                                let breakPart = settings.pauseBreaksDuringVideo ? "Breaks paused" : "Breaks active"
                                let blinkPart = settings.pauseBlinksDuringVideo ? "Blinks paused" : "Blinks active"
                                Text("Video playing\(proc) — \(breakPart), \(blinkPart)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.green)
                            } else {
                                Text("No video detected — Regular schedule active")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )

                    // Section 4: Native Sound Alerts
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.cyan)
                                Text("Notification Sounds")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Toggle("", isOn: $settings.soundEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .onChange(of: settings.soundEnabled) { _ in
                                    HapticManager.shared.buttonClick()
                                }
                        }

                        if settings.soundEnabled {
                            Divider().opacity(0.6)

                            // Blink sound picker
                            HStack {
                                Text("Blink sound:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 90, alignment: .leading)

                                Picker("", selection: Binding(
                                    get: { settings.blinkSoundName },
                                    set: { newSound in
                                        settings.blinkSoundName = newSound
                                        SoundManager.shared.playSound(name: newSound)
                                        HapticManager.shared.sliderTick()
                                    }
                                )) {
                                    ForEach(SoundManager.availableBlinkSounds, id: \.self) { sound in
                                        Text(sound == "None" ? "None (Mute)" : sound).tag(sound)
                                    }
                                }
                                .pickerStyle(.menu)

                                Button {
                                    SoundManager.shared.playSound(name: settings.blinkSoundName)
                                } label: {
                                    Image(systemName: "speaker.wave.1.fill")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.borderless)
                                .help("Preview sound")
                            }

                            // Break sound picker
                            HStack {
                                Text("Break sound:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 90, alignment: .leading)

                                Picker("", selection: Binding(
                                    get: { settings.breakSoundName },
                                    set: { newSound in
                                        settings.breakSoundName = newSound
                                        SoundManager.shared.playSound(name: newSound)
                                        HapticManager.shared.sliderTick()
                                    }
                                )) {
                                    ForEach(SoundManager.availableBreakSounds, id: \.self) { sound in
                                        Text(sound == "None" ? "None (Mute)" : sound).tag(sound)
                                    }
                                }
                                .pickerStyle(.menu)

                                Button {
                                    SoundManager.shared.playSound(name: settings.breakSoundName)
                                } label: {
                                    Image(systemName: "speaker.wave.1.fill")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.borderless)
                                .help("Preview sound")
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )

                    // Section 4: Live Tests
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Button {
                                HapticManager.shared.buttonClick()
                                BreakManager.shared.startBreak(forcedDuration: 10)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.walk")
                                    Text("Test Break Screen")
                                }
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }

                            Button {
                                HapticManager.shared.buttonClick()
                                BreakManager.shared.triggerBlink()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "eye")
                                    Text("Test Blink Nudge")
                                }
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }

                            Spacer()
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 460, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
