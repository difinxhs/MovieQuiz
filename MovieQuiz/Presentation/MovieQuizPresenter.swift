import UIKit

final class MovieQuizPresenter {
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewController?
    var correctAnswers: Int = 0
    
    private var statisticService: StatisticServiceProtocol?
    var questionFactory: QuestionFactoryProtocol?
    
    private var alertPresenter: AlertPresenter?
    
    init() {
        self.statisticService = StatisticService()
    }

    
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

    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
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
           
           viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
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
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            
            statisticService?.store(correct: correctAnswers, total: questionsAmount)
            
                   let text = correctAnswers == self.questionsAmount ?
                   "Поздравляем, вы ответили на 10 из 10!" :
                   "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"

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
           let bestGameInfoLine = "Рекорд: \(bestGame?.correct ?? 0)\\\(bestGame?.total ?? 0)"
           + " (\(bestGame?.date.dateTimeString ?? ""))"
           let averageAccuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService?.totalAccuracy ?? 0))%"

           let resultMessage = [
           currentGameResultLine, totalPlaysCountLine, bestGameInfoLine, averageAccuracyLine
           ].joined(separator: "\n")

           return resultMessage
       }
}
