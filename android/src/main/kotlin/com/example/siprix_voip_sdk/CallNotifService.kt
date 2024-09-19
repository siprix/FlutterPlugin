package com.example.siprix_voip_sdk

import android.Manifest
import android.app.ActivityManager
import android.app.ActivityManager.RunningAppProcessInfo
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.os.PowerManager.WakeLock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
//import com.google.android.gms.tasks.Task
//import com.google.firebase.FirebaseApp
//import com.google.firebase.messaging.FirebaseMessaging
import com.siprix.AccData.RegState
import com.siprix.SiprixCore
import com.siprix.ISiprixServiceListener
import com.siprix.ISiprixRinger
import com.siprix.SiprixRinger
import java.util.Arrays


class CallNotifService : Service(), ISiprixServiceListener {
    private val kMsgChannelId = "kSiprixSDKMsgChannelId"
    private val kCallBaseNotifId = 555
    private val kForegroundId = 777
    //private var objModel_: ObjModel? = null
    private var ringer_: ISiprixRinger? = null
    private var wakeLock_: WakeLock? = null
    private val binder: IBinder = LocalBinder()
    private var foregroundModeStarted_: Boolean = false

    private var activityClassName_: String = "ActivityClassName"
    private var appContentLabel_: String = "Incoming call"
    private var appRejectBtnLabel_: String = "Reject call"
    private var appAcceptBtnLabel_: String = "Accept call"
    private var appNameLabel_: String = "AppName"
    private var appIconId_: Int = 0

    inner class LocalBinder : Binder() {
        val service: CallNotifService
            get() =// Return this instance of LocalService so clients can call public methods.
                this@CallNotifService
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate")
        ringer_ = SiprixRinger(this)

        //getFirebasePushToken()
        //TODO network state receiver
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy")
        stopForegroundMode()
        notifMgr.cancelAll()

        ringer_ = null

        if(core != null) {
            core?.setServiceListener(null)
            core?.setModelListener(null)
            core?.unInitialize()
            core = null
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "onTaskRemoved")
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent): IBinder? {
        return binder
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")
        val result = super.onStartCommand(intent, flags, startId)
        if (kActionIncomingCallReject == intent.action) {
            handleIncomingCallIntent(intent)
        }

        if((kActionAppStarted == intent.action)&&(intent.extras != null)) {
            core?.setServiceListener(this)
            getLabelsFromIntent(intent)
            createNotifChannel()
        }

        return result
    }

    private fun createNotifChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            //NotificationChannel msgChannel = new NotificationChannel(kMsgChannelId,
            //        appName, NotificationManager.IMPORTANCE_DEFAULT);
            //msgChannel.enableLights(true);
            //notifMgr_.createNotificationChannel(msgChannel);

