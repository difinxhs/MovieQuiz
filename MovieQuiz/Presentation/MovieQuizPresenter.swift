import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewControllerProtocol?
    private var correctAnswers: Int = 0
    
    private var statisticService: StatisticServiceProtocol?
    private var questionFactory: QuestionFactoryProtocol?
    
    private var alertPresenter: AlertPresenter?
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.statisticService = StatisticService()
        self.viewController = viewController
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    
    //MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
    
    func didRecieveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    //MARK: - functions
    
    // приватный метод конвертации, который принимает моковый вопрос и возвращает вью модель для главного экрана
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func isLastQuestion() -> Bool {
        return currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    private func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        
        self.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func didAnswer(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        didAnswer(isCorrect: isCorrect)
        
        // Блокируем кнопки
        viewController?.blockButtons()
        
        viewController?.highlightImageBorder(isCorrect: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            
            // Разблокируем кнопки
            viewController?.unBlockButtons()
        }
    }
    
    private func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            statisticService?.store(correct: correctAnswers, total: questionsAmount)
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: makeResultsMessage(),
                buttonText: "Сыграть ещё раз"
            )
            viewController?.show(quiz: viewModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    func makeResultsMessage() -> String {
        statisticService?.store(correct: correctAnswers, total: questionsAmount)
        
        let bestGame = statisticService?.bestGame
        
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService?.gamesCount ?? 0)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)\\\(questionsAmount)"
        let bestGameInfoLine = "Рекорд: \(bestGame?.correct ?? 0)\\\(bestGame?.total ?? 0)" +
        " (\(bestGame?.date.dateTimeString ?? ""))"
        let averageAccuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService?.totalAccuracy ?? 0))%"
        
        let resultMessage = [
            currentGameResultLine, totalPlaysCountLine, bestGameInfoLine, averageAccuracyLine
        ].joined(separator: "\n")
        
        return resultMessage
    }
}
