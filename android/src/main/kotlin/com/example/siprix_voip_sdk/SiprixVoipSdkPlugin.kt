@file:Suppress("SpellCheckingInspection")
package com.example.siprix_voip_sdk

//import io.flutter.embedding.android.FlutterActivity

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.graphics.SurfaceTexture
import android.os.Build
import android.os.IBinder
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.siprix.AccData
import com.siprix.DestData
import com.siprix.ISiprixModelListener
import com.siprix.IniData
import com.siprix.VideoData
import com.siprix.SiprixCore
import com.siprix.SiprixEglBase
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import org.webrtc.EglBase
import org.webrtc.EglRenderer
import org.webrtc.GlRectDrawer
import org.webrtc.RendererCommon
import org.webrtc.ThreadUtils
import java.util.concurrent.CountDownLatch


////////////////////////////////////////////////////////////////////////////////////////
//Method and argument names constants

const val kBadArgumentsError          = "Bad argument. Map with fields expected"
const val kModuleNotInitializedError  = "Siprix module has not initialized yet"

const val kChannelName                = "siprix_voip_sdk"

const val kMethodModuleInitialize     = "Module_Initialize"
const val kMethodModuleUnInitialize   = "Module_UnInitialize"
const val kMethodModuleVersionCode    = "Module_VersionCode"
const val kMethodModuleVersion        = "Module_Version"

const val kMethodAccountAdd           = "Account_Add"
const val kMethodAccountUpdate        = "Account_Update"
const val kMethodAccountRegister      = "Account_Register"
const val kMethodAccountUnregister    = "Account_Unregister"
const val kMethodAccountDelete        = "Account_Delete"

const val kMethodCallInvite           = "Call_Invite"
const val kMethodCallReject           = "Call_Reject"
const val kMethodCallAccept           = "Call_Accept"
const val kMethodCallHold             = "Call_Hold"
const val kMethodCallGetHoldState     = "Call_GetHoldState"
const val kMethodCallGetSipHeader     = "Call_GetSipHeader";
const val kMethodCallMuteMic          = "Call_MuteMic"
const val kMethodCallMuteCam          = "Call_MuteCam"
const val kMethodCallSendDtmf         = "Call_SendDtmf"
const val kMethodCallPlayFile         = "Call_PlayFile"
const val kMethodCallStopPlayFile     = "Call_StopPlayFile"
const val kMethodCallRecordFile       = "Call_RecordFile"
const val kMethodCallStopRecordFile   = "Call_StopRecordFile"
const val kMethodCallTransferBlind    = "Call_TransferBlind"
const val kMethodCallTransferAttended = "Call_TransferAttended"
const val kMethodCallBye              = "Call_Bye"

const val kMethodMixerSwitchToCall   = "Mixer_SwitchToCall"
const val kMethodMixerMakeConference = "Mixer_MakeConference"

const val kMethodDvcSetForegroundMode= "Dvc_SetForegroundMode"
const val kMethodDvcIsForegroundMode = "Dvc_IsForegroundMode"
const val kMethodDvcGetPlayoutNumber = "Dvc_GetPlayoutDevices"
const val kMethodDvcGetRecordNumber  = "Dvc_GetRecordingDevices"
const val kMethodDvcGetVideoNumber   = "Dvc_GetVideoDevices"
const val kMethodDvcGetPlayout       = "Dvc_GetPlayoutDevice"
const val kMethodDvcGetRecording     = "Dvc_GetRecordingDevice"
const val kMethodDvcGetVideo         = "Dvc_GetVideoDevice"
const val kMethodDvcSetPlayout       = "Dvc_SetPlayoutDevice"
const val kMethodDvcSetRecording     = "Dvc_SetRecordingDevice"
const val kMethodDvcSetVideo         = "Dvc_SetVideoDevice"
const val kMethodDvcSetVideoParams   = "Dvc_SetVideoParams"

const val kMethodVideoRendererCreate = "Video_RendererCreate"
const val kMethodVideoRendererSetSrc = "Video_RendererSetSrc"
const val kMethodVideoRendererDispose= "Video_RendererDispose"

const val kOnTrialModeNotif   = "OnTrialModeNotif"
const val kOnDevicesChanged   = "OnDevicesChanged"
const val kOnAccountRegState  = "OnAccountRegState"
const val kOnNetworkState     = "OnNetworkState"
const val kOnPlayerState      = "OnPlayerState"
const val kOnCallProceeding   = "OnCallProceeding"
const val kOnCallTerminated   = "OnCallTerminated"
const val kOnCallConnected    = "OnCallConnected"
const val kOnCallIncoming     = "OnCallIncoming"
const val kOnCallAcceptNotif  = "OnCallAcceptNotif"
const val kOnCallDtmfReceived = "OnCallDtmfReceived"
const val kOnCallTransferred  = "OnCallTransferred"
const val kOnCallRedirected   = "OnCallRedirected"
const val kOnCallSwitched     = "OnCallSwitched"
const val kOnCallHeld         = "OnCallHeld"

const val kArgVideoTextureId  = "videoTextureId"

const val kArgForeground = "foreground"
const val kArgStatusCode = "statusCode"
const val kArgExpireTime = "expireTime"
const val kArgWithVideo  = "withVideo"

const val kArgDvcIndex = "dvcIndex"
const val kArgDvcName  = "dvcName"
const val kArgDvcGuid  = "dvcGuid"

