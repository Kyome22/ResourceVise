/*
 HomePermissionView.swift
 UserInterface

 Created by Takuto Nakamura on 2025/08/02.
 
*/

import DataSource
import Model
import SwiftUI

struct HomePermissionView: View {
    @State var store: HomePermission

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack {
                Image(.icon)
                Text("requiresPreparation", bundle: .module)
            }
            .font(.title2)
            VStack(spacing: 16) {
                Text("controlHomeDirectory", bundle: .module)
                    .multilineTextAlignment(.leading)
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: store.bookmarkState.imageName)
                        .font(.title)
                        .foregroundStyle(store.bookmarkState.imageColor)
                    Text(store.bookmarkState.label)
                }
                VStack {
                    switch store.bookmarkState {
                    case .notSaved:
                        Button {
                            Task {
                                await store.send(.grantPermissionButtonTapped)
                            }
                        } label: {
                            Text("grantPermissionToControlHome", bundle: .module)
                                .frame(maxWidth: .infinity)
                        }
                        .keyboardShortcut(.defaultAction)
                        Button(role: .cancel) {
                            Task {
                                await store.send(.setUpLaterButtonTapped)
                            }
                        } label: {
                            Text("setUpLater", bundle: .module)
                                .frame(maxWidth: .infinity)
                        }
                    case .saved:
                        Button(role: .destructive) {
                            Task {
                                await store.send(.revokePermissionButtonTapped)
                            }
                        } label: {
                            Text("revokePermissionToControlHome", bundle: .module)
                                .frame(maxWidth: .infinity)
                        }
                        Button(role: .cancel) {
                            Task {
                                await store.send(.closeButtonTapped)
                            }
                        } label: {
                            Text("close", bundle: .module)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .controlSize(.large)
            }
        }
        .frame(width: 300)
        .fixedSize()
        .padding()
        .task {
            await store.send(.task(String(describing: Self.self)))
        }
        .fileImporter(
            isPresented: $store.isPresentedFileImporter,
            allowedContentTypes: [.directory],
            onCompletion: { result in
                Task {
                    await store.send(.onCompletionGrantPermission(result))
                }
            }
        )
        .fileDialogDefaultDirectory(store.homeDirectory?.deletingLastPathComponent())
        .fileDialogURLEnabled(store.predicate)
        .fileDialogMessage(Text("selectHome\(store.homeDirectoryPath)", bundle: .module))
        .fileDialogConfirmationLabel(Text("grant", bundle: .module))
    }
}

#Preview {
    HomePermissionView(store: .init(.testDependencies(), action: { _ in }))
}
