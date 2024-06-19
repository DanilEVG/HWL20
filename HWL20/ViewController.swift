//
//  ViewController.swift
//  HWL20
//
//  Created by Даниил Евгеньевич on 19.06.2024.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var slider: UISlider!
    
    let sieve = Sieve()
    let start = Date()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Task {
            await sieve.setProgressClouser {@MainActor idx in
                guard let number = Int(self.textField.text ?? "0") else { return}
                guard idx > number else {return}
                
                if await self.sieve.checkPrime(number: number) {
                    self.textField.backgroundColor = .green
                } else {
                    self.textField.backgroundColor = .red
                }
            }
      
            await sieve.sieve()
            print("complite - \(start.distance(to: Date()))")
            
          
            
            
            
        }
    }
    
    
    
}

actor Sieve {
    var numbers = Array(repeating: true, count: 100000000)
    
    var progressClouser: @Sendable (Int) async -> Void  = { _ in
        
    }
    
    func sieve() async {
        numbers[0] = false
        numbers[1] = false
        
        var idx = 1
        
        while idx < numbers.count {
            guard let number = numbers[idx...].firstIndex(of: true) else { break }
            let i = idx
            Task.detached {
                await self.progressClouser(i)
            }
            
            idx = number + 1
            for i in stride(from: number, to: numbers.count, by: number).dropFirst() {
                numbers[i] = false
            }
            await Task.yield()
        }
    }
    
    func setProgressClouser(_ clouser: @escaping @Sendable (Int) async -> Void) {
        progressClouser = clouser
    }
    
    func checkPrime( number: Int) -> Bool{
        numbers[number]
    }
}
