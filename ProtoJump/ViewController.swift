//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit
import AVFoundation

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        
        if(glesRenderer != nil){
                //if the player isn't dead, update call renderer update and update score
                if(!glesRenderer.box2d.dead){
                      glesRenderer.update()
                      let c: String = String (format: "Score : %0.2f", glesRenderer.totalElapsedTime)
                      ScoreLabel.text = c;
                } else{
                    //put the score into the final score label
                    EndScoreLabel.text = String(format: "Final Score: %0.2f", glesRenderer.totalElapsedTime)
                      //if the player is dead then null glesRenderer, need to call dealloc on glesRenderer somehow
                    glesRenderer = nil;
                    EndScoreLabel.isHidden = false;
                    EndLabel.isHidden = false;
                    EndButton.isHidden = false;
                    //set to one to prevent gesturerecognizer from catching all tap events such as buttons
                    tapHold.minimumPressDuration = 1;
                }
        }
    }
}

class ViewController: GLKViewController {
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    
    var player:AVAudioPlayer?
    
    @IBOutlet weak var ScoreLabel: UILabel!
    
    @IBOutlet weak var EndLabel: UILabel!
    @IBOutlet weak var EndButton: UIButton!
    @IBOutlet weak var EndScoreLabel: UILabel!
    internal var tapHold: UILongPressGestureRecognizer!
    
    @IBAction func onClickReset(_ sender: Any) {
        NSLog("Retry button pressed 1");
        setupGL();
        EndLabel.isHidden = true;
        EndButton.isHidden = true;
        EndScoreLabel.isHidden = true;
        tapHold.minimumPressDuration = 0;
        
    }
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
        //disable the endscreen on load
        //EndButton.addTarget(self, action: Selector("EndButtonPressed"), for: .touchUpInside);
//        let tapGesture = UITapGestureRecognizer(target: self, action: #"retry"));
//        tapGesture.numberOfTapsRequired = 1;
//        EndButton.addGestureRecognizer(tapGesture);
        //self.view.bringSubviewToFront(EndButton);
        EndButton.isHidden = true;
        EndLabel.isHidden = true;
        EndScoreLabel.isHidden = true;
        //EndButton.isUserInteractionEnabled = false;
        
        let buttonTap = UITapGestureRecognizer(target:self, action: #selector(self.onClickReset(_:)))
        buttonTap.numberOfTouchesRequired = 1;
        //EndButton.addGestureRecognizer(buttonTap);
        EndButton.addTarget(self, action: #selector(self.onClickReset(_:)), for: .touchUpInside);
        
        self.view.addSubview(EndButton);
        
        tapHold = UILongPressGestureRecognizer(target: self, action: #selector(self.TapAndHold(_:)));
        tapHold.minimumPressDuration = 0;
        
        self.view.addGestureRecognizer(tapHold)
//        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.doSingleTap(_:)))
//        singleTap.numberOfTapsRequired = 1
//        view.addGestureRecognizer(singleTap)
    }
    
    @IBAction func TapAndHold(_ sender: UILongPressGestureRecognizer) {
        // Disable input if the GameDirector
        if(glesRenderer != nil){
            if (!glesRenderer.box2d.dead) {
        //        float xPos;
                let tapLocation = sender.location(in: sender.view)
                
                let screenSize: CGRect = UIScreen.main.bounds;
                let xPos : Float = Float(tapLocation.x / screenSize.width);
                let yPos : Float = Float(tapLocation.y / screenSize.height);
                
                if sender.state == .began {
        //            NSLog("User has tapped the button at \(xPos), \(yPos) - OnStateEnter")
                    //if player has used all jumps then disable this part
                    if(glesRenderer.box2d.player.jumpCount <= glesRenderer.box2d.player.maxJump){
                        glesRenderer.box2d.slowFactor = 0.2;
                        glesRenderer.box2d.initiateNewJump(xPos, yPos)
                    }
                } else if sender.state == .changed {
                    
        //            NSLog("User has updated their tap at \(xPos), \(yPos) - OnStateChanged")
                    glesRenderer.box2d.updateJumpTarget(xPos, yPos)
                    
                } else if sender.state == .ended {
        //            NSLog("User has released the button - OnStateExit")
                    glesRenderer.box2d.slowFactor = 1;
                    glesRenderer.box2d.launchJump();

                }
                    
            }
        }
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        if(glesRenderer != nil){
            glesRenderer.draw(rect)
        }
    }
    
    //sound section
    func playSound(){
        
    }

}
