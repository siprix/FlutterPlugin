import Flutter
import UIKit
import siprix

////////////////////////////////////////////////////////////////////////////////////////
//Method and argument names constants

private let kBadArgumentsError          = "Bad argument. Map with fields expected"
private let kModuleNotInitializedError  = "Siprix module has not initialized yet"

private let kChannelName                = "siprix_voip_sdk"

private let kMethodModuleInitialize     = "Module_Initialize"
private let kMethodModuleUnInitialize   = "Module_UnInitialize"
private let kMethodModuleHomeFolder     = "Module_HomeFolder"
private let kMethodModuleVersionCode    = "Module_VersionCode"
private let kMethodModuleVersion        = "Module_Version"

private let kMethodAccountAdd           = "Account_Add"
private let kMethodAccountUpdate        = "Account_Update"
private let kMethodAccountRegister      = "Account_Register"
private let kMethodAccountUnregister    = "Account_Unregister"
private let kMethodAccountDelete        = "Account_Delete"

private let kMethodCallInvite           = "Call_Invite"
private let kMethodCallReject           = "Call_Reject"
private let kMethodCallAccept           = "Call_Accept"
private let kMethodCallHold             = "Call_Hold"
private let kMethodCallGetHoldState     = "Call_GetHoldState"
private let kMethodCallGetSipHeader     = "Call_GetSipHeader";
private let kMethodCallMuteMic          = "Call_MuteMic"
private let kMethodCallMuteCam          = "Call_MuteCam"
private let kMethodCallSendDtmf         = "Call_SendDtmf"
private let kMethodCallPlayFile         = "Call_PlayFile"
private let kMethodCallStopPlayFile     = "Call_StopPlayFile"
private let kMethodCallRecordFile       = "Call_RecordFile"
private let kMethodCallStopRecordFile   = "Call_StopRecordFile"
private let kMethodCallTransferBlind    = "Call_TransferBlind"
private let kMethodCallTransferAttended = "Call_TransferAttended"
private let kMethodCallBye              = "Call_Bye"

private let kMethodMixerSwitchToCall   = "Mixer_SwitchToCall"
private let kMethodMixerMakeConference = "Mixer_MakeConference"

private let kMethodDvcGetPlayoutNumber = "Dvc_GetPlayoutDevices"
private let kMethodDvcGetRecordNumber  = "Dvc_GetRecordingDevices"
private let kMethodDvcGetVideoNumber   = "Dvc_GetVideoDevices"
private let kMethodDvcGetPlayout       = "Dvc_GetPlayoutDevice"
private let kMethodDvcGetRecording     = "Dvc_GetRecordingDevice"
private let kMethodDvcGetVideo         = "Dvc_GetVideoDevice"
private let kMethodDvcSetPlayout       = "Dvc_SetPlayoutDevice"
private let kMethodDvcSetRecording     = "Dvc_SetRecordingDevice"
private let kMethodDvcSetVideo         = "Dvc_SetVideoDevice"
private let kMethodDvcSetVideoParams   = "Dvc_SetVideoParams"

private let kMethodVideoRendererCreate = "Video_RendererCreate"
private let kMethodVideoRendererSetSrc = "Video_RendererSetSrc"
private let kMethodVideoRendererDispose = "Video_RendererDispose"

private let kOnTrialModeNotif   = "OnTrialModeNotif"
private let kOnDevicesChanged   = "OnDevicesChanged"
private let kOnAccountRegState  = "OnAccountRegState"
private let kOnNetworkState     = "OnNetworkState"
private let kOnPlayerState      = "OnPlayerState"
private let kOnRingerState      = "OnRingerState"
private let kOnCallProceeding   = "OnCallProceeding"
private let kOnCallTerminated   = "OnCallTerminated"
private let kOnCallConnected    = "OnCallConnected"
private let kOnCallIncoming     = "OnCallIncoming"
private let kOnCallDtmfReceived = "OnCallDtmfReceived"
private let kOnCallTransferred  = "OnCallTransferred"
private let kOnCallRedirected   = "OnCallRedirected"
private let kOnCallSwitched     = "OnCallSwitched"
private let kOnCallHeld         = "OnCallHeld"

private let kArgVideoTextureId  = "videoTextureId"

private let kArgStatusCode = "statusCode"
private let kArgExpireTime = "expireTime"
private let kArgWithVideo  = "withVideo"

private let kArgDvcIndex = "dvcIndex"
private let kArgDvcName  = "dvcName"
private let kArgDvcGuid  = "dvcGuid"

private let kArgCallId     = "callId"
private let kArgFromCallId = "fromCallId"
private let kArgToCallId   = "toCallId"
private let kArgToExt      = "toExt"

private let kArgAccId    = "accId"
private let kArgPlayerId = "playerId"
private let kRegState    = "regState"
private let kHoldState   = "holdState"
private let kPlayerState = "playerState"
private let kNetState    = "netState"
private let kResponse    = "response"

private let kArgName   = "name"
private let kArgTone   = "tone"
private let kFrom      = "from"
private let kTo        = "to"


////////////////////////////////////////////////////////////////////////////////////////
//SiprixEventHandler
class SiprixEventHandler : NSObject, SiprixEventDelegate {
    
    private var _channel : FlutterMethodChannel
    private let ringer : Ringer?
    init(withChannel channel:FlutterMethodChannel) {
        self._channel      = channel
        
        //Ringer (create only when CallKit disabled)
        ringer = Ringer()
    }
    
