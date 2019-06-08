
import UIKit
import AVFoundation

class SpectralViewController: UIViewController {
    @IBOutlet weak var spectrum: UIView!
    @IBOutlet weak var bigNumber: UILabel!
    var audioInput: TempiAudioInput!
    var spectralView: SpectralView!
    var nagTimer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()

        spectralView = SpectralView(frame: self.view.bounds)
        spectralView.backgroundColor = UIColor.black;
        self.spectrum.addSubview(spectralView);
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.applicationBecameActive),
            name: .UIApplicationDidBecomeActive,
            object: nil)
        
        nagTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(nagTimerHandler), userInfo: nil, repeats: true)

    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func applicationBecameActive(notification: NSNotification){
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)
        }
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: 44100, numberOfChannels: 1)
        audioInput.startRecording();
    }
   
    @objc func nagTimerHandler() {
         //https://hooks.zapier.com/hooks/catch/25928/smvqh5/
        NSLog("Nag timer handled");
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if(self.spectralView.highestDBSmooth > 0) { //for now we will filter on zapier side so this can be zero
            let url = URL(string: "https://hooks.zapier.com/hooks/catch/25928/smvqh5/")!
            let session = URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "POST" //set http method as POST
            let parameters = [
                "db": String(format:"%.1f", self.spectralView.highestDBSmooth),
                "time": formatter.string(from: now)
            ]
            do {
                let jsonString = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                request.httpBody = jsonString
            } catch let error {
                print(error.localizedDescription)
            }
            session.dataTask(with: request as URLRequest).resume();
            
        }
        
    }
    func gotSomeAudio(timeStamp: Double, numberOfFrames: Int, samples: [Float]) {
        let fft = TempiFFT(withSize: numberOfFrames, sampleRate: 44100.0)
        fft.windowType = TempiFFTWindowType.hanning
        fft.fftForward(samples)
        
        // Interpoloate the FFT data so there's one band per pixel.
        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
        //fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: Int(screenWidth))
        fft.calculateLogarithmicBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, bandsPerOctave: Int(7))
        tempi_dispatch_main { () -> () in
            self.spectralView.fft = fft
            self.spectralView.setNeedsDisplay()
            self.bigNumber.text = String(format: "%0.0f dB", self.spectralView.highestDBSmooth);
        }
    }
    
    override func didReceiveMemoryWarning() {
        NSLog("*** Memory!")
        super.didReceiveMemoryWarning()
    }
}

