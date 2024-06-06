import Foundation

final class StatisticService: StatisticServiceProtocol {
    
    private let storage: UserDefaults = .standard
    
    private enum Keys: String {
        case correctAnswers
        case totalQuestions
        case gamesCount
        case bestGameCorrect
        case bestGameTotal
        case bestGameDate
    }
    
    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameResult {
        get {
            let correct = storage.integer(forKey: Keys.bestGameCorrect.rawValue)
            let total = storage.integer(forKey: Keys.bestGameTotal.rawValue)
            let date = storage.object(forKey: Keys.bestGameDate.rawValue) as? Date ?? Date()
            
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: Keys.bestGameCorrect.rawValue)
            storage.set(newValue.total, forKey: Keys.bestGameTotal.rawValue)
            storage.set(newValue.date, forKey: Keys.bestGameDate.rawValue)
        }
    }
    
    var totalAccuracy: Double {
        get {
            let gamesCount = storage.integer(forKey: Keys.gamesCount.rawValue)
            let correctAnswers = storage.integer(forKey: Keys.correctAnswers.rawValue)
            
            guard gamesCount > 0 else { return 0.0 }
            
            return Double(correctAnswers) / Double(gamesCount * 10) * 100
        }
    }
    
    func store(correct count: Int, total amount: Int) {
        // Обновляем количество правильных ответов
        let correctAnswers = storage.integer(forKey: Keys.correctAnswers.rawValue) + count
        storage.set(correctAnswers, forKey: Keys.correctAnswers.rawValue)
        
        // Обновляем количество заданных вопросов
        let totalQuestions = storage.integer(forKey: Keys.totalQuestions.rawValue) + amount
        storage.set(totalQuestions, forKey: Keys.totalQuestions.rawValue)
        
        // Обновляем количество сыгранных игр
        gamesCount += 1
        
        // Проверяем, является ли текущий результат лучшим
        if count > bestGame.correct {
            bestGame = GameResult(correct: count, total: amount, date: Date())
        }
    }
}
