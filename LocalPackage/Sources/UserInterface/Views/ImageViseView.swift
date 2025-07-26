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
            HStack {
                ProgressView(value: store.progressValue)
                    .frame(maxWidth: .infinity)
                    .opacity(store.isProcessing ? 1 : 0)
                Button {
                    store.send(.importButtonTapped)
                } label: {
                    Text("import", bundle: .module)
                }
                .controlSize(.large)
                Button {
                    store.send(.exportButtonTapped)
                } label: {
                    Text("export", bundle: .module)
                }
                .controlSize(.large)
                .disabled(store.disableToExport)
            }
        }
        .padding()
        .disabled(store.isProcessing)
        .onAppear {
            store.send(.onAppear(String(describing: Self.self)))
        }
        .onDisappear {
            store.send(.onDisappear)
        }
        .fileImporter(
            isPresented: $store.isPresentedFileImporter,
            allowedContentTypes: [UTType.image],
            allowsMultipleSelection: true,
            onCompletion: { result in
                store.send(.onCompletionFileImport(result))
            },
            onCancellation: {
                store.send(.onCancellationFileExport)
            }
        )
        .fileExporter(
            isPresented: $store.isPresentedFileExporter,
            document: store.exportFolder,
            contentTypes: [UTType.folder],
            defaultFilename: String(localized: "untitled", bundle: .module),
            onCompletion: { result in
                store.send(.onCompletionFileExport(result))
            },
            onCancellation: {
                store.send(.onCancellationFileExport)
            }
        )
        .focusedSceneValue(\.imageViseSend, .init(send: { store.send($0) }))
        .focusedSceneValue(\.disableToExport, store.disableToExport)
    }
}

#Preview {
    ImageViseView(store: .init(.testDependencies()))
}
