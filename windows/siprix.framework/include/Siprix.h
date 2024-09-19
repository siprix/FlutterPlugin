#pragma once

#include <stdint.h>

#if defined(_MSC_VER)
#ifdef __COMPILING_SIPRIX
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __declspec(dllimport)
#endif
#elif defined(LINUX)
#define EXPORT __attribute__ ((visibility ("default") ))
#define IMPORT __attribute__ ((visibility ("default") ))
#else
// For all linux based platforms add visibility attribute to EXPORT and DLLIMPORT macros
#define EXPORT __attribute__ ((visibility ("default") ))
#define IMPORT __attribute__ ((visibility ("default") ))
#endif

namespace Siprix {

typedef uint32_t AccountId;
typedef uint32_t CallId;
typedef uint32_t PlayerId;

struct AccData;
struct IniData;
struct DestData;
struct VideoData;

class ISiprixModule;

enum ErrorCode : int32_t
{
    EOK = 0,
    EAlreadyInitialized  = -1000,
    ENotInitialized      = -1001,
    EInitializeFailure   = -1002,
    EObjectNull          = -1003,
    EArgumentNull        = -1004,
    ENotImplemented      = -1005,
    
    EBadSipServer        = -1010,
    EBadSipExtension     = -1011,
    EBadSecureMediaMode  = -1012,
    EBadTranspProtocol   = -1013,
    EBadTranspPort       = -1014,

    EDuplicateAccount    = -1021,
    EAccountNotFound     = -1022,
    EAccountHasCalls     = -1023,
    EAccountDoenstMatch  = -1024,
    ESingleAccountMode   = -1025,

    EDestNumberEmpty     = -1030,
    EDestNumberSpaces    = -1031,
    EDestNumberScheme    = -1032,
    EDestBadFormat       = -1033,
    EDestSchemeMismatch  = -1034,
    EOnlyOneCallAllowed  = -1035,    

    ECallNotFound        = -1040,
    ECallNotIncoming     = -1041,
    ECallAlreadyAnswered = -1042,
    ECallNotConnected    = -1043,
    EBadDtmfStr          = -1044,
    EFileDoesntExists    = -1045,
    EFileExtMp3Expected  = -1046,
    ECallAlreadySwitched = -1047,
    ECallAlredyMuted     = -1048,
    ECallRecAlredyStarted= -1049,
    ECallRecNotStarted   = -1050,
    ECallCantReferBlind  = -1051,
    ECallReferInProgress = -1052,
    ECallCantReferAtt    = -1053,
    ECallReferAttSameId  = -1054,
    EConfRequires2Calls  = -1055,
    ECallIsHolding       = -1056,    
    ERndrAlreadyAssigned = -1057,

    EBadDeviceIndex      = -1070,