const val kArgCallId     = "callId"
const val kArgFromCallId = "fromCallId"
const val kArgToCallId   = "toCallId"
const val kArgToExt      = "toExt"
const val kArgAccId      = "accId"
const val kArgPlayerId   = "playerId"
const val kRegState    = "regState"
const val kHoldState   = "holdState"
const val kPlayerState = "playerState"
const val kNetState    = "netState"
const val kResponse    = "response"
const val kArgName   = "name"
const val kArgTone   = "tone"
const val kFrom      = "from"
const val kTo        = "to"

const val kErrorCodeEOK = 0

////////////////////////////////////////////////////////////////////////////////////////
//EventListener

class EventListener(private var channel: MethodChannel) : ISiprixModelListener {

  override fun onTrialModeNotified() {
    val argsMap = HashMap<String, Any> ()
    channel.invokeMethod(kOnTrialModeNotif, argsMap)
  }

  override fun onDevicesAudioChanged() {
    val argsMap = HashMap<String, Any> ()
    channel.invokeMethod(kOnDevicesChanged, argsMap)
  }

  override fun onAccountRegState(accId: Int, regState: AccData.RegState, response: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgAccId] = accId
    argsMap[kRegState] = regState.value
    argsMap[kResponse] = response
    channel.invokeMethod(kOnAccountRegState, argsMap)
  }

  override fun onNetworkState(name: String?, state: SiprixCore.NetworkState?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgName] = name
    argsMap[kNetState] = state?.value
    channel.invokeMethod(kOnNetworkState, argsMap)
  }

  override fun onPlayerState(playerId: Int, state: SiprixCore.PlayerState?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgPlayerId] = playerId
    argsMap[kPlayerState] = state?.value
    channel.invokeMethod(kOnPlayerState, argsMap)
  }

  override fun onCallProceeding(callId: Int, response: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kResponse] = response
    channel.invokeMethod(kOnCallProceeding, argsMap)
  }

  override fun onCallTerminated(callId: Int, statusCode: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kArgStatusCode] = statusCode
    channel.invokeMethod(kOnCallTerminated, argsMap)
  }

  override fun onCallConnected(callId: Int, hdrFrom: String?, hdrTo: String?, withVideo:Boolean) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgWithVideo] = withVideo
    argsMap[kArgCallId] = callId
    argsMap[kFrom] = hdrFrom
    argsMap[kTo] = hdrTo
    channel.invokeMethod(kOnCallConnected, argsMap)
  }

  override fun onCallIncoming(
    callId: Int, accId: Int, withVideo: Boolean,
    hdrFrom: String?, hdrTo: String?
  ) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgWithVideo] = withVideo
    argsMap[kArgCallId] = callId
    argsMap[kArgAccId] = accId
    argsMap[kFrom]  = hdrFrom
    argsMap[kTo] = hdrTo
    channel.invokeMethod(kOnCallIncoming, argsMap)
  }

  fun onCallAcceptNotif(callId: Int, withVideo: Boolean) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgWithVideo] = withVideo
    argsMap[kArgCallId] = callId
    channel.invokeMethod(kOnCallAcceptNotif, argsMap)
  }

  override fun onCallDtmfReceived(callId: Int, tone: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kArgTone] = tone
    channel.invokeMethod(kOnCallDtmfReceived, argsMap)
  }

  override fun onCallTransferred(callId: Int, statusCode: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kArgStatusCode] = statusCode
    channel.invokeMethod(kOnCallTransferred, argsMap)
  }

  override fun onCallRedirected(origCallId: Int, relatedCallId: Int, referTo: String?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgFromCallId] = origCallId
    argsMap[kArgToCallId] = relatedCallId
    argsMap[kArgToExt] = referTo
    channel.invokeMethod(kOnCallRedirected, argsMap)
  }

  override fun onCallHeld(callId: Int, state: SiprixCore.HoldState?) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    argsMap[kHoldState] = state?.value
    channel.invokeMethod(kOnCallHeld, argsMap)
  }

  override fun onCallSwitched(callId: Int) {
    val argsMap = HashMap<String, Any?> ()
    argsMap[kArgCallId] = callId
    channel.invokeMethod(kOnCallSwitched, argsMap)
  }
}


////////////////////////////////////////////////////////////////////////////////////////
/// SurfaceTextureRenderer - Displays the video stream on a Surface.

