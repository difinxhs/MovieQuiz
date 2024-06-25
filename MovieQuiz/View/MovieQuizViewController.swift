import UIKit

final class MovieQuizViewController: UIViewController {
    
    @IBOutlet
    private weak var questionTitleLable: UILabel!
    
    @IBOutlet 
    private weak var indexLable: UILabel!
    
    @IBOutlet 
    private weak var previewImage: UIImageView!
    
    @IBOutlet 
    private weak var questionLable: UILabel!
    
    @IBOutlet 
    private weak var noButton: UIButton!
    
    @IBOutlet 
    private weak var yesButton: UIButton!
    
    @IBOutlet
    private weak var activityIndicator: UIActivityIndicatorView!
    
    
    // MARK: - Lifecycle
    
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter: AlertPresenter?
    
    private var statisticService: StatisticServiceProtocol?
    
    private var presenter: MovieQuizPresenter!

       override func viewDidLoad() {
           super.viewDidLoad()
           presenter = MovieQuizPresenter(viewController: self)
           previewImage.layer.cornerRadius = 20
           
           showLoadingIndicator()
           self.alertPresenter = AlertPresenter(viewController: self)
           
           // Разгружаем метод viewDidLoad
           easyViewDid()
           
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
           let alertModel = AlertModel(
               title: result.title,
               message: result.text,
               buttonText: result.buttonText,
               completion: { [weak self] in
                   guard let self = self else { return }
                   
                   self.presenter.restartGame()
               }
           )
           
           alertPresenter?.present(alert: alertModel)
       }
       
       func showAnswerResult(isCorrect: Bool) {
           presenter.didAnswer(isCorrect: isCorrect)
           
           // Блокируем кнопки
           yesButton.isEnabled = false
           noButton.isEnabled = false
           
           previewImage.layer.masksToBounds = true
           previewImage.layer.borderWidth = 8
           previewImage.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
               guard let self = self else { return }
               self.presenter.showNextQuestionOrResults()
               
               // Разблокируем кнопки
               self.yesButton.isEnabled = true
               self.noButton.isEnabled = true
               
               self.previewImage.layer.borderWidth = 0
           }
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
           
           alertPresenter?.present(alert: alertModel)
       }
       
       private func easyViewDid() {
           questionTitleLable.font = UIFont(name: "YSDisplay-Medium", size: 20)
           indexLable.font = UIFont(name: "YSDisplay-Medium", size: 20)
           questionLable.font = UIFont(name: "YSDisplay-Bold", size: 23)
           noButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
           yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
       }
   }