    EMicPermRequired     = -1111
};

enum LogLevel : uint8_t
{
    Stack=0,
    Debug,
    Info,
    Warning,
    Error,
    NoLog
};

enum RegState : uint8_t
{
    Success=0, //Registeration success
    Failed,    //Registration failed
    Removed,   //Registration removed
    InProgress
};

enum SecureMedia : uint8_t
{
    Disabled=0,
    SdesSrtp, // SRTP with SDP key negotiation, SAVP profile    
    DtlsSrtp, // SRTP with DTLS key negotiation, SAVP profile
};

enum SipTransport : uint8_t
{
    UDP=0,
    TCP,
    TLS,
};

enum DtmfMethod : uint8_t
{
    DTMF_RTP=0,
    DTMF_INFO
};

enum AudioCodec : uint8_t
{
    Opus   = 65,
    ISAC16 = 66,
    ISAC32 = 67,
    G722   = 68,
    ILBC   = 69,
    PCMU   = 70,
    PCMA   = 71,
    DTMF   = 72,
    CN     = 73
};

enum VideoCodec : uint8_t
{
    H264 = 80,
    VP8  = 81,
    VP9  = 82,
    AV1  = 83
};


enum HoldState : uint8_t
{
    None = 0,
    Local = 1,
    Remote = 2,
    LocalAndRemote = 3
};

enum PlayerState : uint8_t
{
    PlayerStarted = 0, 
    PlayerStopped = 1,
    PlayerFailed  = 2,
};

enum NetworkState : uint8_t
{
    NetworkLost     = 0,
    NetworkRestored = 1,
    NetworkSwitched = 2
};


////////////////////////////////////////////////////////////////////////////
//Callbacks
typedef void(*OnDevicesAudioChanged)();
typedef void(*OnTrialModeNotified)();

typedef void(*OnAccountRegState)(AccountId accId, RegState state, const char* response);
typedef void(*OnNetworkState)(const char* name, NetworkState state);
typedef void(*OnPlayerState)(PlayerId playerId, PlayerState state);
typedef void(*OnRingerState)(bool start);

typedef void(*OnCallIncoming)(CallId callId, AccountId accId, bool withVideo, const char* hdrFrom, const char* hdrTo);
typedef void(*OnCallConnected)(CallId callId, const char* hdrFrom, const char* hdrTo, bool withVideo);
typedef void(*OnCallTerminated)(CallId callId, uint32_t statusCode);
typedef void(*OnCallProceeding)(CallId callId, const char* response);
typedef void(*OnCallTransferred)(CallId callId, uint32_t statusCode);
typedef void(*OnCallRedirected)(CallId origCallId, CallId relatedCallId, const char* referTo);
typedef void(*OnCallDtmfReceived)(CallId callId, uint16_t tone);
typedef void(*OnCallHeld)(CallId callId, HoldState state);
typedef void(*OnCallSwitched)(CallId callId);


////////////////////////////////////////////////////////////////////////////
//Events handler interface

class ISiprixEventHandler
{
public:
    virtual void OnTrialModeNotified() = 0;
    
    virtual void OnDevicesAudioChanged() = 0;
        
    virtual void OnAccountRegState(AccountId accId, RegState state, const char* response) = 0;    
    virtual void OnNetworkState(const char* name, NetworkState state) = 0;
    virtual void OnPlayerState(PlayerId playerId, PlayerState state) = 0;
    virtual void OnRingerState(bool started) = 0;
    
    virtual void OnCallIncoming(CallId callId, AccountId accId, bool withVideo, const char* hdrFrom, const char* hdrTo) = 0;
    virtual void OnCallConnected(CallId callId, const char* hdrFrom, const char* hdrTo, bool withVideo) = 0;
    virtual void OnCallTerminated(CallId callId, uint32_t statusCode) = 0;
    virtual void OnCallProceeding(CallId callId, const char* response) = 0;
    virtual void OnCallTransferred(CallId callId, uint32_t statusCode) = 0;
    virtual void OnCallRedirected(CallId origCallId, CallId relatedCallId, const char* referTo) = 0;
    virtual void OnCallDtmfReceived(CallId callId, uint16_t tone) = 0;
    virtual void OnCallHeld(CallId callId, HoldState state) = 0;
    virtual void OnCallSwitched(CallId callId) = 0;
};



////////////////////////////////////////////////////////////////////////////
//VideoRenderer interface

class IVideoFrame
{
public:
    enum Rotation {
        kRotation_0 = 0,
        kRotation_90 = 90,
        kRotation_180 = 180,
        kRotation_270 = 270
    };
    enum class RGBType { kARGB, kBGRA, kABGR, kRGBA };

    virtual int width() const = 0;
    virtual int height()const = 0;
    virtual Rotation rotation()const =0;