class SurfaceTextureRenderer
  (name: String?) : EglRenderer(name) {
  // Callback for reporting renderer events. Read-only after initilization so no lock required.
  private var rendererEvents: RendererCommon.RendererEvents? = null
  private val layoutLock = Any()
  private var isRenderingPaused = false
  private var isFirstFrameRendered = false
  private var rotatedFrameWidth = 0
  private var rotatedFrameHeight = 0
  private var frameRotation = 0

  private var texture: SurfaceTexture? = null

  fun init(sharedContext: EglBase.Context?,
    rendererEvents: RendererCommon.RendererEvents?
  ) {
    init(sharedContext, rendererEvents, EglBase.CONFIG_PLAIN, GlRectDrawer())
  }

  private fun init(sharedContext: EglBase.Context?,
    rendererEvents: RendererCommon.RendererEvents?, configAttributes: IntArray?,
    drawer: RendererCommon.GlDrawer?
  ) {
    ThreadUtils.checkIsOnMainThread()
    this.rendererEvents = rendererEvents
    synchronized(layoutLock) {
      isFirstFrameRendered = false
      rotatedFrameWidth = 0
      rotatedFrameHeight = 0
      frameRotation = -1
    }
    super.init(sharedContext, configAttributes, drawer)
  }

  override fun init(sharedContext: EglBase.Context?, configAttributes: IntArray?,
    drawer: RendererCommon.GlDrawer?
  ) {
    init(sharedContext, null,  /* rendererEvents */configAttributes, drawer)
  }

  override fun setFpsReduction(fps: Float) {
    synchronized(layoutLock) {
      isRenderingPaused = fps == 0f
    }
    super.setFpsReduction(fps)
  }

  override fun disableFpsReduction() {
    synchronized(layoutLock) {
      isRenderingPaused = false
    }
    super.disableFpsReduction()
  }

  override fun pauseVideo() {
    synchronized(layoutLock) {
      isRenderingPaused = true
    }
    super.pauseVideo()
  }

  // VideoSink interface.
  override fun onFrame(frame: org.webrtc.VideoFrame) {
    updateFrameDimensionsAndReportEvents(frame)
    super.onFrame(frame)
  }

  fun surfaceCreated(texture: SurfaceTexture?) {
    ThreadUtils.checkIsOnMainThread()
    this.texture = texture
    createEglSurface(texture)
  }

  fun surfaceDestroyed() {
    ThreadUtils.checkIsOnMainThread()
    val completionLatch = CountDownLatch(1)
    releaseEglSurface(completionLatch::countDown)
    ThreadUtils.awaitUninterruptibly(completionLatch)
  }

  // Update frame dimensions and report any changes to |rendererEvents|.
  private fun updateFrameDimensionsAndReportEvents(frame: org.webrtc.VideoFrame) {
    synchronized(layoutLock) {
      if (isRenderingPaused) return

      if (rotatedFrameWidth != frame.rotatedWidth ||
        rotatedFrameHeight != frame.rotatedHeight ||
        frameRotation != frame.rotation
      ) {
        rendererEvents?.onFrameResolutionChanged(
          frame.buffer.width, frame.buffer.height, frame.rotation
        )
        rotatedFrameWidth = frame.rotatedWidth
        rotatedFrameHeight = frame.rotatedHeight
        texture?.setDefaultBufferSize(rotatedFrameWidth, rotatedFrameHeight)
        frameRotation = frame.rotation
      }
    }
  }
}//SurfaceTextureRenderer


////////////////////////////////////////////////////////////////////////////////////////
/// FlutterRendererAdapter

class FlutterRendererAdapter(texturesRegistry: TextureRegistry,
                             messenger: BinaryMessenger) : EventChannel.StreamHandler {
  private val textureEntry: SurfaceTextureEntry
  private val surfaceTextureRenderer: SurfaceTextureRenderer
  private val rendererEvents: RendererCommon.RendererEvents
  private val eventChannel: EventChannel
  private var eventSink: EventSink? = null
  var srcCallId: Int = -1

  init {
    textureEntry = texturesRegistry.createSurfaceTexture()//create and register texture

    rendererEvents = RendererEventsListener(this)//createRendererEventsListener()

    surfaceTextureRenderer = SurfaceTextureRenderer("")
    surfaceTextureRenderer.init(SiprixEglBase.getInstance().context, rendererEvents)
    surfaceTextureRenderer.surfaceCreated(textureEntry.surfaceTexture())

    this.eventChannel = EventChannel(messenger, "Siprix/Texture" + textureEntry.id())
    this.eventChannel.setStreamHandler(this)
  }

  fun getRenderer(): SurfaceTextureRenderer {
    return surfaceTextureRenderer
  }

  fun getTextureId(): Long {
    return textureEntry.id()
  }

  fun dispose() {
    surfaceTextureRenderer.surfaceDestroyed()
    surfaceTextureRenderer.release()
    eventChannel.setStreamHandler(null)

    eventSink = null
    textureEntry.release()
  }

  override fun onListen(o: Any, sink: EventSink) {
    eventSink = sink//AnyThreadSink(sink)
  }

  override fun onCancel(o: Any) {
    eventSink = null
  }

  //private fun createRendererEventsListener() {
  class RendererEventsListener(private val adapter: FlutterRendererAdapter) : RendererCommon.RendererEvents {
    private var _rotation = -1
    private var _width = 0
    private var _height = 0

    override fun onFrameResolutionChanged(videoWidth: Int, videoHeight: Int, rotation: Int) {
      if (adapter.eventSink != null) {
        if (_width != videoWidth || _height != videoHeight) {
          val params = HashMap<String, Any?>()
          params["event"] = "didTextureChangeVideoSize"
          params["id"] = adapter.textureEntry.id()
          params["width"] = videoWidth.toDouble()
          params["height"] = videoHeight.toDouble()
          _width = videoWidth
          _height = videoHeight
          adapter.eventSink!!.success(params.toMap())
        }

        if (_rotation != rotation) {
          val params2 = HashMap<String, Any?>()
          params2["event"] = "didTextureChangeRotation"
          params2["id"] = adapter.textureEntry.id()
          params2["rotation"] = rotation
          _rotation = rotation
          adapter.eventSink!!.success(params2.toMap())
        }
      }
    }//onFrameResolutionChanged

    override fun onFirstFrameRendered() {
    }
  }//RendererEventsListener

}//FlutterVideoRenderer


////////////////////////////////////////////////////////////////////////////////////////
/// SiprixVoipSdkPlugin

