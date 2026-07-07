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

        static let subtleBorderOpacity: Double = 0.08
        static let strongBorderOpacity: Double = 0.10
        static let captionEmphasisTracking: CGFloat = 1.0
        static let eyebrowTracking: CGFloat = 1.5
    }
    
    struct Text {
        // App Core
        static let appTitle = "brew_sixty"
        static let helloFallback = "Hello"
        
        // Empty State dashboard
        static let emptyCanvasTitle = "The Canvas is Clean"
        static let emptyCanvasDescription = "Every great cup begins with a recipe. Let's design a custom method to match your beans."
        static let craftFirstRecipe = "CRAFT FIRST RECIPE"
        
        // Parameter Card Labels
        static let selectMethod = "SELECT METHOD"
        static let beanWeight = "COFFEE DOSE"
        static let waterRatio = "WATER RATIO"
        static let targetWaterVolume = "WATER YIELD"
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

    struct Methods {
        struct Defaults {
            static let recipeName = "Morning Ritual"
            static let beanWeight = 18.0
            static let ratio = 15.0
            static let waterVolume = 270.0
            static let bloomDuration = 45.0
            static let frenchPressSteepDuration = 240.0
            static let aeropressSteepDuration = 60.0
            static let aeropressPressDuration = 30.0
            static let targetTemperature = 93.5
        }

        struct Ranges {
            static let waterRatio: ClosedRange<Double> = 12.0...20.0
            static let waterVolume: ClosedRange<Double> = 100.0...600.0
            static let bloomDuration: ClosedRange<Double> = 30.0...60.0
            static let steepDuration: ClosedRange<Double> = 10.0...480.0
            static let pressDuration: ClosedRange<Double> = 10.0...60.0
            static let temperature: ClosedRange<Double> = 75.0...100.0
        }

        struct Steps {
            static let waterRatio = 0.5
            static let waterVolume = 10.0
            static let bloomDuration = 5.0
            static let steepDuration = 5.0
            static let pressDuration = 5.0
            static let temperature = 0.5
        }

        struct Timing {
            static let contextualHintDismissNanoseconds: UInt64 = 2_400_000_000
            static let methodSheetAnimationDuration = 0.2
        }

        struct Layout {
            static let sectionSpacing: CGFloat = 20
            static let verticalCardSpacing: CGFloat = 16
            static let sectionHeaderSpacing: CGFloat = 10
            static let rowSpacing: CGFloat = 8
            static let compactRowSpacing: CGFloat = 6
            static let controlInset: CGFloat = 8
            static let pillHorizontalPadding: CGFloat = 12
            static let pillVerticalPadding: CGFloat = 8
            static let methodsBottomPadding: CGFloat = 40
            static let methodPickerTopPadding: CGFloat = 8
        }

        struct Text {
            static let recipesTitle = "YOUR RECIPES"
            static let savedTemplatesSuffix = "Saved Templates"
            static let recipesSubtitle = "Manage saved templates"
            static let recipesNavigationTitle = "Recipes"
            static let createRecipeNavigationTitle = "New Recipe"
            static let editRecipeNavigationTitle = "Edit Recipe"
            static let guidedMode = "Guided setup"
            static let manualMode = "Manual setup"
            static let recipeNamePlaceholder = "Recipe Name"
            static let startBrew = "START BREW"
            static let saveAsPreset = "SAVE AS PRESET"
            static let saveChanges = "SAVE CHANGES"
            static let brew = "Brew"
            static let edit = "Edit"
            static let newRecipe = "New Recipe"
            static let createFirstRecipe = "Create your first recipe"
            static let errorTitle = "Something went wrong"
            static let saveFailedMessage = "Couldn't save this recipe right now. Please try again."
            static let deleteFailedMessage = "Couldn't delete this recipe right now. Please try again."
            static let noSavedRecipes = "No Saved Recipes"
            static let emptyRecipesDescription = "Save a preset for your favorite brew or start a one-off recipe whenever you like."
            static let delete = "Delete"
            static let done = "Done"
            static let cancel = "Cancel"
        }

        struct HelpSheet {
            static let goodPlaceToStart = "GOOD PLACE TO START"
            static let whyItMatters = "WHY IT MATTERS"
            static let topPadding: CGFloat = 26
            static let horizontalPadding: CGFloat = 24
            static let bottomPadding: CGFloat = 24
            static let verticalSpacing: CGFloat = 18
            static let sectionSpacing: CGFloat = 6
        }
    }

    struct Pickers {
        static let precisionTrackHeight: CGFloat = 10
        static let precisionThumbSize: CGFloat = 22
        static let precisionCenterDotSize: CGFloat = 6

        static let rulerItemWidth: CGFloat = 16
        static let rulerHeight: CGFloat = 60
        static let rulerIndicatorHeight: CGFloat = 40
        static let rulerIndicatorWidth: CGFloat = 2
        static let rulerTriangleWidth: CGFloat = 8
        static let rulerTriangleHeight: CGFloat = 6

        static let steppedWeightRange: ClosedRange<Double> = 1.0...40.0
        static let steppedWeightStep = 0.5
        static let steppedWeightPresets = [12.0, 15.0, 18.0, 20.0, 30.0]
        static let steppedWeightButtonSize: CGFloat = 40
    }

    struct BrewTimer {
        static let v60BloomDuration: TimeInterval = 45.0
        static let frenchPressSteepDuration: TimeInterval = 240.0
        static let frenchPressPlungeDuration: TimeInterval = 15.0
        static let aeropressSteepDuration: TimeInterval = 60.0
        static let aeropressPressDuration: TimeInterval = 30.0
        static let bloomWaterMultiplier: Double = 3.0
        static let firstPourMultiplier: Double = 0.6
        static let pourOverMainPourDuration: TimeInterval = 60.0
        static let v60DrawdownDuration: TimeInterval = 105.0
        static let chemexDrawdownDuration: TimeInterval = 195.0
        static let timerInterval: TimeInterval = 0.1

        static let donePhaseTitle = "Done"
        static let bloomPhaseTitle = "Bloom"
        static let firstPourPhaseTitle = "First Pour"
        static let finalDrawdownPhaseTitle = "Final Drawdown"
        static let steepPhaseTitle = "Steep"
        static let plungePhaseTitle = "Plunge"
        static let pressPhaseTitle = "Press"

        static let enjoyCoffeeMessage = "Enjoy your coffee!"
        static let targetPrefix = "Target:"
        static let bloomInstructionPrefix = "Bloom: Pour"
        static let firstPourInstructionPrefix = "First Pour: Pour to"
        static let drawdownInstructionPrefix = "Drawdown: Pour to"
        static let steepInstructionPrefix = "Steep: Pour"
        static let plungeInstruction = "Plunge: Press down slowly"
        static let pressInstruction = "Press: Press down slowly"
    }
}
