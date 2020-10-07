//
//  Data.swift
//  BrainStress
//
//  Created by Robert Sandru on 07/10/2020.
//

import Foundation

struct QuizCategoryData {
    static let math = Category(name: "Math")
}

struct QuizData {
    
    struct Math {
        
        static func dummyLevel() -> Quiz {
            return Quiz(title: "Additions",
                        items: QuizItemData.MathItems.generate(mathItems: 1, difficulty: .easy, qOperator: .add),
                        category: QuizCategoryData.math,
                        difficulty: .easy)
        }
        
        static func level1() -> Quiz {
            return Quiz(title: "Additions",
                        items: QuizItemData.MathItems.generate(mathItems: 20, difficulty: .easy, qOperator: .add),
                        category: QuizCategoryData.math,
                        difficulty: .easy)
        }
        
        static func level2() -> Quiz {
            return Quiz(title: "Subtractions",
                        items: QuizItemData.MathItems.generate(mathItems: 20, difficulty: .easy, qOperator: .substract),
                        category: QuizCategoryData.math,
                        difficulty: .easy)
        }
    }
}

struct QuizItemData {
    
    struct MathItems {
        
        static func generate(mathItems items: Int, difficulty: Difficulty, qOperator: Operator) -> [QuizItem] {
            var generatedQuizItems: [QuizItem] = []
            for _ in 0..<items {
                
                let r1 = Double(difficulty.mathInterval(forOperator: qOperator).randomElement()!)
                let r2 = Double(difficulty.mathInterval(forOperator: qOperator).randomElement()!)
                let qA = qOperator.compute(left: r1, right: r2).clean
                let qT = "\(r1.clean) \(qOperator.symbol()) \(r2.clean)"
                
                let quizTime = QuizItemTime(time: [.easy: 5,
                                                   .normal: 8,
                                                   .hard: 12])
                let quizAnsw = QuizItemAnswer(type: .text, answer: [qA])
                let quizItem = QuizItem(text: qT,
                                        time: quizTime,
                                        answer: quizAnsw,
                                        category: QuizCategoryData.math)
                
                generatedQuizItems.append(quizItem)
            }
            return generatedQuizItems
        }
    }
}