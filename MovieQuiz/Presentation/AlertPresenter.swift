import UIKit

final class AlertPresenter {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController? = nil) {
        self.viewController = viewController
    }
    
    func present (alert model: AlertModel) {
        let alertController = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(
            title: model.buttonText,
            style: .default
        ) { _ in
            model.completion?()
        }
        alertController.addAction(action)
        viewController?.present(
            alertController,
            animated: true,
            completion: nil
        )
    }
}
