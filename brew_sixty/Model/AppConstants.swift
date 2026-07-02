import SwiftUI

struct AppConstants {
    struct UI {
        /// The opacity for translucent glassmorphic cards
        static let cardOpacity: Double = 0.55
        
        /// Corner radius for method settings cards
        static let cardCornerRadius: CGFloat = 16
        
        /// Corner radius for home timer cards
        static let homeCardCornerRadius: CGFloat = 24
        
        /// Opacity of glassmorphic borders
        static let glassBorderOpacity: Double = 0.15
        
        /// Stroke width of glassmorphic borders
        static let glassBorderWidth: CGFloat = 1.0
    }
    
    struct Text {
        // App Core
        static let appTitle = "brew_sixty"
        static let helloCharu = "Hello Charu!"
        
        // Empty State dashboard
        static let emptyCanvasTitle = "The Canvas is Clean"
        static let emptyCanvasDescription = "Every great cup begins with a recipe. Let's design a custom method to match your beans."
        static let craftFirstRecipe = "CRAFT FIRST RECIPE"
        
        // Parameter Card Labels
        static let selectMethod = "SELECT METHOD"
        static let beanWeight = "BEAN WEIGHT"
        static let waterRatio = "WATER RATIO"
        static let targetWaterVolume = "TARGET WATER VOLUME"
        static let targetTemperature = "TARGET TEMPERATURE"
        static let bloomDuration = "BLOOM DURATION"
        static let steepDuration = "STEEP DURATION"
        static let pressDuration = "PRESS DURATION"
        static let recipeName = "RECIPE NAME"
        static let saveTemplate = "SAVE TEMPLATE"
        
        // Timer View Dashboard
        static let startBrew = "START BREW"
        static let pauseBrew = "PAUSE BREW"
        static let reset = "Reset"
        static let skipPhase = "Skip Phase"
        
        // Unit measurements
        static let gramsUnit = "g"
        static let secondsUnit = "s"
        static let celsiusUnit = "°C"
    }
}
