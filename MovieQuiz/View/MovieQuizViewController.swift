import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
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

    private var correctAnswers = 0
    
    private var questionFactory: QuestionFactoryProtocol?
    
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter: AlertPresenter?
    
    private var statisticService: StatisticServiceProtocol?
    
    private let presenter = MovieQuizPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewImage.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
       statisticService = StatisticService()

        showLoadingIndicator()
        questionFactory?.loadData()
        
        self.alertPresenter = AlertPresenter(viewController: self)
        
        //выводим статистику
        statisticService = StatisticService()
        
        //разгружаем метод viewDidLoad
        easyViewDid()
        
        activityIndicator.hidesWhenStopped = true
        
        presenter.viewController = self

    }
    //MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didRecieveNextQuestion(question: question)
    }
    
    func didLoadDataFromServer() {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription) // возьмём в качестве сообщения описание ошибки
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
    
    //MARK: - private functions
    
    func show (quiz step: QuizStepViewModel) {
        previewImage.image = step.image
        questionLable.text = step.question
        indexLable.text = step.questionNumber
        
    }
    
    //приватный метод. Получаем данные из структуры модели и привязываем презентер
    func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                
                self.questionFactory?.requestNextQuestion()
            }
        )
        
        alertPresenter?.present(alert: alertModel)
    }
    
    // приватный метод, который меняет цвет рамки
    // принимает на вход булевое значение и ничего не возвращает
    func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        // Блокируем кнопки
        yesButton.isEnabled = false
        noButton.isEnabled = false
        
        previewImage.layer.masksToBounds = true
        previewImage.layer.borderWidth = 8
        previewImage.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
       
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self else { return }
                    self.presenter.correctAnswers = self.correctAnswers
                    self.presenter.questionFactory = self.questionFactory
                    self.presenter.showNextQuestionOrResults()
            
            // Разблокируем кнопки
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
            
            previewImage.layer.borderWidth = 0
        }
    }

    private func showLoadingIndicator() {
        //activityIndicator.isHidden = false // говорим, что индикатор загрузки не скрыт
        activityIndicator.startAnimating() // включаем анимацию
    }
    
    private func hideLoadingIndicator() {
        //activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator() // скрываем индикатор загрузки
        
        let alertModel = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                
                self.questionFactory?.requestNextQuestion()
            }
        )
        
        alertPresenter?.present(alert: alertModel)
    }
    
    private func easyViewDid () {
        questionTitleLable.font =  UIFont(name: "YSDisplay-Medium", size: 20)
        indexLable.font =  UIFont(name: "YSDisplay-Medium", size: 20)
        questionLable.font =  UIFont(name: "YSDisplay-Bold", size: 23)
        noButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
    }
}
