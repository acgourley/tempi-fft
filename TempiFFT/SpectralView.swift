
import UIKit

class SpectralView: UIView {

    var fft: TempiFFT!
    var avgFFT: [Float]!
    private var highestDB: Float = 0.0
    public var highestDBSmooth: Float = 0.0

    override func draw(_ rect: CGRect) {
        
        if fft == nil {
            return
        }
        if avgFFT == nil {
            avgFFT = [Float](repeating: 0, count: fft.numberOfBands)
        }
        let context = UIGraphicsGetCurrentContext()
        
        self.drawSpectrum(context: context!)
        
        // We're drawing static labels every time through our drawRect() which is a waste.
        // If this were more than a demo we'd take care to only draw them once.
        self.drawLabels(context: context!)
    }
    
    private func drawSpectrum(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        let plotYStart: CGFloat = 48.0
        
        context.saveGState()
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -viewHeight)
        
        let colors = [UIColor.blue.cgColor, UIColor.purple.cgColor, UIColor.red.cgColor]
        let gradient = CGGradient(
            colorsSpace: nil, // generic color space
            colors: colors as CFArray,
            locations: [0.0, 0.3, 0.6])

        var x: CGFloat = 0.0
        
        let count = fft.numberOfBands
        
        // Draw the spectrum.
        let maxDB: Float = 80.0
        let minDB: Float = -32.0
        let headroom = maxDB - minDB
        let colWidth = tempi_round_device_scale(d: viewWidth / CGFloat(count))
        highestDB = 0
        for i in 0..<count {
            
            avgFFT[i] = fft.magnitudeAtBand(i) * 0.2 + avgFFT[i] * 0.8 //lowpass
            
            //let magnitude = fft.magnitudeAtBand(i) //fast reading
            let magnitude = avgFFT[i]; // slow avg
            
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = TempiFFT.toDB(magnitude)
            
            // Normalize the incoming magnitude so that -Inf = 0
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
            
            if highestDB < magnitudeDB {
                highestDB = magnitudeDB
            }
            
            let dbRatio = min(1.0, magnitudeDB / headroom)
            let magnitudeNorm = CGFloat(dbRatio) * viewHeight
            
            let colRect: CGRect = CGRect(x: x, y: plotYStart, width: colWidth, height: magnitudeNorm)
            
            let startPoint = CGPoint(x: viewWidth / 2, y: 0)
            let endPoint = CGPoint(x: viewWidth / 2, y: viewHeight)
            
            context.saveGState()
            context.clip(to: colRect)
            context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            
            
            context.restoreGState()
            
            x += colWidth
        }
        if(highestDB > highestDBSmooth) {
            highestDBSmooth = highestDB * 0.2 + highestDBSmooth * 0.8;
        } else {
            highestDBSmooth = highestDB * 0.005 + highestDBSmooth * 0.995;
        }
        context.restoreGState()
    }
    
    private func drawLabels(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        context.saveGState()
        context.translateBy(x: 0, y: viewHeight);
        
        let pointSize: CGFloat = 15.0
        let font = UIFont.systemFont(ofSize: pointSize, weight: UIFont.Weight.regular)
        
        let freqLabelStr = ""//Frequency (kHz) Highest: " + String(format: "%0.0f", highestDB) + " dB"
        var attrStr = NSMutableAttributedString(string: freqLabelStr)
        attrStr.addAttribute(NSAttributedStringKey.font, value: font, range: NSMakeRange(0, freqLabelStr.characters.count))
        attrStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.cyan, range: NSMakeRange(0, freqLabelStr.characters.count))
        
        var x: CGFloat = viewWidth / 2.0 - attrStr.size().width / 2.0
        attrStr.draw(at: CGPoint(x: 0, y: -22))
        
        let labelStrings: [String] = ["5", "10", "15", "20"]
        let labelValues: [CGFloat] = [5000, 10000, 15000, 20000]
        let samplesPerPixel: CGFloat = CGFloat(fft.sampleRate) / 2.0 / viewWidth
        for i in 0..<labelStrings.count {
            let str = labelStrings[i]
            let freq = labelValues[i]
            
            attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttribute(NSAttributedStringKey.font, value: font, range: NSMakeRange(0, str.characters.count))
            attrStr.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.cyan, range: NSMakeRange(0, str.characters.count))
            
            x = freq / samplesPerPixel - pointSize / 2.0
            attrStr.draw(at: CGPoint(x: x, y: -40))
        }
        
        context.restoreGState()
    }
}