    virtual void ConvertToARGB(RGBType type, uint8_t* dstBuffer,
        int dstWidth, int dstHeight) const = 0;
};

class IVideoRenderer
{
public:
    virtual void OnFrame(IVideoFrame* videoFrame) = 0;
};


////////////////////////////////////////////////////////////////////////////
//Exported functions
extern "C" {

////////////////////////////////////////////////////////////////////////////
//Manage module
EXPORT ISiprixModule* Module_Create();
EXPORT ErrorCode   Module_Initialize(ISiprixModule* module, IniData* ini);
EXPORT ErrorCode   Module_UnInitialize(ISiprixModule* module);
EXPORT bool        Module_IsInitialized(ISiprixModule* module);
EXPORT const char* Module_Version(ISiprixModule* module);
EXPORT uint32_t    Module_VersionCode(ISiprixModule* module);

////////////////////////////////////////////////////////////////////////////
//Manage Accounts
EXPORT ErrorCode Account_Add(ISiprixModule* module, AccData* acc, AccountId* accId);
EXPORT ErrorCode Account_Update(ISiprixModule* module, AccData* acc, AccountId accId);
EXPORT ErrorCode Account_GetRegState(ISiprixModule* module, AccountId accId, RegState* state);
EXPORT ErrorCode Account_Register(ISiprixModule* module, AccountId accId, uint32_t expireTime);
EXPORT ErrorCode Account_Unregister(ISiprixModule* module, AccountId accId);
EXPORT ErrorCode Account_Delete(ISiprixModule* module, AccountId accId);

////////////////////////////////////////////////////////////////////////////
//Manage calls
EXPORT ErrorCode Call_Invite(ISiprixModule* module, DestData* destination, CallId* callId);
EXPORT ErrorCode Call_Reject(ISiprixModule* module, CallId callId, uint16_t statusCode);
EXPORT ErrorCode Call_Accept(ISiprixModule* module, CallId callId, bool withVideo);
EXPORT ErrorCode Call_Hold(ISiprixModule* module, CallId callId);
EXPORT ErrorCode Call_GetHoldState(ISiprixModule* module, CallId callId, HoldState* state);
EXPORT ErrorCode Call_GetVideoState(ISiprixModule* module, CallId callId, bool* hasVideo);
EXPORT ErrorCode Call_MuteMic(ISiprixModule* module, CallId callId, bool mute);
EXPORT ErrorCode Call_MuteCam(ISiprixModule* module, CallId callId, bool mute);
EXPORT ErrorCode Call_SendDtmf(ISiprixModule* module, CallId callId, const char* dtmfs, 
                                uint16_t durationMs, uint16_t intertoneGapMs, DtmfMethod method);
EXPORT ErrorCode Call_PlayFile(ISiprixModule* module, CallId callId, const char* pathToMp3File, 
                                bool loop, PlayerId* playerId);
EXPORT ErrorCode Call_StopPlayFile(ISiprixModule* module, PlayerId playerId);
EXPORT ErrorCode Call_RecordFile(ISiprixModule* module, CallId callId, const char* pathToMp3File);
EXPORT ErrorCode Call_StopRecordFile(ISiprixModule* module, CallId callId);
EXPORT ErrorCode Call_TransferBlind(ISiprixModule* module, CallId callId, const char* toExt);
EXPORT ErrorCode Call_TransferAttended(ISiprixModule* module, CallId fromCallId, CallId toCallId);
EXPORT ErrorCode Call_SetVideoWindow(ISiprixModule* module, CallId callId, void* wnd);
EXPORT ErrorCode Call_SetVideoRenderer(ISiprixModule* module, CallId callId, IVideoRenderer* r);
EXPORT ErrorCode Call_Renegotiate(ISiprixModule* module, CallId callId);
EXPORT ErrorCode Call_Bye(ISiprixModule* module, CallId callId);

////////////////////////////////////////////////////////////////////////////
//Mixer
EXPORT ErrorCode Mixer_SwitchToCall(ISiprixModule* module, CallId callId);
EXPORT ErrorCode Mixer_MakeConference(ISiprixModule* module);

////////////////////////////////////////////////////////////////////////////
//Devices (audio/video/net)
EXPORT ErrorCode Dvc_GetPlayoutDevices(ISiprixModule* module, uint32_t* numberOfDevices);
EXPORT ErrorCode Dvc_GetRecordingDevices(ISiprixModule* module, uint32_t* numberOfDevices);
EXPORT ErrorCode Dvc_GetVideoDevices(ISiprixModule* module, uint32_t* numberOfDevices);

EXPORT ErrorCode Dvc_GetPlayoutDevice(ISiprixModule* module, uint16_t index, 
                  char* name, uint32_t nameLength, char* guid, uint32_t guidLength);
EXPORT ErrorCode Dvc_GetRecordingDevice(ISiprixModule* module, uint16_t index,
                  char* name, uint32_t nameLength, char* guid, uint32_t guidLength);
EXPORT ErrorCode Dvc_GetVideoDevice(ISiprixModule* module, uint16_t index,
                  char* name, uint32_t nameLength, char* guid, uint32_t guidLength);

EXPORT ErrorCode Dvc_SetPlayoutDevice(ISiprixModule* module, uint16_t index);
EXPORT ErrorCode Dvc_SetRecordingDevice(ISiprixModule* module, uint16_t index);

EXPORT ErrorCode Dvc_SetVideoDevice(ISiprixModule* module, uint16_t index);
EXPORT ErrorCode Dvc_SetVideoParams(ISiprixModule* module, VideoData* params);

////////////////////////////////////////////////////////////////////////////
//Callbacks

EXPORT ErrorCode Callback_SetTrialModeNotified(ISiprixModule* module, OnTrialModeNotified callback);
EXPORT ErrorCode Callback_SetDevicesAudioChanged(ISiprixModule* module, OnDevicesAudioChanged callback);

EXPORT ErrorCode Callback_SetAccountRegState(ISiprixModule* module, OnAccountRegState callback);
EXPORT ErrorCode Callback_SetNetworkState(ISiprixModule* module, OnNetworkState callback);
EXPORT ErrorCode Callback_SetPlayerState(ISiprixModule* module, OnPlayerState callback);
EXPORT ErrorCode Callback_SetRingerState(ISiprixModule* module, OnRingerState callback);

EXPORT ErrorCode Callback_SetCallProceeding(ISiprixModule* module, OnCallProceeding callback);
EXPORT ErrorCode Callback_SetCallTerminated(ISiprixModule* module, OnCallTerminated callback);
EXPORT ErrorCode Callback_SetCallConnected(ISiprixModule* module, OnCallConnected callback);
EXPORT ErrorCode Callback_SetCallIncoming(ISiprixModule* module, OnCallIncoming callback);
EXPORT ErrorCode Callback_SetCallDtmfReceived(ISiprixModule* module, OnCallDtmfReceived callback);
EXPORT ErrorCode Callback_SetCallTransferred(ISiprixModule* module, OnCallTransferred callback);
EXPORT ErrorCode Callback_SetCallRedirected(ISiprixModule* module, OnCallRedirected callback);
EXPORT ErrorCode Callback_SetCallSwitched(ISiprixModule* module, OnCallSwitched callback);
EXPORT ErrorCode Callback_SetCallHeld(ISiprixModule* module, OnCallHeld callback);

EXPORT ErrorCode Callback_SetEventHandler(ISiprixModule* module, ISiprixEventHandler* handler);

////////////////////////////////////////////////////////////////////////////
//Set fields of Acc's data
EXPORT AccData* Acc_GetDefault();
EXPORT void     Acc_SetSipServer(AccData* acc, const char* sipServer);
EXPORT void     Acc_SetSipExtension(AccData* acc, const char* sipExtension);
EXPORT void     Acc_SetSipAuthId(AccData* acc, const char* sipAuthId);
EXPORT void     Acc_SetSipPassword(AccData* acc, const char* sipPassword);
EXPORT void     Acc_SetExpireTime(AccData* acc, uint32_t expireTime);
EXPORT void     Acc_SetSipProxyServer(AccData* acc, const char* sipProxyServer);

EXPORT void     Acc_SetStunServer(AccData* acc, const char* stunServer);
EXPORT void     Acc_SetTurnServer(AccData* acc, const char* turnServer);
EXPORT void     Acc_SetTurnUser(AccData* acc, const char* turnUser);
EXPORT void     Acc_SetTurnPassword(AccData* acc, const char* turnPassword);

EXPORT void     Acc_SetUserAgent(AccData* acc, const char* userAgent);
EXPORT void     Acc_SetDisplayName(AccData* acc, const char* displayName);
EXPORT void     Acc_SetInstanceId(AccData* acc, const char* instanceId);
EXPORT void     Acc_SetRingToneFile(AccData* acc, const char* ringTonePath);

EXPORT void     Acc_SetSecureMediaMode(AccData* acc, SecureMedia mode);
EXPORT void     Acc_SetUseSipSchemeForTls(AccData* acc, bool useSipSchemeForTls);
EXPORT void     Acc_SetRtcpMuxEnabled(AccData* acc, bool rtcpMuxEnabled);
EXPORT void     Acc_SetIceEnabled(AccData* acc, bool iceEnabled);

EXPORT void     Acc_SetKeepAliveTime(AccData* acc, uint32_t keepAliveTimeSec);
EXPORT void     Acc_SetTranspProtocol(AccData* acc, SipTransport transp);
EXPORT void     Acc_SetTranspPort(AccData* acc, uint16_t transpPort);
EXPORT void     Acc_SetTranspTlsCaCert(AccData* acc, const char* pathToCaCertPem);
EXPORT void     Acc_SetTranspBindAddr(AccData* acc, const char* ipAddr);
EXPORT void     Acc_SetTranspPreferIPv6(AccData* acc, bool prefer);

EXPORT void     Acc_AddXHeader(AccData* acc, const char* header, const char* value);
EXPORT void     Acc_AddXContactUriParam(AccData* acc, const char* param, const char* value);
EXPORT void     Acc_SetRewriteContactIp(AccData* acc, bool enabled);

EXPORT void     Acc_AddAudioCodec(AccData* acc, AudioCodec codec);
EXPORT void     Acc_AddVideoCodec(AccData* acc, VideoCodec codec);
EXPORT void     Acc_ResetAudioCodecs(AccData* acc);
EXPORT void     Acc_ResetVideoCodecs(AccData* acc);

EXPORT const char* Acc_GenerateInstanceId();

////////////////////////////////////////////////////////////////////////////
//Set fields of Ini's data
EXPORT IniData* Ini_GetDefault();
EXPORT void     Ini_SetLicense(IniData* ini, const char* license);
EXPORT void     Ini_SetLogLevelFile(IniData* ini, uint8_t logLevel);
EXPORT void     Ini_SetLogLevelIde(IniData* ini, uint8_t logLevel);
EXPORT void     Ini_SetShareUdpTransport(IniData* ini, bool shareUdpTransport);
EXPORT void     Ini_SetUseExternalRinger(IniData* ini, bool useExternalRinger);
EXPORT void     Ini_SetDmpOnUnhandledExc(IniData* ini, bool writeDmpUnhandledExc);
EXPORT void     Ini_SetTlsVerifyServer(IniData* ini, bool tlsVerifyServer);
EXPORT void     Ini_SetSingleCallMode(IniData* ini, bool singleCallMode);
EXPORT void     Ini_SetRtpStartPort(IniData* ini, uint16_t rtpStartPort);
EXPORT void     Ini_SetHomeFolder(IniData* ini, const char* homeFolder);
EXPORT void     Ini_AddDnsServer(IniData* ini, const char* dns);

////////////////////////////////////////////////////////////////////////////
//Set fields of Dest's data
EXPORT DestData*Dest_GetDefault();
EXPORT void     Dest_SetExtension(DestData* dest, const char* extension);
EXPORT void     Dest_SetAccountId(DestData* dest, AccountId accId);
EXPORT void     Dest_SetVideoCall(DestData* dest, bool video);
EXPORT void     Dest_SetInviteTimeout(DestData* dest, int inviteTimeoutSec);
EXPORT void     Dest_AddXHeader(DestData* dest, const char* header, const char* value);

////////////////////////////////////////////////////////////////////////////
//Set fields of VideoData
EXPORT VideoData* Vdo_GetDefault();
EXPORT void     Vdo_SetNoCameraImgPath(VideoData* vdo, const char* pathToJpg);
EXPORT void     Vdo_SetFramerate(VideoData* vdo, int fps);
EXPORT void     Vdo_SetBitrate(VideoData* vdo, int bitrateKbps);
EXPORT void     Vdo_SetHeight(VideoData* vdo, int height);
EXPORT void     Vdo_SetWidth(VideoData* vdo, int width);

////////////////////////////////////////////////////////////////////////////
//Get error text
EXPORT const char* GetErrorText(ErrorCode code);

}//extern "C"


}//namespace Siprix
