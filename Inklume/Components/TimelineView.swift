//
//  TimelineView.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import SwiftUI

struct TimelineEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var editor: EditorViewModel

    var body: some View {
        NavigationStack {
            TimelineView(editor: editor)
                .navigationTitle("Animation")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onDisappear {
            editor.pausePlayback()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("timelineEditorSheet")
    }
}

struct TimelineView: View {
    @Bindable var editor: EditorViewModel

    private var selectedLayerKeyframes: [LayerKeyframe] {
        guard let layerID = editor.selectedLayerID else { return [] }
        return editor.project.timeline.keyframes
            .filter { $0.layerID == layerID }
            .sorted { $0.time < $1.time }
    }

    var body: some View {
        VStack(spacing: 0) {
            playbackControls
            Divider()
            timelineSettings
            Divider()
            trackEditor
        }
        .task(id: editor.isPlaying) {
            guard editor.isPlaying else { return }
            var previousDate = Date()
            let framesPerSecond = max(
                editor.project.timeline.framesPerSecond,
                1
            )
            let frameDuration = Duration.seconds(1.0 / Double(framesPerSecond))

            while !Task.isCancelled && editor.isPlaying {
                try? await Task.sleep(for: frameDuration)
                guard !Task.isCancelled else { return }
                let currentDate = Date()
                editor.advancePlayback(
                    by: currentDate.timeIntervalSince(previousDate)
                )
                previousDate = currentDate
            }
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 16) {
            Button("Previous Frame", systemImage: "backward.frame.fill") {
                step(by: -1)
            }
            Button(
                editor.isPlaying ? "Pause" : "Play",
                systemImage: editor.isPlaying ? "pause.fill" : "play.fill"
            ) {
                editor.isPlaying
                    ? editor.pausePlayback() : editor.startPlayback()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("timelinePlayPauseButton")
            Button("Stop", systemImage: "stop.fill") {
                editor.stopPlayback()
            }
            .accessibilityIdentifier("timelineStopButton")
            Button("Next Frame", systemImage: "forward.frame.fill") {
                step(by: 1)
            }
            Spacer()
            Text(editor.playhead, format: .number.precision(.fractionLength(2)))
                .font(.body.monospacedDigit())
            Text("/")
                .foregroundStyle(.secondary)
            Text(
                editor.project.timeline.duration,
                format: .number.precision(.fractionLength(2))
            )
            .font(.body.monospacedDigit())
        }
        .labelStyle(.iconOnly)
        .padding()
    }

    private var timelineSettings: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("Duration")
                TextField(
                    "Seconds",
                    value: $editor.project.timeline.duration,
                    format: .number
                )
                .keyboardType(.decimalPad)
                .frame(width: 64)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("durationField")

                Text("FPS")
                TextField(
                    "FPS",
                    value: $editor.project.timeline.framesPerSecond,
                    format: .number
                )
                .keyboardType(.numberPad)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("fpsField")
                Spacer(minLength: 0)
            }
            Toggle(
                "Loop animation",
                isOn: $editor.project.timeline.loopsInfinitely
            )
            .accessibilityIdentifier("loopToggle")
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var trackEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    editor.selectedLayer?.name ?? "Select a Layer",
                    systemImage: "square.3.layers.3d"
                )
                .font(.headline)
                Spacer()
                Button("Add Keyframe", systemImage: "diamond.fill") {
                    editor.addKeyframe()
                }
                .disabled(editor.selectedLayer == nil)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondary.opacity(0.12))

                    ForEach(selectedLayerKeyframes) { keyframe in
                        Button {
                            editor.playhead = keyframe.time
                            editor.pausePlayback()
                        } label: {
                            Image(systemName: "diamond.fill")
                                .font(.title3)
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                        .position(
                            x: xPosition(
                                for: keyframe.time,
                                width: proxy.size.width
                            ),
                            y: proxy.size.height / 2
                        )
                        .contextMenu {
                            Button(
                                "Delete Keyframe",
                                systemImage: "trash",
                                role: .destructive
                            ) {
                                editor.removeKeyframe(keyframe.id)
                            }
                        }
                    }

                    Rectangle()
                        .fill(.red)
                        .frame(width: 2)
                        .offset(
                            x: xPosition(
                                for: editor.playhead,
                                width: proxy.size.width
                            )
                        )
                        .allowsHitTesting(false)
                }
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            editor.pausePlayback()
                            editor.playhead = time(
                                for: value.location.x,
                                width: proxy.size.width
                            )
                        }
                )
            }
            .frame(minHeight: 100)

            HStack {
                Text("0 s")
                Spacer()
                Text(
                    editor.project.timeline.duration,
                    format: .number.precision(.fractionLength(1))
                )
                .monospacedDigit()
                Text("s")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if selectedLayerKeyframes.isEmpty {
                ContentUnavailableView(
                    "No Keyframes",
                    systemImage: "diamond",
                    description: Text(
                        "Move the playhead, adjust the selected layer, then add a keyframe."
                    )
                )
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedLayerKeyframes) { keyframe in
                            Button {
                                editor.playhead = keyframe.time
                            } label: {
                                VStack {
                                    Image(systemName: "diamond.fill")
                                    Text(
                                        keyframe.time,
                                        format: .number.precision(
                                            .fractionLength(2)
                                        )
                                    )
                                    .monospacedDigit()
                                }
                                .padding(8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func step(by frameCount: Int) {
        editor.pausePlayback()
        let frameDuration =
            1.0 / Double(max(editor.project.timeline.framesPerSecond, 1))
        editor.playhead = min(
            max(editor.playhead + Double(frameCount) * frameDuration, 0),
            max(editor.project.timeline.duration, 0)
        )
    }

    private func xPosition(for time: TimeInterval, width: CGFloat) -> CGFloat {
        let duration = max(editor.project.timeline.duration, 0.01)
        return min(max(CGFloat(time / duration) * width, 0), width)
    }

    private func time(for x: CGFloat, width: CGFloat) -> TimeInterval {
        guard width > 0 else { return 0 }
        return TimeInterval(min(max(x / width, 0), 1))
            * max(editor.project.timeline.duration, 0)
    }
}
