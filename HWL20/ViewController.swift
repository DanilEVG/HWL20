//
//  ViewController.swift
//  HWL20
//
//  Created by Даниил Евгеньевич on 19.06.2024.
//

/*
 
 1. Добавить задержку по слайдеру
 2. Остановка расчета
 3. Запуск (продолжение расчета)
 4. Постановка расчета на паузу
 5. Прогресс бар для контроля процесса расчета
 
 */
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    let sieve = Sieve()
    let start = Date()
    var task = Task<Void,Error>{}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playButton.isEnabled = false
        startSieve()
    }
    
    func startSieve() {
        task = Task {
            await sieve.setProgressClouser {@MainActor idx in
                try? await Task.sleep(for: .milliseconds(Double(self.slider.value)))
                await self.progressView.progress = Float(idx) / Float(self.sieve.getCountNumbers())
            }
            
            try await sieve.sieve()
            print("complite - \(start.distance(to: Date()))")
        }
        
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard let number = Int(self.textField.text ?? "0") else { return}
        
        Task {
            if await sieve.checkPrime(number: number) {
                textField.backgroundColor = .green
            } else {
                textField.backgroundColor = .red
            }
            
        }
        
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        startSieve()
        playButton.isEnabled = false
        pauseButton.isEnabled = true
        stopButton.isEnabled = true
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        Task {
            await sieve.pauseCalculation()
            playButton.isEnabled = true
            pauseButton.isEnabled = false
            stopButton.isEnabled = true
        }
        
    }
    
    
    @IBAction func stopButtonPressed(_ sender: UIButton) {
        Task{
            await sieve.stopCalculation()
            try? await task.value
            progressView.setProgress(0, animated: true)
            playButton.isEnabled = true
            pauseButton.isEnabled = false
            stopButton.isEnabled = false
        }
        
    }
    
}

actor Sieve {
    var numbers = Array(repeating: true, count: 100000000)
    var idx = 1
    var isPause = false
    var isStop = false
    
    var progressClouser: @Sendable (Int) async -> Void  = { _ in
        
    }
    
    func sieve() async throws {
        numbers[0] = false
        numbers[1] = false
        
        try await withThrowingDiscardingTaskGroup() { group in
            while idx < numbers.count {
                guard let number = numbers[idx...].firstIndex(of: true) else { break }
                if isStop {
                    isStop = false
                    break
                }
                if isPause {
                    isPause = false
                    break
                }
                
                guard !Task.isCancelled else {throw CancellationError()}
                
                let i = idx
                
                group.addTask {
                    await self.progressClouser(i)
                }
                
                idx = number + 1
                for i in stride(from: number, to: numbers.count, by: number).dropFirst() {
                    numbers[i] = false
                }
                await Task.yield()
            }
            
        }
        
    }
    
    func setProgressClouser(_ clouser: @escaping @Sendable (Int) async -> Void) {
        progressClouser = clouser
    }
    
    func checkPrime( number: Int) -> Bool{
        numbers[number]
    }
    
    func getCountNumbers() -> Int {
        numbers.count
    }
    
    func stopCalculation() {
        isStop = true
        idx = 1
        numbers = Array(repeating: true, count: 100000000)
    }
    
    func pauseCalculation() {
        isPause = true
    }
        
}
