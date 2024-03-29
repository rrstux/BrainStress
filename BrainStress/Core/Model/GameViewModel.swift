//
//  GameViewModel.swift
//  BrainStress
//
//  Created by Robert Sandru on 07/10/2020.
//

import Foundation
import Combine

enum GameState {
    case warmUp
    case playing
    case paused
    case feedback(correct: Bool)
    case end(win: Bool)
}

class GameModel: ObservableObject {
    
    // Quiz
    
    /// Used for score computing.
    let originalQuiz: Quiz
    
    @Published var quiz: Quiz
    @Published var quizItem: QuizItem?
    @Published var quizItemNumber: Int = 1
    
    @Published var quizItemsSolved: [QuizItem] = []
    @Published var quizItemsFailed: [QuizItem] = []
    
    /// Array of strings (in case of multi choice items etc)
    @Published var quizItemUAnswers: [String] = []
    @Published var quizItemUAnswer: String = "" // will only be binded.
    
    // Current Game State
    
    @Published var gameState: GameState = .warmUp
    
    // Timer Configurations
    
    @Published var timeRemainingQuizItem: Int = 5
    @Published var timeRemainingFeedback: Int = 2
    @Published var timeRemainingFoWarmUp: Int = 3
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    var timerCancellables: Set<AnyCancellable> = Set()
    
    init(quiz: Quiz) {
        self.quiz = quiz
        self.originalQuiz = quiz
    }
    
    /// Should be called by Warmup screen :) on appear.
    func startGame() {
        timerConfig()
    }
}

// MARK: Configs

extension GameModel {
    
    /// This function is the placeholder for all the time-based operations.
    func timerConfig() {
        timer
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                switch self.gameState {
                case .warmUp: self.timerRanWarmup()
                case .playing: self.timerRanPlaying()
                case .paused: self.timerRanPaused()
                case .feedback(_): self.timerRanFeedback()
                default: break
                }
            })
            .sink { _ in }
            .store(in: &timerCancellables)
    }
    
    func timerRanWarmup() {
        guard timeRemainingFoWarmUp > 0 else {
            // Out of warmup, play..
            quizStart()
            return
        }
        timeRemainingFoWarmUp -= 1
    }
    
    func timerRanPlaying() {
        guard timeRemainingQuizItem > 0 else {
            itemCheck()
            itemRemove()
            itemLoad()
            return
        }
        timeRemainingQuizItem -= 1
    }
    
    func timerRanPaused() {}
    
    func timerRanFeedback() {}
}

// MARK: Quiz Functionalities

extension GameModel {
    
    func quizStart() {
        itemLoad()
        gameState = .playing
    }
    
    func quizEnd() {
        let won = quizItemsSolved.count == originalQuiz.items.count
        if won {
            UserDefaultsManager.shared.increaseWins(quizId: quiz.id)
        } else {
            UserDefaultsManager.shared.increaseFails(quizId: quiz.id)
        }
        gameState = .end(win: won)
    }
    
    func quizPause() {
        gameState = .paused
    }
    
    func itemLoad() {
        guard let firstItem = quiz.items.first else {
            // No first item, quiz end..
            quizEnd()
            return
        }
        quizItem = firstItem
        timeRemainingQuizItem = Int(quizItem?.time.time[quiz.difficulty] ?? 5)
        quizItemNumber += 1
    }
    
    func itemRemove() {
        guard quiz.items.first != nil else { return }
        quiz.items.removeFirst()
    }
    
    func itemCheck() {
        guard let activeQuizItem = quizItem else { return }
        switch activeQuizItem.answer.type {
        case .text:
            guard let firstAnswer = quizItemUAnswers.first?.lowercased(),
                  let textQuizAns = activeQuizItem.answer.answer.first?.lowercased(),
                  firstAnswer == textQuizAns else {
                quizItemsFailed.append(activeQuizItem)
                quizItemUAnswers.removeAll()
                quizItemUAnswer = ""
                return
            }
            quizItemsSolved.append(activeQuizItem)
            // That's required as we only need one entry for text answers per item.
            quizItemUAnswers.removeAll()
            quizItemUAnswer = ""
        case .singleChoice:
            guard let firstAnswer = quizItemUAnswers.first?.lowercased(),
                  let textQuizAns = activeQuizItem.answer.answer.first?.lowercased(),
                  firstAnswer == textQuizAns else {
                quizItemsFailed.append(activeQuizItem)
                quizItemUAnswers.removeAll()
                quizItemUAnswer = ""
                return
            }
            quizItemsSolved.append(activeQuizItem)
            // That's required as we only need one entry for text answers per item.
            quizItemUAnswers.removeAll()
            quizItemUAnswer = ""
            break
        default: break
        }
    }
    
    /// Kind of hacky.
    func addAnswerToList(answer: String) {
        guard let activeQuizItem = quizItem else { return }
        quizItemUAnswers.append(answer)
        switch activeQuizItem.answer.type {
        case .text, .singleChoice:
            itemCheck()
            itemRemove()
            itemLoad()
        case .multipleChoice:
            // We won't end the quiz item if multiple choice.
            break
        default: break
        }
    }
}

// MARK: UI Helpers

extension GameModel {
    
    func isActive(itemNumber number: Int) -> Bool {
        guard let activeItem = quizItem else { return false }
        return originalQuiz.items[number] == activeItem
    }
    
    func isSolved(itemNumber number: Int) -> Bool {
        let originalQuizItem = originalQuiz.items[number]
        return quizItemsSolved.contains(originalQuizItem)
    }
    
    func inQueue(itemNumber number: Int) -> Bool {
        let originalQuizItem = originalQuiz.items[number]
        return quiz.items.contains(originalQuizItem)
    }
    
    func timeRemainingForHumans() -> String {
        let time = Date.secondsToHoursMinutesSeconds(seconds: timeRemainingQuizItem)
        var humanReadable = ""
        if time.0 > 0 {
            if time.0 < 10 {
                humanReadable.append("0\(time.0):")
            } else {
                humanReadable.append("\(time.0):")
            }
        }

        if time.1 < 10 {
            humanReadable.append("0\(time.1):")
        } else {
            humanReadable.append("\(time.1):")
        }
        if time.2 < 10 {
            humanReadable.append("0\(time.2)")
        } else {
            humanReadable.append("\(time.2)")
        }
        
        return humanReadable
    }
}
