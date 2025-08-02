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
    @Environment(\.appDependencies) private var appDependencies
    @State var store: ImageVise

    var body: some View {
        VStack {
            List {
                ForEach(store.imageFiles) { imageFile in
                    LabeledContent {
                        HStack {
                            Text(imageFile.filename)
                            Spacer()
                            Text(imageFile.size)
                        }
                    } label: {
                        AsyncImage(url: imageFile.url) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                        } placeholder: {
                            Image(systemName: "questionmark.square.dashed")
                        }
                    }
                    .labelStyle(.iconOnly)
                }
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
                .disabled(store.disableToConvert)
            }
        }
        .padding()
        .disabled(store.isProcessing)
        .task {
            await store.send(.task(appDependencies, String(describing: Self.self)))
        }
        .onDisappear {
            Task {
                await store.send(.onDisappear)
            }
        }
        .toolbar {
            ToolbarItem(id: "flexible-space-id") {
                Spacer()
            }
            ToolbarItem {
                Button {
                    Task {
                        await store.send(.homePermissionButtonTapped(appDependencies))
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
                    await store.send(.onCompletionFileImport(appDependencies, result))
                }
            }
        )
        .fileDialogDefaultDirectory(store.homeDirectory?.appending(path: "Desktop"))
        .focusedSceneValue(\.imageViseSend, .init(send: { await store.send($0) }))
        .focusedSceneValue(\.disableToConvert, store.disableToConvert)
    }
}

#Preview {
    ImageViseView(store: .init(.testDependencies()))
}
