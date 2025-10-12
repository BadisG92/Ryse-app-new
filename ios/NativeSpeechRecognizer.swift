import Flutter
import Speech
import AVFoundation

/// Reconnaissance vocale native iOS avec qualité maximale
/// Utilise directement le Speech Framework d'Apple
class NativeSpeechRecognizer: NSObject, FlutterStreamHandler {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var eventSink: FlutterEventSink?
    private var isListening = false

    // Configuration pour qualité maximale
    private var locale: Locale = Locale(identifier: "fr_FR")

    override init() {
        super.init()
        setupRecognizer()
    }

    private func setupRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        speechRecognizer?.delegate = self
    }

    /// Changer la langue de reconnaissance
    func setLocale(localeId: String) {
        locale = Locale(identifier: localeId)
        setupRecognizer()
    }

    /// Démarrer l'écoute avec configuration optimale
    func startListening(result: @escaping FlutterResult) {
        // Vérifier les permissions
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            result(FlutterError(code: "PERMISSION_DENIED",
                              message: "Speech recognition permission not granted",
                              details: nil))
            return
        }

        // Vérifier si déjà en écoute
        if isListening {
            result(FlutterError(code: "ALREADY_LISTENING",
                              message: "Already listening",
                              details: nil))
            return
        }

        do {
            try startRecognition()
            isListening = true
            result(true)
        } catch {
            result(FlutterError(code: "START_ERROR",
                              message: "Failed to start: \(error.localizedDescription)",
                              details: nil))
        }
    }

    private func startRecognition() throws {
        // Annuler toute tâche en cours
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configuration audio optimale
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Créer la requête
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognizer", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Unable to create request"])
        }

        let inputNode = audioEngine.inputNode

        // 🔥 CONFIGURATION OPTIMALE pour qualité maximale
        recognitionRequest.shouldReportPartialResults = true

        // 🔥 ON-DEVICE = Fonctionne SANS internet (mode avion, salle de sport sans WiFi)
        // Note: Qualité légèrement inférieure au Cloud, mais NÉCESSAIRE pour offline
        recognitionRequest.requiresOnDeviceRecognition = true

        // iOS 16+ : Ajouter contexte pour COMPENSER la qualité on-device
        if #available(iOS 16, *) {
            recognitionRequest.addsPunctuation = false // Pas de ponctuation

            // 🎯 Contexte adaptatif : CRITIQUE pour compenser la qualité on-device
            // Plus on donne de contexte, meilleure est la reconnaissance offline
            let context = [
                // Mots-clés français
                "reps", "répétitions", "répétition", "rep",
                "kilos", "kilo", "kilogrammes", "kilogramme", "kg",

                // Nombres courants (1-30 pour les reps)
                "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "dix",
                "onze", "douze", "quinze", "vingt", "vingt-cinq", "trente",

                // Nombres en chiffres (reps courantes)
                "10", "12", "15", "20", "25", "30",

                // Poids courants en kg (multiples de 5)
                "20", "25", "30", "35", "40", "45", "50", "55", "60", "65", "70", "75",
                "80", "85", "90", "95", "100", "105", "110", "115", "120", "140", "160", "180", "200",

                // Poids décimaux courants (disques olympiques)
                "62.5", "72.5", "82.5", "92.5", "102.5", "112.5"
            ]
            recognitionRequest.contextualStrings = context
        }

        // Démarrer la tâche de reconnaissance
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcription = result.bestTranscription.formattedString

                // Envoyer les résultats partiels
                if !result.isFinal {
                    self.sendEvent(["type": "partial", "text": transcription])
                } else {
                    // Résultat final
                    self.sendEvent(["type": "final", "text": transcription])
                    self.stopListening()
                }
            }

            if let error = error {
                print("❌ Recognition error: \(error.localizedDescription)")
                self.sendEvent(["type": "error", "message": error.localizedDescription])
                self.stopListening()
            }
        }

        // Configuration du format audio (16kHz, mono, PCM 16-bit)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Démarrer le moteur audio
        audioEngine.prepare()
        try audioEngine.start()

        print("✅ Speech recognition started with locale: \(locale.identifier)")
    }

    /// Arrêter l'écoute
    func stopListening() {
        isListening = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        print("🛑 Speech recognition stopped")
    }

    /// Vérifier si le service est disponible
    func isAvailable() -> Bool {
        return speechRecognizer?.isAvailable ?? false
    }

    /// Demander les permissions
    static func requestPermissions(result: @escaping FlutterResult) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    result(true)
                case .denied, .restricted, .notDetermined:
                    result(false)
                @unknown default:
                    result(false)
                }
            }
        }
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        stopListening()
        return nil
    }

    private func sendEvent(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(data)
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension NativeSpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("🎤 Speech recognizer availability changed: \(available)")
        sendEvent(["type": "availability", "available": available])
    }
}
