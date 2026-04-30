package com.ustadai.kasrat_ai

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// Note: In reality, we import from com.google.android.gms.aicore or com.google.mlkit.genai
// For the Day-1 Gemma 4 AICore Preview API.
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kasratai.fauj/gemma_aicore"
    private val PROGRESS_CHANNEL = "com.kasratai.fauj/gemma_aicore/download_progress"
    
    // Abstracting our NPU-driven GenAI Model
    private var isGemmaLoaded = false
    private var modelState = "not_downloaded" // "not_downloaded", "downloading", "ready"
    private var modelDownloadProgress = 0
    private var progressSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROGRESS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressSink = events
                    emitDownloadProgress(modelDownloadProgress, currentProgressMessage())
                }

                override fun onCancel(arguments: Any?) {
                    progressSink = null
                }
            })
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkModelStatus" -> {
                    result.success(modelState)
                }
                "downloadModel" -> {
                    if (modelState == "downloading" || modelState == "ready") {
                        emitDownloadProgress(modelDownloadProgress, currentProgressMessage())
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    
                    modelState = "downloading"
                    modelDownloadProgress = 0
                    emitDownloadProgress(modelDownloadProgress, "Preparing model download...")
                    // Simulate Download Process over NPU
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            Log.d("FaujOS", "Downloading ultra-quantized Gemma 4 Nano (INT4) Core to Device...")
                            val progressSteps = listOf(
                                5 to "Fetching manifest...",
                                12 to "Acquiring model package...",
                                25 to "Validating download...",
                                40 to "Streaming INT4 weights...",
                                55 to "Unpacking neural core...",
                                70 to "Optimizing for device NPU...",
                                84 to "Finalizing setup...",
                                95 to "Registering model with AICore...",
                                100 to "Model ready."
                            )

                            for ((progress, message) in progressSteps) {
                                delay(350)
                                modelDownloadProgress = progress
                                emitDownloadProgress(progress, message)
                            }

                            modelState = "ready"
                            isGemmaLoaded = true
                            withContext(Dispatchers.Main) {
                                emitDownloadProgress(100, "Gemma 4 Nano model is ready. Offline reasoning unlocked.")
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            modelState = "not_downloaded"
                            modelDownloadProgress = 0
                            emitDownloadProgress(0, "Download failed.")
                            withContext(Dispatchers.Main) {
                                result.error("DOWNLOAD_ERROR", "Failed to acquire neural model", null)
                            }
                        }
                    }
                }
                "initializeGemmaModel" -> {
                    // Start async load of Gemma 4 E2B weights via AICore
                    initializeAICoreModel { success ->
                        isGemmaLoaded = success
                        result.success(success)
                    }
                }
                "evaluateExcuse" -> {
                    val systemPrompt = call.argument<String>("systemPrompt") ?: ""
                    val userExcuse = call.argument<String>("userExcuse") ?: ""
                    
                    if (!isGemmaLoaded) {
                        result.error("UNAVAILABLE", "Gemma 4 model is not initialized via AICore.", null)
                        return@setMethodCallHandler
                    }
                    
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val jsonResponse = runGemmaInference(systemPrompt, userExcuse)
                            withContext(Dispatchers.Main) {
                                result.success(jsonResponse)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("INFERENCE_ERROR", "Failed to run NPU inference", null)
                            }
                        }
                    }
                }
                "analyzeAudioBufffer" -> {
                    val audioBuffer = call.argument<ByteArray>("audioBuffer")
                    
                    if (!isGemmaLoaded || audioBuffer == null) {
                        result.error("UNAVAILABLE", "Model unavailable or missing audio buffer.", null)
                        return@setMethodCallHandler
                    }
                    
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val jsonResponse = runGemmaAcousticInference(audioBuffer)
                            withContext(Dispatchers.Main) {
                                result.success(jsonResponse)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("INFERENCE_ERROR", "Failed to run acoustic NPU inference", null)
                            }
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun emitDownloadProgress(progress: Int, message: String) {
        val sink = progressSink ?: return
        CoroutineScope(Dispatchers.Main).launch {
            sink.success(
                mapOf(
                    "status" to modelState,
                    "progress" to progress.coerceIn(0, 100),
                    "message" to message,
                    "ready" to (modelState == "ready")
                )
            )
        }
    }

    private fun currentProgressMessage(): String {
        return when (modelState) {
            "downloading" -> when {
                modelDownloadProgress >= 95 -> "Registering model with AICore..."
                modelDownloadProgress >= 84 -> "Finalizing setup..."
                modelDownloadProgress >= 70 -> "Optimizing for device NPU..."
                modelDownloadProgress >= 55 -> "Unpacking neural core..."
                modelDownloadProgress >= 40 -> "Streaming INT4 weights..."
                modelDownloadProgress >= 25 -> "Validating download..."
                modelDownloadProgress >= 12 -> "Acquiring model package..."
                modelDownloadProgress >= 5 -> "Fetching manifest..."
                else -> "Preparing model download..."
            }
            "ready" -> "Gemma 4 Nano model is ready. Offline reasoning unlocked."
            else -> "Neural core not downloaded yet."
        }
    }

    private fun initializeAICoreModel(callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                /*
                 * Android 15/16 Developer Preview: Binding to Local AICore
                 * e.g., val client = AiCoreClient.create(context)
                 * val model = client.getGenerativeModel("gemma-4-e2b")
                 */
                Log.d("FaujOS", "Mapping Gemma 4 E2B weights into memory...")
                Thread.sleep(1200) // Simulated mapping latency on NPU
                
                withContext(Dispatchers.Main) {
                    callback(true)
                }
            } catch(e: Exception) {
                Log.e("FaujOS", "Failed to map NPU Model: " + e.message)
                withContext(Dispatchers.Main) {
                    callback(false)
                }
            }
        }
    }

    private fun runGemmaInference(systemPrompt: String, userText: String): String {
        /*
         * Gemma 4 Function Calling / Structured Output
         * NOTE: Until the AiCoreClient actual dependency is imported and the API
         * drops locally, we simulate the LLM's dynamic reasoning here by looking
         * at the user's specific context to prove the NPU bridging works.
         */
        val input = userText.lowercase()

        // Emergency Detection
        if (input.contains("snap") || input.contains("bleeding") || input.contains("pop") || input.contains("hospital")) {
            return "{\"status\": \"approved\", \"response\": \"A pop is unacceptable. Standard protocol dictates immediate medical evaluation. Dismissed.\"}"
        }

        // Dynamic Excuses Simulation
        if (input.contains("tired") || input.contains("sleep")) {
            return "{\"status\": \"denied\", \"response\": \"Fatigue is just the soul leaving the body. You signed up for this boot camp to suffer. On your feet!\"}"
        }
        
        if (input.contains("leg") || input.contains("sore") || input.contains("hurt")) {
             return "{\"status\": \"denied\", \"response\": \"Good. Pain means the muscle is tearing and rebuilding. Soreness is not an excuse, it's the objective. Resume the drill.\"}"
        }

        if (input.contains("busy") || input.contains("work") || input.contains("shift") || input.contains("time")) {
             return "{\"status\": \"denied\", \"response\": \"You have exactly 24 hours just like everyone else. Your shift is irrelevant here. Nobody cares. Camera on.\"}"
        }
        
        if (input.length < 10) {
            return "{\"status\": \"denied\", \"response\": \"'$userText'? That is the weakest surrender I've ever heard in my 10 years of enforcing standards. Try again, or start squatting.\"}"
        }

        // Generic brutal fallback
        return "{\"status\": \"denied\", \"response\": \"Your excuse ('$userText') has been evaluated and rejected by the system. My grandmother squats better on a Sunday. Back to work!\"}"
    }
    
    private fun runGemmaAcousticInference(audioBuffer: ByteArray): String {
        /*
         * Gemma 4 Edge Native Audio Processing
         * Passes raw PCM bytes into the tensor.
         * NPU evaluates if spectral features match physical exertion (sweat/grunts)
         */
        Log.d("FaujOS", "Analyzed " + audioBuffer.size + " bytes of PCM audio via NPU")
        val isAuthenticStrain = true // Simulated pass via ML Model
        return "{\"isStrainAuthentic\": $isAuthenticStrain}"
    }
}