    public func setRingTonePath(_ path : String) {
        DispatchQueue.main.async {
            self.ringer?.setRingTonePath(path)
        }
    }
    
    //////////////////////////////////////////////////////////////////////////
    //Event handlers
    
    public func onTrialModeNotified() {
        let argsMap = [String:Any]()
        _channel.invokeMethod(kOnTrialModeNotif, arguments: argsMap)
    }

    public func onDevicesAudioChanged() {
        let argsMap = [String:Any]()
        _channel.invokeMethod(kOnDevicesChanged, arguments: argsMap)
    }

    public func onAccountRegState(_ accId: Int, regState: RegState, response: String) {
        var argsMap = [String:Any]()
        argsMap[kArgAccId] = accId
        argsMap[kRegState] = regState.rawValue
        argsMap[kResponse] = response
        _channel.invokeMethod(kOnAccountRegState, arguments: argsMap)
    }
    
    public func onNetworkState(_ name: String, netState: NetworkState) {
        var argsMap = [String:Any]()
        argsMap[kArgName] = name
        argsMap[kNetState] = netState.rawValue
        _channel.invokeMethod(kOnNetworkState, arguments: argsMap)
    }

    public func onPlayerState(_ playerId: Int, playerState: PlayerState) {
        var argsMap = [String:Any]()
        argsMap[kArgPlayerId] = playerId
        argsMap[kPlayerState] = playerState.rawValue
        _channel.invokeMethod(kOnPlayerState, arguments: argsMap)
    }
    
    public func onRingerState(_ started: Bool) {
        DispatchQueue.main.async {
            if(started) { self.ringer?.play() }
            else        { self.ringer?.stop() }
        }
    }

    public func onCallProceeding(_ callId: Int, response:String){
        var argsMap = [String:Any]()
        argsMap[kArgCallId] = callId
        argsMap[kResponse] = response
        _channel.invokeMethod(kOnCallProceeding, arguments: argsMap)
    }

    public func onCallTerminated(_ callId: Int, statusCode:Int) {
        var argsMap = [String:Any]()
        argsMap[kArgCallId] = callId
        argsMap[kArgStatusCode] = statusCode
        _channel.invokeMethod(kOnCallTerminated, arguments: argsMap)
    }

    public func onCallConnected(_ callId: Int, hdrFrom:String, hdrTo:String, withVideo:Bool) {
        var argsMap = [String:Any]()
        argsMap[kArgWithVideo] = withVideo
        argsMap[kArgCallId] = callId
        argsMap[kFrom] = hdrFrom
        argsMap[kTo] = hdrTo
        _channel.invokeMethod(kOnCallConnected, arguments: argsMap)
    }

    public func onCallIncoming(_ callId:Int, accId:Int, withVideo:Bool, hdrFrom:String, hdrTo:String) {
        var argsMap = [String:Any]()
        argsMap[kArgWithVideo] = withVideo
        argsMap[kArgCallId] = callId
        argsMap[kArgAccId] = accId
        argsMap[kFrom] = hdrFrom
        argsMap[kTo] = hdrTo
        _channel.invokeMethod(kOnCallIncoming, arguments: argsMap)
    }

    public func onCallDtmfReceived(_ callId:Int, tone:Int) {
        var argsMap = [String:Any]()
        argsMap[kArgCallId] = callId
        argsMap[kArgTone] = tone
        _channel.invokeMethod(kOnCallDtmfReceived, arguments: argsMap)
    }

    public func onCallSwitched(_ callId:Int) {
        var argsMap = [String:Any]()
        argsMap[kArgCallId] = callId
        _channel.invokeMethod(kOnCallSwitched, arguments: argsMap)
    }
    
    public func onCallTransferred(_ callId:Int, statusCode:Int) {
        var argsMap = [String:Any]()
        argsMap[kArgCallId] = callId
        argsMap[kArgStatusCode] = statusCode
        _channel.invokeMethod(kOnCallTransferred, arguments: argsMap)
    }

    public func onCallRedirected(_ origCallId: Int, relatedCallId: Int, referTo: String) {
        var argsMap = [String:Any]()
        argsMap[kArgFromCallId] = origCallId
        argsMap[kArgToCallId] = relatedCallId
        argsMap[kArgToExt] = referTo
        _channel.invokeMethod(kOnCallRedirected, arguments: argsMap)
    }

    public func onCallHeld(_ callId:Int, holdState:HoldState) {
        var argsMap = [String:Any]()
        argsMap[kArgCallId] = callId
        argsMap[kHoldState] = holdState.rawValue
        _channel.invokeMethod(kOnCallHeld, arguments: argsMap)
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///Ringer

class Ringer {
    private var player: AVAudioPlayer?
    private var ringtonePath: String = ""
    
    public func setRingTonePath(_ path : String) {
        ringtonePath = path
    }

    func unInit() {
        if (player != nil)&&(player!.isPlaying) {
            player!.stop()
        }
    }

    private func enableSpeaker(_ enabled: Bool) {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        var options = session.categoryOptions

        if enabled {
            options.insert(AVAudioSession.CategoryOptions.defaultToSpeaker)
        } else {
            options.remove(AVAudioSession.CategoryOptions.defaultToSpeaker)
        }
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: options)
        } catch {
            print("Can't start ringer: error \(error)")
        }
        #endif
    }

