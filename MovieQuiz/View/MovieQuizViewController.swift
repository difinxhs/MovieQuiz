import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    @IBOutlet
    private weak var questionTitleLable: UILabel!
    
    @IBOutlet
    private weak var indexLable: UILabel!
    
    @IBOutlet
    weak var previewImage: UIImageView!
    
    @IBOutlet
    private weak var questionLable: UILabel!
    
    @IBOutlet
    weak var noButton: UIButton!
    
    @IBOutlet
    weak var yesButton: UIButton!
    
    @IBOutlet
    private weak var activityIndicator: UIActivityIndicatorView!
    
    
    // MARK: - Lifecycle
    
//    private var currentQuestion: QuizQuestion?
//    
//    private var alertPresenter: AlertPresenter?
    
    private var presenter: MovieQuizPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MovieQuizPresenter(viewController: self)
        previewImage.layer.cornerRadius = 20
        
        showLoadingIndicator()
        //self.alertPresenter = AlertPresenter(viewController: self)
        
        // Разгружаем метод viewDidLoad
        setupViews()
        
        activityIndicator.hidesWhenStopped = true
        
        presenter.viewController = self
    }
    
    // MARK: - Actions
    
    @IBAction
    private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    @IBAction
    private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    
    // MARK: - private functions
    
    func show(quiz step: QuizStepViewModel) {
        previewImage.image = step.image
        questionLable.text = step.question
        indexLable.text = step.questionNumber
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let message = presenter.makeResultsMessage()
        
        let alert = UIAlertController(
            title: result.title,
            message: message,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.presenter.restartGame()
        }
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func highlightImageBorder(isCorrect: Bool) {
        previewImage.layer.masksToBounds = true
        previewImage.layer.borderWidth = 8
        previewImage.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    func blockButtons() {
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    
    func unBlockButtons() {
        yesButton.isEnabled = true
        noButton.isEnabled = true
        
        //Убираем рамку после ответа
        previewImage.layer.borderWidth = 0
    }
    
    func showLoadingIndicator() {
        activityIndicator.startAnimating() // включаем анимацию
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func showNetworkError(message: String) {
        hideLoadingIndicator() // скрываем индикатор загрузки
        
        let alertModel = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.presenter.restartGame()
            }
        )
        
        presenter?.alertPresenter?.present(alert: alertModel)
    }
    
    private func setupViews() {
        questionTitleLable.font = UIFont(name: "YSDisplay-Medium", size: 20)
        indexLable.font = UIFont(name: "YSDisplay-Medium", size: 20)
        questionLable.font = UIFont(name: "YSDisplay-Bold", size: 23)
        noButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
    }
}
