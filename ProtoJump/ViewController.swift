//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update()
        
        let c: String = String (format: "Score : %0.2f", glesRenderer.totalElapsedTime)
        ScoreLabel.text = c;
    }
}

class ViewController: GLKViewController {
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    
    @IBOutlet weak var ScoreLabel: UILabel!
    
    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
            glesRenderer.loadModels()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGL()
//        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.doSingleTap(_:)))
//        singleTap.numberOfTapsRequired = 1
//        view.addGestureRecognizer(singleTap)
    }
    
        
    @IBAction func TapAndHold(_ sender: UILongPressGestureRecognizer) {
        
//        float xPos;
        let tapLocation = sender.location(in: sender.view)
        
        let screenSize: CGRect = UIScreen.main.bounds;
        let xPos : Float = Float(tapLocation.x / screenSize.width);
        let yPos : Float = Float(tapLocation.y / screenSize.height);
        
        if sender.state == .began {
//            NSLog("User has tapped the button at \(xPos), \(yPos) - OnStateEnter")
            glesRenderer.box2d.initiateNewJump(xPos, yPos)
            
        } else if sender.state == .changed {
            
//            NSLog("User has updated their tap at \(xPos), \(yPos) - OnStateChanged")
            glesRenderer.box2d.updateJumpTarget(xPos, yPos)
            
        } else if sender.state == .ended {
//            NSLog("User has released the button - OnStateExit")
            glesRenderer.box2d.launchJump()
        }

    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glesRenderer.draw(rect)
    }
    
//    @objc func doSingleTap(_ sender: UITapGestureRecognizer) {
//
//        NSLog("User Tapped at !");
//
//    }

}