    @discardableResult
    func play() -> Bool {
        if player == nil {
            let url = URL(fileURLWithPath:ringtonePath)
            player = try? AVAudioPlayer(contentsOf: url)
        }
        if player != nil {
            player?.numberOfLoops = -1
            enableSpeaker(true)
            player?.play()
            return true
        }
        return false
    }

    @discardableResult
    func stop() -> Bool {
        if (player != nil) && player!.isPlaying {
            player?.stop()
            enableSpeaker(false)
        }
        return true
    }
    
}//Ringer

///////////////////////////////////////////////////////////////////////////////////////
//FlutterVideoRenderer

class FlutterVideoRenderer : NSObject, SiprixVideoRendererDelegate, FlutterTexture, FlutterStreamHandler {
    struct EventData {
        var width: Int32 = 0
        var height: Int32 = 0
        var rotation: VideoFrameRotation = .rotation_0
    }
    var _eventData = EventData()
    var _textureRegistry : FlutterTextureRegistry
    var _eventChannel : FlutterEventChannel?
    var _eventSink : FlutterEventSink?
    var _pixelBuffer : CVPixelBuffer? = nil
    var _pixelBufferWidth = 0
    var _pixelBufferHeight = 0
    var _textureId : Int64 = 0
    
    static let kInvalidCallCallId : Int32 = -1
    public var srcCallId : Int32 = kInvalidCallCallId
            
    init(textureRegistry:FlutterTextureRegistry) {
        self._textureRegistry = textureRegistry
    }
    
    deinit {
       // _textureRegistry.unregisterTexture(_textureId)
    }
    
    public func registerTextureAndCreateChannel(binMessenger : FlutterBinaryMessenger) -> Int64 {
        _textureId = _textureRegistry.register(self)
        
        _eventChannel = FlutterEventChannel(name:"Siprix/Texture\(_textureId)", binaryMessenger:binMessenger)
        _eventChannel?.setStreamHandler(self)
        return _textureId
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self._eventSink = events
        return nil
    }
       
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self._eventSink = nil
        return nil
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
      if (_pixelBuffer != nil) {
        return Unmanaged<CVPixelBuffer>.passRetained(_pixelBuffer!)
      }
      return nil
    }
    
    func copyFrameToCVPixelBuffer(frame : SiprixVideoFrame) {
        if (_pixelBufferWidth != frame.width() || _pixelBufferHeight != frame.height()) {
            _pixelBufferWidth  = Int(frame.width())
            _pixelBufferHeight = Int(frame.height())
            
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                         kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                         kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue] as CFDictionary
            
            CVPixelBufferCreate(nil, _pixelBufferWidth, _pixelBufferHeight,
                                kCVPixelFormatType_32ARGB, attrs, &_pixelBuffer)
        }
        
        CVPixelBufferLockBaseAddress(_pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        if let baseAddress = CVPixelBufferGetBaseAddress(_pixelBuffer!) {
            let buf = baseAddress.assumingMemoryBound(to: UInt8.self)
            frame.convert(toARGB: .ARGB, dstBuffer: buf, dstWidth: frame.width(), dstHeight: frame.height())
        }
        CVPixelBufferUnlockBaseAddress(_pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    }
        
    public func onFrame(_ videoFrame : SiprixVideoFrame) {
        copyFrameToCVPixelBuffer(frame:videoFrame)
        sendEvent(frame:videoFrame)
        DispatchQueue.main.async {
            self._textureRegistry.textureFrameAvailable(self._textureId)
        }
    }

    func sendEvent(frame : SiprixVideoFrame) {
        if(_eventData.rotation != frame.rotation()) {
            if(_eventSink != nil) {
                var argsMap = [String:Any]()
                argsMap["event"]  = "didTextureChangeRotation"
                argsMap["id"]     = _textureId
                argsMap["rotation"]  = _eventData.width
                DispatchQueue.main.async {
                    self._eventSink!(argsMap)
                }
            }
            _eventData.rotation = frame.rotation()
        }
        
        if(_eventData.width != frame.width() || _eventData.height != frame.height()) {
            _eventData.width = frame.width()
            _eventData.height = frame.height()
            if(_eventSink != nil) {
                var argsMap = [String:Any]()
                argsMap["event"]  = "didTextureChangeVideoSize"
                argsMap["id"]     = _textureId
                argsMap["width"]  = _eventData.width
                argsMap["height"] = _eventData.height
                DispatchQueue.main.async {
                    self._eventSink!(argsMap)
                }
            }
        }
    }//sendEvent
    
}//FlutterVideoRenderer


////////////////////////////////////////////////////////////////////////////////////////
//SiprixVoipSdkPlugin
public class SiprixVoipSdkPlugin: NSObject, FlutterPlugin {
    typealias ArgsMap = Dictionary<AnyHashable,Any>

    var _siprixModule : SiprixModule
    var _eventHandler : SiprixEventHandler
    var _textureRegistry : FlutterTextureRegistry
    var _binMessenger : FlutterBinaryMessenger
    var _renderers = [Int64 : FlutterVideoRenderer]()
    var _initialized = false

    init(withChannel channel:FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
        self._siprixModule = SiprixModule()
        self._eventHandler = SiprixEventHandler(withChannel:channel)
        self._textureRegistry = registrar.textures()
        self._binMessenger = registrar.messenger()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: kChannelName, binaryMessenger: registrar.messenger())
        
