/*
 ImageViseView.swift
 UserInterface

 Created by Takuto Nakamura on 2024/11/30.
 
*/

import DataSource
import Model
import SwiftUI
import UniformTypeIdentifiers

struct ImageViseView: View {
    @StateObject var store: ImageVise

    var body: some View {
        VStack {
            List {
                ForEach(store.imageFiles) { imageFile in
                    LabeledContent {
                        HStack {
                            Text(imageFile.filename)
                            Spacer()
                            Text(imageFile.size)
                            Button {
                                Task {
                                    await store.send(.removeButtonTapped(imageFile.id))
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .help(Text("remove", bundle: .module))
                        }
                    } label: {
                        ThumbnailImage(thumbnail: imageFile.thumbnail)
                    }
                    .labelStyle(.iconOnly)
                    .task(id: imageFile.id) {
                        await store.send(.imageFileAppeared(imageFile.id))
                    }
                }
            }
            .overlay {
                if store.imageFiles.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("dropImagesHere", bundle: .module)
                        } icon: {
                            Image(systemName: "square.and.arrow.down")
                        }
                    } description: {
                        Text("dropImagesHereDescription", bundle: .module)
                    }
                }
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard store.imageFiles.isEmpty else { return false }
                Task {
                    await store.send(.fileImportCompleted(.success(urls)))
                }
                return true
            }
            ProgressView(value: store.progressValue)
                .frame(maxWidth: .infinity)
                .opacity(store.isProcessing ? 1 : 0)
            HStack(spacing: 8) {
                Button {
                    Task {
                        await store.send(.importButtonTapped)
                    }
                } label: {
                    Text("import", bundle: .module)
                }
                .controlSize(.large)
                Button {
                    Task {
                        await store.send(.clearAllButtonTapped)
                    }
                } label: {
                    Text("clearAll", bundle: .module)
                }
                .controlSize(.large)
                .disabled(store.hasNoImageFiles)
                Spacer()
                HStack(spacing: 2) {
                    Text("size", bundle: .module)
                    TextField(value: $store.percentage, format: .number) {
                        EmptyView()
                    }
                    .multilineTextAlignment(.trailing)
                    .labelsHidden()
                    .frame(width: 40)
                    Text(verbatim: "%")
                }
                HStack(spacing: 2) {
                    Text("quality", bundle: .module)
                    TextField(value: $store.quality, format: .number) {
                        EmptyView()
                    }
                    .multilineTextAlignment(.trailing)
                    .labelsHidden()
                    .frame(width: 40)
                    Text(verbatim: "%")
                }
                Toggle(isOn: $store.deleteOriginal) {
                    Text("deleteOriginal", bundle: .module)
                }
                Button {
                    Task {
                        await store.send(.convertButtonTapped)
                    }
                } label: {
                    Text("convert", bundle: .module)
                }
                .controlSize(.large)
                .disabled(store.hasNoImageFiles)
            }
            .fixedSize()
        }
        .padding()
        .disabled(store.isProcessing)
        .toolbar {
            ToolbarItem(id: "flexible-space-id") {
                Spacer()
            }
            ToolbarItem {
                Button {
                    Task {
                        await store.send(.homePermissionButtonTapped)
                    }
                } label: {
                    Image(systemName: store.bookmarkState.imageName)
                }
            }
        }
        .sheet(
            item: $store.homePermission,
            content: { store in
                HomePermissionView(store: store)
            }
        )
        .fileImporter(
            isPresented: $store.isPresentedFileImporter,
            allowedContentTypes: [UTType.image],
            allowsMultipleSelection: true,
            onCompletion: { result in
                Task {
                    await store.send(.fileImportCompleted(result))
                }
            }
        )
        .fileDialogDefaultDirectory(store.homeDirectory?.appending(path: "Desktop"))
        .focusedSceneValue(\.imageViseSend, .init(send: { await store.send($0) }))
        .focusedSceneValue(\.hasNoImageFiles, store.hasNoImageFiles)
        .task {
            await store.send(.viewAppeared(String(describing: Self.self)))
        }
        .onDisappear {
            Task {
                await store.send(.viewDisappeared)
            }
        }
    }
}

extension ImageVise: ObservableObject {}

#Preview {
    ImageViseView(store: .init(.testDependencies()))
}
