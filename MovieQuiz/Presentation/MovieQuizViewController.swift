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

    private var currentQuestionIndex = 0
    
    private var correctAnswers = 0
    
    private let questionsAmount: Int = 10
    
    private var questionFactory: QuestionFactoryProtocol?
    
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter: AlertPresenter?
    
    private var statisticService: StatisticServiceProtocol?
    
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

    }
    //MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        //проверка что вопрос не нил
        guard let question = question else {
            return
        }
        
            currentQuestion = question
            let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
            self?.hideLoadingIndicator()
        }
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
        guard let currentQuestion = currentQuestion else {
            return
        }
            let givenAnswer = true
            showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBAction 
    private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
           let givenAnswer = false
           showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    //MARK: - private functions
    
    // приватный метод конвертации, который принимает моковый вопрос и возвращает вью модель для главного экрана
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func show (quiz step: QuizStepViewModel) {
        previewImage.image = step.image
        questionLable.text = step.question
        indexLable.text = step.questionNumber
        
    }
    
    //приватный метод. Получаем данные из структуры модели и привязываем презентер
    private func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText,
            completion: { [weak self] in
                guard let self = self else { return }
                
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                
                self.questionFactory?.requestNextQuestion()
            }
        )
        
        alertPresenter?.present(alert: alertModel)
    }
    
    // приватный метод, который меняет цвет рамки
    // принимает на вход булевое значение и ничего не возвращает
    private func showAnswerResult(isCorrect: Bool) {
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
            
            self.showNextQuestionOrResults()
            
            // Разблокируем кнопки
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            guard let statisticService = statisticService else {
                return
            }
            
            //убираем цветную рамку после каждого вопроса и при запуске новой игры
            previewImage.layer.borderWidth = 0
            
            // Сохраняем результаты игры
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            let text = correctAnswers == questionsAmount ?
            "Поздравляем, вы ответили на 10 из 10!" :
            "Ваш результат: \(correctAnswers)/10"
            
            //Получаем данные об общем кол-ве сыгранных игр
            let totalGames = statisticService.gamesCount
            let totalGamesMessage = "Количество сыгранных квизов: \(totalGames)"
            
            // Получаем данные о лучшей игре
            let bestGame = statisticService.bestGame
            
            // Форматируем дату
            let formattedDate = bestGame.date.dateTimeString
            
            let bestGameMessage = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(formattedDate))"
            
            // Получаем среднюю точность
            let totalAccuracy = statisticService.totalAccuracy
            let accuracyMessage = "Средняя точность: \(String(format: "%.2f", totalAccuracy))%"
            
            // Формируем полное сообщение
            let fullMessage = """
            \(text)
            \(totalGamesMessage)
            \(bestGameMessage)
            \(accuracyMessage)
            """
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: fullMessage,
                buttonText: "Сыграть ещё раз"
            )
            show(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            previewImage.layer.borderWidth = 0
            questionFactory?.requestNextQuestion()
            showLoadingIndicator()
        }
    }

    private func easyViewDid () {
        questionTitleLable.font =  UIFont(name: "YSDisplay-Medium", size: 20)
        indexLable.font =  UIFont(name: "YSDisplay-Medium", size: 20)
        questionLable.font =  UIFont(name: "YSDisplay-Bold", size: 23)
        noButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        yesButton.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
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
                
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                
                self.questionFactory?.requestNextQuestion()
            }
        )
        
        alertPresenter?.present(alert: alertModel)
    }
}