        let instance = SiprixVoipSdkPlugin(withChannel:channel, registrar:registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let argsMap = call.arguments as? ArgsMap
        if (argsMap==nil) {
            result(FlutterError(code: "-", message: kBadArgumentsError, details: nil))
            return
        }

        if(_initialized) {
            switch call.method {
            case kMethodModuleInitialize   :  handleModuleInitialize(argsMap!, result:result)
            case kMethodModuleUnInitialize :  handleModuleUnInitialize(argsMap!, result:result)
            case kMethodModuleHomeFolder   :  handleModuleHomeFolder(argsMap!, result:result)
            case kMethodModuleVersionCode  :  handleModuleVersionCode(argsMap!, result:result)
            case kMethodModuleVersion      :  handleModuleVersion(argsMap!, result:result)
                    
            case kMethodAccountAdd         :  handleAccountAdd(argsMap!, result:result)
            case kMethodAccountUpdate      :  handleAccountUpdate(argsMap!, result:result)
            case kMethodAccountRegister    :  handleAccountRegister(argsMap!, result:result)
            case kMethodAccountUnregister  :  handleAccountUnregister(argsMap!, result:result)
            case kMethodAccountDelete      :  handleAccountDelete(argsMap!, result:result)
                
            case kMethodCallInvite        :   handleCallInvite(argsMap!, result:result)
            case kMethodCallReject        :   handleCallReject(argsMap!, result:result)
            case kMethodCallAccept        :   handleCallAccept(argsMap!, result:result)
            case kMethodCallHold          :   handleCallHold(argsMap!, result:result)
            case kMethodCallGetHoldState  :   handleCallGetHoldState(argsMap!, result:result)
            case kMethodCallGetSipHeader  :   handleCallGetSipHeader(argsMap!, result:result)
            case kMethodCallMuteMic       :   handleCallMuteMic(argsMap!, result:result)
            case kMethodCallMuteCam       :   handleCallMuteCam(argsMap!, result:result)
            case kMethodCallSendDtmf      :   handleCallSendDtmf(argsMap!, result:result)
            case kMethodCallPlayFile      :   handleCallPlayFile(argsMap!, result:result)
            case kMethodCallStopPlayFile  :   handleCallStopPlayFile(argsMap!, result:result)
            case kMethodCallRecordFile     :  handleCallRecordFile(argsMap!, result:result)
            case kMethodCallStopRecordFile :  handleCallStopRecordFile(argsMap!, result:result)
            case kMethodCallTransferBlind  :  handleCallTransferBlind(argsMap!, result:result)
            case kMethodCallTransferAttended : handleCallTransferAttended(argsMap!, result:result)
            case kMethodCallBye :             handleCallBye(argsMap!, result:result)
    
            case kMethodMixerSwitchToCall :   handleMixerSwitchToCall(argsMap!, result:result)
            case kMethodMixerMakeConference : handleMixerMakeConference(argsMap!, result:result)
    
            case kMethodDvcGetPlayoutNumber:   handleDvcGetPlayoutNumber(argsMap!, result:result)
            case kMethodDvcGetRecordNumber :   handleDvcGetRecordNumber(argsMap!, result:result)
            case kMethodDvcGetVideoNumber  :   handleDvcGetVideoNumber(argsMap!, result:result)
            case kMethodDvcGetPlayout      :   handleDvcGetPlayout(argsMap!, result:result)
            case kMethodDvcGetRecording    :   handleDvcGetRecording(argsMap!, result:result)
            case kMethodDvcGetVideo        :   handleDvcGetVideo(argsMap!, result:result)
            case kMethodDvcSetPlayout      :   handleDvcSetPlayout(argsMap!, result:result)
            case kMethodDvcSetRecording    :   handleDvcSetRecording(argsMap!, result:result)
            case kMethodDvcSetVideo        :   handleDvcSetVideo(argsMap!, result:result)
            case kMethodDvcSetVideoParams  :   handleDvcSetVideoParams(argsMap!, result:result)
            
            case kMethodVideoRendererCreate :  handleVideoRendererCreate(argsMap!, result:result)
            case kMethodVideoRendererSetSrc :  handleVideoRendererSetSrc(argsMap!, result:result)
            case kMethodVideoRendererDispose:  handleVideoRendererDispose(argsMap!, result:result)
    
            default:      result(FlutterMethodNotImplemented)
            }//switch
        }else{
            if(call.method==kMethodModuleInitialize) { handleModuleInitialize(argsMap!, result:result) }
            else { result(FlutterError(code: "UNAVAILABLE", message:kModuleNotInitializedError, details: nil)) }
        }
    }//handle
        
    deinit {
        if (_initialized) {
            _siprixModule.unInitialize()
        }
    }

    func handleModuleInitialize(_ args : ArgsMap, result: @escaping FlutterResult) {
        //Check alredy created
        if (_initialized) {
            result("Already created")
            return
        }
        
        //Get arguments from map
        let iniData = SiprixIniData()
        
        let license = args["license"] as? String
        if(license != nil) { iniData.license = license }
        
        let logLevelFile = args["logLevelFile"] as? Int
        if(logLevelFile != nil) { iniData.logLevelFile = NSNumber(value: logLevelFile!) }
        
        let logLevelIde = args["logLevelIde"] as? Int
        if(logLevelIde != nil) { iniData.logLevelIde = NSNumber(value: logLevelIde!) }
        
        let rtpStartPort = args["rtpStartPort"] as? Int
        if(rtpStartPort != nil) { iniData.rtpStartPort = NSNumber(value: rtpStartPort!) }
        
        let tlsVerifyServer = args["tlsVerifyServer"] as? Bool
        if(tlsVerifyServer != nil) { iniData.tlsVerifyServer = NSNumber(value: tlsVerifyServer!) }
        
        let singleCallMode = args["singleCallMode"] as? Bool
        if(singleCallMode != nil) { iniData.singleCallMode = NSNumber(value: singleCallMode!) }
        
        let shareUdpTransport = args["shareUdpTransport"] as? Bool
        if(shareUdpTransport != nil) { iniData.shareUdpTransport = NSNumber(value: shareUdpTransport!) }
      
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        iniData.homeFolder = documentsURL.path + "/"

        let err = _siprixModule.initialize(_eventHandler, iniData:iniData)
        _initialized = (err == kErrorCodeEOK)
        sendResult(err, result:result)
    }
        