class SiprixVoipSdkPlugin: FlutterPlugin,
  MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  private lateinit var channel : MethodChannel

  private lateinit var eventListener : EventListener
  private lateinit var activity: Activity
  private lateinit var appContext : Context

  private lateinit var messenger: BinaryMessenger
  private lateinit var textures: TextureRegistry

  private var core : SiprixCore? = null
  private var bgService: CallNotifService? = null
  private var serviceBound = false

  private val renderAdapters = HashMap<Long, FlutterRendererAdapter>()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, kChannelName)
    channel.setMethodCallHandler(this)

    textures = flutterPluginBinding.textureRegistry
    messenger = flutterPluginBinding.binaryMessenger

    eventListener = EventListener(channel)

    //Create instance when hasn't created yet
    if (CallNotifService.core == null) {
      CallNotifService.core = SiprixCore(flutterPluginBinding.applicationContext)
    }
    core = CallNotifService.core
    core?.setModelListener(eventListener)

    //Start service
    appContext = flutterPluginBinding.applicationContext
    val srvIntent = Intent(appContext, CallNotifService::class.java)
    srvIntent.setAction(CallNotifService.kActionAppStarted)
    srvIntent.putExtra(CallNotifService.kAppNameLabel, getStrResource(appContext, "app_name"))
    srvIntent.putExtra(CallNotifService.kAppIcon, getMipmapResource(appContext, "ic_launcher"))
    appContext.startService(srvIntent)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addOnNewIntentListener(this)

    setActivityFlags(activity)

    activity.bindService(Intent(activity, CallNotifService::class.java),
      serviceConnection, Context.BIND_AUTO_CREATE
    )

    hasMicPermission()
    hasCamPermission()
    hasNotifPermission()
  }

  override fun onDetachedFromActivityForConfigChanges() {
    TODO("Not yet implemented")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    TODO("Not yet implemented")
  }

  override fun onDetachedFromActivity() {
    if (serviceBound) {
      core?.setModelListener(null)
      core = null

      activity.unbindService(serviceConnection)
      serviceBound = false
    }
  }

  private val serviceConnection: ServiceConnection = object : ServiceConnection {
    override fun onServiceConnected(className: ComponentName, service: IBinder) {
      // Service is running in our own process we can directly access it.
      val binder: CallNotifService.LocalBinder = service as CallNotifService.LocalBinder
      bgService = binder.service
      bgService?.setActivityClassName(activity.javaClass.name) //!!!
      serviceBound = true

      raiseIncomingCallEvent(activity.intent)
      bgService?.handleIncomingCallIntent(activity.intent)
    }

    // Called when the connection with the service disconnects unexpectedly.
    override fun onServiceDisconnected(className: ComponentName) {
      serviceBound = false
      bgService = null
    }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val args : HashMap<String, Any?>? = call.arguments as? HashMap<String, Any?>
    if ((args==null)||(core==null)) {
      result.error( "-", kBadArgumentsError, null)
      return
    }
    if(!core!!.isInitialized) {
      if(call.method==kMethodModuleInitialize) { handleModuleInitialize(args, result); }
      else { result.error("UNAVAILABLE", kModuleNotInitializedError, null); }
      return
    }
    
    when(call.method){
      //"getPlatformVersion" ->    {  result.success("Android ${android.os.Build.VERSION.RELEASE}")  }
      kMethodModuleInitialize   ->  handleModuleInitialize(args, result)
      kMethodModuleUnInitialize ->  handleModuleUnInitialize(args, result)
      kMethodModuleVersionCode  ->  handleModuleVersionCode(args, result)
      kMethodModuleVersion      ->  handleModuleVersion(args, result)

      kMethodAccountAdd         ->  handleAccountAdd(args, result)
      kMethodAccountUpdate      ->  handleAccountUpdate(args, result)
      kMethodAccountRegister    ->  handleAccountRegister(args, result)
      kMethodAccountUnregister  ->  handleAccountUnregister(args, result)
      kMethodAccountDelete      ->  handleAccountDelete(args, result)

      kMethodCallInvite        ->   handleCallInvite(args, result)
      kMethodCallReject        ->   handleCallReject(args, result)
      kMethodCallAccept        ->   handleCallAccept(args, result)
      kMethodCallHold          ->   handleCallHold(args, result)
      kMethodCallGetHoldState  ->   handleCallGetHoldState(args, result)
      kMethodCallGetSipHeader  ->   handleCallGetSipHeader(args, result)
      kMethodCallMuteMic       ->   handleCallMuteMic(args, result)
      kMethodCallMuteCam       ->   handleCallMuteCam(args, result)
      kMethodCallSendDtmf      ->   handleCallSendDtmf(args, result)
      kMethodCallPlayFile      ->   handleCallPlayFile(args, result)
      kMethodCallStopPlayFile  ->   handleCallStopPlayFile(args, result)
      kMethodCallRecordFile    ->   handleCallRecordFile(args, result)
      kMethodCallStopRecordFile->   handleCallStopRecordFile(args, result)
      kMethodCallTransferBlind ->   handleCallTransferBlind(args, result)
      kMethodCallTransferAttended -> handleCallTransferAttended(args, result)
      kMethodCallBye ->             handleCallBye(args, result)

      kMethodMixerSwitchToCall ->   handleMixerSwitchToCall(args, result)
      kMethodMixerMakeConference -> handleMixerMakeConference(args, result)

      kMethodDvcSetForegroundMode->  handleDvcSetForegroundMode(args, result)
      kMethodDvcIsForegroundMode->   handleDvcIsForegroundMode(args, result)
      kMethodDvcGetPlayoutNumber->   handleDvcGetPlayoutNumber(args, result)
      kMethodDvcGetRecordNumber ->   handleDvcGetRecordNumber(args, result)
      kMethodDvcGetVideoNumber  ->   handleDvcGetVideoNumber(args, result)
      kMethodDvcGetPlayout      ->   handleDvcGetPlayout(args, result)
      kMethodDvcGetRecording    ->   handleDvcGetRecording(args, result)
      kMethodDvcGetVideo        ->   handleDvcGetVideo(args, result)
      kMethodDvcSetPlayout      ->   handleDvcSetPlayout(args, result)
      kMethodDvcSetRecording    ->   handleDvcSetRecording(args, result)
      kMethodDvcSetVideo        ->   handleDvcSetVideo(args, result)
      kMethodDvcSetVideoParams  ->   handleDvcSetVideoParams(args, result)

      kMethodVideoRendererCreate ->   handleVideoRendererCreate(args, result)
      kMethodVideoRendererSetSrc ->   handleVideoRendererSetSrc(args, result)
      kMethodVideoRendererDispose->   handleVideoRendererDispose(args, result)

      else                       ->   result.notImplemented()
    }//when
  }


  private fun handleModuleInitialize(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    //Check already created
    if (core!!.isInitialized) {
      result.success("Already initialized")
      return
    }

    //Get arguments from map
    val iniData = IniData()

    val license : String? = args["license"] as? String
    if(license != null) { iniData.setLicense(license) }

    val logLevelFile : Int? = args["logLevelFile"] as? Int
    if(logLevelFile != null) { iniData.setLogLevelFile(IniData.LogLevel.fromInt(logLevelFile)); }

    val logLevelIde : Int? = args["logLevelIde"] as? Int
    if(logLevelIde != null) { iniData.setLogLevelIde(IniData.LogLevel.fromInt(logLevelIde)); }

    val rtpStartPort : Int? = args["rtpStartPort"] as? Int
    if(rtpStartPort != null) { iniData.setRtpStartPort(rtpStartPort); }

    val tlsVerifyServer : Boolean? = args["tlsVerifyServer"] as? Boolean
    if(tlsVerifyServer != null) { iniData.setTlsVerifyServer(tlsVerifyServer); }

    val singleCallMode : Boolean? = args["singleCallMode"] as? Boolean
    if(singleCallMode != null) { iniData.setSingleCallMode(singleCallMode); }

    val shareUdpTransport : Boolean? = args["shareUdpTransport"] as? Boolean
    if(shareUdpTransport != null) { iniData.setShareUdpTransport(shareUdpTransport); }

    val listenTelState : Boolean? = args["listenTelState"] as? Boolean
    if(listenTelState != null) { iniData.setUseTelState(listenTelState); }

    iniData.setUseExternalRinger(true)
    val err = core!!.initialize(iniData)
    sendResult(err, result)
  }

  @Suppress("UNUSED_PARAMETER")
  private fun handleModuleUnInitialize(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val err = core!!.unInitialize()
    sendResult(err, result)
  }

  @Suppress("UNUSED_PARAMETER")
  private fun handleModuleVersionCode(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val versionCode : Int = core!!.versionCode
    result.success(versionCode)
  }

  @Suppress("UNUSED_PARAMETER")
  private fun handleModuleVersion(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val version: String = core!!.version
    result.success(version)
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Account methods implementation

  private fun parseAccData(args : HashMap<String, Any?>) : AccData {
    //Get arguments from map
    val accData = AccData()

    val sipServer : String? = args["sipServer"] as? String
    if(sipServer != null) { accData.setSipServer(sipServer); }

    val sipExtension : String? = args["sipExtension"] as? String
    if(sipExtension != null) { accData.setSipExtension(sipExtension); }

    val sipPassword : String? = args["sipPassword"] as? String
    if(sipPassword != null) { accData.setSipPassword(sipPassword); }

    val sipAuthId : String? = args["sipAuthId"] as? String
    if(sipAuthId != null) { accData.setSipAuthId(sipAuthId); }

    val sipProxy : String? = args["sipProxy"] as? String
    if(sipProxy != null) { accData.setSipProxyServer(sipProxy); }

    val displName : String? = args["displName"] as? String
    if(displName != null) { accData.setDisplayName(displName); }

    val userAgent : String? = args["userAgent"] as? String
    if(userAgent != null) { accData.setUserAgent(userAgent); }

    val expireTime : Int? = args["expireTime"] as? Int
    if(expireTime != null) { accData.setExpireTime(expireTime); }

    val transport : Int? = args["transport"] as? Int
    if(transport != null) { accData.setTranspProtocol(AccData.SipTransport.fromInt(transport)); }

    val port : Int? = args["port"] as? Int
    if(port != null) { accData.setTranspPort(port); }

    val tlsCaCertPath : String? = args["tlsCaCertPath"] as? String
    if(tlsCaCertPath != null) { accData.setTranspTlsCaCert(tlsCaCertPath); }

    val tlsUseSipScheme : Boolean? = args["tlsUseSipScheme"] as? Boolean
    if(tlsUseSipScheme != null) { accData.setUseSipSchemeForTls(tlsUseSipScheme); }

    val rtcpMuxEnabled : Boolean? = args["rtcpMuxEnabled"] as? Boolean
    if(rtcpMuxEnabled != null) { accData.setRtcpMuxEnabled(rtcpMuxEnabled); }

    val instanceId : String? = args["instanceId"] as? String
    if(instanceId != null) { accData.setInstanceId(instanceId); }

    val ringTonePath : String? = args["ringTonePath"] as? String
    if(ringTonePath != null) { accData.setRingToneFile(ringTonePath); }
    
    val keepAliveTime : Int? = args["keepAliveTime"] as? Int
    if(keepAliveTime != null) { accData.setKeepAliveTime(keepAliveTime); }
    
    val rewriteContactIp : Boolean? = args["rewriteContactIp"] as? Boolean
    if(rewriteContactIp != null) { accData.setRewriteContactIp(rewriteContactIp); }

    val verifyIncomingCall : Boolean? = args["verifyIncomingCall"] as? Boolean
    if(verifyIncomingCall != null) { accData.setVerifyIncomingCall(verifyIncomingCall); }

    val secureMedia : Int? = args["secureMedia"] as? Int
    if(secureMedia != null) { accData.setSecureMediaMode(AccData.SecureMediaMode.fromInt(secureMedia)); }

    val xheaders: HashMap<String, Any?>? = args["xheaders"] as? HashMap<String, Any?>?
    if(xheaders != null) {
      for ((hdrName, hdrVal) in xheaders) {
        val hdrStrVal : String? = hdrVal as? String
        if(hdrStrVal != null)
          accData.addXHeader(hdrName, hdrStrVal)
      }
    }

    val aCodecs: ArrayList<Int?>? = args["aCodecs"] as? ArrayList<Int?>?
    if(aCodecs != null) {
      accData.resetAudioCodecs()
      for (c in aCodecs)
        if(c != null)
          accData.addAudioCodec(AccData.AudioCodec.fromInt(c))
    }
    val vCodecs: ArrayList<Int?>? = args["vCodecs"] as? ArrayList<Int?>?
    if(vCodecs != null) {
      accData.resetVideoCodecs()
      for (c in vCodecs)
        if(c != null)
          accData.addVideoCodec(AccData.VideoCodec.fromInt(c))
    }

    return accData
  }

  private fun handleAccountAdd(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accData = parseAccData(args)
    val accIdArg = SiprixCore.IdOutArg()
    val err = core!!.accountAdd(accData, accIdArg)
    if(err == kErrorCodeEOK){
      result.success(accIdArg.value)
    }else{
      result.error(err.toString(), core!!.getErrText(err), accIdArg.value)
    }
  }

  private fun handleAccountUpdate(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accData = parseAccData(args)
    val accId : Int? = args[kArgAccId] as? Int

    if(accId != null) {
      val err = core!!.accountUpdate(accData, accId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleAccountRegister(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accId : Int?     = args[kArgAccId] as? Int
    val expireTime: Int? = args[kArgExpireTime] as? Int

    if((accId != null) && ( expireTime != null)) {
      val err = core!!.accountRegister(accId, expireTime)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }    
  }
  
  private fun handleAccountUnregister(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accId : Int? = args[kArgAccId] as? Int

    if(accId != null) {
      val err = core!!.accountUnregister(accId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleAccountDelete(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val accId : Int? = args[kArgAccId] as? Int

    if(accId != null) {
      val err = core!!.accountDelete(accId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Calls methods implementation
  
  private fun handleCallInvite(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    if(!hasMicPermission()) {
      result.error("Microphone permission required", "-", null)
      return
    }

    //Get arguments from map
    val destData = DestData()

    val toExt : String? = args["extension"] as? String
    if(toExt != null) { destData.setExtension(toExt); }

    val fromAccId : Int? = args[kArgAccId] as? Int
    if(fromAccId != null) { destData.setAccountId(fromAccId); }

    val inviteTimeout : Int? = args["inviteTimeout"] as? Int
    if(inviteTimeout != null) { destData.setInviteTimeout(inviteTimeout); }

    val withVideo : Boolean? = args[kArgWithVideo] as? Boolean
    if(withVideo != null) { destData.setVideoCall(withVideo); }

    val xheaders: HashMap<String, Any?>? = args["xheaders"] as? HashMap<String, Any?>?
    if(xheaders != null) {
      for ((hdrName, hdrVal) in xheaders) {
        val hdrStrVal : String? = hdrVal as? String
        if(hdrStrVal != null)
          destData.addXHeader(hdrName, hdrStrVal)
      }
    }

    val callIdArg = SiprixCore.IdOutArg()
    val err = core!!.callInvite(destData, callIdArg)
    if(err == kErrorCodeEOK) {
      result.success(callIdArg.value)
    }else{
      result.error(err.toString(), core!!.getErrText(err), null)
    }
  }
  
  private fun handleCallReject(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId    : Int? = args[kArgCallId] as? Int
    val statusCode: Int? = args[kArgStatusCode] as? Int

    if((callId != null) && ( statusCode != null)) {
      val err = core!!.callReject(callId, statusCode)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallAccept(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    if(!hasMicPermission()) {
      result.error("Microphone permission required", "-", null)
      return
    }

    val callId : Int?= args[kArgCallId] as? Int
    val withVideo :Boolean? = args[kArgWithVideo] as? Boolean

    if((callId != null)&&(withVideo != null)) {
      val err = core!!.callAccept(callId, withVideo)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallHold(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int

    if(callId != null) {
      val err = core!!.callHold(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallGetHoldState(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId :Int? = args[kArgCallId] as? Int

    if(callId == null) {
      sendBadArguments(result)
      return
    }

    val state = SiprixCore.IdOutArg()
    val err = core!!.callGetHoldState(callId, state)
    if(err == kErrorCodeEOK){
      result.success(state.value)
    }else{
      result.error(err.toString(), core!!.getErrText(err), null)
    }
  }

  private fun handleCallGetSipHeader(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId :Int? = args[kArgCallId] as? Int
    val hdrName :String? = args["hdrName"] as? String
    
    if((callId == null)||(hdrName==null)) {
      sendBadArguments(result)
      return
    }

    result.success(core!!.callGetSipHeader(callId, hdrName))
  }

  private fun handleCallMuteMic(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int
    val mute :Boolean? = args["mute"] as? Boolean

    if((callId == null)||(mute==null)) {
      sendBadArguments(result)
      return
    }
    val err = core!!.callMuteMic(callId, mute)
    sendResult(err, result)
  }
  
  private fun handleCallMuteCam(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int
    val mute :Boolean? = args["mute"] as? Boolean

    if((callId == null)||(mute==null)) {
      sendBadArguments(result)
      return
    }
    val err = core!!.callMuteCam(callId, mute)
    sendResult(err, result)
  }

  private fun handleCallSendDtmf(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId :Int?         = args[kArgCallId] as? Int
    val durationMs : Int?    = args["durationMs"] as? Int
    val interToneGapMs: Int? = args["intertoneGapMs"] as? Int
    val method  : Int?       = args["method"] as? Int
    val dtmfs  : String?     = args["dtmfs"] as? String

    if((callId == null)||(durationMs==null)||(interToneGapMs==null)||(dtmfs==null)||(method==null)) {
      sendBadArguments(result)
      return
    }

    val err = core!!.callSendDtmf(callId, dtmfs,
      durationMs, interToneGapMs, SiprixCore.DtmfMethod.fromInt(method))
    sendResult(err, result)
  }
  
  private fun handleCallPlayFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int?          = args[kArgCallId] as? Int
    val pathToMp3File :String? = args["pathToMp3File"] as? String
    val loop :Boolean?         = args["loop"] as? Boolean

    if((callId == null)||(pathToMp3File==null)||(loop==null)) {
      sendBadArguments(result)
      return
    }

    val playerIdArg = SiprixCore.IdOutArg()
    val err = core!!.callPlayFile(callId, pathToMp3File, loop, playerIdArg)
    if(err == kErrorCodeEOK) {
      result.success(playerIdArg.value)
    }else{
      result.error(err.toString(), core!!.getErrText(err), null)
    }
  }

  private fun handleCallStopPlayFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val playerId : Int? = args[kArgPlayerId] as? Int

    if(playerId != null) {
      val err = core!!.callStopPlayFile(playerId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallRecordFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int?           = args[kArgCallId] as? Int
    val pathToMp3File :String? = args["pathToMp3File"] as? String
    
    if((callId != null)&&((pathToMp3File!=null))) {
      val err = core!!.callRecordFile(callId, pathToMp3File)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }

  private fun handleCallStopRecordFile(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId : Int? = args[kArgCallId] as? Int

    if(callId != null) {
      val err = core!!.callStopRecordFile(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }

  private fun handleCallTransferBlind(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int
    val toExt  = args[kArgToExt] as? String

    if((callId != null) && ( toExt != null)) {
      val err = core!!.callTransferBlind(callId, toExt)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallTransferAttended(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val fromCallId = args[kArgFromCallId] as? Int
    val toCallId   = args[kArgToCallId] as? Int

    if((fromCallId != null) && ( toCallId != null)) {
      val err = core!!.callTransferAttended(fromCallId, toCallId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }
  
  private fun handleCallBye(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int

    if(callId != null) {
      val err = core!!.callBye(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Mixer methods implementation
  
  private fun handleMixerSwitchToCall(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int

    if(callId != null) {
      val err = core!!.mixerSwitchToCall(callId)
      sendResult(err, result)
    }else{
      sendBadArguments(result)
    }    
  }

  @Suppress("UNUSED_PARAMETER")
  private fun handleMixerMakeConference(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val err = core!!.mixerMakeConference()
    sendResult(err, result)
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Devices methods implementation

  private fun handleDvcSetForegroundMode(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val foregroundEnable :Boolean? = args[kArgForeground] as? Boolean
    if(foregroundEnable == null) {
      sendBadArguments(result)
      return
    }

    if(bgService == null) {
      result.error("-", "Service has not bound yet", null)
      return
    }

    if(foregroundEnable) {
      val success = bgService!!.startForegroundMode()
      if(success) result.success("Foreground mode started")
      else        result.error( "-", "Missed permissions", null)
    }
    else {
      bgService!!.stopForegroundMode()
      result.success("Foreground mode stopped")
    }
  }
  private fun handleDvcIsForegroundMode(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(if(bgService!=null) bgService!!.isForegroundMode() else false)
  }


  private fun handleDvcGetPlayoutNumber(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(core!!.dvcGetAudioDevices())
  }
  private fun handleDvcGetRecordNumber(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(0)//TODO add impl
  }
  private fun handleDvcGetVideoNumber(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success(0)//TODO add impl
  }

  private fun handleDvcGetPlayout(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val dvcIndex :Int? = args[kArgDvcIndex] as? Int

    if(dvcIndex != null) {
      val argsMap = HashMap<String, Any?> ()
      argsMap[kArgDvcName] = core!!.dvcGetAudioDevice(dvcIndex).name
      argsMap[kArgDvcGuid] = dvcIndex.toString()
      result.success(argsMap)
    }else{
      sendBadArguments(result)
    }
  }
  private fun handleDvcGetRecording(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success("")//TODO add impl
  }
  private fun handleDvcGetVideo(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success("")//TODO add impl
  }

  private fun handleDvcSetPlayout(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val dvcIndex :Int? = args[kArgDvcIndex] as? Int
    if(dvcIndex != null) {
      val dvc = core!!.dvcGetAudioDevice(dvcIndex)
      if(!dvc.equals(SiprixCore.AudioDevice.None)) {
        core!!.dvcSetAudioDevice(dvc)
        result.success("Success")
      }else{
        result.error( "-", "Bad device index", null)
      }
    }else{
      sendBadArguments(result)
    }
  }
  private fun handleDvcSetRecording(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success("Success")
  }
  private fun handleDvcSetVideo(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    result.success("Success")
  }

  private fun handleDvcSetVideoParams(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val vdoData = VideoData()

    val noCameraImgPath : String? = args["noCameraImgPath"] as? String
    if(noCameraImgPath != null) { vdoData.setNoCameraImgPath(noCameraImgPath) }

    val framerateFps : Int? = args["framerateFps"] as? Int
    if(framerateFps != null) { vdoData.setFramerate(framerateFps); }

    val bitrateKbps : Int? = args["bitrateKbps"] as? Int
    if(bitrateKbps != null) { vdoData.setBitrate(bitrateKbps); }

    val height : Int? = args["height"] as? Int
    if(height != null) { vdoData.setHeight(height); }

    val width : Int? = args["width"] as? Int
    if(width != null) { vdoData.setWidth(width); }

    val err = core!!.dvcSetVideoParams(vdoData)
    sendResult(err, result)
  }



  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix video renderers

  private fun handleVideoRendererCreate(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val renderAdapter = FlutterRendererAdapter(textures, messenger)
    val textureId = renderAdapter.getTextureId()

    renderAdapters[textureId] = renderAdapter

    result.success(textureId)
  }

  private fun handleVideoRendererSetSrc(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    val callId = args[kArgCallId] as? Int
    var textureId = args[kArgVideoTextureId] as? Long
    if(textureId==null) textureId = (args[kArgVideoTextureId] as? Int)?.toLong();

    if((callId == null) || ( textureId == null)) {
      sendBadArguments(result)
      return
    }

    val renderAdapter: FlutterRendererAdapter? = renderAdapters[textureId]
    if(renderAdapter != null) {
      renderAdapter.srcCallId = callId
      val err = core!!.callSetVideoRenderer(callId, renderAdapter.getRenderer())
      sendResult(err, result)
    }
  }

  private fun handleVideoRendererDispose(args : HashMap<String, Any?>, result: MethodChannel.Result) {
    var textureId = args[kArgVideoTextureId] as? Long
    if(textureId==null) textureId = (args[kArgVideoTextureId] as? Int)?.toLong();
    if(textureId == null) { sendBadArguments(result); return; }

    val renderAdapter: FlutterRendererAdapter? = renderAdapters[textureId]
    if(renderAdapter != null) {
      val nullRenderer : EglRenderer? = null
      core!!.callSetVideoRenderer(renderAdapter.srcCallId, nullRenderer)
      renderAdapter.dispose()
      renderAdapters.remove(textureId)
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Helpers methods

  private fun sendResult(err : Int, result: MethodChannel.Result) {
    if (err == kErrorCodeEOK) {
      result.success("Success")
    }
    else{
      result.error(err.toString(), core!!.getErrText(err), null)
    }
  }

  private fun sendBadArguments(result: MethodChannel.Result){
    result.error( "-", kBadArgumentsError, null)
  }

  private fun hasNotifPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= 33) {
      hasPermission(Manifest.permission.POST_NOTIFICATIONS)
    }
    else true
  }

  private fun hasMicPermission(): Boolean {
    return hasPermission(Manifest.permission.RECORD_AUDIO)
  }

  private fun hasCamPermission(): Boolean {
    return hasPermission(Manifest.permission.CAMERA)
  }

  private fun hasPermission(permission: String): Boolean {
    if (ContextCompat.checkSelfPermission(
        activity, permission) == PackageManager.PERMISSION_GRANTED
    ) {
      return true
    }
    val requestCode = 1
    ActivityCompat.requestPermissions(activity, arrayOf(permission),
      requestCode
    )
    return false
  }

  override fun onNewIntent(intent: Intent): Boolean {
    //Raised when activity exist, but in background
    bgService?.handleIncomingCallIntent(intent)
    return raiseIncomingCallEvent(intent)
  }

  private fun raiseIncomingCallEvent(intent: Intent):Boolean {
    val args = intent.extras
    val callId = args?.getInt(CallNotifService.kExtraCallId)
    val accId = args?.getInt(CallNotifService.kExtraAccId)
    val video = args?.getBoolean(CallNotifService.kExtraWithVideo)
    val from = args?.getString(CallNotifService.kExtraHdrFrom)
    val to = args?.getString(CallNotifService.kExtraHdrTo)

    if((callId != null)&&(accId != null)&&(video != null)) {
      eventListener.onCallIncoming(callId, accId, video, from, to)

      if(CallNotifService.kActionIncomingCallAccept == intent.action)
        eventListener.onCallAcceptNotif(callId, false)

      return true
    }
    return false
  }

  private fun setActivityFlags(activity: Activity) {
    if (Build.VERSION.SDK_INT < 27) {
      activity.window.addFlags(
        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
              WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
      )
    } else {
      activity.setTurnScreenOn(true)
      activity.setShowWhenLocked(true)
    }
  }

  private fun getStrResource(context: Context, resName: String): String {
    val stringRes = context.resources.getIdentifier(resName, "string", context.packageName)
    return if(stringRes != 0) context.getString(stringRes)
    else context.applicationInfo.nonLocalizedLabel.toString()
  }
  private fun getMipmapResource(context: Context, resName: String): Int {
    return context.resources.getIdentifier(resName, "mipmap", context.packageName)
  }

}
