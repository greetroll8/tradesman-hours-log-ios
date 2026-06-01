import SwiftUI
import PhotosUI
import UIKit

/// PHPicker-based image importer. Returns the saved local file path of the picked image.
struct PhotoPicker: UIViewControllerRepresentable {
    var onPicked: (String) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.8) else { return }
                let dir = PhotoStorage.directory()
                let url = dir.appendingPathComponent("\(UUID().uuidString).jpg")
                try? data.write(to: url, options: .atomic)
                DispatchQueue.main.async {
                    self.parent.onPicked(url.path)
                }
            }
        }
    }
}

enum PhotoStorage {
    static func directory() -> URL {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: true)) ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("TradesmanHoursLog/Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