    func handleModuleUnInitialize(_ args : ArgsMap, result: @escaping FlutterResult) {
        let err = _siprixModule.unInitialize()
        sendResult(err, result:result)
    }

    func handleModuleHomeFolder(_ args : ArgsMap, result: @escaping FlutterResult) {
        let path = _siprixModule.homeFolder()
        result(path)
    }

    func handleModuleVersionCode(_ args : ArgsMap, result: @escaping FlutterResult) {
        let versionCode = _siprixModule.versionCode()
        result(versionCode)
    }

    func handleModuleVersion(_ args : ArgsMap, result: @escaping FlutterResult) {
        let version = _siprixModule.version()
        result(version)
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Account methods implementation

    func parseAccData(_ args : ArgsMap) -> SiprixAccData {
        //Get arguments from map
        let accData = SiprixAccData()
        
        let sipServer = args["sipServer"] as? String
        if(sipServer != nil) { accData.sipServer = sipServer! }
        
        let sipExtension = args["sipExtension"] as? String
        if(sipExtension != nil) { accData.sipExtension = sipExtension! }
        
        let sipPassword = args["sipPassword"] as? String
        if(sipPassword != nil) { accData.sipPassword = sipPassword! }
        
        let sipAuthId = args["sipAuthId"] as? String
        if(sipAuthId != nil) { accData.sipAuthId = sipAuthId! }
        
        let sipProxy = args["sipProxy"] as? String
        if(sipProxy != nil) { accData.sipProxy = sipProxy! }
        
        let displName = args["displName"] as? String
        if(displName != nil) { accData.displName = displName! }
        
        let userAgent = args["userAgent"] as? String
        if(userAgent != nil) { accData.userAgent = userAgent! }
        
        let expireTime = args["expireTime"] as? Int
        if(expireTime != nil) { accData.expireTime = NSNumber(value:expireTime!) }
      
        let transport = args["transport"] as? Int
        if(transport != nil) { accData.transport = SipTransport(rawValue: transport!)! }
        
        let port = args["port"] as? Int
        if(port != nil) { accData.port = NSNumber(value:port!) }
         
        let tlsCaCertPath = args["userAgent"] as? String
        if(tlsCaCertPath != nil) { accData.tlsCaCertPath = tlsCaCertPath! }

        let tlsUseSipScheme = args["tlsUseSipScheme"] as? Bool
        if(tlsUseSipScheme != nil) { accData.tlsUseSipScheme = NSNumber(value:tlsUseSipScheme!) }

        let rtcpMuxEnabled = args["rtcpMuxEnabled"] as? Bool
        if(rtcpMuxEnabled != nil) { accData.rtcpMuxEnabled = NSNumber(value:rtcpMuxEnabled!) }

        let instanceId = args["instanceId"] as? String
        if(instanceId != nil) { accData.instanceId = instanceId! }
        
        let ringTonePath = args["ringTonePath"] as? String
        if(ringTonePath != nil) { accData.ringTonePath = ringTonePath! }

        let keepAliveTime = args["keepAliveTime"] as? Int
        if(keepAliveTime != nil) { accData.keepAliveTime = NSNumber(value:keepAliveTime!) }

        let rewriteContactIp = args["rewriteContactIp"] as? Bool
        if(rewriteContactIp != nil) { accData.rewriteContactIp = NSNumber(value: rewriteContactIp!) }

        let verifyIncomingCall = args["verifyIncomingCall"] as? Bool
        if(verifyIncomingCall != nil) { accData.verifyIncomingCall = NSNumber(value: verifyIncomingCall!) }
         
        let forceSipProxy = args["forceSipProxy"] as? Bool
        if(forceSipProxy != nil) { accData.forceSipProxy = NSNumber(value: forceSipProxy!) }
         
        let secureMedia = args["secureMedia"] as? Int
        if(secureMedia != nil) { accData.secureMedia = NSNumber(value:secureMedia!) }
         
        let xheaders = args["xheaders"] as? Dictionary<AnyHashable,Any>
        if(xheaders != nil) { accData.xheaders = xheaders }

        let xContactUriParams = args["xContactUriParams"] as? Dictionary<AnyHashable,Any>
        if(xContactUriParams != nil) { accData.xContactUriParams = xContactUriParams }
        
        let aCodecs = args["aCodecs"] as? [Int]
        if(aCodecs != nil) { accData.aCodecs = aCodecs }
        
        let vCodecs = args["vCodecs"] as? [Int]
        if(vCodecs != nil) { accData.vCodecs = vCodecs }
        
        return accData
    }
    
    func handleAccountAdd(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accData = parseAccData(args)
        let err = _siprixModule.accountAdd(accData)
        setRingtonePath(err, assetPath:accData.ringTonePath)
        if(err == kErrorCodeEOK){
            result(accData.myAccId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: accData.myAccId))
        }
    }

