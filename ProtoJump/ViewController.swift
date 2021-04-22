//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit
import AVFoundation

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        
        //to ensure that when the glesrenderer is null, it doesnt check box2d variables which is also null
        if(glesRenderer != nil){
            
                //if the player isn't dead, update call renderer update and update score
                if(!glesRenderer.box2d.dead){
                      glesRenderer.update()
                    //updates the score
                      let c: String = String (format: "Score : %0.2f", glesRenderer.totalElapsedTime)
                      ScoreLabel.text = c;
                    
                    //updates the current jump count
                    let d: String = String(format: "Jumps Left: %0.0f", 3 - glesRenderer.box2d.player.jumpCount)
                    JumpCounter.text = d;
                } else{
                    //put the score into the final score label
                    EndScoreLabel.text = String(format: "Final Score: %0.2f", glesRenderer.totalElapsedTime)
                    
                    //Do update highscore when the score higher than highscore, and update UserDefaults.
                    if(glesRenderer.totalElapsedTime > Highscore){
                        Highscore = glesRenderer.totalElapsedTime;
                        HighscoreLabel.text = String(format: "Highscore: %0.2f", Highscore)
                        let HighscoreDefault = UserDefaults.standard;
                        HighscoreDefault.setValue(Highscore, forKey: "Highscore")
                        HighscoreDefault.synchronize()
                    }
                    
                    //if the player is dead then null glesRenderer
                    glesRenderer = nil;
                    //when the player is dead reveal the endscreen components
                    EndScoreLabel.isHidden = false;
                    EndLabel.isHidden = false;
                    EndButton.isHidden = false;
                    //set to one to prevent gesturerecognizer from catching all tap events such as buttons
                    tapHold.minimumPressDuration = 1;
                    playSfx(soundName: "Death");
                }
        }
    }
}

class ViewController: GLKViewController {
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    
    //Designated Audioplayer for Background Music
    var BGMplayer:AVAudioPlayer?
    //Designated Audioplayer for Sound Effects
    var SFXplayer:AVAudioPlayer?
    var Highscore : Float = 0.0
    
    //UI Elements from story board
    @IBOutlet weak var ScoreLabel: UILabel!
    @IBOutlet weak var HighscoreLabel: UILabel!
    @IBOutlet weak var JumpCounter: UILabel!
    @IBOutlet weak var EndLabel: UILabel!
    @IBOutlet weak var EndButton: UIButton!
    @IBOutlet weak var EndScoreLabel: UILabel!
    internal var tapHold: UILongPressGestureRecognizer!
    
    //when the retry button is pressed, the glesrenderer is re-initialized, labels are hidden and the
    //longpressgesture is returned to 0
    @IBAction func onClickReset(_ sender: Any) {
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
        setupGL();
        playBGM();
        
       //hides the end screen UI components on startup
        EndButton.isHidden = true;
        EndLabel.isHidden = true;
        EndScoreLabel.isHidden = true;
        
        //retry button onclick set
        EndButton.addTarget(self, action: #selector(self.onClickReset(_:)), for: .touchUpInside);
        self.view.addSubview(EndButton);
        
        //adds longpressgesturerecognizer to view
        tapHold = UILongPressGestureRecognizer(target: self, action: #selector(self.TapAndHold(_:)));
        tapHold.minimumPressDuration = 0;
        self.view.addGestureRecognizer(tapHold)
        
        //Set Highscore from UserDefaults
        let HighscoreDefault = UserDefaults.standard;
        if (HighscoreDefault.float(forKey: "Highscore") != nil){
            Highscore = HighscoreDefault.float(forKey: "Highscore");
            HighscoreLabel.text = String(format: "Highscore: %0.2f", Highscore);
        }
    }
    
    @IBAction func TapAndHold(_ sender: UILongPressGestureRecognizer) {
        if(glesRenderer != nil){
            //when the player isn't dead grab inputs
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
                    if(glesRenderer.box2d.player.jumpCount < glesRenderer.box2d.player.maxJump){
                        playSfx(soundName: "Jump");
                    }
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
    func playBGM(){
        //gets path to sound file
        let pathToSound = Bundle.main.path(forResource: "BGM-Speed", ofType: "mp3")!
        let url = URL(fileURLWithPath: pathToSound)
        do{
            BGMplayer = try AVAudioPlayer(contentsOf: url)
            //makes it continously loop
            BGMplayer?.numberOfLoops = -1;
            BGMplayer?.play()
        } catch {
            NSLog("Error");
        }
    }
    
    func playSfx(soundName: String){
        //gets path to sound file
        if(soundName == "Jump"){
            let pathToSound = Bundle.main.path(forResource: "SFX-Jump", ofType: "mp3")!
            let url = URL(fileURLWithPath: pathToSound)
            do{
                SFXplayer = try AVAudioPlayer(contentsOf: url)
                //makes it continously loop
                SFXplayer?.numberOfLoops = 0;
                SFXplayer?.volume = 0.5;
                SFXplayer?.play()
            } catch {
                NSLog("Error");
            }
        }
        
        if(soundName == "Death"){
            //gets path to sound file
            let pathToSound = Bundle.main.path(forResource: "SFX-Death", ofType: "mp3")!
            let url = URL(fileURLWithPath: pathToSound)
            do{
                SFXplayer = try AVAudioPlayer(contentsOf: url)
                //makes it continously loop
                SFXplayer?.numberOfLoops = 0;
                SFXplayer?.volume = 0.5;
                SFXplayer?.play()
            } catch {
                NSLog("Error");
            }
            
        }
        
    }

}
