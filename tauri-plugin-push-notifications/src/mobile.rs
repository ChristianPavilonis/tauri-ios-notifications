use serde::de::DeserializeOwned;
use tauri::{
    plugin::{PluginApi, PluginHandle},
    AppHandle, Runtime,
};

use crate::models::*;

#[cfg(target_os = "ios")]
tauri::ios_plugin_binding!(init_plugin_push_notifications);

// initializes the Kotlin or Swift plugin classes
pub fn init<R: Runtime, C: DeserializeOwned>(
    _app: &AppHandle<R>,
    api: PluginApi<R, C>,
) -> crate::Result<PushNotifications<R>> {
    #[cfg(target_os = "android")]
    let handle = api.register_android_plugin("com.plugin.push_notifications", "ExamplePlugin")?;
    #[cfg(target_os = "ios")]
    let handle = api.register_ios_plugin(init_plugin_push_notifications)?;
    Ok(PushNotifications(handle))
}

/// Access to the push-notifications APIs.
pub struct PushNotifications<R: Runtime>(PluginHandle<R>);

impl<R: Runtime> PushNotifications<R> {
    pub fn ping(&self, payload: PingRequest) -> crate::Result<PingResponse> {
        self.0
            .run_mobile_plugin("ping", payload)
            .map_err(Into::into)
    }

    pub fn register_for_notificaitons(&self) -> crate::Result<String> {
        self.0
            .run_mobile_plugin("requestDeviceToken", ())
            .map_err(Into::into)
    }
}
