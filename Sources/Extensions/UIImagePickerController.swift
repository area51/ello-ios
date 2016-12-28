////
///  UIImagePickerController.swift
//

import ImagePickerSheetController
import Photos


enum ImagePickerSheetResult {
    case controller(UIImagePickerController)
    case images([PHAsset])
}

extension UIImagePickerController {
    class var elloImagePickerController: UIImagePickerController {
        let controller = UIImagePickerController()
        controller.mediaTypes = [kUTTypeImage as String]
        controller.allowsEditing = false
        controller.modalPresentationStyle = .fullScreen
        controller.navigationBar.tintColor = .greyA()
        return controller
    }

    class var elloPhotoLibraryPickerController: UIImagePickerController {
        let controller = elloImagePickerController
        controller.sourceType = .photoLibrary
        return controller
    }

    class var elloCameraPickerController: UIImagePickerController {
        let controller = elloImagePickerController
        controller.sourceType = .camera
        return controller
    }

    class func alertControllerForImagePicker(_ callback: @escaping (UIImagePickerController) -> Void) -> AlertViewController? {
        let alertController: AlertViewController

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController = AlertViewController(message: InterfaceString.ImagePicker.ChooseSource)

            let cameraAction = AlertAction(title: InterfaceString.ImagePicker.Camera, style: .dark) { _ in
                Tracker.sharedTracker.imageAddedFromCamera()
                callback(.elloCameraPickerController)
            }
            alertController.addAction(cameraAction)

            let libraryAction = AlertAction(title: InterfaceString.ImagePicker.Library, style: .dark) { _ in
                Tracker.sharedTracker.imageAddedFromLibrary()
                callback(.elloPhotoLibraryPickerController)
            }
            alertController.addAction(libraryAction)

            let cancelAction = AlertAction(title: InterfaceString.Cancel, style: .light) { _ in
                Tracker.sharedTracker.addImageCanceled()
            }
            alertController.addAction(cancelAction)
        } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            Tracker.sharedTracker.imageAddedFromLibrary()
            callback(.elloPhotoLibraryPickerController)
            return nil
        } else {
            alertController = AlertViewController(message: InterfaceString.ImagePicker.NoSourceAvailable)

            let cancelAction = AlertAction(title: InterfaceString.OK, style: .light, handler: .none)
            alertController.addAction(cancelAction)
        }

        return alertController
    }

    class func imagePickerSheetForImagePicker(
        config: ImagePickerSheetConfig = ImagePickerSheetConfig(),
        callback: @escaping (ImagePickerSheetResult) -> Void
        ) -> ImagePickerSheetController
    {
        let controller = ImagePickerSheetController(mediaType: config.mediaType)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.addAction(
                ImagePickerAction(
                    title: config.cameraAction,
                    handler: { _ in
                        Tracker.sharedTracker.imageAddedFromCamera()
                        callback(.controller(.elloCameraPickerController))
                    })
            )
        }
        controller.addAction(
            ImagePickerAction(
                title: config.photoLibrary,
                secondaryTitle: config.addImage,
                handler: { _ in
                    Tracker.sharedTracker.imageAddedFromLibrary()
                    callback(.controller(.elloPhotoLibraryPickerController))
                }, secondaryHandler: { _, numberOfPhotos in
                    callback(.images(controller.selectedAssets))
                })
        )
        controller.addAction(ImagePickerAction(title: InterfaceString.Cancel, style: .cancel, handler: { _ in
            Tracker.sharedTracker.addImageCanceled()
        }))

        return controller
    }

}