            val callChannel = NotificationChannel(
                kCallChannelId, appNameLabel_, NotificationManager.IMPORTANCE_HIGH
            )
            callChannel.lockscreenVisibility= Notification.VISIBILITY_PUBLIC
            callChannel.description = "Incoming calls notifications channel" //TODO resource
            //callChannel.enableLights(true);
            notifMgr.createNotificationChannel(callChannel)
        }
    }

    private fun getLabelsFromIntent(intent: Intent) {
        val content = intent.getStringExtra(kAppContentLabel);
        if (content != null) appContentLabel_ = content

        val reject = intent.getStringExtra(kAppRejectBtnLabel);
        if (reject != null) appRejectBtnLabel_ = reject

        val accept = intent.getStringExtra(kAppAcceptBtnLabel);
        if (accept != null) appAcceptBtnLabel_ = accept

        val name = intent.getStringExtra(kAppNameLabel)
        if (name != null) appNameLabel_ = name;

        appIconId_ = intent.getIntExtra(kAppIcon, 0)
    }


    fun setActivityClassName(name: String) {
        activityClassName_ = name
    }

    private fun getIntentActivity(action: String?, bundle: Bundle): PendingIntent {
        val activityIntent = Intent(action)
        activityIntent.setClassName(this, activityClassName_)
        activityIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activityIntent.putExtras(bundle)
        return PendingIntent.getActivity(
            this, 1,
            activityIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun getIntentService(action: String?, bundle: Bundle): PendingIntent {
        val srvIntent = Intent(action)
        srvIntent.setClassName(this, CallNotifService::class.java.name)
        srvIntent.putExtras(bundle)
        return PendingIntent.getService(
            this, 1,
            srvIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun handleIncomingCallIntent(intent: Intent) {
        val args = intent.extras
        val callId = args?.getInt(kExtraCallId) ?: 0
        if (callId <= 0) return
        //if (kActionIncomingCallAccept == intent.action) {
        //    core!!.callAccept(callId, false) //TODO add 'withVideo'
        //} else
        if (kActionIncomingCallReject == intent.action) {
            core!!.callReject(callId)
        }
        cancelNotification(callId)
    }

    private fun cancelNotification(callId: Int) {
        notifMgr.cancel(kCallBaseNotifId + callId)
    }

    private val notifMgr: NotificationManager
        get() = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

    private fun displayIncomingCallNotification(
        callId: Int, accId: Int,
        withVideo: Boolean, hdrFrom: String?, hdrTo: String?
    ) {
        val bundle : Bundle = Bundle()
        bundle.putInt(kExtraCallId, callId)
        bundle.putInt(kExtraAccId, accId)
        bundle.putBoolean(kExtraWithVideo, withVideo)
        bundle.putString(kExtraHdrFrom, hdrFrom)
        bundle.putString(kExtraHdrTo, hdrTo)

        val contentIntent = getIntentActivity(kActionIncomingCall, bundle)
        val pendingAcceptCall = getIntentActivity(kActionIncomingCallAccept, bundle)
        val pendingRejectCall = getIntentService(kActionIncomingCallReject, bundle)

        //Popup style
        val bigTextStyle = NotificationCompat.BigTextStyle()
        bigTextStyle.bigText(hdrFrom)
        bigTextStyle.setBigContentTitle(appContentLabel_)

        val builder: NotificationCompat.Builder = NotificationCompat.Builder(this, kCallChannelId)
            .setSmallIcon(appIconId_)
            .setContentTitle(appContentLabel_)
            .setContentText(hdrFrom)
            .setAutoCancel(true)
            .setChannelId(kCallChannelId)
            .setDefaults(Notification.DEFAULT_ALL)
            .setContentIntent(contentIntent)
            .setFullScreenIntent(contentIntent, true)
            .setOngoing(true)
            .setStyle(bigTextStyle)
            .addAction(0, appRejectBtnLabel_, pendingRejectCall)
            .addAction(0, appAcceptBtnLabel_, pendingAcceptCall)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(Notification.PRIORITY_MAX)

        if (Build.VERSION.SDK_INT >= 21)
            builder.setColor(-0x80ff01)

        notifMgr.notify(kCallBaseNotifId + callId, builder.build())
    }

    fun stopForegroundMode() {
        releaseWakelock()
        if (Build.VERSION.SDK_INT >= 33) stopForeground(STOP_FOREGROUND_REMOVE)
        else stopForeground(true)
        foregroundModeStarted_ = false;
    }

    fun startForegroundMode(): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.FOREGROUND_SERVICE)
            != PackageManager.PERMISSION_GRANTED) return false;

        acquireWakelock()

        val contentIntent = getIntentActivity(kActionForeground, Bundle())
        val builder: Notification.Builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, kCallChannelId)
        } else {
            Notification.Builder(this)
        }

        builder.setSmallIcon(appIconId_)
            .setContentTitle(appNameLabel_)
            .setContentText("Siprix call notification service")
            .setContentIntent(contentIntent)
            .build() // getNotification()

        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(kForegroundId, builder.build(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
            )
        } else {
            startForeground(kForegroundId, builder.build())
        }
        foregroundModeStarted_ = true;
        return true;
    }

    fun isForegroundMode() :Boolean {
        return foregroundModeStarted_;
    }

    private fun acquireWakelock() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WAKE_LOCK)
            != PackageManager.PERMISSION_GRANTED) return;

        if (wakeLock_ == null) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock_ = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Siprix:WakeLock.")
        }
        if (wakeLock_ != null && !wakeLock_!!.isHeld) {
            wakeLock_!!.acquire()
        }
    }

    private fun releaseWakelock() {
        if (wakeLock_ != null && wakeLock_!!.isHeld) {
            wakeLock_!!.release()
        }
    }


    override fun onRingerState(start: Boolean) {
        if (start) ringer_?.start() else ringer_?.stop()
    }

    override fun onCallTerminated(callId: Int, statusCode: Int) {
        cancelNotification(callId)
    }

    override fun onCallIncoming(
        callId: Int, accId: Int, withVideo: Boolean,
        hdrFrom: String, hdrTo: String
    ) {
        if (!isAppInForeground) {
            displayIncomingCallNotification(callId, accId, withVideo, hdrFrom, hdrTo)
        }
    }



    private val isAppInForeground: Boolean
        get() {
            val am = this.getSystemService(ACTIVITY_SERVICE) as ActivityManager
            val appProcs = am.runningAppProcesses
            for (app in appProcs) {
                if (app.importance == RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
                    val found = Arrays.asList(*app.pkgList).contains(
                        packageName
                    )
                    if (found) return true
                }
            }
            return false
        }
/*
    private fun getFirebasePushToken() {
        FirebaseMessaging.getInstance().token
            .addOnCompleteListener { task: Task<String?> ->
                if (!task.isSuccessful) {
                    Log.e(TAG,"Fetch FCM token failed: ", task.exception)
                    return@addOnCompleteListener
                }
                Log.e(TAG,"Fetch FCM token success: $task.result")
            }
    }
*/

    companion object {
        private const val TAG = "CallNotifService"

        const val kCallChannelId = "kSiprixCallChannelId_"
        const val kParamToken = "kParamToken"
        const val kActionAppStarted = "kActionAppStarted"
        const val kActionPushToken = "kActionPushToken"
        const val kActionPushNotif = "kActionPushNotif"
        const val kActionForeground = "kActionForeground"
        const val kActionIncomingCall = "kActionIncomingCall"
        const val kActionIncomingCallAccept = "kActionIncomingCallAccept"
        const val kActionIncomingCallReject = "kActionIncomingCallReject"

        const val kExtraCallId   = "kExtraCallId"
        const val kExtraAccId    = "kExtraAccId"
        const val kExtraWithVideo= "kExtraWithVideo"
        const val kExtraHdrFrom  = "kExtraHdrFrom"
        const val kExtraHdrTo    = "kExtraHdrTo"

        const val kAppRejectBtnLabel = "kAppRejectBtnLabel"
        const val kAppAcceptBtnLabel = "kAppAcceptBtnLabel"
        const val kAppContentLabel = "kAppContentLabel"
        const val kAppNameLabel="kAppNameLabel"
        const val kAppIcon="kAppIcon"

        //Single instance, provides access to calling functionality
        //Created - when activity started
        //Destroyed - when service destroyed
        var core: SiprixCore? = null
    }
}