    func handleAccountUpdate(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accData = parseAccData(args)
        let accId   = args[kArgAccId] as? Int

        if(accId != nil) {
            let err = _siprixModule.accountUpdate(accData, accId:Int32(accId!))
            setRingtonePath(err, assetPath:accData.ringTonePath)
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleAccountRegister(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accId      = args[kArgAccId] as? Int
        let expireTime = args[kArgExpireTime] as? Int

        if((accId != nil) && ( expireTime != nil)) {
            let err = _siprixModule.accountRegister(Int32(accId!), expireTime:Int32(expireTime!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleAccountUnregister(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accId = args[kArgAccId] as? Int

        if(accId != nil) {
            let err = _siprixModule.accountUnRegister(Int32(accId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleAccountDelete(_ args : ArgsMap, result: @escaping FlutterResult) {
        let accId = args[kArgAccId] as? Int

        if(accId != nil) {
            let err = _siprixModule.accountDelete(Int32(accId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Calls methods implementation

    func handleCallInvite(_ args : ArgsMap, result: @escaping FlutterResult) {
        //Get arguments from map
        let destData = SiprixDestData()
        
        let toExt = args["extension"] as? String
        if(toExt != nil) { destData.toExt = toExt! }
        
        let fromAccId = args[kArgAccId] as? Int
        if(fromAccId != nil) { destData.fromAccId = Int32(fromAccId!) }
        
        let inviteTimeout = args["inviteTimeout"] as? Int
        if(inviteTimeout != nil) { destData.inviteTimeoutSec = NSNumber(value:inviteTimeout!) }
        
        let withVideo = args[kArgWithVideo] as? Bool
        if(withVideo != nil) { destData.withVideo = NSNumber(value: withVideo!) }
        
        let xheaders = args["xheaders"] as? Dictionary<AnyHashable,Any>
        if(xheaders != nil) { destData.xheaders = xheaders }
     
        let err = _siprixModule.callInvite(destData)
        if(err == kErrorCodeEOK){
            result(destData.myCallId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }

    func handleCallReject(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId     = args[kArgCallId] as? Int
        let statusCode = args[kArgStatusCode] as? Int

        if((callId != nil) && ( statusCode != nil)) {
            let err = _siprixModule.callReject(Int32(callId!), statusCode:Int32(statusCode!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallAccept(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let withVideo = args[kArgWithVideo] as? Bool

        if((callId != nil)&&(withVideo != nil)) {
            let err = _siprixModule.callAccept(Int32(callId!), withVideo:withVideo!)
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallHold(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId != nil) {
            let err = _siprixModule.callHold(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
    }
}

    func handleCallGetHoldState(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let data = SiprixHoldData()
        let err = _siprixModule.callGetHoldState(Int32(callId!), holdState:data)
        if(err == kErrorCodeEOK){
            result(data.holdState.rawValue)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }

    func handleCallGetSipHeader(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let hdrName = args["hdrName"] as? String

        if((callId == nil)||(hdrName == nil)) {
            sendBadArguments(result:result)
            return
        }
        
        let hdrVal = _siprixModule.callGetSipHeader(Int32(callId!), hdrName:hdrName!)
        result(hdrVal)
    }

    func handleCallMuteMic(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let mute   = args["mute"] as? Bool

        if((callId == nil)||(mute==nil)) {
            sendBadArguments(result:result)
            return
        }
        let err = _siprixModule.callMuteMic(Int32(callId!), mute:mute!)
        sendResult(err, result:result)
    }

    func handleCallMuteCam(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let mute   = args["mute"] as? Bool

        if((callId == nil)||(mute==nil)) {
            sendBadArguments(result:result)
            return
        }
        let err = _siprixModule.callMuteCam(Int32(callId!), mute:mute!)
        sendResult(err, result:result)
    }

    func handleCallSendDtmf(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId         = args[kArgCallId] as? Int
        let durationMs     = args["durationMs"] as? Int
        let intertoneGapMs = args["intertoneGapMs"] as? Int
        let method         = args["method"] as? Int
        let dtmfs          = args["dtmfs"] as? String
        
        if((callId == nil)||(durationMs==nil)||(intertoneGapMs==nil)||(dtmfs==nil)||(method==nil)) {
            sendBadArguments(result:result)
            return
        }
        let m = (method! == DtmfMethod.rtp.rawValue) ? DtmfMethod.rtp : DtmfMethod.info
        
        let err = _siprixModule.callSendDtmf(Int32(callId!), dtmfs:dtmfs!,
                                    durationMs:Int32(durationMs!),
                                    intertoneGapMs:Int32(intertoneGapMs!),
                                    method:m)
        sendResult(err, result:result)
    }

    func handleCallPlayFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId        = args[kArgCallId] as? Int
        let pathToMp3File = args["pathToMp3File"] as? String
        let loop          = args["loop"] as? Bool
        
        if((callId == nil)||(pathToMp3File==nil)||(loop==nil)) {
            sendBadArguments(result:result)
            return
        }
        
        let data = SiprixPlayerData()
        let err = _siprixModule.callPlayFile(Int32(callId!), pathToMp3File:pathToMp3File!, 
                                              loop:loop!, playerData:data)
        if(err == kErrorCodeEOK){
            result(data.playerId)
        }else{
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }

    func handleCallStopPlayFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let playerId = args[kArgPlayerId] as? Int
        
        if(playerId != nil) {
            let err = _siprixModule.callStopPlayFile(Int32(playerId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallRecordFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId        = args[kArgCallId] as? Int
        let pathToMp3File = args["pathToMp3File"] as? String
        
        if((callId != nil)||(pathToMp3File != nil)) {
            let err = _siprixModule.callRecordFile(Int32(callId!), pathToMp3File:pathToMp3File!)
            sendResult(err, result:result)
        }else{            
            sendBadArguments(result:result)
        }
    }

    func handleCallStopRecordFile(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        
        if(callId != nil) {
            let err = _siprixModule.callStopRecordFile(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallTransferBlind(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int
        let toExt  = args[kArgToExt] as? String
        
        if((callId != nil) && ( toExt != nil)) {
            let err = _siprixModule.callTransferBlind(Int32(callId!), toExt:toExt!)
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallTransferAttended(_ args : ArgsMap, result: @escaping FlutterResult) {
        let fromCallId = args[kArgFromCallId] as? Int
        let toCallId   = args[kArgToCallId] as? Int
        
        if((fromCallId != nil) && ( toCallId != nil)) {
            let err = _siprixModule.callTransferAttended(Int32(fromCallId!), toCallId:Int32(toCallId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleCallBye(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId != nil) {
            let err = _siprixModule.callBye(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Mixer methods implementation

    func handleMixerSwitchToCall(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId = args[kArgCallId] as? Int

        if(callId != nil) {
            let err = _siprixModule.mixerSwitchCall(Int32(callId!))
            sendResult(err, result:result)
        }else{
            sendBadArguments(result:result)
        }
    }

    func handleMixerMakeConference(_ args : ArgsMap, result: @escaping FlutterResult) {
        let err = _siprixModule.mixerMakeConference()
        sendResult(err, result:result)
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //Siprix Devices methods implementation

    func handleDvcGetPlayoutNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        //let data = SiprixDevicesNumbData()
        //_siprixModule.dvcGetPlayoutDevices(data)
        result(4)//result(data.number)
    }

    func handleDvcGetRecordNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        //let data = SiprixDevicesNumbData()
        //_siprixModule.dvcGetRecordingDevices(data)
        result(0)//result(data.number)
    }

    func handleDvcGetVideoNumber(_ args : ArgsMap, result: @escaping FlutterResult) {
        //let data = SiprixDevicesNumbData()
        //_siprixModule.dvcGetVideoDevices(data)
        result(0)//result(data.number)
    }

    //enum DvcType { case Playout; case Recording; case Video}
    //func doGetDevice(_ dvcType:DvcType, args:ArgsMap, result:@escaping FlutterResult) {
    //    let dvcIndex = args[kArgDvcIndex] as? Int
    //
    //    if(dvcIndex == nil) {
    //        sendBadArguments(result:result)
    //        return
    //    }
    //
    //    let err : Int32
    //    let data = SiprixDeviceData()
    //    switch (dvcType) {
    //        case .Playout   :  err = _siprixModule.dvcGetPlayoutDevice(Int32(dvcIndex!), device:data)
    //        case .Recording :  err = _siprixModule.dvcGetRecordingDevice(Int32(dvcIndex!), device:data)
    //        case .Video     :  err = _siprixModule.dvcGetVideoDevice(Int32(dvcIndex!), device:data)
    //    }
    //    if(err == kErrorCodeEOK) {
    //        var argsMap = [String:Any]()
    //        argsMap[kArgDvcName] = data.name
    //        argsMap[kArgDvcGuid] = data.guid
    //        result(argsMap);
    //    }else{
    //        result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil));
    //    }
    //}

    enum iOSDevices : Int { case kOutSpeaker=0; case kOutEarPiece=1; case kRouteBluetoth=2; case kRouteBuildIn=3}
    func handleDvcGetPlayout(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(DvcType.Playout, args:args, result:result)
        
        let dvcIndex = args[kArgDvcIndex] as? Int
        if(dvcIndex == nil) {
            sendBadArguments(result:result)
            return
        }
        
        var argsMap = [String:Any]()
        switch(dvcIndex!) {
            case iOSDevices.kOutSpeaker.rawValue:    argsMap[kArgDvcName] = "Speaker"
            case iOSDevices.kOutEarPiece.rawValue:   argsMap[kArgDvcName] = "Earpiece"
            case iOSDevices.kRouteBluetoth.rawValue: argsMap[kArgDvcName] = "Bluetoth"
            case iOSDevices.kRouteBuildIn.rawValue:  argsMap[kArgDvcName] = "BuiltIn"
            default:                                 argsMap[kArgDvcName] = "---"
        }
        argsMap[kArgDvcGuid] = String(dvcIndex!)
        result(argsMap);
    }

    func handleDvcGetRecording(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(DvcType.Recording, args:args, result:result)
    }

    func handleDvcGetVideo(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(DvcType.Video, args:args, result:result)
    }


    //func doSetDevice(dvcType:DvcType, args : ArgsMap, result: @escaping FlutterResult) {
    //    let dvcIndex = args[kArgDvcIndex] as? Int;
    //
    //    if(dvcIndex == nil) {
    //        sendBadArguments(result:result);
    //        return;
    //    }
    //
    //    let err : Int32;
    //    switch (dvcType) {
    //        case .Playout   : err = _siprixModule.dvcSetPlayoutDevice(Int32(dvcIndex!));
    //        case .Recording : err = _siprixModule.dvcSetRecordingDevice(Int32(dvcIndex!));
    //        case .Video     : err = _siprixModule.dvcSetVideoDevice(Int32(dvcIndex!));
    //    }
    //    sendResult(err, result:result);
    //}

    func handleDvcSetPlayout(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(.Playout, args:args, result:result)
        
        let dvcIndex = args[kArgDvcIndex] as? Int
        if(dvcIndex == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let ret : Bool;
        switch(dvcIndex) {
            case iOSDevices.kOutSpeaker.rawValue:    ret = _siprixModule.overrideAudioOutput(toSpeaker: true)
            case iOSDevices.kOutEarPiece.rawValue:   ret = _siprixModule.overrideAudioOutput(toSpeaker: false)
            case iOSDevices.kRouteBluetoth.rawValue: ret = _siprixModule.routeAudioToBluetoth()
            case iOSDevices.kRouteBuildIn.rawValue:  ret = _siprixModule.routeAudioToBuiltIn()
            default:                                 ret = false;
        }

        if (ret) { result("Success") }
        else     { result(FlutterError(code: "-", message: "Can't overrideAudioOutput/set route", details: nil)) }
    }

    func handleDvcSetRecording(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(.Recording, args:args, result:result)
    }

    func handleDvcSetVideo(_ args : ArgsMap, result: @escaping FlutterResult) {
        //doGetDevice(.Video, args:args, result:result)
    }

    func handleDvcSetVideoParams(_ args : ArgsMap, result: @escaping FlutterResult) {
         let vdoData = SiprixVideoData()
        
        let noCameraImgPath = args["noCameraImgPath"] as? String
        if(noCameraImgPath != nil) { vdoData.noCameraImgPath = noCameraImgPath }
        
        let framerateFps = args["framerateFps"] as? Int
        if(framerateFps != nil) { vdoData.framerateFps = NSNumber(value: framerateFps!) }
        
        let bitrateKbps = args["bitrateKbps"] as? Int
        if(bitrateKbps != nil) { vdoData.bitrateKbps = NSNumber(value: bitrateKbps!) }
        
        let height = args["height"] as? Int
        if(height != nil) { vdoData.height = NSNumber(value: height!) }
        
        let width = args["width"] as? Int
        if(width != nil) { vdoData.width = NSNumber(value: width!) }
        
        let err = _siprixModule.dvcSetVideoParams(vdoData)
        sendResult(err, result:result)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //Video methods
    
    func handleVideoRendererCreate(_ args : ArgsMap, result: @escaping FlutterResult) {
        let renderer = FlutterVideoRenderer(textureRegistry:_textureRegistry)
        let textureId = renderer.registerTextureAndCreateChannel(binMessenger:_binMessenger)
        _renderers[textureId] = renderer
        result(textureId)
    }
    
    func handleVideoRendererSetSrc(_ args : ArgsMap, result: @escaping FlutterResult) {
        let callId   = args[kArgCallId] as? Int
        let textureId = args[kArgVideoTextureId] as? Int64

        if((callId == nil)||(textureId == nil)) {
            sendBadArguments(result:result)
            return
        }
        
        let renderer = _renderers[textureId!]
        if(renderer == nil) {
            result(FlutterError(code: "-", message: "Renderer for specified texture doesn't exist", details: nil))
            return
        }
        
        //Unsubscribe from previous call
        if(renderer!.srcCallId != FlutterVideoRenderer.kInvalidCallCallId) {
            _siprixModule.callSetVideoRenderer(renderer!.srcCallId, renderer: nil)
        }
        
        //Set new call
        renderer!.srcCallId = Int32(callId!)
        let err = _siprixModule.callSetVideoRenderer(renderer!.srcCallId, renderer: renderer)
        sendResult(err, result:result)
    }
    
    func handleVideoRendererDispose(_ args : ArgsMap, result: @escaping FlutterResult) {
        let textureId = args[kArgVideoTextureId] as? Int64
        if(textureId == nil) {
            sendBadArguments(result:result)
            return
        }
        
        let renderer = _renderers[textureId!]
        if(renderer != nil) {
            _siprixModule.callSetVideoRenderer(renderer!.srcCallId, renderer: nil)
            _renderers.removeValue(forKey: textureId!)
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //Helpers methods
    
    func sendResult(_ err : Int32, result: @escaping FlutterResult) {
        if (err == kErrorCodeEOK) {
            result("Success")
        } else {
            result(FlutterError(code: String(err), message: _siprixModule.getErrorText(err), details: nil))
        }
    }
    
    func sendBadArguments(result: @escaping FlutterResult){
        result(FlutterError(code: "-", message: kBadArgumentsError, details: nil))
    }
    
    func setRingtonePath(_ err : Int32, assetPath: String?) {
        if (err != kErrorCodeEOK) || (assetPath == nil) {
            return;
        }

        let exists = (FileManager.default.fileExists(atPath:assetPath!))
        if(exists) {
            print("Ringtone path: '\(assetPath!)' - exists")
            _eventHandler.setRingTonePath(assetPath!)
            return;
        }

        let index = assetPath!.lastIndex(of: "/")
        if(index != nil) {
            let updatedPath = _siprixModule.homeFolder() + assetPath!.suffix(from: index!).dropFirst()
            print("Ringtone path updated: '\(updatedPath)'")
            _eventHandler.setRingTonePath(updatedPath)
        }
    }
    
}//SiprixVoipSdkPlugin

